# Repository audit — 2026-10-21

## Bugs addressed

| Area | Defect | Change |
| --- | --- | --- |
| GPU scheduling | HAGS enabled/disabled registry values reversed | Enable requests use HwSchMode=2. Unknown/legacy adapters keep their existing preference. Model detection is not proof of driver support. |
| Pagefile | Invalid Set-CimInstance -ClassName calls; C: hardcoded; failures returned success | Update queried instances; create missing PageFileSet with New-CimInstance; derive system drive, verify configuration and attempt rollback on failure; return nonzero on apply failure. |
| Toolbox download | Logging polluted Boolean function results | Write logs on the host/information stream. Added mocked failure/success tests without network/installer execution. |
| Toolbox integrity | A hash mismatch still executed the download | Abort on mismatch. Missing upstream digest is explicitly warned about, not labelled verified. |
| Toolbox installer | Exit status ignored; timeout could still become success | Check parent timeout and exit status, return nonzero when deployment fails; remove automatic Defender exclusions. This is still not a test of installed apps. |
| Account selection | Keep Store still ran unconditional account-block policies | Gate task 17 with store-disable. Does not automatically reverse policies left by older builds. |
| AppX repair | AppReadiness was protected elsewhere but missing from repair | Include it in demand-start runtime repair and boot configuration. Repair script/task retained. |
| Cleanup | Default deleted local OneDrive documents and Recycle Bin contents; erased crash evidence; recursively wiped live temporary directories | Preserve documents, Recycle Bin and event logs; clean only old loose temp files, excluding reparse points; stop clearing Windows Temp and Prefetch. |
| Release pipeline | Rewrote config, ignored push errors, deleted/recreated published tags/releases; untrusted inputs embedded in shell | Validate existing tag/version/source commit, pass inputs through environment variables, run validation before packaging, verify archive and publish checksum; never delete releases/tags/assets. Existing releases fail safely. |

Earlier Store-removal fixes in this branch remain intact: syntax correction,
per-user service template disabling, removal verification, separate intent and
completion markers, and repair/watchdog respect for the removal selection.

## Validation performed locally

- `python tests/validate_repo.py`: passed dependency-free structural guards.
- With PyYAML installed in an ignored local virtual environment: all 39 task YAML
  files parsed; 38 task references and 43 executable references checked; 41
  PowerShell files passed the lightweight balance check.
- `python -m unittest discover -s tests -v`: mutation tests check that reintroducing
  audited defects causes regression guard failures. These are static tests.
- `git -c core.whitespace=cr-at-eol diff --check`: clean.

Windows CI now parses every PowerShell executable with Windows PowerShell's real
parser, and runs an isolated mocked download test. Those Windows checks have not
been executed in this Linux workspace. Downloading a local PowerShell runtime was
blocked by the sandbox's release-asset host restriction; no parser/runtime pass
is claimed here. No workflow has been triggered and no release has been published.

## Remaining limitations / Windows validation needed

1. AppX repair restores services and policy, not deleted package files/frameworks,
   Store licenses, Gaming Services, WebView2 or app-specific prerequisites. It
   cannot guarantee every Toolbox-installed app will work.
2. Edge/WebView2 removal remains enabled. Applications using WebView2 can crash,
   show blank windows or hang on sign-in. Changing this aggressive policy needs
   an explicit compatibility decision rather than silently reinstalling it.
3. Store removal/account blocking may break licensed apps or sign-in flows;
   manual account services can trigger-start. There is no universal zero-idle
   process guarantee.
4. Fixed pagefile size is not universally optimal. Heavy workloads can exhaust
   commit, and crash dumps may need a larger or system-managed pagefile. Test on
   C: and non-C: Windows installations, existing fixed/system-managed pagefiles,
   insufficient disk space and injected CIM failure; verify rollback and reboot.
5. HAGS depends on Windows build and driver support, not just GPU names. Compare
   frame times on real hardware after reboot. No FPS improvement is guaranteed.
6. The short-lived timer script's request is process-scoped; it does not enforce
   a permanent timer resolution. Boot/logon tasks can overlap a game launched
   immediately after login.
7. Existing debloated systems may already have missing files or old policies.
   These changes do not restore deleted user data or reverse every older tweak.
   Preserved OneDrive documents may remain under the old redirected folder.
8. Some other optimization scripts still suppress Windows errors. This is a
   targeted audit, not a claim that every OS/build/hardware combination is fixed.
9. A restore point is not a full backup and may not restore removed applications.
   Test on disposable Windows 10/11 VM snapshots before applying to a main PC.

## Follow-up: hosts and network compatibility

Additional fixes:

- Removed an assignment to PowerShell's read-only `$Host` automatic variable in
  legacy Defender endpoint cleanup. This could prevent endpoint unblocking.
- Replaced regex/sub-string host checks with a shared token-based editor used by
  telemetry blocking, update blocking and Defender cleanup. It ignores comments
  for matching, handles aliases and IPv6 loopback blocks, adds a missing newline,
  preserves unrelated aliases/comments and supported encoding/BOM bytes, and
  creates a backup during same-volume replacement. No-op runs do not rewrite the
  file or make another backup. Access failures are reported rather than ignored.
- Both hosts-mutating playbook tasks explicitly wait for script completion.
- Per-interface TCP writes use the existing brace-wrapped GUID registry key.
  Invalid GUIDs/missing keys are skipped with diagnostics; no unused registry
  branches are created. TCP preferences are not represented as UDP optimizations.
- NIC tuning uses advertised standard registry keywords/values instead of
  English-only display names and values. All setting changes use `-NoRestart`
  so setup does not repeatedly disconnect the live adapter. Unsupported vendor
  options are skipped, not blindly written. Some changes require reboot.
- Removed unsupported Chimney/NetDMA commands. TCP Chimney is not a UDP
  latency feature. Volume retrim now targets the actual Windows drive, not C:.

Follow-up local checks passed: all 39 task YAML files plus both workflow YAML
files parsed, 42 executable PowerShell scripts passed the lightweight balance
check, and 13 Python regression/mutation tests passed. These are not actual
Windows service, registry or network integration tests. Windows CI additionally
runs `tests/test_hosts_file.ps1` against disposable files to exercise literal
matching, aliases, IPv6, backups, encodings and idempotency; that test has not run
in this Linux workspace.

Remaining boundaries:

- Hosts edits cannot unblock a domain blocked by firewall, DNS, proxy, policy or
  the network. Windows Update service/policy disabling is a separate layer; these
  fixes do not guarantee Defender signature downloads on every Windows build.
- Hosts matching is exact (case-insensitive), not a wildcard/subdomain block.
  The editor supports ASCII-compatible files and UTF-8/UTF-16 BOMs. UTF-32 is
  rejected without writing. Another program concurrently editing hosts can race
  this tool; do not run multiple hosts-management tools during playbook apply.
- NIC vendors expose different properties. Unsupported settings are skipped.
  Disabling interrupt moderation can increase CPU/DPC load and may worsen
  performance on low-end CPUs. No registry tweak can fix ISP routing or guarantee
  lower ping. Compare throughput, latency and CPU use on the actual adapter.
- TCPNoDelay/ACK preferences only affect TCP consumers that honor them; most
  competitive game traffic is UDP. New/reinstalled adapters may need another
  tuning pass. Changes require Windows VM/hardware validation after reboot.

## Follow-up: broad Windows 10/11 build compatibility

Shared build checks now gate HAGS before Windows 10 build 19041 and legacy
Windows 11 taskbar sizing from build 22621 onward. Both taskbar and final user
settings honor the gate. Auto-hide preserves existing recognized layouts and
flags, supports the older StuckRects2 path, and no longer fabricates a fixed
geometry blob or restarts Explorer across all user sessions.

Local validation: 39 task YAML files, 43 executable script balance checks and
15 Python regression tests passed. Pure Windows build/layout tests were added
to CI but have not run here. Coverage targets, tooling requirements, edition and
architecture boundaries are detailed in `docs/windows-compatibility.md`.

## Follow-up: reversible kernel/scheduler baseline

Added `set_kernel_profile.ps1` to Gaming Core with a validated first-run snapshot,
verified registry writes, best-effort rollback and ownership-aware restore.
Snapshot storage is outside the runtime-reset directory so full playbook reapply
does not erase originals. Conflicting memory/MMCSS writers, forced BCD timing,
security-mitigation disabling, obsolete IOPageLockLimit, undocumented global
timer forcing and blanket small input buffers were removed. The short-lived
timer script is now diagnostic only. Details and boundaries: `docs/kernel-profile.md`.

Local checks: 39 YAML task files, 44 executable script balance checks and 17
Python regression tests passed. Windows parser/pure snapshot tests are added to
CI, not executed locally. No measured gaming performance gain or runtime
registry/boot safety certification is claimed.
