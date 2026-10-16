WoW Forever Dungeon Quest Helper v0.8.0
Target client: 1.60.1.70374 (Interface 16001)

WICHTIG: Die Questdatenbank ist jetzt von der Addon-Logik getrennt.
- Questdaten liegen in QuestData.lua.
- Um die Datenbank künftig zu aktualisieren, muss nur QuestData.lua ersetzt werden.
- Core.lua und die .toc-Datei müssen für reine Datenupdates nicht geändert werden.

Installation
1. ZIP entpacken und Ordner WoWForeverDungeonHelper in Interface/AddOns kopieren.
2. Spiel starten und /dqhelp öffnen.
3. /dqhelp dbversion zeigt die Datenbankversion an.
4. /dqhelp refresh aktualisiert die sichtbare Liste nach einem Datenwechsel, der beim nächsten Spielstart geladen wurde.

So aktualisierst du die Datenbank später
1. Lade die neue QuestData.lua herunter, die ich dir erstelle.
2. Schließe WoW vollständig.
3. Ersetze in Interface/AddOns/WoWForeverDungeonHelper die alte QuestData.lua durch die neue Datei.
4. Starte WoW neu.
5. Prüfe mit /dqhelp dbversion die neue Version.

Wichtig zu automatischen Updates
WoW-Addons können normalerweise nicht frei im Hintergrund Wowhead-Webseiten abrufen oder Dateien aus dem Internet herunterladen. Deshalb ist ein sicherer, wiederholbarer Datei-Austausch die zuverlässige Methode. Wenn du mir später eine aktualisierte Wowhead-Datenquelle oder eine exportierte Datenbank gibst, kann ich eine neue QuestData.lua erzeugen, ohne die restliche Addon-Logik zu verändern.

Datenstatus / Grenzen
- Die mitgelieferte Questliste ist eine kuratierte Startauswahl, keine vollständige Datenbank aller Forever-Dungeonquests.
- Wowhead kann Beta-Daten ändern oder korrigieren.
- Für zuverlässige Abschlussprüfung braucht jeder Datensatz eine geprüfte Quest-ID.
- Für Kartenwegpunkte brauchen wir geprüfte mapID- und numerische x/y-Werte; die bisher bekannten Koordinaten sind überwiegend als Text hinterlegt.
- Keine Live-Tests im Spielclient durchgeführt.


Version 0.5.0 – Wegpunkt/Kartensystem
- In der Questliste bei Einträgen mit Zahlenkoordinaten auf „Karte“ klicken.
- Zeigt einen verschiebbaren TomTom-ähnlichen Richtungspfeil mit Zielkoordinaten an.
- Auf der Weltkarte wird ein Pin gesetzt, sofern der Client die angezeigte Zone zuverlässig dem Quest-Ort zuordnen kann.
- /dqhelp clear entfernt den aktiven Wegpunkt.
- Hinweis: Die vorhandene Startdatenbank enthält keine geprüften Zonen-IDs; deshalb werden Pins nur bei erkennbar passender Zone angezeigt. Ein Teil der Quests hat nur Textangaben oder Dungeon-Orte und ist noch nicht markierbar. Entfernungsangabe ist eine grobe Koordinatendifferenz, keine Meter-/Yardmessung.


Version 0.5.1: improved world-map pin placement (uses WorldMapDetailFrame where available), larger red target marker, and a visible target-zone/coordinate notice when another map zone is open.


KARTENFIX 0.5.2:
- Kartenmarker wird direkt auf WorldMapButton gesetzt, nicht auf die Detail-Textur.
- Marker wird nicht mehr durch einen abweichenden/lokalisierten Gebietsnamen ausgeblendet.
- Ein Hinweis zeigt Zielgebiet und Koordinaten.
Hinweis: Die Position ist nur dann geografisch korrekt, wenn die richtige Gebiets-Karte geöffnet ist und die Koordinaten in der Datenbank stimmen.


VERSION 0.5.3:
- Kartenmarker verkleinert (16x16 Pixel).
- Kartenbefehl wechselt direkt, wenn ein Datensatz mapIndex/mapID enthält. Die derzeitige Starter-Datenbank hat diese Angaben noch nicht für alle Quests; ohne Kartenindex kann der alte Client das Zielgebiet nicht zuverlässig automatisch anhand des Gebietnamens öffnen.


VERSION 0.5.4 – MINIMAP-BUTTON:
- Ein Karten-Symbol an der Minimap öffnet/schließt den Dungeon Quest Helper, wie /dqhelp.
- Linksklick schaltet das Fenster um; Rechtsklick ebenfalls.


VERSION 0.5.5 – QUEST-ICON:
- Minimap-Button verwendet jetzt ein Quest-Notizsymbol statt der Karte.


VERSION 0.6.0 – SORTIERUNG:
- Neuer Sortierknopf: Klick wechselt zwischen Questname A–Z, erforderlichem Level aufsteigend und Fraktion.
- Die Sortierung wird gespeichert und mit den bestehenden Such- und Level-Filtern kombiniert.


VERSION 0.6.3 – MEHRFACHSORTIERUNG / LAYOUTFIX:
- Sortierkriterien Name, Level und Fraktion sind separate Kontrollkästchen.
- Mehrere Kriterien können gleichzeitig gewählt werden; die Reihenfolge ist Level, Fraktion, Name als alphabetischer Tie-Breaker.
- Mindestens ein Kriterium bleibt aktiv.


LAYOUTFIX 0.6.3:
Die Checkboxen Name, Level und Fraktion wurden weiter nach unten verschoben. Die Questliste beginnt ebenfalls tiefer, damit die Checkboxen nicht mehr mit „Sortieren nach“ überlappen.

Version 0.6.3: Minimap-Symbol auf 24x24 verkleinert, Icon-Textur korrigiert, per Ziehen am Minimaprand positionierbar; Winkel wird in WFDQHDB gespeichert.


Version 0.6.5 – Questabschluss-Abgleich
- Neue Option „Erledigte Quests ausblenden“ (standardmäßig aktiviert).
- Nutzt verfügbare Questabschluss-APIs des Clients und blendet Datensätze mit questID aus, sobald der Abschluss erkannt wird.
- WICHTIG: Die mitgelieferte Startdatenbank enthält aktuell keine verifizierten questID-Felder. Ohne Quest-IDs kann der Client die Datenbankeinträge nicht zuverlässig einem Abschluss zuordnen. Die QuestData.lua muss deshalb um geprüfte IDs ergänzt werden, damit das automatische Ausblenden für diese Einträge greift.
- Die Questliste kann nach Questabschluss-/Questlog-Ereignissen neu aufgebaut werden.


VERSION 0.7.5 – DUNGEON-SORTIERUNG
- Neues Sortierkriterium „Dungeon“ als eigene Checkbox im Hauptfenster.
- Wenn aktiv, werden Quests alphabetisch nach Dungeon gruppiert; danach greifen die optionalen Kriterien Level, Fraktion und Name.
- Die Einstellung wird zusammen mit den bisherigen Sortierkriterien in WFDQHDB gespeichert.
- Bestehende SavedVariables bleiben kompatibel; bei älteren Einstellungen ist Dungeon standardmäßig ausgeschaltet.


VERSION 0.8.0 – BELOHNUNGSDATEN
- Der Pin-Knopf setzt für Questgeber mit Koordinaten einen nativen WoW-Wegpunkt auf der passenden Ingame-Karte.
- Das Addon sucht den Kartenbereich automatisch anhand des Questgeber-Gebiets, öffnet die Karte und aktiviert die Wegverfolgung.
- /dqhelp clear entfernt den vom Addon gesetzten Wegpunkt wieder.

Version 0.7.7: Das zusätzliche Koordinatenfenster auf der Weltkarte und der Kreisrahmen am Minimap-Symbol wurden entfernt. Der native Questgeber-Pin bleibt aktiv.


Version 0.7.8: Schaltfläche Pin löschen im Addon-Fenster ergänzt; sie entfernt den aktiven Karten-Wegpunkt und blendet den Richtungspfeil aus.


Version 0.7.9: Belohnungs-Kurzinfo beim Überfahren und ausklappbare Detailansicht per Klick ergänzt.


Version 0.8.0: Quest-IDs für alle 114 Einträge und bestätigte Forever-Belohnungen für Einträge mit aktuellen Beta-Quellen ergänzt. Mehrfach-IDs werden bei Questlog und Abschlussstatus berücksichtigt. Nicht verifizierte Belohnungen und fehlende XP bleiben ausdrücklich markiert.

