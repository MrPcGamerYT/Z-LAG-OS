# Reversible kernel/scheduler baseline

This is a Windows configuration profile, **not a modified kernel, overclock or
universally fastest preset**. It prioritizes a predictable client baseline over
undocumented timing switches. It runs once during Gaming Core and exits.

## Settings

| Setting | Profile | Reason / limit |
| --- | --- | --- |
| DisablePagingExecutive | 0 | Permit pageable kernel code to be reclaimed under memory pressure; forcing nonpageability is not a universal low-RAM optimization. |
| LargeSystemCache | 0 | Desktop/client cache policy rather than server-style cache preference. |
| Win32PrioritySeparation | 38 / 0x26 | Foreground scheduling preference. Does not set a real-time priority or pin threads/disable E-cores. Not every game benefits. |
| MMCSS SystemResponsiveness | 10 | Valid MMCSS reserve setting. Values below 10, including 0, are treated as 20 by MMCSS rather than a zero reserve. It affects participating multimedia workloads, not a guarantee of extra game CPU time. |

The existing MMCSS Games profile now uses Priority=2 with High category rather
than an ineffective Priority=6 claim (High-category task priority is treated as
2). No claim that the GPU Priority registry field forces GPU hardware priority
or that legacy SFIO Priority optimizes modern Windows storage is made.

Memory compression remains enabled when supported by the existing guarded task.
Required AppX repair remains unchanged and wired into the playbook.

## Removed blanket tweaks

- No forced `disabledynamictick`, `tscsyncpolicy`, platform clock/tick or other
  BCDEdit writes during power-plan/kernel tuning. Windows/firmware choose timers.
- No undocumented `GlobalTimerResolutionRequests` setting. The timer script only
  queries current/bound timer resolution; it does not request permanent 0.5 ms.
- No automatic FeatureSettingsOverride/Mask security-mitigation disabling or
  obsolete IOPageLockLimit write. This does not re-enable mitigations already
  disabled by an older install or by another tool.
- No forced 32-packet mouse/keyboard class queues. These are capacity buffers,
  not a latency delay; reducing them can lose input under load/high polling.
- Final push/process-floor scripts no longer overwrite this profile's memory
  settings later. One owner avoids contradictory settings and broken rollback.

## Backup, restore and errors

Before tuning, every target key/type must be readable and supported. The tool
records the original values (including absent values) in:

`%ProgramData%\Z-LAG-Backups\kernel-profile-original.json`

This directory is outside the runtime reset's deleted folders. The original
snapshot is not overwritten on reapply. A corrupt/incompatible existing snapshot
aborts before tuning. The tool verifies each applied value; failures trigger a
best-effort rollback to the state immediately before that invocation and exit 1.
Rollback failures are warnings that require manual attention.

The script and build helper are retained in `%SystemRoot%\Z-LAG-OS`. From an
**elevated Windows PowerShell**:

```powershell
& "$env:SystemRoot\Z-LAG-OS\set_kernel_profile.ps1" -Restore
```

Restore validates the snapshot schema and approved registry targets. It restores
only values that still match this profile, leaving newer user/system changes
alone. Absent original values are removed. The snapshot is retained for future
restore/reapply; it records the first profile installation, not every historical
Windows tweak. Reboot after apply/restore before comparing results.

Restore covers these **four values only**, not the entire playbook, MMCSS Games
profile, power plan, removed apps, drivers or older BCD/security overrides. Old
boot/registry tweaks may remain after upgrading; without an ownership snapshot
it is unsafe to guess and delete administrator-selected settings automatically.

## Validation and measurement

Local structural/YAML checks and 17 Python regression tests pass. Windows CI
parses the scripts and tests extracted pure profile/snapshot functions, including
rejection of arbitrary restore targets and corrupt JSON. Those Windows tests
have not run in this Linux workspace. Real registry apply/restore, reboot safety
and performance improvements have **not** been validated here.

Use Windows 10/11 VM snapshots first. Test an absent original value, existing
DWORDs, a deliberately corrupt snapshot, a denied write, reapply, restore and a
later user edit. Verify the original snapshot survives a full playbook reapply.
Then compare on real hardware using the same game replay/settings, driver,
power source and temperatures. Record frame-time p95/p99, 1% lows, input response,
CPU utilization, DPC/ISR load and memory pressure. Keep the setting only if the
actual workload improves. Kernel, drivers, thermal limits, game engines and
network conditions prevent a universal zero-lag or FPS guarantee.
