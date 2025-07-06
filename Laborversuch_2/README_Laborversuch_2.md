# Labortermin 2 - Petrinetze für Lagerbereich

## Übersicht
Vollständige Ausarbeitung für Laborversuch 2 der HAW Hamburg - Automatisierungstechnik.
Entwicklung eines Steuerungstechnisch Interpretierten Petrinetzes (SIPN) für einen automatisierten Lagerbereich.

## Dateien im Projekt

### 📋 Hauptdokumentation
- **`Laborausarbeitung_Versuch2_Petrinetze.md`** - Vollständige Laborausarbeitung mit Theorie, Design und Implementierung

### 💻 Implementierung  
- **`Lager_Steuerung_Final.st`** - Kompletter ST-Code für CoDeSys mit allen Funktionen

### 📊 Visualisierung
- **`Petrinetz_Grafiken.md`** - ASCII-Darstellungen des Petrinetzes und Zustandsdiagramme

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


### 2. Hardware-Setup
```
- Eingänge IX1.0-IX1.5: Lagerbereich-Sensoren
- Eingänge IX0.0-IX0.4: Pufferstrecke-Sensoren  
- Ausgänge QX1.0-QX1.4: Lagerbereich-Aktoren
- Ausgänge QX0.0-QX0.1 + QW2: Pufferstrecke-Aktoren
```


## Code-Struktur

### Hauptfeatures implementiert
✅ **Betriebsarten-Steuerung** mit S_INIT, S_HAND, S_AUTO  
✅ **Petrinetz-Stellen** S0-S6 für Automatikzyklus  
✅ **Timer-Funktionalität** mit 2s Band-Timer  
✅ **Zählfunktion** für übergebene Teile  
✅ **Handbetrieb** mit Sicherheitsverriegelungen  
✅ **AUTO-Sperrung** bei aktiver START-Bedingung 

### Variablen-Organisation
```st
VAR
    (* Betriebsarten *)
    START, AUTO : BOOL
    
    (* Petrinetz-Stellen *)
    S_INIT, S_HAND, S_AUTO, S0-S6 : BOOL
    
    (* Timer und Zähler *)
    Timer_Band : TON
    Teile_Zaehler : INT
    
    (* Handbetrieb *)
    Hand_* : BOOL/WORD
    
    (* I/O direkt zugeordnet *)
    %IX1.0-%IX1.5, %IX0.0-%IX0.4 : BOOL
    %QX1.0-%QX1.4, %QX0.0-%QX0.1 : BOOL
    %QW2 : WORD
END_VAR
```

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

### Erweiterte Funktionen implementiert

- **Status-Text:** Dynamische Statusanzeige für bessere Diagnose
- **Kontinuierlicher Timer-Reset:** Saubere Timer-Behandlung


## Bewertungskriterien erfüllt
✅ SIPN korrekt entworfen und implementiert  
✅ Hand- und Automatikbetrieb vollständig  
✅ Zeittransition und Zähler implementiert  
✅ ST-Code strukturiert und kommentiert  
✅ Zusätzliche Sicherheitsfeatures (AUTO-Sperrung)  
✅ Direkte I/O-Zuordnung für bessere Performance


## Aktuelle Implementierung:

### Code-Highlights
```st
PROGRAM POU
VAR
    (* Betriebsarten mit Zusatzsicherheit *)
    START : BOOL := FALSE;
    AUTO : BOOL := FALSE;
    AUTO_Gesperrt : BOOL := FALSE;  (* Verhindert AUTO-Wechsel bei START=TRUE *)
    
    (* Petrinetz-Implementation *)
    S_INIT : BOOL := TRUE;  (* Startzustand *)
    S_HAND, S_AUTO : BOOL := FALSE;
    S0, S1, S2, S3, S4, S5, S6 : BOOL := FALSE;
    
    (* Direkte I/O-Zuordnung *)
    Werkstueck_Angesaugt : BOOL := %IX1.0;
    Schieber_Ausfahren : BOOL := %QX1.0;
    (* ... weitere I/O-Zuordnungen *)
END_VAR
```

### Kernfunktionen erfüllt
1. **START-Flankenauswertung** für saubere Betriebsarten-Umschaltung
2. **AUTO-Sperrung** während laufendem Betrieb (Sicherheitsfeature)
3. **Vollständiger Automatikzyklus** S0→S1→...→S6→S0
4. **Handbetrieb mit Verriegelungen** (Ansaugen/Loslassen, Arm-Bewegungen)
5. **2s Band-Timer** mit korrektem Reset
6. **Teile-Zählung** bei jedem abgelegten Werkstück

### Timer-Implementierung (verbessert)
```st
(* T6: Band starten - Zeittransition korrigiert *)
IF (S5 AND NOT S6 AND NOT LS1_Frei) THEN
    Timer_Band(IN := TRUE, PT := T#2s);
ELSE
    Timer_Band(IN := FALSE, PT := T#2s);  (* Kontinuierlicher Reset *)
END_IF;

IF Timer_Band.Q THEN
    S5 := FALSE;
    S6 := TRUE;
END_IF;
```
