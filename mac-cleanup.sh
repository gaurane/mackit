#!/usr/bin/env bash
# Safe macOS cleanup — caches only. Never touches Downloads, Documents, or project code.
# Usage:  chmod +x mac-cleanup.sh && ./mac-cleanup.sh
# Add --deep to also wipe heavy dev caches (gradle, pub, npm) that take a while to rebuild.

set -u
shopt -s nullglob dotglob   # unmatched globs expand to nothing instead of erroring

DEEP=false
[[ "${1:-}" == "--deep" ]] && DEEP=true

# rm_safe: delete only if the path exists, never prompt, never fail the script
rm_safe() {
  for p in "$@"; do
    [[ -e "$p" ]] && rm -rf "$p" 2>/dev/null
  done
  return 0
}

bytes_free() { df -k / | awk 'NR==2 {print $4}'; }
human()      { echo "$(( $1 / 1024 / 1024 )) GB"; }

BEFORE=$(bytes_free)
echo "🧹 Starting safe macOS cleanup (free before: $(human "$BEFORE"))"
echo

# 1. User caches — skip Chrome while it's running (locked files just error out)
echo "🗑  Library caches..."
for d in ~/Library/Caches/*; do
  [[ "$d" == *"/Google"* ]] && pgrep -xq "Google Chrome" && continue
  rm_safe "$d"
done
rm_safe ~/Library/Logs/*

# 2. Trash
echo "🚮 Emptying Trash..."
rm_safe ~/.Trash/*

# 3. Xcode
if [[ -d ~/Library/Developer/Xcode ]]; then
  echo "🧰 Xcode DerivedData + stale simulators..."
  rm_safe ~/Library/Developer/Xcode/DerivedData/* \
          ~/Library/Developer/Xcode/Archives/* \
          ~/Library/Developer/CoreSimulator/Caches/*
  xcrun simctl delete unavailable 2>/dev/null
fi

# 4. Homebrew
if command -v brew >/dev/null; then
  echo "🍺 Homebrew cleanup..."
  brew cleanup --prune=all -s >/dev/null 2>&1
  brew autoremove >/dev/null 2>&1
fi

# 5. Dev tool caches — use each tool's own cleaner so configs survive
echo "📦 Developer caches..."
command -v npm     >/dev/null && npm cache clean --force >/dev/null 2>&1
command -v yarn    >/dev/null && yarn cache clean      >/dev/null 2>&1
command -v pip3    >/dev/null && pip3 cache purge      >/dev/null 2>&1
command -v flutter >/dev/null && flutter pub cache clean --force >/dev/null 2>&1
rm_safe ~/.dartServer ~/.flutter_tool_state ~/.gradle/caches ~/.gradle/daemon

# Docker: prune, don't rm the Data dir (that nukes every image, container and volume)
if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
  echo "🐳 Docker prune (dangling images, stopped containers, build cache)..."
  docker system prune -f >/dev/null 2>&1
fi

if $DEEP; then
  echo "🔥 Deep mode: removing full gradle/pub/npm caches (will re-download on next build)"
  rm_safe ~/.gradle ~/.pub-cache ~/.npm ~/.cocoapods/repos
fi

# 6. System temp + DNS (the only part needing sudo)
echo "🔧 System temp files (sudo)..."
sudo rm -rf /private/var/tmp/* /private/var/log/asl/*.asl 2>/dev/null
sudo dscacheutil -flushcache 2>/dev/null
sudo killall -HUP mDNSResponder 2>/dev/null

AFTER=$(bytes_free)
echo
echo "💾 Free after:  $(human "$AFTER")"
echo "✨ Recovered:   $(human $(( AFTER - BEFORE )))"
echo "✅ Done. Downloads untouched."
