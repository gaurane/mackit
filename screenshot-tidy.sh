#!/usr/bin/env bash
# screenshot-tidy — move old screenshots off the Desktop into dated folders.
#   screenshot-tidy        move screenshots older than 7 days
#   screenshot-tidy 1      move anything older than 1 day
#   screenshot-tidy 0      move everything now

set -u
DAYS=${1:-7}
SRC=$(defaults read com.apple.screencapture location 2>/dev/null || echo "$HOME/Desktop")
DEST="$HOME/Pictures/Screenshots"

moved=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  # Folder named by the month the screenshot was taken, e.g. 2026-10
  month=$(stat -f '%Sm' -t '%Y-%m' "$f")
  mkdir -p "$DEST/$month"
  mv "$f" "$DEST/$month/" && moved=$((moved+1))
done < <(find "$SRC" -maxdepth 1 -type f \( -iname 'Screenshot*' -o -iname 'Screen Shot*' -o -iname 'Screen Recording*' \) -mtime +"$DAYS")

if (( moved == 0 )); then
  echo "🖼  Nothing older than $DAYS day(s) to tidy."
else
  echo "🖼  Moved $moved file(s) into $DEST/<year-month>/"
fi
