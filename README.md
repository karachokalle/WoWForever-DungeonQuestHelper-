# WoW Forever Dungeon Quest Helper – Datenfeed und Addon

Öffentlicher Datenfeed und Quellcode für den Begleit-Updater des Addons **WoWForeverDungeonHelper** für den WoW Forever Client-Build `1.60.1.70374`.

## Updater-Manifest

`https://raw.githubusercontent.com/karachokalle/WoWForever-DungeonQuestHelper-/main/manifest.json`

Das Manifest verweist auf `QuestData.lua` und enthält die aktuelle Datenbankversion sowie eine SHA-256-Prüfsumme.

## Addon herunterladen / installieren

Die für das Addon benötigten Dateien liegen im Repository: `WoWForeverDungeonHelper.toc`, `QuestData.lua` und `Core.lua`. Kopiere sie in einen Ordner namens `WoWForeverDungeonHelper` unter `World of Warcraft/Interface/AddOns/`.

Aktuelle Addon-Version: **0.7.5**. Die Oberfläche enthält Sortierkriterien **Dungeon**, **Level**, **Fraktion** und **Name**. Ist Dungeon aktiv, werden Quest-Einträge alphabetisch nach Dungeon gruppiert; innerhalb derselben Dungeon-Gruppe greifen die weiteren eingeschalteten Kriterien.

## Datenbankstand und Datenqualität

- Datenbankversion: `2026-10-15a`
- Client-Build: `1.60.1.70374`
- Questdatenbank: 114 kuratierte Einträge

Die Questliste ist eine Starter-Datenbank und keine vollständige, unabhängig verifizierte Datenbank. Quest-IDs und Koordinaten sind nicht durchgehend verifiziert. Eine passende SHA-256-Prüfsumme bestätigt die Integrität der heruntergeladenen Datei, nicht die Richtigkeit jedes Eintrags.

## Dateien

- `manifest.json` – Version, Client-Build, Quelldatei und SHA-256
- `QuestData.lua` – austauschbare Questdatenbank
- `Core.lua` – Addon-Oberfläche, Filter, Dungeon-Sortierung und Wegpunktlogik
- `WoWForeverDungeonHelper.toc` – Addon-Ladereihenfolge und Metadaten
