#!/usr/bin/env bash
# Zet een URL, lokale PDF of Word-/office-bestand om in schone markdown
# en slaat het resultaat, voorzien van een frontmatter-blok met metadata,
# direct op in de Inbox-map van de Obsidian vault.
#
# Gebruik:
#   ./naar-obsidian.sh <url | pad-naar.pdf | pad-naar.docx|.pptx|.odt|.rtf>
#
# Vault-map is te overschrijven met de env var OBSIDIAN_VAULT_INBOX.

set -euo pipefail

VAULT_INBOX="${OBSIDIAN_VAULT_INBOX:-/Users/h.j.tenbolscher/Library/CloudStorage/OneDrive-Saxion/Obsidian/Saxion/Inbox}"

if [ "$#" -lt 1 ]; then
  echo "Gebruik: $0 <url | pad-naar.pdf | pad-naar.docx|.pptx|.odt|.rtf>" >&2
  exit 1
fi

INPUT="$1"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$VAULT_INBOX" || {
  echo "Kan Inbox-map niet aanmaken/bereiken: $VAULT_INBOX" >&2
  echo "Zet OBSIDIAN_VAULT_INBOX naar het juiste pad van je vault." >&2
  exit 1
}

TODAY="$(date +%Y-%m-%d)"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Vereist commando '$1' ontbreekt. Installeer het en probeer opnieuw." >&2
    exit 1
  }
}

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

# Knipt overtollige lege regels weg (3+ opeenvolgende -> 1)
clean_markdown() {
  awk 'BEGIN{blank=0} { if ($0 ~ /^[[:space:]]*$/) { blank++; if (blank<=1) print } else { blank=0; print } }' "$1"
}

extract_title() {
  local file="$1" fallback="$2" t
  t="$(grep -m1 -E '^#[[:space:]]+' "$file" 2>/dev/null | sed -E 's/^#+[[:space:]]*//')"
  if [ -z "$t" ]; then
    t="$fallback"
  fi
  echo "$t"
}

escape_title() {
  echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

write_note() {
  local body_file="$1" title="$2" source="$3" type="$4"
  local slug target n=2
  slug="$(slugify "$title")"
  [ -z "$slug" ] && slug="document"
  target="$VAULT_INBOX/${TODAY}-${slug}.md"
  while [ -e "$target" ]; do
    target="$VAULT_INBOX/${TODAY}-${slug}-${n}.md"
    n=$((n + 1))
  done

  {
    echo "---"
    echo "title: \"$(escape_title "$title")\""
    echo "source: \"$(escape_title "$source")\""
    echo "date: $TODAY"
    echo "type: $type"
    echo "tags: [inbox]"
    echo "---"
    echo
    cat "$body_file"
  } >"$target"

  echo "$target"
}

case "$INPUT" in
http://* | https://*)
  need curl
  type="url"
  source="$INPUT"
  raw="$TMPDIR/raw.md"
  curl -sL --max-time 90 "https://markdown.new/${INPUT}" -o "$raw"
  if [ ! -s "$raw" ]; then
    echo "Kon geen inhoud ophalen van $INPUT" >&2
    exit 1
  fi
  clean_markdown "$raw" >"$TMPDIR/body.md"
  title="$(extract_title "$TMPDIR/body.md" "$INPUT")"
  ;;
*.pdf)
  need marker_single
  [ -f "$INPUT" ] || {
    echo "Bestand niet gevonden: $INPUT" >&2
    exit 1
  }
  type="pdf"
  source="$(cd "$(dirname "$INPUT")" && pwd)/$(basename "$INPUT")"
  outdir="$TMPDIR/marker-out"
  marker_single "$INPUT" --output_dir "$outdir"
  mdfile="$(find "$outdir" -name '*.md' | head -n1)"
  if [ -z "$mdfile" ]; then
    echo "marker leverde geen markdown-bestand op" >&2
    exit 1
  fi
  clean_markdown "$mdfile" >"$TMPDIR/body.md"
  title="$(extract_title "$TMPDIR/body.md" "$(basename "$INPUT" .pdf)")"
  ;;
*.docx | *.pptx | *.odt | *.rtf)
  need pandoc
  [ -f "$INPUT" ] || {
    echo "Bestand niet gevonden: $INPUT" >&2
    exit 1
  }
  type="${INPUT##*.}"
  source="$(cd "$(dirname "$INPUT")" && pwd)/$(basename "$INPUT")"
  pandoc "$INPUT" -t gfm -o "$TMPDIR/raw.md"
  clean_markdown "$TMPDIR/raw.md" >"$TMPDIR/body.md"
  title="$(extract_title "$TMPDIR/body.md" "$(basename "$INPUT" ".$type")")"
  ;;
*)
  echo "Onbekend inputtype: $INPUT" >&2
  echo "Ondersteund: URL (http/https), .pdf, .docx, .pptx, .odt, .rtf" >&2
  exit 1
  ;;
esac

target="$(write_note "$TMPDIR/body.md" "$title" "$source" "$type")"
echo "Opgeslagen in Obsidian Inbox: $target"
