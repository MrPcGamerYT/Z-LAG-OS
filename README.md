# Z LAG OS - Zero Lag Gaming Operating System

[![License: Use Only](https://img.shields.io/badge/License-Proprietary%20%2F%20Use--Only-red.svg)](LICENSE)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%20%2F%2011-0078d7.svg)](https://www.microsoft.com/windows)
[![Framework: AME Wizard](https://img.shields.io/badge/Framework-AME%20Wizard-orange.svg)](https://amelabs.net/)
[![Version: 5.17](https://img.shields.io/badge/Version-5.17-success.svg)](https://github.com/MrPcGamerYT/Z-LAG-OS/releases)
[![Build: Stable](https://img.shields.io/badge/Build-Stable-brightgreen.svg)]()

> **Maximum FPS. Zero Lag. No Bloat.** A performance-driven AME Wizard playbook engineered for competitive gaming, Android emulators (BlueStacks / MSI App Player / LDPlayer), and low-end hardware.

![Z-LAG Wallpaper](src/Executables/Z_LAG_Wallpaper/Desktop.png)

---

### ⚠️ CRITICAL DISCLAIMER
This playbook applies **aggressive system-wide modifications**: disables telemetry, strips built-in apps, blocks updates, removes OneDrive (including local sync folders), Edge/WebView2, Cortana/Widgets, purges services, and modifies kernel power & scheduler policies. It is designed for **performance-critical gaming environments only**. Create a restore point and use on a **Local Offline Account**.

---

## 📚 Table of Contents
- [Core Objectives](#-core-objectives)
- [What's New in v5.17](#-whats-new-in-v517)
- [Optimization Matrix](#️-optimization-matrix)
- [Optional Performance Profiles](#-optional-performance-profiles)
- [Expected Performance Gains](#-expected-performance-gains)
- [What Is Removed vs Preserved](#-what-is-removed-vs-preserved)
- [Compatibility](#-compatibility)
- [FAQ](#-faq)
- [Validation](#-validation)
- [Contributing](#-contributing)
- [License & Credits](#-license--credits)

---

## 🎯 Core Objectives

| Goal | How We Achieve It |
| :--- | :--- |
| **Latency Minimization** | MMCSS system responsiveness tuning, GPU priority boosts, scheduler & I/O lock optimizations, a dedicated high-resolution timer service |
| **Debloat & Privacy** | Removes 60+ built-in apps, blocks 40+ telemetry hosts, disables diagnostics/telemetry tasks and tracking services |
| **RAM Efficiency** | Svchost consolidation, disables Superfetch/Search indexing, turns off visual effects, turns off prefetch, aggressively trims working sets (target idle RAM ~1.2–1.8 GB, ~40–55 background processes) |
| **Gaming & Emulator Boost** | High CPU priority for emulator processes, forces Hardware-Accelerated GPU Scheduling, bypasses fullscreen optimizations, honors GameDVR fullscreen-exclusive mode |
| **Network Latency** | Disables Nagle's algorithm, maximizes network throttling index, normal autotuning, DNS flush for reduced jitter and competitive ping |

---

## 🆕 What's New in v5.17

### v5.17 - universal Win10/11 + expanded Z LAG TOOLBOX context menu

**Universal Windows 10 / Windows 11:** every task is either shared (identical
registry paths/services on both) or properly gated (`builds: ['>=22000']` for
the two Win11-only floors). The new context-menu tools detect the OS at
runtime and use only APIs that exist on both Windows PowerShell 5.1 (Win10)
and Windows 11 builds. Nothing Win11-specific ever runs on Win10 and
vice versa.

**Z LAG Welcome native panel + Z LAG TOOLBOX context menu: kept 100%** -
the interactive Task Scheduler Welcome panel and the top-positioned Z LAG
TOOLBOX desktop submenu remain exactly as before, and the classic (Win10-style)
right-click menu stays enforced on Windows 11 so the submenu is always one
click away.

**5 NEW context-menu tools (12 total, zero background processes - they only
run when clicked and exit immediately):**

| New tool | What it does |
| :--- | :--- |
| **GAME BOOST (One-Click)** | Positioned FIRST. Kills respawned bloat processes (Edge, Widgets, Teams, OneDrive, GameBar...), trims all working sets, flushes DNS - one click right before launching a game |
| **Clear Standby Memory** | Purges the standby page list via `NtSetSystemInformation` - prevents mid-match allocation hitches after long sessions (RAMMap-style, no extra software) |
| **Ping / Latency Test** | Pings router + Cloudflare + Google, shows avg/max/**jitter** per target - check your connection before queueing |
| **Activate Max FPS Power Plan** | One click re-activates the Maximum FPS / Ultimate Performance plan if a driver installer or Windows switched it back |
| **System Info (Gamer View)** | OS build (detects Win10 vs Win11), free/total RAM, CPU cores/threads, GPU + driver version, active power plan, live process count |

Existing tools kept: RAM Trim / Clean, Temp Clean, Recycle Bin Clean, Flush
DNS Cache, Restart Explorer, Sound Manager (Classic), Volume Mixer (Classic).

### v5.16 - true zero-lag pass: AppX crash-proofing, anti-flicker, raw input

**AppX apps can no longer crash (client app stability):**
- `appx_remover.ps1` now hard-protects the full AppX runtime framework set:
  `Microsoft.WindowsAppRuntime` / `WindowsAppSDK` (WinUI3 apps),
  `DesktopAppInstaller` (winget), `SecHealthUI`, `AAD.BrokerPlugin` +
  `AccountsControl` (sign-in brokers - apps hang at login without them),
  `LockApp`, `CloudExperienceHost`, `MicrosoftWindows.Client.CBS`/`Core`
  (Win11 shell surfaces), `CapturePicker` and `PinningConfirmationDialog`.
  These have ~zero idle footprint but removing them causes class-activation
  crashes in every packaged app.
- The Microsoft Store is no longer removed by the BASE app pass - that
  silently broke the "Keep Microsoft Store" option and caused licensing
  failures (= UWP apps crash on launch). Store removal now happens ONLY via
  the store-disable option, which handles licensing services correctly.
- `Microsoft.XboxIdentityProvider` stays in the base pass (zero background
  processes, but Minecraft Launcher / Game Pass sign-in crashes without it).
  The Xbox/Store removal options still remove it for users who choose that.

**Anti-flicker + frame pacing (new ZLAG Gaming Core section):**
- **MPO disabled** (`OverlayTestMode=5`): Multi-Plane Overlay is the #1
  documented cause of screen flicker/stutter on NVIDIA and AMD GPUs. Both
  vendors recommend this exact fix. No background cost.
- **High-resolution timer enforced** (`GlobalTimerResolutionRequests=1`):
  Windows 11 22H2+ coalesces/ignores game timer-resolution requests, causing
  micro-stutter; this forces the kernel to honor them. Safe no-op on Win10.
- **`SFIO Priority=High`** completes the MMCSS Games profile (GPU Priority 8 /
  Priority 6 / High scheduling already set) so game disk I/O outranks
  background I/O - no asset-streaming hitches.
- **Machine-wide GameDVR policy ban** (`AllowGameDVR=0`) on top of the
  existing per-user GameDVR kill - background capture can never re-enable.

**Raw input (mouse/keyboard):**
- Driver-level input queues (`MouseDataQueueSize` / `KeyboardDataQueueSize`)
  set to 32 (default 100) - input events are flushed to the game sooner,
  still deep enough for 8000 Hz mice to never drop packets.

## 🆕 What's New in v5.15

### v5.15 - stability & smoothness pass (mid-game FPS drops + input fixes)

This release fixes the reported "FPS stuck/stutter mid-game" and mouse/keyboard
issues **without adding any background processes or services** - it actually
removes recurring background wakeups:

- **Mid-game stutter fixed - watchdogs no longer run during gameplay.** The
  service-floor watchdog lost its every-15-minutes repetition (boot + logon
  only now; TriggerInfo removal already prevents services returning
  mid-session), and the AppX runtime re-arm no longer repeats every 10 minutes
  forever (boot/logon + one 3-minute post-boot recheck). Both tasks now run at
  below-normal priority with hard execution time limits. Result: **zero
  scheduled Z-LAG activity while you play.**
- **Mouse fixed - correct SmoothMouse curves.** The old build wrote malformed
  24-byte all-zero `SmoothMouseXCurve`/`SmoothMouseYCurve` values that corrupt
  pointer math; v5.15 writes the proper 40-byte linear (MarkC-style) 1:1
  curves and keeps Enhanced Pointer Precision off.
- **Input freezes fixed - USB can never power-gate your mouse/keyboard.** The
  power plan now forces USB selective suspend OFF, USB3 link power management
  OFF and PCIe ASPM OFF (AC + DC), and strips "allow the computer to turn off
  this device" from USB/HID devices.
- **Keyboard fixed - `TabletInputService` is demand-start, not disabled.**
  Hard-disabling the text-input stack broke keyboard input in UWP/search
  surfaces; demand-start keeps 0 idle footprint while staying functional. All
  four floor scripts were aligned so nothing re-disables it.
- **FPS stability - no more thermal throttling.** Minimum processor state was
  locked at 100%, which heat-soaks laptops/SFF PCs until the CPU throttles
  mid-game. Now 5% min / 100% max / aggressive boost + core parking fully off:
  same peak clocks, far more thermal headroom.
- **Frame-time spikes - GPU MSI limit removed.** `MessageNumberLimit=1`
  serialized GPU interrupts; the driver default message count is restored
  (MSI mode itself stays enabled).
- **Hitching fixed - memory compression stays ON.** Disabling it turned every
  memory-pressure event into hard pagefile I/O (stutter on 8/16 GB systems).
  Compression is now explicitly enabled; Superfetch/indexing stay off.
- **Network stability - destructive tweaks removed.** `netsh int ip reset`
  (which wiped the per-interface latency tweaks and could destabilize
  adapters) is gone, and TCP checksum offload is no longer disabled (it pushed
  per-packet work onto the CPU during firefights). Instead the NIC gets real
  latency tuning: interrupt moderation off, energy-efficient Ethernet off, and
  adapter power saving off.
- **Smoothness - font cache preserved, Game Mode on.** `FontCache` is no
  longer killed (UI text re-rendering caused shell stutter), `MouseHoverTime`
  is consistent everywhere, and Game Mode (a pure scheduler policy, no extra
  processes) now protects the foreground game's CPU/GPU time while GameDVR
  capture stays fully disabled.

### v5.14 - publish-quality reliability and Windows runtime storage

- A first-run core reset removes stale Z-LAG tasks, startup values, registry
  state and runtime folders before current payloads are installed.
- Persistent Welcome, context-tool, process-floor and AppX watchdog files are
  stored visibly under `C:\Windows\Z-LAG-OS` with normal file attributes,
  inherited ACLs and standard-user read/execute access. ProgramData remains for
  logs, backups and diagnostics.
- The Welcome panel now uses an interactive Task Scheduler logon trigger instead
  of Registry Run/Startup folders, so it is absent from Task Manager Startup apps.
  The task remains visible in Task Scheduler, and its temporary `wscript.exe` /
  `powershell.exe` hosts remain observable through normal Windows administration.
- Every PowerShell file now passes syntax parsing; all JSON/XML/YAML data and the
  exact 01–38 task-to-executable graph pass repository validation.
- Restore-point, power-plan, AppX/Store, Toolbox, AppX watchdog, user-default
  registry, wallpaper/default-hive, Start Menu, ReTrim and TEMP cleanup paths
  handle expected missing/disabled resources without noisy first-run failures.
- Toolbox installation runs in the actual elevated user profile with bounded
  installer and executable-detection waits.
- Protected Windows binaries no longer receive a permanent Everyone deny ACE;
  notification behavior remains policy-driven and reversible.
- Added `tests/validate_repo.py` and documented the release validation command.

---

## 🛠️ Optimization Matrix

| Category | What Gets Tuned | Benefit |
| :--- | :--- | :--- |
| **Kernel & CPU** | Ultimate Performance power plan, core parking disabled, power throttling off | Eliminates downclocking and frequency-scaling lag |
| **Process Management** | Svchost consolidation plus a non-resident boot/logon/15-minute service-floor enforcer | Prevents trigger-start and per-user services from causing idle process creep |
| **Graphics Pipeline** | Forces HAGS, MSI mode on GPU, disables fullscreen optimizations | Stabilizes 1% lows, reduces frame-time variance |
| **Input & Timer** | Disabled dynamic tick, high-resolution timer, instant key/mouse response | Lower DPC latency, snappier input |
| **Networking** | Global + per-interface TCP no-delay, offload tuning, DNS flush | Reduced jitter, competitive ping |
| **Privacy & Telemetry** | Telemetry blocked at host + task level, update hosts blocked | Zero background upload |
| **UI/UX** | Transparency & animations off, forced dark theme, clean Start layout, first-position Z LAG TOOLBOX submenu, classic sound tools, native loading status and Welcome-only panel | Less RAM usage, clean labels and visible boot progress |

---

## ⚙️ Optional Performance Profiles

During AME Wizard setup you get radio pages so you control how aggressive the optimization is:

| Page | Default | Max Performance Option | Effect |
| :--- | :--- | :--- | :--- |
| **Browser** | Chrome | Brave / OperaGX / None | Choose a pre-installed browser; affects privacy posture |
| **Defender** | Keep (Recommended) | Disable | Frees ~150–300 MB RAM and removes scanning stutter. Advanced users only |
| **Bluetooth** | Keep | Disable | Removes Bluetooth drivers/services. Only if you use wired peripherals |
| **Wi-Fi** | Keep | Disable | Stops WLAN services. Only if you are on Ethernet |
| **MS Store & Services** | Keep (Recommended) | Remove | **Totally removes** Store + Xbox + MS account/cloud apps & services, saving 300–500 MB. Only the Windows shell's own AppX runtime is kept so apps still launch |

**Z-LAG Toolbox** is always installed from [GitHub Releases](https://github.com/MrPcGamerYT/Z-LAG-TOOLBOX/releases) as the official app/driver/tweak hub. Alt App Installer is not used. It installs Win32 (EXE/MSI) apps, so even with Microsoft services removed, downloaded apps launch instead of crashing.

---

## 📊 Expected Performance Gains

*Note: varies by hardware. Tested on i5-11400F + GTX 1660 + 16GB.*

| Metric | Stock Windows 11 | After Z LAG OS | Delta |
| :--- | :--- | :--- | :--- |
| **Idle RAM after boot** | 3.8–4.5 GB | 1.2–1.9 GB | -60% |
| **Processes** | 180–220 | ~40–55 (target as low as possible) | -70%+ |
| **Boot Time (SATA SSD)** | 22s | 12–14s | ~-40% |
| **DPC Latency (LatencyMon)** | 300–600µs spikes | 40–90µs avg | -80% |
| **FPS 1% lows (Valorant 1080p Low)** | 110 FPS | 165 FPS | +50% 1% low stability |
| **BlueStacks 5 startup** | 18s | 9s | 2x faster |
| **Disk Idle I/O** | 5–10 MB/s telemetry | <0.5 MB/s | ~-95% |

Optimization achieves: less background CPU, more CPU cycles to game threads via high MMCSS priority, and core parking disabled to prevent downclock spikes.

---

## 🧹 What Is Removed vs Preserved

### Removed / Disabled
- Built-in apps: People, Maps, Alarms, Camera, 3D Viewer, Sticky Notes, Mail, Calendar, Feedback, GetStarted, PowerAutomate, Clipchamp, Office Hub, Xbox layers (optional), YourPhone, and more
- Services: DiagTrack, dmwappush, WerSvc, SysMain, WSearch, VSS/SwPrv, RpcLocator, SNMPTRAP, vds, WMPNetworkSvc, ssh-agent, MSDTC, Windows Backup, MapsBroker, Xbox networking, RemoteRegistry, and many per-user service instances
- ULTRA (v5.11): System Restore/VSS, notifications, network discovery, file sharing, hotspot/ICS, WebDAV, iSCSI, clipboard history are now fully disabled for gaming (see the v5.11 notes before applying)
- Optional removals: Defender, Bluetooth stack, Wi-Fi stack, Store + MS identity/gaming services (all gated behind options)
- Telemetry: CEIP tasks, appraiser, 43 hosts-file entries, update-host blocking
- Features: OneDrive client/setup/sync integration and local sync folders, Widgets, Edge, WebView2 Runtime, Transparency, Animations, Search highlights, News/Feeds, Cortana hotkey

### Preserved (for stability)
- **WebView2 is not preserved in v5.12** - it is deliberately removed; apps that require it must supply or reinstall their own runtime
- **NVIDIA / AMD / Intel GPU driver packages** - never removed
- **Critical System apps**: desktop backbone and security-health UI
- **VC++ Runtimes 2015+** - installed fresh (x86 + x64 + ARM64 where applicable)
- **DirectX Jun2010** redist - installed for legacy games
- **.NET Framework** - left intact
- **Win32 core**: SFC, DISM, core audio, networking core (TCP/IP, DHCP, DNS cache kept)
- **Windows shell AppX runtime** (AppXSvc, StateRepository, LicenseManager, ClipSVC) - kept even with "Remove MS Services" so the Start Menu/Search and Toolbox-installed apps keep launching
- **WLAN / Bluetooth hardware** - kept by default; only removed if you opt in
- **Windows core / boot** - boot & system-critical services (Start ≤ 1) are never touched, so the OS boots cleanly on both Windows 10 and 11 even with ULTRA applied

---

## 💻 Compatibility (Universal Windows 10 + Windows 11)

The playbook is **version-universal**: every OS-sensitive step detects the running
build and applies the correct tweak, so the same `.apbx` works perfectly on both.

- **Windows 10**: 1809, 1903, 1909, 20H1, 20H2, 21H1, 21H2, 22H2
- **Windows 11**: 21H2 (22000), 22H2 (22621), 23H2 (22631), 24H2 (26100+)
- Architecture: x64 dominant, x86 limited, ARM64 (Surface) supported
- Languages: All display languages
- Framework: AME Wizard latest beta (0.7+)

**Version-aware highlights**
- **Taskbar** (`set_small_taskbar.ps1`): Win10 gets small icons + auto-hide + hidden
  search/task view/badges; Win11 gets left-aligned + small taskbar + hidden
  search/Copilot/task view/badges + auto-hide. No more Win10-only registry values
  being written onto Windows 11.
- **Power plan**: uses the real Ultimate Performance GUID and falls back to High
  Performance on editions where Ultimate is unavailable; tunes both AC and DC so
  laptops match desktops.
- **Windows 11 extra process floor** (`32_win11ProcessFloor.yml`, gated
  `builds: >=22000`): disables Win11-only services (AI/Copilot/Recall runtime,
  data-usage, notifications, per-user bloat), removes Win11-only apps, kills
  AI/Widgets processes and locks Copilot/Recall/Chat/Suggestions via policy — so
  Windows 11's idle count lands close to Windows 10's.
- **AppX / bloat removal**: all package/service removals are tolerant
  (`-ErrorAction SilentlyContinue`), so packages that only exist on one OS are
  simply skipped on the other.
- **Start menu, Edge/WebView2 removal, OneDrive removal, wallpaper, classic sound, boot Welcome and AppX repair**: all build-safe.

---

## ❓ FAQ

**Q: Is this a custom Windows ISO?**
A: No. It's a playbook (`.apbx`) that transforms a clean official Windows install via AME Wizard. No piracy.

**Q: Where did Alt App Installer go?**
A: Removed in v5.6. The playbook installs [Z-LAG Toolbox](https://github.com/MrPcGamerYT/Z-LAG-TOOLBOX/releases) instead.

**Q: Removed the Store and now Xbox Game Bar is gone?**
A: Expected. Use Z-LAG Toolbox to install apps, or keep the Store if you need Xbox services.

**Q: Why do apps installed by Z-LAG Toolbox never crash silently?**
A: The toolbox installer (1) downloads the latest release with retries, (2) verifies the file's SHA-256 digest, (3) smoke-tests the installed binary, and (4) pre-flights the packaged-app launch stack (LicenseManager, ClipSVC, AppXSvc, StateRepository) before it installs anything. Every result — success or failure — is written to `C:\ProgramData\Z-LAG-OS\toolbox_install.log` and registry markers, so nothing can fail silently. Since it installs Win32 apps, they run even with Microsoft services removed.

**Q: I removed the Store and still get "The service has not been started"?**
A: This is fixed in v5.10. The playbook keeps the *Windows shell's own* AppX runtime (License Manager, ClipSVC, AppXSvc, StateRepository) alive — those are part of Windows, not the Store — and the self-healing watchdog re-arms them on boot/logon. Microsoft account services (`wlidsvc`, `TokenBroker`) are left **demand-only** when you removed Microsoft services, so they add zero idle processes but can still answer if an app asks. To fix it manually, run `repair_appx_runtime.ps1` as Admin:

```
sc.exe config LicenseManager start= auto
sc.exe config ClipSVC start= auto
sc.exe config AppXSvc start= demand
sc.exe config StateRepository start= demand
net start LicenseManager
net start ClipSVC
```

Reboot and open the app. You still have no Microsoft Store.

**Q: I chose "Remove Microsoft Store & All MS Services" — is *everything* Microsoft gone?**
A: All Microsoft *apps* (Store, Xbox, YourPhone, Bing, Office Hub, etc.) are uninstalled and deprovisioned, and all Microsoft *account/cloud/identity/telemetry* services are disabled so they cannot run. Four tiny services (`AppXSvc`, `StateRepository`, `LicenseManager`, `ClipSVC`) are kept on purpose: they are the Windows desktop shell's own runtime (Start Menu/Search/app launching), not Store bloat — removing them is what used to make apps crash with "The service has not been started".

**Q: An app says WebView2 is missing after applying v5.12. Is that expected?**
A: Yes. v5.12 intentionally removes the WebView2 protection and runtime. Reinstall Microsoft's Evergreen WebView2 Runtime if that app does not ship its own fixed runtime.

**Q: What appears during and after boot?**
A: During secure Windows loading, native `VerboseStatus` text appears below Welcome/Please wait. After loading and Explorer startup, the per-user `Z LAG Services - Welcome` scheduled task starts the five-second panel. It does not create a Registry Run/Startup-folder entry, so Task Manager Startup apps stays clean; `wscript.exe` and `powershell.exe` remain normally visible only while the panel runs.

**Q: Where are the cleanup and classic sound tools?**
A: Right-click the desktop or a folder background and open **Z LAG TOOLBOX**. RAM Trim/Clean and Temp Clean are the first two options; classic Sound Manager and Volume Mixer are at the bottom. The old visible Start Menu folder, standalone Sound submenu and shortcut hotkey are intentionally removed.

**Q: Bluetooth Keep is selected but Add Device says "Couldn't connect"?**
A: The root cause was the global floor disabling `CDPSvc`, `CDPUserSvc` and `NcbService` even though radio services were protected. Those pairing dependencies and Device Association services are now globally protected and are never disabled in Keep mode. If Device Manager has no Bluetooth adapter or shows Code 10/43 afterward, that remaining problem is the OEM driver, BIOS or hardware.

**Q: Why did the process count rise again after the first boot?**
A: Windows can create suffixed per-user service instances at logon and trigger-start demand services later. `ZLAG-EnforceServiceFloor` now runs briefly as SYSTEM at boot, logon and every 15 minutes to stop those instances and restore `Start=4`. It is a scheduled recheck, not a resident background process. Hardware utilities and third-party drivers can still change the final count.

**Q: Will Windows Update break this?**
A: The hosts file blocks updates and the update service is disabled. If you later want updates, restore the hosts file first.

**Q: Is disabling Defender safe?**
A: Only if you understand the risks. Keep it enabled for daily use; disable only for tournament PCs behind a hardware firewall.

**Q: Can I use Wi-Fi removal on a laptop?**
A: No. Only pick Wi-Fi disable if you are on a desktop plugged in via Ethernet. Laptops should keep Wi-Fi.

**Q: FPS not improved?**
A: Make sure HPET is off, the Ultimate Performance power plan is active, Game Mode is off if using the MMCSS tweak, and your GPU driver is a clean install.

---

## ✅ Validation

Run the dependency-free repository validator before packaging:

```bash
python3 tests/validate_repo.py
```

It checks playbook/version metadata, JSON/XML files, the exact 01–37 task order,
all task-to-executable references, persistent runtime destinations, and the
Welcome task's XML/interactive principal/no-Run-key contract. Release review also
parses every PowerShell file and checks batch structure and Git whitespace.

---

## 🛠️ Contributing

1. Fork repository
2. Create branch: `git checkout -b feature/MyTweak`
3. Commit: `git commit -m 'Add registry tweak: TCPNoDelay optimization'`
4. Push: `git push origin feature/MyTweak`
5. Open a Pull Request with registry paths + benchmark before/after

Please test on a VM (VMware Workstation with nested virtualization) before opening a PR.

---

## 📝 License

**Proprietary — Use Only. No Modification or Reuse.** See [LICENSE](LICENSE).

This project is **copyrighted** and is **not** open source or free software. The
license grants permission to use, run, install, and deploy an **unmodified** copy
for personal, educational, or commercial operation.

- ✅ You may use the unmodified Software for its intended purpose.
- ❌ You may not modify, adapt, patch, translate, or create derivative works.
- ❌ You may not reuse or extract its code, scripts, configurations, or assets in another project.
- ❌ You may not redistribute, sell, sublicense, lend, or publish the Software.
- ✅ Only technical installation/runtime copies and one backup copy are allowed.

Written permission from the copyright owner (**MR.PC GAMER / Z-LAG Community**)
is required for anything outside this limited use permission. All rights reserved.

---

## 🙏 Credits

- AME Wizard Team - Framework
- [Z-LAG Toolbox](https://github.com/MrPcGamerYT/Z-LAG-TOOLBOX) - Official app/driver/tweak hub
- AtlasOS & RevisionOS - Inspiration for advanced reg tweaks, adapted beyond
- MR.PC GAMER (MrPcGamerYT) - Maintainer, Z LAG Community
- ElegantDark cursor set - open source cursor designers

**Star ⭐ this repo if you get an FPS boost!**

---
*Z LAG OS v5.17 - Zero Lag, Max Performance. Built for gamers, by gamers.*
