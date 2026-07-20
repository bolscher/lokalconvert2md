# lokalconvert2md

Lokale workflow om een URL, een PDF of een Word-/office-bestand om te zetten
in schone markdown en die direct als notitie op te slaan in de `Inbox`-map
van je Obsidian vault, voorzien van een frontmatter-blok met metadata.

Volledige inhoud, geen samenvatting: alleen rommelige opmaak wordt omgezet
naar nette markdown.

## Gebruik

```bash
./naar-obsidian.sh <url | pad-naar-bestand.pdf | pad-naar-bestand.docx|.pptx|.odt|.rtf>
```

Het resultaat komt terecht in `<vault>/Inbox/YYYY-MM-DD-titel-van-document.md`,
met bovenaan een frontmatter-blok:

```markdown
---
title: "Titel van het document"
source: "https://... of het oorspronkelijke bestandspad"
date: 2026-07-20
type: url | pdf | docx | pptx | odt | rtf
tags: [inbox]
---

... volledige, opgeschoonde inhoud ...
```

De titel wordt overgenomen uit de eerste `# kop` in de omgezette markdown;
is die er niet, dan valt het script terug op de URL of bestandsnaam.

## Vault-pad instellen

Standaard schrijft het script naar:

```
/Users/h.j.tenbolscher/Library/CloudStorage/OneDrive-Saxion/Obsidian/Saxion/Inbox
```

Wil je een ander pad gebruiken (bijvoorbeeld op een andere machine), zet dan
de environment variable `OBSIDIAN_VAULT_INBOX`:

```bash
OBSIDIAN_VAULT_INBOX="/pad/naar/andere/vault/Inbox" ./naar-obsidian.sh document.pdf
```

## Vereisten

Per inputtype is een ander commando nodig, alleen dat commando moet aanwezig
zijn voor de bewuste conversie:

- **URL** → `curl` (haalt op via de dienst `markdown.new`)
- **Lokale PDF** → [`marker`](https://github.com/VikParuchuri/marker)
  (`pip install marker-pdf`), levert `marker_single` — behoudt tabellen,
  kolommen en leesvolgorde
- **Word-/office-bestand** (`.docx`, `.pptx`, `.odt`, `.rtf`) → `pandoc`

## Routering

- Begint de input met `http` → URL
- Eindigt op `.pdf` → lokale PDF via `marker_single`
- Eindigt op `.docx`, `.pptx`, `.odt` of `.rtf` → office-bestand via `pandoc`
