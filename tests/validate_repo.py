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
        if "Update-ZLagHostsFile" not in content or "hosts_file_utils.ps1" not in content:
            fail(f"{name}: shared literal hosts editor is not wired in")


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

    # GamerzOS-parity pieces: tile-grid purge, policy keys, compact UI and the
    # host package cache clear must stay wired in (user-reported regression).
    if "start.tilegrid" not in layout or "DefaultAccount" not in layout:
        fail("set_empty_start_layout.ps1: GamerzOS start.tilegrid purge missing")
    if "start.tilegrid" not in cmd:
        fail("startmenu.cmd: GamerzOS start.tilegrid purge missing")
    for token in (
        "NoStartMenuMFUprogramsList",
        "ShowOrHideMostUsedApps",
        "HideRecentlyAddedApps",
        "HideRecommendedPersonalizedSites",
        "ConfigureStartPins",
        "Start_Layout",
        "UseCompactMode",
        "StartMenuExperienceHost*",
    ):
        if token not in task:
            fail(f"27_cleanStartMenu.yml: GamerzOS-parity key missing: {token!r}")


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

    # 7. Retain the existing display workaround; reject fake global timer tuning.
    core = (TASKS / "26_gamingCore.yml").read_text(encoding="utf-8-sig")
    for token in ("OverlayTestMode", "set_kernel_profile.ps1"):
        if token not in core:
            fail(f"26_gamingCore.yml: missing anti-flicker/pacing key {token!r}")

    # 8. GPU-aware HAGS must stay wired in (no static HwSchMode in task ymls).
    hags = EXECUTABLES / "set_gpu_scheduling.ps1"
    if not hags.is_file():
        fail("set_gpu_scheduling.ps1: GPU-aware HAGS script missing")
    htext = hags.read_text(encoding="utf-8-sig")
    for token in ("HwSchMode", "RTX", "Arc", "SupportsHags"):
        if token not in htext:
            fail(f"set_gpu_scheduling.ps1: missing {token!r}")
    if "set_gpu_scheduling.ps1" not in core:
        fail("26_gamingCore.yml: set_gpu_scheduling.ps1 is not wired in (orphaned)")
    for path in sorted(TASKS.glob("*.yml")):
        code_lines = [
            line
            for line in path.read_text(encoding="utf-8-sig").splitlines()
            if not line.lstrip().startswith("#")
        ]
        if "HwSchMode" in "\n".join(code_lines):
            fail(f"{path.name}: static HwSchMode value reintroduced (GPU detection owns this key)")

    # 9. Fixed-size pagefile must stay wired in (mid-game pagefile-growth stalls).
    pf = EXECUTABLES / "set_pagefile.ps1"
    if not pf.is_file():
        fail("set_pagefile.ps1: fixed-pagefile script missing")
    pftext = pf.read_text(encoding="utf-8-sig")
    for token in ("Win32_PageFileSet", "Win32_ComputerSystem", "AutomaticManagedPagefile"):
        if token not in pftext:
            fail(f"set_pagefile.ps1: missing {token!r}")
    adv = (TASKS / "23_advancedPerf.yml").read_text(encoding="utf-8-sig")
    if "set_pagefile.ps1" not in adv:
        fail("23_advancedPerf.yml: set_pagefile.ps1 is not wired in (orphaned)")

    # 10. The Win11 Xbox gaming-services stack stays out of the idle footprint.
    win11floor = (EXECUTABLES / "win11_process_floor.ps1").read_text(encoding="utf-8-sig")
    if "GameXc" not in win11floor:
        fail("win11_process_floor.ps1: GameXc (Gaming Services) no longer disabled")


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


def _code_only(text: str) -> str:
    """Drop full-line comments so documentation may reference a banned token."""
    return "\n".join(
        line for line in text.splitlines() if not line.lstrip().startswith("#")
    )


def validate_defender_option_gating() -> None:
    """Defender tweaks apply ONLY when defender-disable is selected, and the
    keep path must be explicitly re-established (user-reported: kept Defender
    still broken - protections slow to load, Win10 + Win11)."""
    removal = (TASKS / "07_defenderAggressive.yml").read_text(encoding="utf-8-sig")
    for token in ("DefenderRemoved", "DisableAntiSpyware", "DisableRealtimeMonitoring"):
        if token not in removal:
            fail(f"07_defenderAggressive.yml: option-gated removal must own {token!r}")

    notif = (TASKS / "15_notifications.yml").read_text(encoding="utf-8-sig")
    if "Windows Defender Security Center" in _code_only(notif):
        fail("15_notifications.yml: Defender alert suppression leaked back into the unconditional task")

    push = (EXECUTABLES / "final_push.ps1").read_text(encoding="utf-8-sig")
    if "DefenderRemoved" not in push:
        fail("final_push.ps1: Windows-Security lockdown must be gated on the DefenderRemoved marker")

    floor = (EXECUTABLES / "process_floor.ps1").read_text(encoding="utf-8-sig")
    if "DefenderRemoved" not in floor:
        fail("process_floor.ps1: wscsvc/systray handling must be gated on the DefenderRemoved marker")
    disable_block = _code_only(floor[floor.index("$Disable = @("): floor.index("$disabledCount")])
    if "wscsvc" in disable_block:
        fail("process_floor.ps1: wscsvc reappeared in the unconditional disable list (breaks kept Windows Security)")

    guard = EXECUTABLES / "defender_guard.ps1"
    if not guard.is_file():
        fail("defender_guard.ps1: keep-path enforcement script missing")
    gtext = guard.read_text(encoding="utf-8-sig")
    for token in ("DefenderRemoved", "Update-MpSignature", "wscsvc", "download.microsoft.com"):
        if token not in gtext:
            fail(f"defender_guard.ps1: keep-path enforcement missing {token!r}")
    repair_task = (TASKS / "34_repairAppxRuntime.yml").read_text(encoding="utf-8-sig")
    if "defender_guard.ps1" not in repair_task:
        fail("34_repairAppxRuntime.yml: defender_guard.ps1 is not wired in (orphaned)")

    upd = (EXECUTABLES / "add_update_hosts.ps1").read_text(encoding="utf-8-sig")
    if "0.0.0.0 download.microsoft.com" in upd:
        fail("add_update_hosts.ps1: download.microsoft.com blocks Defender signature downloads")
    if "defender.microsoft.com" not in upd:
        fail("add_update_hosts.ps1: legacy Defender-endpoint cleanup missing")

    block = (TASKS / "13_blockUpdates.yml").read_text(encoding="utf-8-sig")
    if re.search(r'SoftwareDistribution["\']', block):
        fail("13_blockUpdates.yml: full SoftwareDistribution tree deletion reintroduced (clear subfolders only)")

    tools = (EXECUTABLES / "zlag_context_tools.ps1").read_text(encoding="utf-8-sig")
    if "DefenderRemoved" not in tools:
        fail("zlag_context_tools.ps1: GameBoost systray kill must be gated on the DefenderRemoved marker")

    watchdog = (EXECUTABLES / "enforce_service_floor.ps1").read_text(encoding="utf-8-sig")
    ghost_code = _code_only(watchdog)
    if "DefenderRemoved" not in watchdog:
        fail("enforce_service_floor.ps1: boot watchdog systray kill must be gated on the DefenderRemoved marker")
    if ghost_code.count("SecurityHealthSystray") != 1 or "+= 'SecurityHealthSystray'" not in ghost_code:
        fail("enforce_service_floor.ps1: systray kill reappeared in the unconditional boot watchdog list")


def validate_gpu_app_protection() -> None:
    """GPU vendor apps (new NVIDIA App = WinUI3 MSIX) must be protected from
    broad removal passes and from global background bans (user-reported:
    NVIDIA App not working)."""
    edge = (EXECUTABLES / "remove_edge.ps1").read_text(encoding="utf-8-sig")
    if re.search(r"-match\s+'Edge\|WebView", edge):
        fail("remove_edge.ps1: broad 'Edge|WebView' regex package removal reintroduced")
    for token in ("NVIDIA", "Microsoft.EdgeWebView"):
        if token not in edge:
            fail(f"remove_edge.ps1: explicit Edge allowlist / vendor guard missing ({token!r})")

    for name in ("win11_process_floor.ps1", "RemoveStoreServices.ps1"):
        if "NVIDIA" not in (EXECUTABLES / name).read_text(encoding="utf-8-sig"):
            fail(f"{name}: GPU vendor guard missing from package removal")

    remover = (EXECUTABLES / "appx_remover.ps1").read_text(encoding="utf-8-sig")
    if "'NVIDIAApp'" not in remover:
        fail("appx_remover.ps1: explicit NVIDIA App keep entry missing")

    protect = EXECUTABLES / "protect_gpu_apps.ps1"
    if not protect.is_file():
        fail("protect_gpu_apps.ps1: per-app background policy engine missing")
    ptext = protect.read_text(encoding="utf-8-sig")
    for token in ("LetAppsRunInBackground", "BackgroundAccessApplications", "NVIDIA"):
        if token not in ptext:
            fail(f"protect_gpu_apps.ps1: missing {token!r}")

    appx_task = (TASKS / "04_appx.yml").read_text(encoding="utf-8-sig")
    if "protect_gpu_apps.ps1" not in appx_task:
        fail("04_appx.yml: protect_gpu_apps.ps1 is not wired in (orphaned)")

    # The GLOBAL background kill switches must stay gone (per-app scheme).
    for path in (
        TASKS / "03_registry.yml",
        TASKS / "21_win11specific.yml",
        TASKS / "25_networkLatency.yml",
        TASKS / "26_gamingCore.yml",
    ):
        text = _code_only(path.read_text(encoding="utf-8-sig"))
        if "LetAppsRunInBackground" in text or "GlobalUserDisabled" in text:
            fail(f"{path.name}: global UWP background ban reintroduced in code")
    push = _code_only((EXECUTABLES / "final_push.ps1").read_text(encoding="utf-8-sig"))
    if "LetAppsRunInBackground" in push:
        fail("final_push.ps1: global UWP background ban reintroduced")
    floor = _code_only((EXECUTABLES / "process_floor.ps1").read_text(encoding="utf-8-sig"))
    if "GlobalUserDisabled" in floor:
        fail("process_floor.ps1: global UWP background ban reintroduced")

    # Real gaming improvements must stay wired in.
    core = (TASKS / "26_gamingCore.yml").read_text(encoding="utf-8-sig")
    if "set_timer_resolution.ps1" not in core:
        fail("26_gamingCore.yml: high-resolution timer script is orphaned again")
    net = (TASKS / "25_networkLatency.yml").read_text(encoding="utf-8-sig")
    if "EnablePacing" not in net:
        fail("25_networkLatency.yml: pacing preference missing")
    if re.search(r"command:.*(?:chimney=|netdma=)", net):
        fail("25_networkLatency.yml: unsupported Chimney/NetDMA command reintroduced")


def validate_store_removal_contract() -> None:
    remover = (EXECUTABLES / "RemoveStoreServices.ps1").read_text(encoding="utf-8-sig")
    repair = (EXECUTABLES / "repair_appx_runtime.ps1").read_text(encoding="utf-8-sig")
    main = (SRC / "Configuration" / "main.yml").read_text(encoding="utf-8-sig")
    if not re.search(r"05_RemoveStoreServices\.yml'.*option: 'store-disable'", main):
        fail("Store removal must remain gated by store-disable")
    for path in EXECUTABLES.glob("*.ps1"):
        if re.search(r"\$_\s+\.\w+", path.read_text(encoding="utf-8-sig")):
            fail(f"{path.name}: whitespace before member access breaks PowerShell parsing")
    for token in ("StoreRemovalComplete", "$remainingProvisioned", "$failures.Count -gt 0",
                  "exit 1", "${Svc}_*", "-Name Start -Value 4", "Administrator"):
        if token not in remover:
            fail(f"Store removal verification/disable guard missing: {token}")
    if remover.index('-Name StoreRemoved -Value 1') > remover.index('foreach ($Pkg in $StorePackages)'):
        fail("Store removal intent must be saved before package operations")
    if "$storeRemoved -and $entry.Name -in @('wlidsvc', 'TokenBroker')" not in repair:
        fail("AppX repair must not start account services after Store removal")
    if repair.count('REG_DWORD  *0x1$') != 2:
        fail("Both watchdog branches must inspect marker value, not just existence")


def validate_audit_regressions() -> None:
    """Static regression guards, not substitutes for Windows integration tests."""
    gpu = (EXECUTABLES / 'set_gpu_scheduling.ps1').read_text(encoding='utf-8-sig')
    modern = gpu.split('if ($modern) {', 1)[1].split('} else {', 1)[0]
    if not re.search(r"-Name 'HwSchMode' -Value 2\b", modern):
        fail('HAGS enabled value must be 2, not 1')
    if 'Remove-ItemProperty' in gpu or "-Name 'HwSchMode' -Value 1" in gpu:
        fail('Unknown GPU path must preserve existing HAGS preference')

    page = (EXECUTABLES / 'set_pagefile.ps1').read_text(encoding='utf-8-sig')
    if re.search(r'^\s*Set-CimInstance -ClassName', page, re.M):
        fail('Set-CimInstance has no ClassName parameter')
    for token in ('$env:SystemDrive', 'New-CimInstance -ClassName Win32_PageFileSet',
                  '-InputObject $cs', 'configuration verification failed',
                  'AutomaticManagedPagefile = $wasAutomatic', 'exit 1'):
        if token not in page:
            fail(f'Pagefile safety guard missing: {token}')
    if "C:\\pagefile.sys" in page or "DeviceID='C:'" in page:
        fail('Pagefile logic must not hardcode C:')

    toolbox = (EXECUTABLES / 'install_toolbox.ps1').read_text(encoding='utf-8-sig')
    for token in ('throw "SHA256 mismatch', '$process.ExitCode -notin',
                  'if (-not $ok) { exit 1 }'):
        if token not in toolbox:
            fail(f'Toolbox failure guard missing: {token}')
    if 'Write-Output $line' in toolbox:
        fail('Toolbox logs must not contaminate Boolean helper return values')
    if 'Add-MpPreference -ExclusionPath' in toolbox:
        fail('Toolbox download must not bypass antivirus scanning')

    clean = (TASKS / '38_deepClean.yml').read_text(encoding='utf-8-sig')
    for unsafe in ('-RemoveSyncedData', 'wevtutil cl', 'Clear-RecycleBin',
                   'Remove-Item -Recurse', 'Prefetch\\*', 'Windows\\Temp\\*'):
        if unsafe in clean:
            fail(f'Default cleanup must preserve user data, diagnostics and live payloads: {unsafe}')
    if 'AddDays(-7)' not in clean or 'ReparsePoint' not in clean:
        fail('Loose temp-file cleanup must be age-gated and skip reparse points')

    main = (SRC / 'Configuration' / 'main.yml').read_text(encoding='utf-8-sig')
    if not re.search(r"17_removeMSAccount\.yml'.*option: 'store-disable'", main):
        fail('Keep Store must not unconditionally block Microsoft account sign-in')
    if '34_repairAppxRuntime.yml' not in main:
        fail('AppX repair must remain in the playbook')
    repair = (EXECUTABLES / 'repair_appx_runtime.ps1').read_text(encoding='utf-8-sig')
    if 'AppReadiness' not in repair:
        fail('AppX repair must restore packaged-app preparation service')

    release = (ROOT / '.github/workflows/build-release.yml').read_text(encoding='utf-8')
    for unsafe in ('gh release delete', 'git push', 'git tag ', 'sed -i',
                   '${{ github.event.inputs.version }}"'):
        if unsafe in release:
            fail(f'Release workflow must not mutate published source/tags or inject shell input: {unsafe}')
    for token in ('needs: validate-windows', 'python tests/validate_repo.py',
                  'release_context.py', '--target "$RELEASE_COMMIT"', '--verify-tag', 'build-release.sh'):
        if token not in release:
            fail(f'Release validation guard missing: {token}')


def validate_network_hosts_regressions() -> None:
    for path in EXECUTABLES.glob('*.ps1'):
        if re.search(r'(?i)\$(?:host|pid|pshome|home)\s*=', _code_only(path.read_text(encoding='utf-8-sig'))):
            fail(f'{path.name}: assignment to a read-only PowerShell automatic variable')
    helper = (EXECUTABLES / 'hosts_file_utils.ps1').read_text(encoding='utf-8-sig')
    for token in ('[IO.File]::Replace', '.zlag-backup-', 'GetEncoding(28591)',
                  '$present.ContainsKey($hostname)', '$_ -notin $UnblockedHosts', "'::1'"):
        if token not in helper:
            fail(f'Hosts-file preservation guard missing: {token}')
    for name in ('add_telemetry_hosts.ps1', 'add_update_hosts.ps1', 'defender_guard.ps1'):
        source = (EXECUTABLES / name).read_text(encoding='utf-8-sig')
        if 'Update-ZLagHostsFile' not in source:
            fail(f'{name}: hosts mutations must use shared byte-preserving editor')
    tcp = (EXECUTABLES / 'set_tcp_nodelay_per_interface.ps1').read_text(encoding='utf-8-sig')
    if ".ToString('B')" not in tcp or 'New-Item -Path' in tcp:
        fail('TCP tuning must use existing brace-wrapped GUID interface keys')
    nic = (EXECUTABLES / 'disable_network_offload.ps1').read_text(encoding='utf-8-sig')
    for line in nic.splitlines():
        if re.match(r'\s*(?:Set-NetAdapterAdvancedProperty|Disable-NetAdapterPowerManagement)\b', line) and '-NoRestart' not in line:
            fail('NIC tuning must not restart live adapters')
    if 'ValidRegistryValues' not in nic or '-DisplayValue' in nic:
        fail('NIC tuning must use supported registry values, not localized display strings')


def validate_windows_compatibility() -> None:
    helper = (EXECUTABLES / 'windows_compatibility.ps1').read_text(encoding='utf-8-sig')
    for token in ('CurrentBuildNumber', 'CurrentBuild', '$Build -ge 19041',
                  '$Build -ge 22000 -and $Build -lt 22621', '-bor 1',
                  '40, 48', '$Settings.Clone()', 'return 0'):
        if token not in helper:
            fail(f'Windows capability/layout guard missing: {token}')
    for name in ('set_small_taskbar.ps1', 'set_gpu_scheduling.ps1', 'apply_user_settings.ps1'):
        text = (EXECUTABLES / name).read_text(encoding='utf-8-sig')
        if 'windows_compatibility.ps1' not in text:
            fail(f'{name}: shared compatibility checks must remain wired in')
    taskbar = (EXECUTABLES / 'set_small_taskbar.ps1').read_text(encoding='utf-8-sig')
    for token in ('SupportsTaskbarSi', 'Enable-ZLagTaskbarAutoHide', 'StuckRects2', '$_.SessionId -eq $sessionId'):
        if token not in taskbar:
            fail(f'Taskbar compatibility guard missing: {token}')
    if '[byte[]]@(' in taskbar or 'Stop-Process -Name explorer' in taskbar:
        fail('Taskbar must not invent layout blobs or kill every user session')
    gpu = (EXECUTABLES / 'set_gpu_scheduling.ps1').read_text(encoding='utf-8-sig')
    if gpu.index('if (-not $compat.SupportsHags)') > gpu.index("$graphicsKey ="):
        fail('HAGS build support must be checked before modifying registry')


def validate_kernel_profile() -> None:
    profile = (EXECUTABLES / 'set_kernel_profile.ps1').read_text(encoding='utf-8-sig')
    for token in ("Name = 'DisablePagingExecutive'; Value = 0", "Name = 'LargeSystemCache'; Value = 0",
                  "Name = 'SystemResponsiveness'; Value = 10", 'kernel-profile-original.json',
                  '[switch]$Restore', 'Out-File -LiteralPath $backupPath -Encoding UTF8 -NoClobber', 'Z-LAG-Backups', 'Verification failed', '$mutationStarted',
                  '$current.Value -ne $setting.Value', 'Unexpected registry type', 'Rollback failed'):
        if token not in profile:
            fail(f'Kernel profile safety/rollback guard missing: {token}')
    for path in list(TASKS.glob('*.yml')) + list(EXECUTABLES.glob('*.ps1')):
        if path.name == 'set_kernel_profile.ps1':
            continue
        code = _code_only(path.read_text(encoding='utf-8-sig'))
        if re.search(r'bcdedit(?:\.exe)?\s+/(?:set|deletevalue)\b', code, re.I):
            fail(f'{path.name}: forced boot timing is not a universal optimization')
        if re.search(r'(?:FeatureSettingsOverride|IOPageLockLimit|GlobalTimerResolutionRequests)', code):
            fail(f'{path.name}: unsupported/security-weakening universal kernel preset')
        if 'DisablePagingExecutive' in code or 'SystemResponsiveness' in code:
            fail(f'{path.name}: kernel settings must have a single reversible owner')
    timer = (EXECUTABLES / 'set_timer_resolution.ps1').read_text(encoding='utf-8-sig')
    if 'NtQueryTimerResolution' not in timer or 'NtSetTimerResolution' in timer:
        fail('Timer diagnostic must not pretend a transient request is permanent tuning')


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
    validate_store_removal_contract()
    validate_audit_regressions()
    validate_network_hosts_regressions()
    validate_windows_compatibility()
    validate_kernel_profile()
    validate_context_menu_contract()
    validate_defender_option_gating()
    validate_gpu_app_protection()
    yaml_note = f"{yaml_count} YAML files parsed; " if yaml_count else ""
    print(
        f"PASS: Z LAG OS v{version}; {task_count} sequential tasks; "
        f"{executable_count} executable references; {yaml_note}"
        f"{script_count} scripts balanced; perf/appx/context-menu/defender/gpu-app/audit regression guards valid"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, ET.ParseError, json.JSONDecodeError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
