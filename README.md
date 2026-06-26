# ⚡ OPTY — Windows Optimizer & Cleaner

> A single, self-contained `.bat` with a clear colored menu to **clean**, **optimize** and **fix** Windows 10/11 — no install, no dependencies, pure CMD.
>
> 🧠 *Based on 7 years of IT experience and 2 years of laziness typing the same commands.*

---

## 🚀 Quick Start

1. Download [`OPTY.bat`](https://github.com/YannD-Deltagon/OPTY/blob/master/OPTY.bat) (no other file needed)
2. **Right-click → Run as administrator**
3. Follow the on-screen menu (use the numpad)

⚡ **Fast full cleanup + reboot:** press `1` `Enter`, then `3r` `Enter`
*(Auto Full optimization, then reboot)*

> ✅ An Internet connection is recommended (for the auto-update check) but **not required** — OPTY falls back to *local mode* if GitHub is unreachable.

---

## 📌 What it does

OPTY groups dozens of maintenance commands behind a readable menu, with **three levels of automation** so you stay in control.

### 🎯 Highlights (v04.0)
- 🛟 **Automatic System Restore Point** before any change (the 2026 safety standard — System Protection is enabled on `C:` if needed)
- 🧹 Deep cleanup: temp, caches (GPU/shader, browsers, apps), Windows Update cache, Delivery Optimization, dumps, logs, INetCache, thumbnails, `Windows.old`, Recycle Bin…
- 🐳 **WSL / Docker disk compaction** — cleanly stops Docker Desktop & WSL, then shrinks the virtual disks (`docker_data.vhdx` + every distro `ext4.vhdx`) to reclaim space
- 🛠️ Repair tools: `DISM` (with `AnalyzeComponentStore`), `SFC`, `CHKDSK` (online `/scan` by default, full `/f /r` on demand)
- 🧰 Enables **Storage Sense** for ongoing automatic maintenance (the native 2026 complement to manual cleanup)
- 🌐 Network: DNS flush, Winsock/IP reset (manual mode only) + **TCP good-default tuning** (autotuning normal / RSS on / heuristics off)
- 💾 Storage: drive **optimization** (`defrag` / SSD TRIM)
- ⚙️ Service & registry tweaks, **Ultimate Performance** power plan, mouse anti-lag
- 🎮 Optional **Gaming / Performance profile**: game priority (MMCSS), Game Mode + HAGS, VBS/Memory Integrity off, power-throttling off, network latency (Nagle/throttling), SSD TRIM, USB-suspend off, background apps + telemetry off, **MPO off** (fixes game flicker/stutter, incl. 24H2+ keys), telemetry scheduled-tasks off
- 🛡️ Optional **2026 debloat**: disable Windows **Recall** & **Copilot**, block sponsored apps (Consumer Features), disable **Widgets** & Task View — all reversible via **Restore ALL profile defaults**
- 🔐 **Re-assert good Windows defaults** (safety net): turns **Firewall**, **Defender real-time** and **UAC** back ON, plus SSD TRIM / SysMain / Prefetch / system-managed pagefile — undoes damage left by shady "optimizers"
- ♻️ Re-enable helpers (Office / Chrome / Windows Update behind corporate GPO)
- 📊 **Disk-space-freed report** (before / after) at the end of every run
- 🎨 **Live colored output** (ANSI/VT) + **complete timestamped logs** for every action

### 🖥️ Compatibility
- Windows **10** / **11** (x64)
- Requires **administrator** rights (the script checks and exits otherwise)

---

## 🧭 Main menu

| Key | Action |
|-----|--------|
| `1` | **Clean + Optimization** (opens the mode selector below) |
| `2` | **Re-enable options** (Office / Chrome / Windows Update) |
| `3` | **Register profile**: services, registry, power plan, mouse, **Gaming/Performance**, **Debloat 2026**, **Re-assert good defaults**, **Restore ALL defaults** |
| `9` | Clean OPTY's own working files |
| `0` | Exit |

### 🔁 The 3 optimization modes (menu `1`)

| Mode | Behaviour |
|------|-----------|
| **1 — Manual** | Asks before each step (DNS, DISM, SFC, Windows Update, Cleanmgr, delete, defrag, CHKDSK…). Full control. |
| **2 — Auto (lite)** | Quick pass: Windows Update + cleanup, then the shutdown prompt. |
| **3 — Auto (full)** | The works: services, DNS + TCP, DISM, SFC, Windows Update, **cleanup + WSL/Docker compaction**, defrag, then disk report. |

**Suffixes** — add a letter after the mode number to chain a power action:
- `3r` → Auto Full **+ reboot**
- `3s` → Auto Full **+ shutdown**
- `2r`, `2s` → same for Auto lite

---

## 📊 Reporting & logs

- **Session header** at startup: OS build, machine, user, CPU, and **free space per drive**.
- Every action is written to a timestamped log file next to the script: `logs_<date>_<time>.txt` (the 15 most recent are kept, older ones auto-pruned).
- At the end of a run, a colored panel shows **free space before / after** and the amount **freed** (MB and ~GB).
- Exit codes of the heavy operations (DISM, SFC, CHKDSK, DEFRAG) are logged.

> 🎨 Colors use ANSI/VT sequences (best in **Windows Terminal**, the default on Windows 11). OPTY enables VT automatically.

---

## ⚙️ Configuration (edit before first run if needed)

A few paths are defined as variables at the **top of the script** — change them to match your machine:

```bat
set "USERHOME=C:\Users\compt"
set "WSL_DOCKER_VHDX=%USERHOME%\AppData\Local\Docker\wsl\disk\docker_data.vhdx"
set "DOCKER_EXE=C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

`USERHOME` is hard-coded (instead of `%USERPROFILE%`) so the right profile is used even when the script runs elevated under another admin account.

---

## ⚠️ Good to know (this is an aggressive optimizer)

Some steps are intentionally thorough. In particular:

- **Closes apps**: Docker Desktop, Edge/Chrome, and the Microsoft Store window are closed during cleanup.
- **`Windows.old`** is deleted → you lose the ability to roll back to the previous Windows build.
- **Restore points**: old shadow copies are trimmed (**the most recent one is kept**).
- **`DISM /StartComponentCleanup /ResetBase`** → installed updates can no longer be uninstalled.
- **`CHKDSK /f /r`** may schedule a scan on the next reboot.
- WSL/Docker compaction stops Docker — it is **not** restarted automatically.

When in doubt, run **Mode 1 (Manual)** first: it asks before each step and ends with the disk-space report.

> 🛟 A **System Restore Point** is created automatically before any of the above runs (menu `1`/`2`/`3`), so you can roll back from *Settings → System → Recovery → Open System Restore*.

---

## 🔄 Self-update

On launch OPTY copies itself to `C:\OPTY_by-YannD\` and checks GitHub for a newer release. Hidden menu input:
- `.` → force the update check

---

## 🙏 Credits

Made by **[@YannD-Deltagon](https://github.com/YannD-Deltagon)**.
Use at your own risk — review the script before running it on a machine you care about.
