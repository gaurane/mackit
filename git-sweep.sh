#!/usr/bin/env bash
# git-sweep — end-of-day git check across all your repos.
#   git-sweep              scan ~/Projects (or $PROJECTS_DIR)
#   git-sweep ~/code       scan a different folder
#   git-sweep --prune      also delete local branches already merged into main/master

set -u
ROOT=${1:-${PROJECTS_DIR:-$HOME/Projects}}
PRUNE=false
for a in "$@"; do [[ "$a" == "--prune" ]] && PRUNE=true; done
[[ "$ROOT" == "--prune" ]] && ROOT=${PROJECTS_DIR:-$HOME/Projects}

[[ -d "$ROOT" ]] || { echo "No such folder: $ROOT"; exit 1; }

echo "🔍 Scanning repos under $ROOT"
echo

find "$ROOT" -maxdepth 3 -name .git -type d 2>/dev/null | while read -r gitdir; do
  repo=$(dirname "$gitdir")
  name=${repo#"$ROOT"/}
  cd "$repo" || continue

  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
  behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)

  flags=""
  (( dirty  > 0 )) && flags+=" 📝 $dirty uncommitted"
  (( ahead  > 0 )) && flags+=" ⬆ $ahead unpushed"
  (( behind > 0 )) && flags+=" ⬇ $behind behind"
  [[ -z "$flags" ]] && flags=" ✅ clean"

  printf '%-30s %-18s%s\n' "$name" "[$branch]" "$flags"

  if $PRUNE; then
    main=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||')
    main=${main:-main}
    git branch --merged "$main" 2>/dev/null | grep -vE "^\*|$main|master" | while read -r b; do
      git branch -d "$b" >/dev/null 2>&1 && echo "   🗑  deleted merged branch $b"
    done
    git remote prune origin >/dev/null 2>&1
  fi
done
