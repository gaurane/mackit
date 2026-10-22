#!/usr/bin/env bash
# dev-update — update every dev tool you have installed, in one go.
# Only runs updaters for tools that are actually present.

set -u

step() { echo; echo "▶ $1"; }

step "Homebrew"
if command -v brew >/dev/null; then
  brew update >/dev/null 2>&1
  outdated=$(brew outdated --quiet)
  if [[ -n "$outdated" ]]; then
    echo "$outdated" | sed 's/^/   ↑ /'
    brew upgrade >/dev/null 2>&1 && echo "   ✓ upgraded"
  else
    echo "   ✓ all formulae up to date"
  fi
  brew upgrade --cask --greedy >/dev/null 2>&1
else
  echo "   – not installed"
fi

step "Flutter"
if command -v flutter >/dev/null; then
  flutter upgrade --force 2>&1 | grep -E 'Flutter is already|Upgrading|Flutter [0-9]' | head -2 | sed 's/^/   /'
else
  echo "   – not installed"
fi

step "Node (global npm packages)"
if command -v npm >/dev/null; then
  outdated=$(npm outdated -g --parseable 2>/dev/null | cut -d: -f4)
  if [[ -n "$outdated" ]]; then
    echo "$outdated" | sed 's/^/   ↑ /'
    npm update -g >/dev/null 2>&1 && echo "   ✓ updated"
  else
    echo "   ✓ all up to date"
  fi
else
  echo "   – not installed"
fi

step "Rust"
command -v rustup >/dev/null && rustup update 2>&1 | grep -E 'unchanged|updated' | sed 's/^/   /' || echo "   – not installed"

step "Python (pip)"
command -v pip3 >/dev/null && pip3 install --upgrade pip >/dev/null 2>&1 && echo "   ✓ pip $(pip3 --version | awk '{print $2}')" || echo "   – not installed"

step "App Store"
command -v mas >/dev/null && { mas outdated | sed 's/^/   ↑ /'; mas upgrade >/dev/null 2>&1; } || echo "   – mas not installed (brew install mas)"

step "macOS"
softwareupdate -l 2>&1 | grep -E '^\s*\*' | sed 's/^/   /' || echo "   ✓ no system updates"

echo
echo "✅ Everything updated."
