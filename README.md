# Z LAG OS — Zero Lag Gaming Operating System

[![License: Use Only](https://img.shields.io/badge/License-Proprietary%20%2F%20Use--Only-red.svg)](LICENSE)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%20%2F%2011-0078d7.svg)](https://www.microsoft.com/windows)
[![Framework: AME Wizard](https://img.shields.io/badge/Framework-AME%20Wizard-orange.svg)](https://ameliorated.io/)
[![Version: 5.16](https://img.shields.io/badge/Version-5.16-success.svg)](https://github.com/MrPcGamerYT/Z-LAG-OS/releases)
[![Build: Stable](https://img.shields.io/badge/Build-Stable-brightgreen.svg)]()

> **Maximum FPS. Zero Lag. No Bloat.** A performance-first AME Wizard playbook engineered for competitive gaming, Android emulators (BlueStacks / MSI App Player / LDPlayer), and low-end hardware — universal for **Windows 10 and Windows 11**.

![Z-LAG Wallpaper](src/Executables/Z_LAG_Wallpaper/Desktop.png)

---

### ⚠️ CRITICAL DISCLAIMER
This playbook applies **aggressive system-wide modifications**: it disables telemetry, strips built-in apps, blocks updates, removes OneDrive (including local sync folders), Edge/WebView2, Cortana/Widgets, purges services, and modifies kernel power & scheduler policies. It is designed for **performance-critical gaming environments only**. Create a restore point and use a **Local Offline Account**.

---

## 📚 Table of Contents
- [Why Z LAG OS](#-why-z-lag-os)
- [Feature Highlights](#-feature-highlights)
- [Installation](#-installation)
- [Setup Options](#-setup-options)
- [Z LAG TOOLBOX Context Menu](#-z-lag-toolbox-context-menu)
- [Clean & Compact Start Menu](#-clean--compact-start-menu)
- [Maximum FPS Power Plan](#-maximum-fps-power-plan)
- [Expected Performance Gains](#-expected-performance-gains)
- [What Is Removed vs Preserved](#-what-is-removed-vs-preserved)
- [Compatibility](#-compatibility)
- [Changelog](#-changelog)
- [FAQ](#-faq)
- [Validation](#-validation)
- [Contributing](#-contributing)
- [License & Credits](#-license--credits)

---

## 🎯 Why Z LAG OS

Most "gaming optimizers" flip a few registry switches and call it a day. Z LAG OS is a complete, engineered pipeline of **38 sequential tasks** that rebuilds Windows around one goal: **every CPU cycle, every millisecond of latency, and every megabyte of RAM goes to your game.**

| Goal | How it is achieved |
| :--- | :--- |
| **Latency Minimization** | MMCSS gaming profile (GPU Priority 8 / High scheduling / High SFIO), hardware GPU scheduling, dynamic tick disabled, high-resolution timer enforced, MSI mode on the GPU |
| **Stable FPS (no mid-game drops)** | Zero scheduled activity during gameplay, thermal-headroom power tuning (no heat-soak throttling), core parking off, Multi-Plane Overlay disabled (no flicker/stutter), memory compression kept ON (no pagefile hitches) |
| **Raw Input** | Correct 40-byte linear mouse curves (true 1:1, zero acceleration), driver-level input queues tuned, USB selective suspend and USB3/PCIe link power management forced OFF so input devices can never sleep mid-game |
| **Heavy Debloat** | 60 + built-in apps removed, 100 + services disabled or demand-only, telemetry blocked at host + task + service level, Edge/WebView2/OneDrive fully removed |
| **RAM Efficiency** | Svchost consolidation, Superfetch/Search indexing off, visual effects off, working-set trims — target idle: **~1.2–1.9 GB RAM, ~40–55 processes** |
| **Network Latency** | Nagle disabled globally + per interface, ACK frequency tuned, interrupt moderation off, energy-efficient Ethernet off, NIC power saving off — with zero destructive stack resets |
| **AppX Stability** | The complete packaged-app runtime framework set is hard-protected, so heavy debloat never causes UWP/sideloaded app crashes |

---

## ✨ Feature Highlights

- 🚀 **True zero-lag design** — no Z-LAG process, service, or scheduled task ever runs while you play. Maintenance happens at boot/logon only.
- 🖥️ **Clean compact Start Menu** — no pinned tiles, no Recommended section, no "Most used"/"Recently added" lists. Pure app list, on both Windows 10 and 11.
- 🖱️ **Z LAG TOOLBOX right-click menu** — 12 built-in tools including one-click GAME BOOST, standby-memory clear, ping/jitter test, and instant Max FPS power plan re-activation.
- ⚡ **Maximum FPS power plan** — created once, tuned by GUID, activated and **verified**; the exact plan GUID is recorded so it can always be restored in one click.
- 🎨 **Custom native experience** — Z LAG Welcome panel at logon (Task Scheduler based — invisible to Startup apps), ElegantDark cursor set, dark theme, custom wallpaper, small auto-hide taskbar, classic context menu on Windows 11.
- 🛡️ **Crash-proof debloat** — Store/identity removals are option-gated and licensing-aware; the shell's own AppX runtime is never touched.
- 🔁 **Self-healing runtime** — a non-resident watchdog re-locks the service floor at boot/logon, and the AppX launch stack re-arms itself after every purge.
- 🧪 **Production validation** — every release passes a structural + regression test suite covering task wiring, script syntax balance, and every historical bug class.

---

## 📦 Installation

1. Download the latest `Z_LAG_OS.apbx` from [Releases](https://github.com/MrPcGamerYT/Z-LAG-OS/releases).
2. Download [AME Wizard](https://ameliorated.io/) (latest beta, 0.7+).
3. **Create a restore point** (the playbook also creates one as its first real action).
4. Drag the `.apbx` into AME Wizard and follow the setup pages.
5. Pick your options (browser, Defender, Bluetooth, Wi-Fi, Store — see below).
6. Let it run (~30–60 min). The system reboots automatically when finished.

> 💡 Best results: apply on a **fresh Windows install** with a **local account**.

---

## ⚙️ Setup Options

You stay in control of how aggressive the optimization is:

| Page | Default | Max Performance Option | Effect |
| :--- | :--- | :--- | :--- |
| **Browser** | Chrome | Brave / OperaGX / None | Pre-installed browser choice |
| **Defender** | Keep (Recommended) | Disable | Frees ~150–300 MB RAM, removes scanning stutter. Advanced users only |
| **Bluetooth** | Keep | Disable | Removes the Bluetooth stack. Only for wired-peripheral setups |
| **Wi-Fi** | Keep | Disable | Stops WLAN services. Ethernet desktops only |
| **MS Store & Services** | Keep (Recommended) | Remove | Fully removes Store + Xbox + MS account/cloud apps & services (~300–500 MB saved). The Windows shell's own AppX runtime is kept so apps still launch |

**Z-LAG Toolbox** is always installed from [GitHub Releases](https://github.com/MrPcGamerYT/Z-LAG-TOOLBOX/releases) as the official app/driver/tweak hub. It installs Win32 (EXE/MSI) apps, so even with Microsoft services removed, downloaded apps launch instead of crashing.

---

## 🧰 Z LAG TOOLBOX Context Menu

Right-click the desktop or any folder background → **Z LAG TOOLBOX** (always first position). Every tool runs only when clicked and exits immediately — **zero background processes**.

| Tool | What it does |
| :--- | :--- |
| **GAME BOOST (One-Click)** | Kills respawned bloat processes (Edge, Widgets, Teams, OneDrive, GameBar…), trims all working sets, flushes DNS — click, then launch your game |
| **RAM Trim / Clean** | Releases working-set RAM from all user-session processes |
| **Clear Standby Memory** | Purges the standby page list natively — prevents mid-match allocation hitches after long sessions |
| **Temp Clean** | Cleans user + Windows temp folders, reports space reclaimed |
| **Recycle Bin Clean** | Empties the recycle bin |
| **Flush DNS Cache** | Resets the DNS resolver for a clean connection |
| **Ping / Latency Test** | Pings router + Cloudflare + Google; shows avg / max / **jitter** per hop |
| **Activate Max FPS Power Plan** | One-click re-activation of the tuned plan (verified before reporting success) |
| **System Info (Gamer View)** | OS build, free/total RAM, CPU cores/threads, GPU + driver, active power plan, live process count |
| **Restart Explorer** | Fixes shell glitches instantly |
| **Sound Manager (Classic)** | Opens the classic mmsys.cpl sound panel |
| **Volume Mixer (Classic)** | Opens the classic per-app volume mixer |

---

## 🧹 Clean & Compact Start Menu

A completely clean, compact Start Menu on **both** Windows versions — no pinned item section at all:

**Windows 10**
- Empty tile layout applied via `Import-StartLayout` + per-user layout XML
- The real pinned-tile grid (`start.tilegrid` CloudStore keys) is purged for **every user**, so pins never come back
- Full-screen/tablet Start forced off — small, compact desktop Start
- Legacy tile database cleaned on old builds

**Windows 11**
- Empty `{"pinnedList":[]}` layout per user **and** machine-wide (`ConfigureStartPins`) — new accounts start pin-free too
- `start*.bin` pin caches (including `start2.bin` on 22H2+) deleted for every profile
- Compact "More pins" layout + Recommended section hidden
- Compact File Explorer mode (dense rows, like Windows 10)

**Both**
- "Most used", "Recently added", ads/stubs and website recommendations removed at HKLM policy level (survives resets, applies to all users)
- The Start Menu host is stopped **before** cache deletion (so it can't rewrite pins from memory) and its package cache is cleared — the clean menu appears immediately

---

## ⚡ Maximum FPS Power Plan

The playbook builds a dedicated **"Maximum FPS"** plan and guarantees it is really active:

1. Created **once** from Ultimate Performance (High Performance fallback) — never duplicated on re-runs; stale copies are auto-removed
2. Tuned **by explicit GUID** on AC + DC: min CPU 5% / max 100% / aggressive boost (full speed under load, thermal headroom at idle — no heat-soak throttling), core parking off, disk/display/sleep timeouts off
3. **USB selective suspend OFF, USB3 link power OFF, PCIe ASPM OFF** — mouse, keyboard, and GPU link never power-gate mid-game
4. Activated **after** tuning and **verified** via `powercfg /getactivescheme` (with retry) — the log prints `VERIFIED: Maximum FPS plan is ACTIVE`
5. The plan GUID is recorded in the registry so the right-click tool and later playbook stages always re-activate the **exact tuned plan**, never a stock template

---

## 📊 Expected Performance Gains

*Note: varies by hardware. Tested on i5-11400F + GTX 1660 + 16 GB.*

| Metric | Stock Windows 11 | After Z LAG OS | Delta |
| :--- | :--- | :--- | :--- |
| **Idle RAM after boot** | 3.8–4.5 GB | 1.2–1.9 GB | −60% |
| **Processes** | 180–220 | ~40–55 | −70%+ |
| **Boot time (SATA SSD)** | 22 s | 12–14 s | ~−40% |
| **DPC latency (LatencyMon)** | 300–600 µs spikes | 40–90 µs avg | −80% |
| **FPS 1% lows (Valorant 1080p Low)** | 110 FPS | 165 FPS | +50% 1%-low stability |
| **BlueStacks 5 startup** | 18 s | 9 s | 2× faster |
| **Disk idle I/O** | 5–10 MB/s telemetry | <0.5 MB/s | ~−95% |

---

## 🧹 What Is Removed vs Preserved

### Removed / Disabled
- **Apps**: People, Maps, Alarms, Camera, 3D Viewer, Sticky Notes, Mail/Calendar, Feedback Hub, Get Started, Power Automate, Clipchamp, Office Hub, Teams, Skype, Copilot, Widgets, Bing apps, Solitaire, YourPhone/CrossDevice, Xbox layers (optional), and more
- **Services**: DiagTrack, dmwappush, WerSvc, SysMain, WSearch, VSS/SwPrv, RpcLocator, SNMPTRAP, vds, WMPNetworkSvc, MSDTC, Windows Backup, MapsBroker, Xbox networking, RemoteRegistry, dozens of per-user service instances, and the full ULTRA floor (System Restore/VSS, notifications, network discovery, file sharing, hotspot/ICS, WebDAV, iSCSI, clipboard history)
- **Telemetry**: CEIP tasks, compatibility appraiser, 43 hosts-file entries, update-host blocking
- **Components**: OneDrive (client + sync folders), Edge, WebView2 Runtime, Cortana, News/Feeds, Search highlights, transparency, animations
- **Optional**: Defender, Bluetooth stack, Wi-Fi stack, Store + MS identity/gaming services

### Preserved (for stability)
- **GPU drivers & panels** — NVIDIA / AMD / Intel are never touched
- **AppX runtime frameworks** — VCLibs, UI.Xaml, .NET Native, WindowsAppRuntime/SDK, App Installer, sign-in brokers, shell surface packages: near-zero footprint, but removing them crashes every packaged app
- **Windows shell AppX services** — AppXSvc, StateRepository, LicenseManager, ClipSVC stay alive even with "Remove MS Services" so the Start Menu, Search, and Toolbox-installed apps keep launching
- **Text-input stack** — demand-start (0 idle footprint), never hard-disabled, so keyboard input always works
- **Font cache** — kept (killing it causes shell-wide text-rendering stutter)
- **Memory compression** — kept ON (prevents pagefile hitching on 8/16 GB systems)
- **Networking core** — TCP/IP, DHCP, DNS cache, firewall; Wi-Fi/Bluetooth kept unless you opt out
- **Boot-critical services** — anything with Start ≤ 1 is never touched; the OS always boots cleanly
- **VC++ Runtimes 2015+, DirectX Jun2010, .NET Framework** — installed/kept for game compatibility

---

## 💻 Compatibility

**Universal Windows 10 + Windows 11** — every OS-sensitive step detects the running build and applies the correct tweak. One `.apbx` for both.

- **Windows 10**: 1809 → 22H2
- **Windows 11**: 21H2 (22000) → 24H2 (26100+)
- **Architecture**: x64 primary, ARM64 supported
- **Languages**: all display languages (power/scheme parsing is locale-safe)
- **Framework**: AME Wizard latest beta (0.7+)

Win11-only passes (AI/Copilot/Recall floor, Win11 shell tweaks) are gated behind `builds: ['>=22000']` and never run on Windows 10 — and vice versa for Win10-only mechanisms.

---

## 📜 Changelog

<details>
<summary><b>v5.26 — Clean compact Start Menu, universal Win10/11</b></summary>

- Windows 10 pinned section fully removed: the real pin grid (`start.tilegrid` CloudStore keys) is now purged for every user — pins can no longer come back
- Machine-wide HKLM policies: no "Most used", no "Recently added", no ads/stubs, no website recommendations — applies to all users and survives resets
- Windows 11: device-wide empty pin list, compact "More pins" Start layout, compact File Explorer
- Windows 10: full-screen/tablet Start forced off, collapsed tray
- Start Menu host stopped before cache deletion + package cache cleared, so the clean menu appears immediately
</details>

<details>
<summary><b>v5.15 — Maximum FPS plan verified-active + universal Start Menu engine</b></summary>

- Power plan flow rewritten: reuse-or-create once, tune by explicit GUID (AC+DC), activate AFTER tuning, verify via `/getactivescheme` with retry, record GUID for the context-menu tool
- Removed the legacy duplicate-and-activate pass that created duplicate plans and could re-activate an untuned stock template
- Start Menu engine split per OS: `Import-StartLayout` (Win10) vs `pinnedList` JSON (Win11), with `start*.bin` purge and host-stop on both
</details>

<details>
<summary><b>v5.14 — Start Menu cleaner fixed + production hardening</b></summary>

- Fixed three root causes of the broken cleaner: an orphaned layout script that never ran, `start2.bin` (Win11 22H2+) never being deleted, and the host rewriting caches from memory
- Regression test suite extended to cover every historical bug class; all 37 scripts declare an explicit error policy; CI validation staged in `docs/ci/`
</details>

<details>
<summary><b>v5.13 — Universal Win10/11 + expanded TOOLBOX (12 tools)</b></summary>

- Added GAME BOOST, Clear Standby Memory, Ping/Latency Test, Activate Max FPS Power Plan, System Info (Gamer View)
- All tools use APIs available on both PowerShell 5.1 (Win10) and Windows 11
</details>

<details>
<summary><b>v5.12 — AppX crash-proofing, anti-flicker, raw input</b></summary>

- Full AppX runtime framework set hard-protected (no more packaged-app crashes)
- Store no longer removed by the base pass (option-gated with licensing handled)
- Multi-Plane Overlay disabled (the documented NVIDIA/AMD flicker/stutter fix)
- High-resolution timer enforced on Win11 22H2+; MMCSS `SFIO Priority=High`; machine-wide GameDVR ban
- Driver-level mouse/keyboard queue tuning for faster input delivery
</details>

<details>
<summary><b>v5.11 — Mid-game FPS drops + input issues fixed</b></summary>

- Watchdog tasks no longer repeat during gameplay (boot/logon only) — zero scheduled activity while playing
- Correct 40-byte linear mouse curves (previous builds wrote corrupt values)
- USB selective suspend / USB3 LPM / PCIe ASPM forced off; input devices never power-gate
- Thermal-headroom power tuning (min CPU 5%, boost aggressive) — no more heat-soak throttling
- GPU MSI message limit removed; memory compression kept ON; destructive network resets removed; font cache preserved; Game Mode enabled
</details>

<details>
<summary><b>v5.10 and earlier</b></summary>

- First-run core reset, visible runtime storage under `C:\Windows\Z-LAG-OS`, Task Scheduler based Welcome panel, self-healing AppX runtime, ULTRA process/RAM floor, Edge/WebView2/OneDrive removal engines, telemetry host blocking, and the full 38-task pipeline
</details>

---

## ❓ FAQ

**Q: Is this a custom Windows ISO?**
A: No. It's a playbook (`.apbx`) that transforms a clean official Windows install via AME Wizard. Nothing is redistributed or pirated.

**Q: How many background processes after install?**
A: Target is **~40–55** at idle (depends on GPU driver and whether Defender/Store are kept). Check anytime: right-click desktop → Z LAG TOOLBOX → System Info (Gamer View).

**Q: Will my UWP / packaged apps crash after the debloat?**
A: No. The complete AppX runtime framework set (VCLibs, UI.Xaml, WindowsAppRuntime, sign-in brokers, shell surfaces) is hard-protected, and shell AppX services stay alive even with "Remove MS Services" selected.

**Q: How do I know the Maximum FPS power plan is really active?**
A: Settings → Power shows "**Maximum FPS**" selected, and the install log prints `VERIFIED: Maximum FPS plan is ACTIVE`. If any driver installer switches plans later: right-click desktop → Z LAG TOOLBOX → **Activate Max FPS Power Plan**.

**Q: The Start Menu still shows some pins right after install?**
A: The menu is rebuilt immediately at apply time and finalized on the automatic reboot. After reboot: pure app list, no pinned section, no Recommended.

**Q: I removed the Store and an app says "The service has not been started"?**
A: The shell's own AppX runtime (LicenseManager, ClipSVC, AppXSvc, StateRepository) is kept and self-heals at boot/logon. If it ever happens, run `repair_appx_runtime.ps1` as Admin and reboot.

**Q: An app says WebView2 is missing?**
A: Expected — WebView2 is intentionally removed. Reinstall Microsoft's Evergreen WebView2 Runtime if a specific app needs it.

**Q: Bluetooth Keep is selected but pairing fails?**
A: Pairing dependencies (CDPSvc, CDPUserSvc, NcbService, Device Association) are globally protected in Keep mode. If the adapter itself shows Code 10/43, that's an OEM driver/BIOS issue.

**Q: Why did the process count rise again after first boot?**
A: Windows re-creates per-user service instances at logon. The non-resident `ZLAG-EnforceServiceFloor` task re-locks the floor at boot/logon (never during gameplay), so the count settles back down.

**Q: Will Windows Update break this?**
A: Updates are blocked (hosts + services). To update later, restore the hosts file and re-enable the update services first.

**Q: Is disabling Defender safe?**
A: Only for advanced users (tournament PCs behind a hardware firewall). Keep it enabled for daily-driver machines.

**Q: FPS not improved?**
A: Verify the Maximum FPS plan is active, your GPU driver is a clean install, and no OEM utility re-enabled power saving. Then use GAME BOOST before launching.

---

## ✅ Validation

Run the full repository validation suite before packaging:

```bash
python3 tests/validate_repo.py
```

It verifies: playbook/version metadata, JSON/XML/YAML data files, the exact 01–38 task order, all task-to-executable references, runtime layout contracts, the Welcome task XML, PowerShell brace/paren balance for all 37 scripts, explicit error-policy in every script, and **regression guards** for every historical bug class (power-plan activation, Start Menu contract, AppX keep-list, watchdog scheduling, input curves, network safety, context-menu wiring).

CI workflow files (PowerShell AST parse + PSScriptAnalyzer gate on every push) are staged in [`docs/ci/`](docs/ci/README.md).

---

## 🛠️ Contributing

1. Fork the repository
2. Create a branch: `git checkout -b feature/MyTweak`
3. Commit: `git commit -m 'Add registry tweak: XYZ'`
4. Run `python3 tests/validate_repo.py` — it must pass
5. Open a Pull Request with registry paths + before/after benchmarks

Please test on a VM (VMware Workstation with nested virtualization) before opening a PR.

---

## 📝 License & Credits

**Proprietary — Use Only. No Modification or Reuse.** See [LICENSE](LICENSE).

- ✅ You may use the unmodified Software for its intended purpose.
- ❌ You may not modify, adapt, or create derivative works.
- ❌ You may not reuse its code, scripts, configurations, or assets in another project.
- ❌ You may not redistribute, sell, sublicense, or republish the Software.

Written permission from the copyright owner (**MR.PC GAMER / Z-LAG Community**) is required for anything outside this limited use permission. All rights reserved.

### Credits
- **AME Wizard Team** — framework
- **[Z-LAG Toolbox](https://github.com/MrPcGamerYT/Z-LAG-TOOLBOX)** — official app/driver/tweak hub
- **AtlasOS & RevisionOS** — inspiration for advanced registry tweaks, adapted and extended
- **MR.PC GAMER (MrPcGamerYT)** — maintainer, Z LAG Community
- **ElegantDark cursor set** — open-source cursor designers

**⭐ Star this repo if you got an FPS boost!**

---
*Z LAG OS v5.16 — Zero Lag, Max Performance. Built for gamers, by gamers.*
