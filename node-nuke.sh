#!/usr/bin/env bash
# node-nuke — find and delete build/dependency folders across your projects.
# These re-create themselves on the next `npm install` / `flutter pub get`, so they're safe to drop.
#   node-nuke              scan ~/Projects (or $PROJECTS_DIR), ask before deleting
#   node-nuke ~/code       scan a different folder
#   node-nuke --yes        delete without asking

set -u
ROOT=${1:-${PROJECTS_DIR:-$HOME/Projects}}
YES=false
for a in "$@"; do [[ "$a" == "--yes" || "$a" == "-y" ]] && YES=true; done
[[ "$ROOT" == "--yes" || "$ROOT" == "-y" ]] && ROOT=${PROJECTS_DIR:-$HOME/Projects}

[[ -d "$ROOT" ]] || { echo "No such folder: $ROOT"; exit 1; }

TARGETS=(node_modules .next .nuxt dist build .dart_tool .gradle .turbo .cache __pycache__ .pytest_cache .venv)

echo "🔍 Scanning $ROOT for build folders..."
# Build a find expression: -name A -o -name B ...
expr=()
for t in "${TARGETS[@]}"; do expr+=(-name "$t" -o); done
unset 'expr[${#expr[@]}-1]'

found=$(find "$ROOT" -type d \( "${expr[@]}" \) -prune 2>/dev/null)
[[ -z "$found" ]] && { echo "Nothing to clean 🎉"; exit 0; }

echo
total=0
while read -r d; do
  kb=$(du -sk "$d" 2>/dev/null | awk '{print $1}')
  total=$((total + kb))
  printf '%8d MB  %s\n' "$((kb/1024))" "${d#"$ROOT"/}"
done <<< "$found" | sort -rn

total_mb=$(echo "$found" | xargs du -skc 2>/dev/null | tail -1 | awk '{print int($1/1024)}')
echo
echo "💾 Total: ${total_mb} MB"

if ! $YES; then
  printf 'Delete all of these? [y/N] '; read -r ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }
fi

echo "$found" | xargs rm -rf
echo "✅ Freed ~${total_mb} MB. Run npm install / flutter pub get to rebuild when needed."
