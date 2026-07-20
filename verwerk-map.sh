#!/usr/bin/env bash
# Verwerkt alle ondersteunde bestanden in de watch-map: zet elk bestand
# (of .webloc-linkbestand) om naar markdown in de Obsidian Inbox (via
# naar-obsidian.sh) en verplaatst het bronbestand daarna naar de
# prullenbak. Bedoeld om aangeroepen te worden door Verwerk.app, maar werkt
# ook los vanaf de command line.
#
# Watch-map is te overschrijven met de env var WATCH_FOLDER, of via
# ~/.naar-obsidianrc.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
[ -f "$HOME/.naar-obsidianrc" ] && . "$HOME/.naar-obsidianrc"

WATCH_FOLDER="${WATCH_FOLDER:-$HOME/NaarMarkdown}"
LOGFILE="/tmp/naar-obsidian-$(date +%Y%m%d-%H%M%S).log"

# Geeft titel/bericht als los argument mee aan osascript (on run argv) in
# plaats van ze in de AppleScript-broncode te plakken. Zo kan de inhoud
# nooit uit de string breken, ongeacht aanhalingstekens of andere tekens.
notify() {
  osascript >/dev/null 2>&1 <<'APPLESCRIPT' "$1" "$2" || true
on run argv
  set theTitle to item 1 of argv
  set theMessage to item 2 of argv
  display notification theMessage with title theTitle
end run
APPLESCRIPT
}

# Zelfde argv-aanpak voor het verplaatsen naar de prullenbak: het pad wordt
# als argument doorgegeven, nooit in de scriptstring geïnterpoleerd. Dat
# voorkomt AppleScript-/command-injectie via een kwaadaardig gekozen
# bestandsnaam (bv. met een dubbel aanhalingsteken erin).
move_to_trash() {
  osascript >/dev/null 2>&1 <<'APPLESCRIPT' "$1" || true
on run argv
  set thePath to item 1 of argv
  tell application "Finder" to delete POSIX file thePath
end run
APPLESCRIPT
}

# Haalt de URL uit een .webloc-linkbestand (zoals macOS aanmaakt wanneer je
# een link uit Safari's adresbalk naar Finder sleept). Probeert plutil
# (moderne macOS) en valt terug op PlistBuddy (altijd aanwezig).
extract_webloc_url() {
  local f="$1" url
  url="$(plutil -extract URL raw -o - "$f" 2>/dev/null)"
  if [ -z "$url" ]; then
    url="$(/usr/libexec/PlistBuddy -c 'Print :URL' "$f" 2>/dev/null)"
  fi
  echo "$url"
}

convert_one() {
  local f="$1"
  case "$f" in
  *.[wW][eE][bB][lL][oO][cC])
    local url
    url="$(extract_webloc_url "$f")"
    if [ -z "$url" ]; then
      echo "Kon geen URL uit .webloc-bestand halen: $f" >&2
      return 1
    fi
    "$SCRIPT_DIR/naar-obsidian.sh" "$url"
    ;;
  *)
    "$SCRIPT_DIR/naar-obsidian.sh" "$f"
    ;;
  esac
}

if ! mkdir -p "$WATCH_FOLDER" 2>/dev/null; then
  notify "Naar Markdown" "Kan map niet aanmaken/bereiken: $WATCH_FOLDER"
  exit 1
fi

shopt -s nullglob nocaseglob
files=("$WATCH_FOLDER"/*.pdf "$WATCH_FOLDER"/*.docx "$WATCH_FOLDER"/*.pptx "$WATCH_FOLDER"/*.odt "$WATCH_FOLDER"/*.rtf "$WATCH_FOLDER"/*.webloc)
shopt -u nullglob nocaseglob

if [ "${#files[@]}" -eq 0 ]; then
  notify "Naar Markdown" "Geen bestanden om te verwerken in $WATCH_FOLDER"
  exit 0
fi

ok=0
fail=0
fail_names=()

for f in "${files[@]}"; do
  if convert_one "$f" >>"$LOGFILE" 2>&1; then
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
