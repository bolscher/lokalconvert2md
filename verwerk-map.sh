#!/usr/bin/env bash
# Verwerkt alle ondersteunde bestanden in de watch-map: zet elk bestand om
# naar markdown in de Obsidian Inbox (via naar-obsidian.sh) en verplaatst
# het bronbestand daarna naar de prullenbak. Bedoeld om aangeroepen te
# worden door Verwerk.app, maar werkt ook los vanaf de command line.
#
# Watch-map is te overschrijven met de env var WATCH_FOLDER, of via
# ~/.naar-obsidianrc.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
[ -f "$HOME/.naar-obsidianrc" ] && . "$HOME/.naar-obsidianrc"

WATCH_FOLDER="${WATCH_FOLDER:-$HOME/NaarMarkdown}"
LOGFILE="/tmp/naar-obsidian-$(date +%Y%m%d-%H%M%S).log"

notify() {
  local title="$1" message="$2"
  osascript -e "display notification \"$(echo "$message" | sed 's/\\/\\\\/g; s/"/\\"/g')\" with title \"$(echo "$title" | sed 's/\\/\\\\/g; s/"/\\"/g')\"" >/dev/null 2>&1 || true
}

move_to_trash() {
  osascript -e "tell application \"Finder\" to delete POSIX file \"$1\"" >/dev/null 2>&1
}

if ! mkdir -p "$WATCH_FOLDER" 2>/dev/null; then
  notify "Naar Markdown" "Kan map niet aanmaken/bereiken: $WATCH_FOLDER"
  exit 1
fi

shopt -s nullglob nocaseglob
files=("$WATCH_FOLDER"/*.pdf "$WATCH_FOLDER"/*.docx "$WATCH_FOLDER"/*.pptx "$WATCH_FOLDER"/*.odt "$WATCH_FOLDER"/*.rtf)
shopt -u nullglob nocaseglob

if [ "${#files[@]}" -eq 0 ]; then
  notify "Naar Markdown" "Geen bestanden om te verwerken in $WATCH_FOLDER"
  exit 0
fi

ok=0
fail=0
fail_names=()

for f in "${files[@]}"; do
  if "$SCRIPT_DIR/naar-obsidian.sh" "$f" >>"$LOGFILE" 2>&1; then
    move_to_trash "$f"
    ok=$((ok + 1))
  else
    fail=$((fail + 1))
    fail_names+=("$(basename "$f")")
  fi
done

if [ "$fail" -eq 0 ]; then
  notify "Naar Markdown" "$ok bestand(en) omgezet, in Obsidian Inbox gezet en naar de prullenbak verplaatst."
else
  notify "Naar Markdown" "$ok gelukt, $fail mislukt (${fail_names[*]}). Log: $LOGFILE"
fi
