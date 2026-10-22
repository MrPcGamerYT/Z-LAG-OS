# Windows 10/11 compatibility policy

Z-LAG targets broad Windows **client** compatibility while prioritizing gaming
latency and frame-time stability. The goal is one playbook, not a separate fork
for each Windows release. No claim of tested support for every historical build,
Insider release, edition, architecture or modified image is made.

## Build-aware behavior

`src/Executables/windows_compatibility.ps1` provides shared checks used by the
GPU scheduling, taskbar and final user-settings scripts:

| Build | Classification | HAGS request | Legacy TaskbarSi sizing |
| --- | --- | --- | --- |
| Unknown / below 10240 | Not identified as Windows 10/11 | Skip | Skip |
| 10240–19040 | Windows 10 family | Skip (feature predates support) | Skip; use Win10 small icons |
| 19041–21999 | Windows 10 family | Eligible, subject to GPU/driver | Skip; use Win10 small icons |
| 22000–22620 | Windows 11 family | Eligible, subject to GPU/driver | Eligible |
| 22621 and newer | Windows 11 family | Eligible, subject to GPU/driver | Skip; keep native sizing |

Build ranges are feature gates, not assertions that every number is a released
or tested Windows client build. Build numbers alone cannot distinguish Windows
Server; Server is not a supported target.

The taskbar script tries existing StuckRects3/StuckRects2 settings. Only known
40/48-byte layouts with matching size headers are edited. The auto-hide bit is
ORed into a copy, preserving other flags and display geometry. Missing/unknown
formats are skipped; no hardcoded desktop geometry is invented. Explorer is
restarted only in the current interactive session, not other logged-in users.
The later user-settings pass also respects TaskbarSi build support so it cannot
undo the taskbar gate.

## Requirements and boundaries

- Windows PowerShell 5.1 and compatible AME Wizard are the tooling baseline.
  Older Windows 10 releases may require tooling updates before use.
- Home, Pro, Enterprise, Education, LTSB/LTSC and N editions expose different
  policies/features. A registry value existing does not prove Windows honors it.
  N editions may require the appropriate Media Feature Pack for media apps.
- x64 is the primary target. ARM64/x86 compatibility depends on Wizard support,
  native binaries, browsers, drivers and Toolbox installers. This work does not
  certify those external dependencies.
- Removed Windows modules/services cannot always be recreated by scripts.
  Optional-feature skips should not be confused with successful application.
- Unsupported/EOL Windows builds remain security risks; a performance playbook
  does not provide security patches or change Microsoft's support lifecycle.
- Newer Windows can change undocumented taskbar/Start behavior. Conservative
  skipping is preferable to corrupting layout state to force a cosmetic tweak.
- AppX repair remains part of the playbook. App compatibility still depends on
  frameworks, licensing, account services, Gaming Services and WebView2.

## Validation

`tests/test_windows_compatibility.ps1` checks pure build decisions across early
Windows 10, LTSC-era, current Windows 10/11 and hypothetical future builds. It
also checks that taskbar flags/geometry are preserved, inputs are not mutated,
and unknown layouts are rejected. It never changes registry or processes.
Windows CI runs it along with real PowerShell syntax parsing.

In this Linux workspace, repository/YAML checks and 15 Python regression tests
passed; Windows PowerShell tests and actual Windows installation tests have not
run. Pure build tests are not a multi-version OS certification.

Before declaring a release supported, validate on disposable snapshots of at
least Windows 10 1809/LTSC 2019, 19044/LTSC 2021, 19045/22H2, Windows 11 22000,
22621/22631, 26100/LTSC 2024 and the newest targeted build. Add early Windows 10
builds when claiming coverage for them. Cover Home/Pro/N editions, a non-English
locale and each claimed architecture. Check both keep/remove options, reboot,
Start/taskbar, network, drivers, Toolbox apps and AppX repair. Record failures
and skipped features rather than labelling every pass fully successful.
