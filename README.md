# WoW Forever Dungeon Quest Helper

Version **0.9.9** for WoW Forever client build `1.60.1.70374` (Interface `16001`).

## Dateien im Addon

- `Core.lua` enthält die Addon-Oberfläche und Logik.
- `QuestData.lua` enthält Questgeber, Quest-IDs, Belohnungen und verfügbare EP-Angaben.
- `DungeonLoot.lua` enthält Dungeon-Bosse, Gegenstands-IDs und verfügbare Dropchancen.
- `RaidLoot.lua` enthält Raid-Bosse, Gegenstands-IDs und verfügbare Dropchancen.
- `WoWForeverDungeonHelper.toc` lädt die Datendateien vor `Core.lua`.

Kopiere alle fünf Dateien gemeinsam in `Interface/AddOns/WoWForeverDungeonHelper`. Öffne das Addon im Spiel mit `/dqhelp`.

## Datenstand und Grenzen

Die Questliste ist eine kuratierte Auswahl. Dungeon- und Raidbeute sowie die bekannten Dropchancen wurden aus AtlasLoot Classic Forever 1.2.5 übernommen. Dropchancen sind beobachtete Quellenwerte und können serverseitig abweichen. Fehlt in der Quelle eine Rate, zeigt das Addon „Dropchance nicht hinterlegt“ an.

Die Raidliste umfasst Molten Core, Onyxia's Lair, Zul'Gurub, Blackwing Lair, Ruins of Ahn'Qiraj, Temple of Ahn'Qiraj, Naxxramas, Mount Hyjal und Barrow Deeps. Für Mount Hyjal und Barrow Deeps sind Bossnamen aufgeführt, aber AtlasLoot enthält derzeit keine Dropgegenstände.

Der Spielclient liefert die Gegenstandssymbole und Item-Tooltips. Bei noch nicht geladenen Itemdaten fordert das Addon die Daten beim Client an. Die Items lassen sich mit Shift-Linksklick anprobieren.

## Manifest

`manifest.json` enthält die direkten Raw-GitHub-URLs und SHA-256-Prüfsummen der Quest-, Dungeonloot- und Raidloot-Datenbanken. Questdaten bleiben außerdem unter den bisherigen Feldern `database_url` und `sha256` erreichbar.
