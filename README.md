# WoW Forever Dungeon Quest Helper

Version **1.0.0** for WoW Forever client build `1.60.1.70374` (Interface `16001`).

## Dateien im Addon

- `Core.lua` enthält die Addon-Oberfläche und Logik.
- `QuestData.lua` enthält Questgeber, Quest-IDs, Belohnungen und verfügbare EP-Angaben.
- `DungeonLoot.lua` enthält Dungeon-Bosse, Gegenstands-IDs und verfügbare Dropchancen.
- `RaidLoot.lua` enthält Raid-Bosse, Gegenstands-IDs und verfügbare Dropchancen.
- `GearData.lua` enthält die verfügbaren Tierset-Boni sowie die vorbereitete Datenstruktur für Pre-BiS/BiS.
- `WoWForeverDungeonHelper.toc` lädt die Datendateien vor `Core.lua`.

Kopiere alle sechs Dateien gemeinsam in `Interface/AddOns/WoWForeverDungeonHelper`. Öffne das Addon im Spiel mit `/dqhelp`.

## Tiersets und Pre-BiS/BiS

Der Reiter **Tiersets** zeigt die für Season 1 verfügbaren klassenspezifischen Setboni aus Wowheads Forever-Übersicht. Wowhead kennzeichnet diese Angaben als Datamining, das sich noch ändern kann. Zu den neuen Sets sind derzeit noch keine bestätigten Gegenstandsteile und Bossquellen hinterlegt; die Oberfläche kennzeichnet diesen Stand.

Der Reiter **Pre-BiS/BiS** bietet Klassenauswahl, Spezialisierung und Umschaltung zwischen Pre-BiS und BiS. Für WoW Forever sind in den verfügbaren Wowhead-Quellen noch keine bestätigten Empfehlungen hinterlegt. Deshalb bleibt die Liste zunächst leer, statt Classic-Empfehlungen als Forever-Daten auszugeben.

## Datenstand und Grenzen

Die Questliste ist eine kuratierte Auswahl. Dungeon- und Raidbeute sowie die bekannten Dropchancen wurden aus AtlasLoot Classic Forever 1.2.5 übernommen. Dropchancen sind beobachtete Quellenwerte und können serverseitig abweichen. Fehlt in der Quelle eine Rate, zeigt das Addon „Dropchance nicht hinterlegt“ an.

Die Raidliste umfasst Molten Core, Onyxia's Lair, Zul'Gurub, Blackwing Lair, Ruins of Ahn'Qiraj, Temple of Ahn'Qiraj, Naxxramas, Mount Hyjal und Barrow Deeps. Für Mount Hyjal und Barrow Deeps sind Bossnamen aufgeführt, aber AtlasLoot enthält derzeit keine Dropgegenstände.

Der Spielclient liefert die Gegenstandssymbole und Item-Tooltips. Bei noch nicht geladenen Itemdaten fordert das Addon die Daten beim Client an. Die Items lassen sich mit Shift-Linksklick anprobieren.

## Manifest

`manifest.json` enthält die direkten Raw-GitHub-URLs und SHA-256-Prüfsummen der Quest-, Dungeonloot-, Raidloot- und Gear-Datenbanken. Questdaten bleiben außerdem unter den bisherigen Feldern `database_url` und `sha256` erreichbar.
