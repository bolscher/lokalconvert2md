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
   Wil je een **webpagina** toevoegen: sleep de link uit Safari's adresbalk
   (of uit Mail) naar diezelfde map — dat maakt automatisch een
   `.webloc`-bestand aan, dat door de workflow herkend en verwerkt wordt
   als URL.
2. Dubbelklik op `Verwerk.app` (staat in de projectmap, naast dit README).
3. Elk bestand (en elke `.webloc`-link) in `~/NaarMarkdown` wordt omgezet,
   met frontmatter in de Obsidian Inbox gezet, en het originele
   bestand/linkje verdwijnt naar de prullenbak. Je krijgt een
   macOS-notificatie met het resultaat (aantal gelukt/mislukt).

Bestanden die mislukken (bijv. een corrupte PDF) blijven gewoon in
`~/NaarMarkdown` staan zodat je ze kunt bekijken; details staan in
`/tmp/naar-obsidian-<tijdstip>.log`.

**Eerste keer opstarten:** macOS blokkeert onbekende apps standaard. Klik met
de rechtermuisknop (of ctrl-klik) op `Verwerk.app` → **Open**, en bevestig.
Dat hoeft maar één keer.

**Notificaties niet zichtbaar?** Ga naar Systeeminstellingen →
Berichtgeving en controleer of meldingen van `osascript`/Script Editor zijn
toegestaan (macOS koppelt de melding daaraan omdat het script die aanroept).

## Configuratie: doelvault en watch-map instellen

Kopieer het meegeleverde voorbeeldbestand naar je home-map en pas het aan:

```bash
cp naar-obsidianrc.example ~/.naar-obsidianrc
```

`~/.naar-obsidianrc` wordt door alle scripts automatisch ingelezen — ook
wanneer ze via `Verwerk.app` worden gestart (een dubbelgeklikte app leest je
`.zshrc` namelijk niet). Inhoud:

```bash
# Map waar je bestanden neerzet om te laten converteren.
WATCH_FOLDER="$HOME/NaarMarkdown"

# Root van je Obsidian vault.
VAULT_PATH="/pad/naar/je/vault"

# Map binnen de vault waar de omgezette notities in terechtkomen.
VAULT_FOLDER="Inbox"
```

Zonder dit bestand vallen de scripts terug op `~/NaarMarkdown` als watch-map,
maar stoppen ze met een duidelijke foutmelding zodra er geen doelvault is
ingesteld — er zit dus geen hardcoded persoonlijk vaultpad in de broncode.

Wil je liever in één keer het volledige doelpad opgeven in plaats van
`VAULT_PATH`/`VAULT_FOLDER`, zet dan `OBSIDIAN_VAULT_INBOX` (heeft voorrang)
— hetzij in `~/.naar-obsidianrc`, hetzij losstaand als env var:

```bash
OBSIDIAN_VAULT_INBOX="/pad/naar/andere/vault/Inbox" ./naar-obsidian.sh document.pdf
```

## Vereisten

Per inputtype is een ander commando nodig, alleen dat commando moet aanwezig
zijn voor de bewuste conversie:

- **URL / `.webloc`-linkbestand** → `curl` (haalt op via de dienst
  `markdown.new`); `.webloc` wordt uitgelezen met `plutil`
  (standaard aanwezig op macOS)
- **Lokale PDF** → [`marker`](https://github.com/VikParuchuri/marker)
  (`pip install marker-pdf`), levert `marker_single` — behoudt tabellen,
  kolommen en leesvolgorde
- **Word-/office-bestand** (`.docx`, `.pptx`, `.odt`, `.rtf`) → `pandoc`

## Routering

- Begint de input met `http` → URL
- `.webloc`-bestand (alleen bij de map-workflow) → URL wordt eruit gehaald
  en als URL verwerkt
- Eindigt op `.pdf` → lokale PDF via `marker_single`
- Eindigt op `.docx`, `.pptx`, `.odt` of `.rtf` → office-bestand via `pandoc`
