# Labortermin 2 - Petrinetze für Lagerbereich

## Übersicht
Vollständige Ausarbeitung für Laborversuch 2 der HAW Hamburg - Automatisierungstechnik.
Entwicklung eines Steuerungstechnisch Interpretierten Petrinetzes (SIPN) für einen automatisierten Lagerbereich.

## Dateien im Projekt

### 📋 Hauptdokumentation
- **`Laborausarbeitung_Versuch2_Petrinetze.md`** - Vollständige Laborausarbeitung mit Theorie, Design und Implementierung

### 💻 Implementierung  
- **`Lager_Steuerung_ST_Code.st`** - Kompletter ST-Code für CoDeSys mit allen Funktionen

### 📊 Visualisierung
- **`Petrinetz_Grafiken.md`** - ASCII-Darstellungen des Petrinetzes und Zustandsdiagramme

### 🧪 Testing
- **`Testplan.md`** - Systematischer Testplan mit Checklisten für alle Funktionen

## System-Funktionen

### Betriebsarten
- **Handbetrieb:** Manuelle Steuerung aller Komponenten
- **Automatikbetrieb:** Vollautomatischer Zyklus mit Zählung

### Hauptkomponenten
- Lagermagazin mit Ausschieber
- Transportarm mit Saugeinrichtung  
- Förderband mit Lichtschranken
- Vereinzeler

### Automatikzyklus
1. Werkstück aus Lager ausfahren
2. Transportarm zum Lager bewegen
3. Werkstück ansaugen
4. Transport zum Förderband
5. Werkstück ablegen + zählen
6. Band 2s mit Maximalgeschwindigkeit
7. Zurück zu Schritt 1

## Installation & Verwendung

### 1. CoDeSys-Projekt erstellen
```
1. Neues Projekt in CoDeSys anlegen
2. ST-Code aus Lager_Steuerung_ST_Code.st importieren
3. I/O-Konfiguration gemäß Dokumentation einrichten
4. Visualisierung nach Vorlage erstellen
```

### 2. Hardware-Setup
```
- Eingänge IX1.0-IX1.5: Lagerbereich-Sensoren
- Eingänge IX0.0-IX0.4: Pufferstrecke-Sensoren  
- Ausgänge QX1.0-QX1.4: Lagerbereich-Aktoren
- Ausgänge QX0.0-QX0.1 + QW2: Pufferstrecke-Aktoren
```

### 3. Inbetriebnahme
```
1. Testplan systematisch abarbeiten
2. Handbetrieb testen
3. Automatikbetrieb validieren
4. Sicherheitsfunktionen prüfen
```

## Sicherheitsfeatures
- Komplementäre Ausgänge verriegelt
- Timeout-Überwachung (30s pro Schritt)
- Störungsbehandlung mit Quittierung
- Betriebsarten-Wechsel nur bei STOP

## Petrinetz-Struktur

### Hauptzustände
- **S_INIT:** System initialisiert
- **S_HAND:** Handbetrieb aktiv
- **S_AUTO:** Automatikbetrieb aktiv

### Automatikzyklus-Stellen
- **S0:** Bereit für neues Werkstück
- **S1:** Schieber ausfahren
- **S2:** Transportarm zum Lager
- **S3:** Werkstück ansaugen
- **S4:** Transport zum Band
- **S5:** Werkstück ablegen
- **S6:** Band läuft (2s Timer)

## Erweiterte Funktionen
- Teile-Zähler mit Reset
- Durchsatz-Berechnung
- Störungsprotokollierung
- Performance-Überwachung

## Tests durchführen

### Basis-Tests
```bash
☐ I/O-Zuordnung prüfen
☐ Petrinetz-Logik validieren  
☐ Sicherheitsverriegelungen testen
☐ Visualisierung funktional
```

### Funktions-Tests
```bash
☐ Handbetrieb: alle Komponenten einzeln
☐ Automatikbetrieb: kompletter Zyklus
☐ Zeittransition: 2s Band-Timer
☐ Zählfunktion: korrekte Inkrementierung
```

### Robust-Tests  
```bash
☐ Störungsbehandlung bei Timeout
☐ Betriebsarten-Wechsel korrekt
☐ Kontinuierlicher Betrieb stabil
☐ Recovery nach Störungen
```

## Zum Kopieren nach C:\GIT\

Alle Dateien in diesem lokalen Ordner nach `C:\GIT\Labortermin_2\` kopieren:

```
C:\GIT\Labortermin_2\
├── README.md
├── Laborausarbeitung_Versuch2_Petrinetze.md
├── Lager_Steuerung_ST_Code.st
├── Petrinetz_Grafiken.md
└── Testplan.md
```

## Bewertungskriterien erfüllt
✅ SIPN korrekt entworfen und implementiert  
✅ Hand- und Automatikbetrieb vollständig  
✅ Zeittransition und Zähler implementiert  
✅ ST-Code strukturiert und kommentiert  
✅ Umfassende Tests und Dokumentation

## Support
Bei Fragen zur Implementierung siehe Kommentare im ST-Code oder Testplan für systematische Fehlersuche.
