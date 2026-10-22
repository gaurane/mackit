<div align="center">

# 🧰 mackit

**Seven tiny shell scripts that keep a developer's Mac fast, clean and under control.**

![macOS](https://img.shields.io/badge/macOS-13%2B-000000?style=for-the-badge&logo=apple&logoColor=white)
![Shell](https://img.shields.io/badge/shell-bash%20%7C%20zsh-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Dependencies](https://img.shields.io/badge/dependencies-none-FF6B6B?style=for-the-badge)
![License](https://img.shields.io/badge/license-MIT-3B82F6?style=for-the-badge)

*No Homebrew formula, no Node, no Python. Just `bash` and the tools macOS already ships with.*

</div>

---

## ⚡ Install in 10 seconds

```bash
git clone https://github.com/gaurane/mackit.git ~/Documents/mackit
~/Documents/mackit/install.sh
source ~/.zshrc
```

That's it. Every script is now a short command you can run from any directory.

---

## 🚀 Run them all, or one at a time

### Everything at once

After `install.sh`, chain the aliases in whatever order you like:

```bash
# Weekly full routine
health && sstidy && nuke && cleanup && devup && gsweep

# Quick morning check
health && sstidy && gsweep
```

Or without the aliases, straight from the folder:

```bash
cd ~/Documents/mackit
./mac-health.sh && ./screenshot-tidy.sh && ./node-nuke.sh && ./mac-cleanup.sh && ./dev-update.sh && ./git-sweep.sh
```

> `nuke` and `cleanup` still pause and ask before deleting, so a chained run is safe to walk away from — it just waits for your `y`.

### One at a time

```bash
health                 # or  ~/Documents/mackit/mac-health.sh
ports kill 3000        # or  ~/Documents/mackit/ports.sh kill 3000
cleanup --deep         # or  ~/Documents/mackit/mac-cleanup.sh --deep
```

Every script works on its own — none of them depend on the others.

---

## 🧰 The scripts

| Alias | Script | What it does | Run it… |
|:--|:--|:--|:--|
| 🩺 `health` | `mac-health.sh` | One-screen status: disk, RAM, battery cycles, last backup, Wi-Fi, top CPU & memory hogs | Daily |
| 🔌 `ports` | `ports.sh` | See what's listening on which port, and free one with `ports kill 3000` | Daily |
| 🌿 `gsweep` | `git-sweep.sh` | Scan every repo: uncommitted, unpushed, behind. `--prune` deletes merged branches | End of day |
| 🧹 `cleanup` | `mac-cleanup.sh` | Safe cache cleanup — Library, Xcode, Homebrew, npm, Flutter, Docker. Never touches your files | Weekly |
| 💥 `nuke` | `node-nuke.sh` | Find & delete every `node_modules`, `build`, `.dart_tool`, `.next`… across your projects | Weekly |
| ⬆️ `devup` | `dev-update.sh` | Update Homebrew, Flutter, npm globals, Rust, pip and the App Store in one go | Weekly |
| 🖼️ `sstidy` | `screenshot-tidy.sh` | Move old screenshots off the Desktop into `Pictures/Screenshots/2026-10/` | Whenever |

---

## 📖 Usage

### 🩺 `health`

```
🖥  Gaurangs-MacBook-Air  ·  macOS 15.1  ·  up 3 days

💾 Disk      10Gi used of 228Gi  (103Gi free, 10%)
🧠 Memory    16 GB total  ·  42% free
🔋 Battery   87% (discharging)  ·  214 cycles  ·  Normal
⏱  Backup    last Time Machine: 2026-10-22-231004
📶 Network   HomeWiFi  ·  192.168.1.42

🔥 Top CPU
    12.3%  Google Chrome
     4.1%  Code
...
🔌 3 listening ports  (run 'ports' to see them)
```

> 💡 Add `~/Documents/mackit/mac-health.sh` as the last line of `.zshrc` to see this every time you open a terminal.

### 🔌 `ports`

```bash
ports              # table of every listening port + process + PID
ports 3000         # just port 3000
ports kill 3000    # free it (graceful kill, then force if needed)
```

### 🌿 `gsweep`

```bash
gsweep                 # scan ~/Projects
gsweep ~/code          # scan another folder
gsweep --prune         # also delete local branches already merged into main
```

```
codecanvas                     [main]            📝 3 uncommitted ⬆ 1 unpushed
portfolio                      [feat/hero]       ✅ clean
flat-expense-app               [main]            ⬇ 2 behind
```

Set `export PROJECTS_DIR=~/code` in `.zshrc` to change the default folder for `gsweep` and `nuke`.

### 🧹 `cleanup`

```bash
cleanup            # safe default
cleanup --deep     # also wipe ~/.gradle, ~/.pub-cache, ~/.npm (slow first rebuild)
```

Protected and never touched: **Downloads, Documents, Desktop, project folders.**
Skips Chrome's cache while Chrome is running. Uses `docker system prune` instead of deleting your images.

### 💥 `nuke`

```bash
nuke               # lists every build folder with its size, asks before deleting
nuke --yes         # no questions
```

Targets: `node_modules` `.next` `.nuxt` `dist` `build` `.dart_tool` `.gradle` `.turbo` `.cache` `__pycache__` `.pytest_cache` `.venv`
All of them come back with `npm install` / `flutter pub get`, so nothing is lost.

### ⬆️ `devup`

Runs the updater for every tool it finds and skips the ones you don't have. Nothing to configure.

### 🖼️ `sstidy`

```bash
sstidy        # move screenshots older than 7 days
sstidy 1      # older than 1 day
sstidy 0      # everything, now
```

Files land in `~/Pictures/Screenshots/<year-month>/`.

---

## 🔁 Automate the boring ones

Let `launchd` run `cleanup` and `sstidy` for you every Sunday:

```bash
cat > ~/Library/LaunchAgents/com.mackit.weekly.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.mackit.weekly</string>
  <key>ProgramArguments</key><array>
    <string>/bin/bash</string><string>-c</string>
    <string>~/Documents/mackit/screenshot-tidy.sh; ~/Documents/mackit/mac-cleanup.sh</string>
  </array>
  <key>StartCalendarInterval</key><dict><key>Weekday</key><integer>0</integer><key>Hour</key><integer>10</integer></dict>
</dict></plist>
EOF
launchctl load ~/Library/LaunchAgents/com.mackit.weekly.plist
```

---

## 🛡️ Safety

- Every `rm` is guarded: paths are checked with `[[ -e ]]` before deletion, globs use `nullglob` so a missing folder never becomes a wildcard
- Nothing under `~/Downloads`, `~/Documents` or `~/Desktop` is ever deleted
- Only `cleanup` asks for `sudo`, and only for `/private/var/tmp` and a DNS flush
- `nuke` and `gsweep --prune` show you the list and ask before acting

---

## 🤝 Contributing

Found a cache folder I missed, or a tool that should be in `devup`? Open a PR — each script is under 80 lines and self-contained, so changes are easy to review.

---

<div align="center">

Made with ☕ in Mumbai by [**@gaurane**](https://github.com/gaurane)

</div>
