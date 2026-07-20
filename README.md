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

## Map-workflow op de Mac: verzamelen, dubbelklikken, klaar

Voor dagelijks gebruik hoef je niets op de command line te doen:

1. Sleep of bewaar bestanden (`.pdf`, `.docx`, `.pptx`, `.odt`, `.rtf`) in de
   map `~/NaarMarkdown` (wordt automatisch aangemaakt bij de eerste run).
2. Dubbelklik op `Verwerk.app` (staat in de projectmap, naast dit README).
3. Elk bestand in `~/NaarMarkdown` wordt omgezet, met frontmatter in de
   Obsidian Inbox gezet, en het originele bestand verdwijnt naar de
   prullenbak. Je krijgt een macOS-notificatie met het resultaat
   (aantal gelukt/mislukt).

Bestanden die mislukken (bijv. een corrupte PDF) blijven gewoon in
`~/NaarMarkdown` staan zodat je ze kunt bekijken; details staan in
`/tmp/naar-obsidian-<tijdstip>.log`.

**Eerste keer opstarten:** macOS blokkeert onbekende apps standaard. Klik met
de rechtermuisknop (of ctrl-klik) op `Verwerk.app` → **Open**, en bevestig.
Dat hoeft maar één keer.

**Notificaties niet zichtbaar?** Ga naar Systeeminstellingen →
Berichtgeving en controleer of meldingen van `osascript`/Script Editor zijn
toegestaan (macOS koppelt de melding daaraan omdat het script die aanroept).

**Andere map- of vaultpaden gebruiken:** maak een bestand `~/.naar-obsidianrc`
aan (wordt door beide scripts ingelezen, ook wanneer ze via de app worden
gestart — een dubbelgeklikte app leest je `.zshrc` namelijk niet):

```bash
export WATCH_FOLDER="/pad/naar/eigen/map"
export OBSIDIAN_VAULT_INBOX="/pad/naar/andere/vault/Inbox"
```

## Losse aanroep en vault-pad instellen

Standaard schrijft het script naar:

```
/Users/h.j.tenbolscher/Library/CloudStorage/OneDrive-Saxion/Obsidian/Saxion/Inbox
```

Wil je een ander pad gebruiken (bijvoorbeeld op een andere machine), zet dan
de environment variable `OBSIDIAN_VAULT_INBOX` (of gebruik `~/.naar-obsidianrc`
zoals hierboven):

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
