#!/usr/bin/env python3
"""Dependency-free structural validation for the Z LAG OS playbook."""

from __future__ import annotations

import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
TASKS = SRC / "Configuration" / "Tasks"
EXECUTABLES = SRC / "Executables"


def fail(message: str) -> None:
    raise AssertionError(message)


def validate_metadata() -> str:
    config = ET.parse(SRC / "playbook.conf").getroot()
    version = config.findtext("Version")
    if not version:
        fail("playbook.conf has no Version")
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    if f"Version: {version}" not in readme:
        fail(f"README badge does not match playbook version {version}")
    if f"Z LAG OS v{version}" not in readme:
        fail(f"README footer does not match playbook version {version}")
    return version


def validate_data_files() -> None:
    for path in SRC.rglob("*.json"):
        json.loads(path.read_text(encoding="utf-8-sig"))
    for path in SRC.rglob("*.xml"):
        ET.parse(path)


def validate_yaml_files() -> int:
    """Full YAML parse of every playbook file when PyYAML is available.

    AME task files use custom tags (!task, !registryValue, ...) which are
    accepted through a permissive multi-constructor. Skips silently when
    PyYAML is not installed (CI installs it; the check is best-effort locally).
    """
    try:
        import yaml  # type: ignore
    except ImportError:
        return 0

    class AnyTagLoader(yaml.SafeLoader):
        pass

    def construct_unknown(loader, suffix, node):  # noqa: ANN001
        if isinstance(node, yaml.MappingNode):
            return loader.construct_mapping(node, deep=False)
        if isinstance(node, yaml.SequenceNode):
            return loader.construct_sequence(node)
        return loader.construct_scalar(node)

    AnyTagLoader.add_multi_constructor("!", construct_unknown)

    count = 0
    for path in sorted((SRC / "Configuration").rglob("*.yml")):
        try:
            yaml.load(path.read_text(encoding="utf-8-sig"), Loader=AnyTagLoader)
        except yaml.YAMLError as error:
            fail(f"{path.name}: YAML parse error: {error}")
        count += 1
    return count


def validate_tasks() -> int:
    main = (SRC / "Configuration" / "main.yml").read_text(encoding="utf-8-sig")
    refs = re.findall(r"!task:\s*\{path:\s*'Tasks\\\\([^']+)'", main)
    files = {path.name for path in TASKS.glob("*.yml")}
    if len(refs) != 38:
        fail(f"expected 38 active task references, found {len(refs)}")
    if not refs or refs[0] != "01_resetZlagCore.yml":
        fail("the previous-runtime reset must be the first task")
    if set(refs) != files:
        fail(f"task mismatch: missing={set(refs)-files}, unreferenced={files-set(refs)}")
    for index, name in enumerate(refs, 1):
        if not name.startswith(f"{index:02d}_"):
            fail(f"task {index} is out of order: {name}")
    return len(refs)


def validate_executable_references() -> int:
    pattern = re.compile(r"command:\s*['\"]\.\\([^'\"]+\.(?:ps1|bat|cmd))", re.I)
    references: list[tuple[Path, str]] = []
    for task in (SRC / "Configuration").rglob("*.yml"):
        for name in pattern.findall(task.read_text(encoding="utf-8-sig")):
            references.append((task, name))
            if not (EXECUTABLES / name).is_file():
                fail(f"{task.relative_to(ROOT)} references missing executable {name}")
    return len(references)


def validate_runtime_layout() -> None:
    scripts = {
        "configure_boot_welcome.ps1": ("show_welcome_panel.ps1", "launch_welcome_panel.vbs"),
        "configure_zlag_context_menu.ps1": ("zlag_context_tools.ps1",),
        "enforce_service_floor.ps1": ("enforce_service_floor.ps1",),
        "repair_appx_runtime.ps1": ("start_appx_runtime.cmd", "repair_appx_runtime.ps1"),
    }
    for script, names in scripts.items():
        content = (EXECUTABLES / script).read_text(encoding="utf-8-sig")
        if "Join-Path $env:SystemRoot" not in content:
            fail(f"{script} does not target the Windows runtime directory")
        for name in names:
            if name not in content:
                fail(f"{script} does not install/reference {name}")

        required_access = (
            "attrib.exe -r -h -s",
            "icacls.exe $Path /inheritance:e",
            "icacls.exe $Path /reset",
            "*S-1-5-32-545:(OI)(CI)RX",
            "*S-1-5-11:(OI)(CI)RX",
        )
        for value in required_access:
            if value not in content:
                fail(f"{script} does not normalize visible runtime access: missing {value!r}")
        forbidden_access = ("attrib.exe +h", "attrib.exe +s", "/inheritance:r")
        for value in forbidden_access:
            if value.lower() in content.lower():
                fail(f"{script} restores a restrictive/hidden runtime setting: {value!r}")

    reset = (EXECUTABLES / "reset_zlag_core.ps1").read_text(encoding="utf-8-sig")
    for value in ("Z LAG Services - Welcome", "ZLAG-EnforceServiceFloor", "ZLAG-StartAppXRuntime"):
        if value not in reset:
            fail(f"runtime reset does not remove task {value!r}")
    for value in ("Join-Path $env:SystemRoot 'Z-LAG-OS'", "attrib.exe -r -h -s", "Remove-ZLagRuntimePath"):
        if value not in reset:
            fail(f"runtime reset is missing {value!r}")


def validate_welcome_registration() -> None:
    content = (EXECUTABLES / "configure_boot_welcome.ps1").read_text(encoding="utf-8-sig")
    required = (
        "Z LAG Services - Welcome",
        "<LogonTrigger>",
        "<LogonType>InteractiveToken</LogonType>",
        "<RunLevel>LeastPrivilege</RunLevel>",
        "System32\\wscript.exe",
        "Register-ScheduledTask",
    )
    for value in required:
        if value not in content:
            fail(f"Welcome task registration is missing {value!r}")
    if re.search(r"New-ItemProperty\s+-Path\s+\$runKey", content, re.I):
        fail("Welcome panel must not be registered through a Registry Run value")

    embedded = re.search(r'\$taskXml\s*=\s*@"\r?\n(.*?)\r?\n"@', content, re.S)
    if not embedded:
        fail("Welcome Task Scheduler XML was not found")
    task_xml = (
        embedded.group(1)
        .replace("$interactiveSid", "S-1-5-21-1-2-3-1001")
        .replace("$xmlWscript", r"C:\Windows\System32\wscript.exe")
        .replace("$xmlLauncher", r"C:\Windows\Z-LAG-OS\launch_welcome_panel.vbs")
    )
    ET.fromstring(task_xml)


def validate_powershell_balance() -> int:
    """Dependency-free brace/paren balance check for every PowerShell script.

    Strips here-strings, quoted strings and comments with a small tokenizer so
    format strings like '{0:N2}' can never cause false positives. Catches the
    truncated-edit bug class (unclosed function bodies) without needing pwsh.
    """
    here_string = re.compile(r'@["\']\r?\n.*?\r?\n["\']@', re.S)
    checked = 0
    for path in sorted(EXECUTABLES.glob("*.ps1")):
        text = here_string.sub("", path.read_text(encoding="utf-8-sig"))
        depth_brace = 0
        depth_paren = 0
        state = None  # None | "'" | '"'
        index = 0
        while index < len(text):
            char = text[index]
            nxt = text[index + 1] if index + 1 < len(text) else ""
            if state == "'":
                if char == "'":
                    if nxt == "'":
                        index += 2
                        continue
                    state = None
            elif state == '"':
                if char == "`":
                    index += 2
                    continue
                if char == '"':
                    if nxt == '"':
                        index += 2
                        continue
                    state = None
            else:
                if char == "'":
                    state = "'"
                elif char == '"':
                    state = '"'
                elif char == "#":
                    newline = text.find("\n", index)
                    index = len(text) if newline == -1 else newline
                    continue
                elif char == "{":
                    depth_brace += 1
                elif char == "}":
                    depth_brace -= 1
                elif char == "(":
                    depth_paren += 1
                elif char == ")":
                    depth_paren -= 1
                if depth_brace < 0 or depth_paren < 0:
                    fail(f"{path.name}: unbalanced closer at offset {index}")
            index += 1
        if state is not None:
            fail(f"{path.name}: unterminated {state} string")
        if depth_brace != 0 or depth_paren != 0:
            fail(
                f"{path.name}: unbalanced braces ({depth_brace:+d}) "
                f"or parentheses ({depth_paren:+d})"
            )
        checked += 1
    return checked


def validate_script_hardening() -> None:
    """Every executable script must declare an explicit error policy so a
    single failed cmdlet can never abort a playbook step half-applied."""
    for path in sorted(EXECUTABLES.glob("*.ps1")):
        content = path.read_text(encoding="utf-8-sig")
        if "ErrorActionPreference" not in content:
            fail(f"{path.name}: missing explicit $ErrorActionPreference")

    # Hosts-file writers must stay idempotent (no duplicate lines on re-run).
    for name in ("add_telemetry_hosts.ps1", "add_update_hosts.ps1"):
        content = (EXECUTABLES / name).read_text(encoding="utf-8-sig")
        if "Select-String" not in content or "Add-Content" not in content:
            fail(f"{name}: idempotent duplicate-check pattern missing")


def validate_power_plan_contract() -> None:
    """The Maximum FPS plan must be tuned BY GUID, activated and verified."""
    power = (EXECUTABLES / "set_power_plan.ps1").read_text(encoding="utf-8-sig")
    required = (
        "/setactive",            # the plan is actually activated
        "/getactivescheme",      # ... and the activation is verified
        "MaxFpsPlanGuid",        # GUID marker for the context-menu tool
        "$targetGuid $setting[0]",  # tuning targets the explicit GUID
    )
    for token in required:
        if token not in power:
            fail(f"set_power_plan.ps1: power-plan contract broken, missing {token!r}")
    if re.search(r"valueindex['\"]?\)?\s+SCHEME_CURRENT", power, re.I):
        fail("set_power_plan.ps1: tuning must target the plan GUID, not SCHEME_CURRENT")

    push = (EXECUTABLES / "final_push.ps1").read_text(encoding="utf-8-sig")
    if "duplicatescheme" in push.lower():
        fail("final_push.ps1: must not duplicate power schemes (creates duplicates on every run)")
    if "MaxFpsPlanGuid" not in push:
        fail("final_push.ps1: must re-activate the recorded Maximum FPS plan GUID")

    tools = (EXECUTABLES / "zlag_context_tools.ps1").read_text(encoding="utf-8-sig")
    if "MaxFpsPlanGuid" not in tools:
        fail("zlag_context_tools.ps1: PowerMaxFps must prefer the recorded plan GUID")


def validate_start_menu_contract() -> None:
    """Start Menu cleaner must stay universal (Win10 + Win11) and race-free."""
    layout = (EXECUTABLES / "set_empty_start_layout.ps1").read_text(encoding="utf-8-sig")
    required = (
        "22000",                    # explicit Win10/Win11 build gate
        "Import-StartLayout",       # Win10 path
        '{"pinnedList":[]}',        # Win11 path
        "start*.bin",               # covers start.bin AND start2.bin
        "StartMenuExperienceHost",  # host stopped before cache deletion
        "HideRecommendedSection",   # Win11 Recommended section hidden
    )
    for token in required:
        if token not in layout:
            fail(f"set_empty_start_layout.ps1: universal contract broken, missing {token!r}")

    cmd = (EXECUTABLES / "startmenu.cmd").read_text(encoding="utf-8-sig")
    if "taskkill" not in cmd.lower() or "startmenuexperiencehost" not in cmd.lower():
        fail("startmenu.cmd: must stop StartMenuExperienceHost before deleting caches")
    if "start*.bin" not in cmd:
        fail("startmenu.cmd: must delete the whole start*.bin family")

    cache = (EXECUTABLES / "clear_start_menu_cache.ps1").read_text(encoding="utf-8-sig")
    if "start*.bin" not in cache:
        fail("clear_start_menu_cache.ps1: must glob start*.bin (start2.bin on Win11 22H2+)")

    task = (TASKS / "27_cleanStartMenu.yml").read_text(encoding="utf-8-sig")
    if "set_empty_start_layout.ps1" not in task:
        fail("27_cleanStartMenu.yml: set_empty_start_layout.ps1 is not wired in (orphaned)")
    if not re.search(r"set_empty_start_layout\.ps1'\s*\r?\n\s*runas:\s*currentUserElevated", task):
        fail("27_cleanStartMenu.yml: layout script must run as currentUserElevated")


def validate_performance_regressions() -> None:
    """Guards for the specific FPS/input bug classes fixed in v5.15-v5.16."""
    # 1. The watchdog tasks must never repeat periodically (mid-game stutter).
    for name in ("enforce_service_floor.ps1", "repair_appx_runtime.ps1"):
        content = (EXECUTABLES / name).read_text(encoding="utf-8-sig")
        if "RepetitionInterval" in content:
            fail(f"{name}: periodic RepetitionInterval reintroduced (mid-game stutter)")

    # 2. Mouse curves must be full 40-byte linear curves, not truncated blobs.
    mouse = (EXECUTABLES / "set_smooth_mouse.ps1").read_text(encoding="utf-8-sig")
    for curve in ("xCurve", "yCurve"):
        match = re.search(rf"\${curve}\s*=\s*\[byte\[\]\]\(([^)]*)\)", mouse, re.S)
        if not match:
            fail(f"set_smooth_mouse.ps1: ${curve} definition missing")
        count = len(re.findall(r"0x[0-9A-Fa-f]{2}", match.group(1)))
        if count != 40:
            fail(f"set_smooth_mouse.ps1: ${curve} has {count} bytes, expected 40")

    # 3. Destructive network stack reset must stay out of the playbook.
    #    Comment lines are ignored so documentation may reference the removal.
    for path in sorted(TASKS.glob("*.yml")) + sorted(EXECUTABLES.glob("*.ps1")):
        code_lines = [
            line
            for line in path.read_text(encoding="utf-8-sig").splitlines()
            if not line.lstrip().startswith("#")
        ]
        text = "\n".join(code_lines)
        if re.search(r"netsh\s+int(?:erface)?\s+ip\s+reset", text, re.I):
            fail(f"{path.name}: destructive 'netsh int ip reset' reintroduced")
        if re.search(r"Disable-MMAgent\b.*-MemoryCompression", text):
            fail(f"{path.name}: memory compression must stay enabled (pagefile hitches)")

    # 4. GPU MSI message limit must never be forced to 1 again.
    push = (EXECUTABLES / "final_push.ps1").read_text(encoding="utf-8-sig")
    if re.search(r'"MessageNumberLimit"\s+-Value\s+1\b', push):
        fail("final_push.ps1: MessageNumberLimit=1 reintroduced (GPU interrupt starvation)")

    # 5. Minimum processor state must stay low (thermal headroom, no throttle).
    power = (EXECUTABLES / "set_power_plan.ps1").read_text(encoding="utf-8-sig")
    match = re.search(r"'PROCTHROTTLEMIN','(\d+)'", power)
    if not match or int(match.group(1)) > 20:
        fail("set_power_plan.ps1: PROCTHROTTLEMIN must be <=20 (thermal throttling)")
    for token in ("48e6b7a6-50f5-4782-a5d4-53bb8f07e226", "ASPM"):
        if token not in power:
            fail(f"set_power_plan.ps1: USB/PCIe power-gating fix missing ({token})")

    # 6. The text-input service must never be hard-disabled (keyboard breakage).
    services = (TASKS / "10_services.yml").read_text(encoding="utf-8-sig")
    if not re.search(r"TabletInputService'\s*,\s*operation:\s*change,\s*startup:\s*3", services):
        fail("10_services.yml: TabletInputService must be demand-start (3)")
    for name in ("process_floor.ps1", "final_push.ps1", "enforce_service_floor.ps1"):
        content = (EXECUTABLES / name).read_text(encoding="utf-8-sig")
        if re.search(r"['\"]TabletInputService['\"]", content):
            fail(f"{name}: TabletInputService reappeared in a disable list")

    # 7. Anti-flicker + frame pacing keys must stay in the gaming core.
    core = (TASKS / "26_gamingCore.yml").read_text(encoding="utf-8-sig")
    for token in ("OverlayTestMode", "GlobalTimerResolutionRequests", "SFIO Priority"):
        if token not in core:
            fail(f"26_gamingCore.yml: missing anti-flicker/pacing key {token!r}")


def validate_appx_safety() -> None:
    """The AppX runtime protection set must never be removed from the keep list."""
    remover = (EXECUTABLES / "appx_remover.ps1").read_text(encoding="utf-8-sig")
    required_keeps = (
        "Microsoft.VCLibs",
        "Microsoft.UI.Xaml",
        "Microsoft.NET.Native",
        "Microsoft.WindowsAppRuntime",
        "Microsoft.DesktopAppInstaller",
        "Microsoft.AAD.BrokerPlugin",
        "Microsoft.AccountsControl",
        "MicrosoftWindows.Client.CBS",
        "Microsoft.Windows.ShellExperienceHost",
        "Microsoft.Windows.StartMenuExperienceHost",
    )
    for keep in required_keeps:
        if f"'{keep}'" not in remover:
            fail(f"appx_remover.ps1: protected runtime package missing: {keep}")

    base = (TASKS / "04_appx.yml").read_text(encoding="utf-8-sig")
    for package in ("Microsoft.WindowsStore", "Microsoft.StorePurchaseApp"):
        if re.search(rf"^\s*'{re.escape(package)}'", base, re.M):
            fail(f"04_appx.yml: {package} must not be removed by the base pass")


def validate_context_menu_contract() -> None:
    """Every context action must be wired end to end: tools -> menu -> reset."""
    tools = (EXECUTABLES / "zlag_context_tools.ps1").read_text(encoding="utf-8-sig")
    menu = (EXECUTABLES / "configure_zlag_context_menu.ps1").read_text(encoding="utf-8-sig")
    reset = (EXECUTABLES / "reset_zlag_core.ps1").read_text(encoding="utf-8-sig")

    validate_set = re.search(r"ValidateSet\(([^)]*)\)", tools, re.S)
    if not validate_set:
        fail("zlag_context_tools.ps1: ValidateSet not found")
    actions = set(re.findall(r"'(\w+)'", validate_set.group(1)))
    if len(actions) < 12:
        fail(f"zlag_context_tools.ps1: expected >=12 actions, found {len(actions)}")

    switch_body = tools[tools.rindex("switch ($Action)"):]
    for action in sorted(actions):
        if f"'{action}'" not in switch_body:
            fail(f"zlag_context_tools.ps1: action {action} missing from switch")

    entries = re.findall(r"Id\s*=\s*'([^']+)';\s*Label\s*=\s*'[^']+';\s*Action\s*=\s*'(\w+)'", menu)
    if len(entries) < 12:
        fail(f"configure_zlag_context_menu.ps1: expected >=12 menu entries, found {len(entries)}")
    for entry_id, action in entries:
        if action not in actions:
            fail(f"menu entry {entry_id!r} references unknown action {action!r}")
        if f"'{entry_id}'" not in reset:
            fail(f"reset_zlag_core.ps1 does not clean menu command {entry_id!r}")

    game_boost = next((entry_id for entry_id, action in entries if action == "GameBoost"), None)
    if not game_boost or entries[0][1] != "GameBoost":
        fail("configure_zlag_context_menu.ps1: GAME BOOST must be the first menu entry")


def main() -> int:
    version = validate_metadata()
    validate_data_files()
    yaml_count = validate_yaml_files()
    task_count = validate_tasks()
    executable_count = validate_executable_references()
    validate_runtime_layout()
    validate_welcome_registration()
    script_count = validate_powershell_balance()
    validate_script_hardening()
    validate_performance_regressions()
    validate_power_plan_contract()
    validate_start_menu_contract()
    validate_appx_safety()
    validate_context_menu_contract()
    yaml_note = f"{yaml_count} YAML files parsed; " if yaml_count else ""
    print(
        f"PASS: Z LAG OS v{version}; {task_count} sequential tasks; "
        f"{executable_count} executable references; {yaml_note}"
        f"{script_count} scripts balanced; perf/appx/context-menu regression guards valid"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, ET.ParseError, json.JSONDecodeError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
