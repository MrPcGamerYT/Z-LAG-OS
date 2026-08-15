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


def validate_tasks() -> int:
    main = (SRC / "Configuration" / "main.yml").read_text(encoding="utf-8-sig")
    refs = re.findall(r"!task:\s*\{path:\s*'Tasks\\\\([^']+)'", main)
    files = {path.name for path in TASKS.glob("*.yml")}
    if len(refs) != 37:
        fail(f"expected 37 active task references, found {len(refs)}")
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


def main() -> int:
    version = validate_metadata()
    validate_data_files()
    task_count = validate_tasks()
    executable_count = validate_executable_references()
    validate_runtime_layout()
    validate_welcome_registration()
    print(
        f"PASS: Z LAG OS v{version}; {task_count} sequential tasks; "
        f"{executable_count} executable references; XML/JSON/runtime/Welcome task valid"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, ET.ParseError, json.JSONDecodeError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
