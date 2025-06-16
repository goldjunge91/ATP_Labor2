# Laborausarbeitung Versuch 2: Petrinetze für Lagerbereich
**HAW Hamburg - Labor für Automatisierungstechnik**  
**Version 2025**

## 1. Aufgabenstellung

Entwicklung und Implementierung eines Steuerungstechnisch Interpretierten Petrinetzes (SIPN) für einen Lagerbereich mit zugehöriger Pufferstrecke.

### 1.1 Systemkomponenten

**Lagerbereich:**
- Magazin für runde Werkstücke
- Ausschieber 
- Transportarm mit Saugeinrichtung

**Pufferstrecke:**
- Förderband mit drei Lichtschranken (LS1, LS2, LS3)
- Vereinzeler

### 1.2 I/O-Signale

**Lagerbereich Eingänge:**
- %IX1.0: Werkstück angesaugt (1 = angesaugt)
- %IX1.1: Lager leer (1 = leer)
- %IX1.2: Ausschieber eingefahren (1 = Position erreicht)
- %IX1.3: Ausschieber ausgefahren (1 = Position erreicht)
- %IX1.4: Transportarm am Band (1 = Position erreicht)
- %IX1.5: Transportarm am Lager (1 = Position erreicht)

**Lagerbereich Ausgänge:**
- %QX1.0: Schieber ausfahren (1 = Ausfahren)
- %QX1.1: Werkstück ansaugen (1 = Ansaugen)
- %QX1.2: Werkstück loslassen (1 = Loslassen)
- %QX1.3: Transportarm zum Lager (1 = Befehl)
- %QX1.4: Transportarm zum Band (1 = Befehl)

**Pufferstrecke:**
- %IX0.2: LS1 - LS Start (1 = nicht belegt)
- %IX0.3: LS2 - LS Vereinzeler (1 = nicht belegt)
- %IX0.4: LS3 - LS Ende (1 = nicht belegt)
- %QX0.0: Vereinzeler auf (1 = auf)
- %QX0.1: Drehrichtung Band (0 = Standard)
- %QW2: Bandgeschwindigkeit (0-32500)

### 1.3 Betriebsarten

**Handbetrieb (AUTO = FALSE):**
- Manuelle Steuerung über Visualisierung
- Einzelne Komponenten separat bedienbar

**Automatikbetrieb (AUTO = TRUE):**
- Automatischer Zyklus: Werkstück aus Lager → Transport → Ablage auf Band
- Zählung der übergebenen Teile

## 2. Petrinetz-Design

### 2.1 Hauptpetrinetz mit Betriebsarten-Steuerung

```
                    START ∧ ¬AUTO
S_INIT ────────────────────────────→ S_HAND
   │                                     │
   │ START ∧ AUTO                       │ ¬START
   ↓                                     │
S_AUTO ←──────────────────────────────────┘
   │        ¬START
   │
   └─→ [Automatikzyklus-Petrinetz]
```

**Stellen:**
- S_INIT: Initialisierung/Bereit
- S_HAND: Handbetrieb aktiv  
- S_AUTO: Automatikbetrieb aktiv

### 2.2 Automatikbetrieb-Petrinetz

```
S0 ──→ T1 ──→ S1 ──→ T2 ──→ S2 ──→ T3 ──→ S3 ──→ T4 ──→ S4 ──→ T5 ──→ S5 ──→ T6 ──→ S6
│      ¬Lager_leer   Schieber    Transportarm    Werkstück    Transport    Band_frei   2s_Timer  │
│      ∧ LS1_frei    ausgefahren am_Lager       angesaugt    am_Band      ∧LS1_belegt            │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Detaillierte Transitionen:**

**T1:** Werkstück ausfahren
- Schaltbedingung: S0 ∧ ¬S1 ∧ ¬%IX1.1 ∧ %IX0.2
- Aktion: %QX1.0 := 1 (Schieber ausfahren)

**T2:** Transportarm zum Lager
- Schaltbedingung: S1 ∧ ¬S2 ∧ %IX1.3
- Aktion: %QX1.3 := 1 (Transportarm zum Lager)

**T3:** Werkstück ansaugen
- Schaltbedingung: S2 ∧ ¬S3 ∧ %IX1.5
- Aktion: %QX1.1 := 1 (Werkstück ansaugen)

**T4:** Transport zum Band
- Schaltbedingung: S3 ∧ ¬S4 ∧ %IX1.0
- Aktion: %QX1.4 := 1, %QX1.0 := 0 (Transport zum Band, Schieber einfahren)

**T5:** Werkstück ablegen
- Schaltbedingung: S4 ∧ ¬S5 ∧ %IX1.4
- Aktion: %QX1.2 := 1, Zähler := Zähler + 1 (Werkstück loslassen, Zähler erhöhen)

**T6:** Band starten (Zeittransition 2s)
- Schaltbedingung: S5 ∧ ¬S6 ∧ ¬%IX0.2
- Aktion: %QW2 := 32500 (Maximalgeschwindigkeit)

**T7:** Zyklus beenden
- Schaltbedingung: S6 ∧ ¬S0 ∧ Timer_2s.Q
- Aktion: %QW2 := 0, Reset aller Ausgänge

## 3. ST-Code Implementierung

### 3.1 Variablendeklaration

```pascal
VAR
    (* Betriebsarten-Steuerung *)
    START : BOOL := FALSE;
    AUTO : BOOL := FALSE;
    
    (* Petrinetz-Stellen Betriebsarten *)
    S_INIT : BOOL := TRUE;
    S_HAND : BOOL := FALSE;
    S_AUTO : BOOL := FALSE;
    
    (* Petrinetz-Stellen Automatikzyklus *)
    S0, S1, S2, S3, S4, S5, S6 : BOOL := FALSE;
    
    (* Zeittransition *)
    Timer_Band : TON;
    
    (* Zähler *)
    Teile_Zaehler : INT := 0;
    
    (* Handbetrieb Variablen *)
    Hand_Schieber_Aus : BOOL := FALSE;
    Hand_Ansaugen : BOOL := FALSE;
    Hand_Loslassen : BOOL := FALSE;
    Hand_Arm_Lager : BOOL := FALSE;
    Hand_Arm_Band : BOOL := FALSE;
    Hand_Band_Start : BOOL := FALSE;
    Hand_Bandgeschw : WORD := 0;
    Hand_Vereinzeler : BOOL := FALSE;
    
    (* Hilfsvariablen *)
    START_Alt : BOOL := FALSE;
    START_Flanke : BOOL := FALSE;
END_VAR
```

### 3.2 Hauptprogramm

```pascal
PROGRAM Lager_Steuerung
VAR_INPUT
    (* Eingänge Lagerbereich *)
    Werkstueck_Angesaugt : BOOL := %IX1.0;
    Lager_Leer : BOOL := %IX1.1;
    Schieber_Eingefahren : BOOL := %IX1.2;
    Schieber_Ausgefahren : BOOL := %IX1.3;
    Arm_Am_Band : BOOL := %IX1.4;
    Arm_Am_Lager : BOOL := %IX1.5;
    
    (* Eingänge Pufferstrecke *)
    Vereinzeler_Auf : BOOL := %IX0.0;
    Vereinzeler_Zu : BOOL := %IX0.1;
    LS1_Frei : BOOL := %IX0.2;
    LS2_Frei : BOOL := %IX0.3;
    LS3_Frei : BOOL := %IX0.4;
END_VAR

VAR_OUTPUT
    (* Ausgänge Lagerbereich *)
    Schieber_Ausfahren : BOOL := %QX1.0;
    Werkstueck_Ansaugen : BOOL := %QX1.1;
    Werkstueck_Loslassen : BOOL := %QX1.2;
    Arm_Zum_Lager : BOOL := %QX1.3;
    Arm_Zum_Band : BOOL := %QX1.4;
    
    (* Ausgänge Pufferstrecke *)
    Vereinzeler_Auf_Out : BOOL := %QX0.0;
    Band_Drehrichtung : BOOL := %QX0.1;
    Bandgeschwindigkeit : WORD := %QW2;
END_VAR

(* START-Flankenauswertung *)
START_Flanke := START AND NOT START_Alt;
START_Alt := START;

(* Initialisierung bei START-Flanke *)
IF START_Flanke THEN
    IF AUTO THEN
        S_INIT := FALSE;
        S_AUTO := TRUE;
        S0 := TRUE;
        Teile_Zaehler := 0;
    ELSE
        S_INIT := FALSE;
        S_HAND := TRUE;
    END_IF;
END_IF;

(* Betriebsarten-Umschaltung nur bei START = FALSE *)
IF NOT START THEN
    S_INIT := TRUE;
    S_HAND := FALSE;
    S_AUTO := FALSE;
    S0 := FALSE; S1 := FALSE; S2 := FALSE; S3 := FALSE; 
    S4 := FALSE; S5 := FALSE; S6 := FALSE;
END_IF;

(* Handbetrieb *)
IF S_HAND THEN
    (* Direkte Ausgangszuweisungen *)
    Schieber_Ausfahren := Hand_Schieber_Aus;
    Werkstueck_Ansaugen := Hand_Ansaugen AND NOT Hand_Loslassen;
    Werkstueck_Loslassen := Hand_Loslassen AND NOT Hand_Ansaugen;
    Arm_Zum_Lager := Hand_Arm_Lager AND NOT Hand_Arm_Band;
    Arm_Zum_Band := Hand_Arm_Band AND NOT Hand_Arm_Lager;
    Vereinzeler_Auf_Out := Hand_Vereinzeler;
    
    IF Hand_Band_Start THEN
        Bandgeschwindigkeit := Hand_Bandgeschw;
    ELSE
        Bandgeschwindigkeit := 0;
    END_IF;
END_IF;

(* Automatikbetrieb *)
IF S_AUTO THEN
    (* T1: Werkstück ausfahren *)
    IF (S0 AND NOT S1 AND NOT Lager_Leer AND LS1_Frei) THEN
        S0 := FALSE;
        S1 := TRUE;
    END_IF;
    
    (* T2: Transportarm zum Lager *)
    IF (S1 AND NOT S2 AND Schieber_Ausgefahren) THEN
        S1 := FALSE;
        S2 := TRUE;
    END_IF;
    
    (* T3: Werkstück ansaugen *)
    IF (S2 AND NOT S3 AND Arm_Am_Lager) THEN
        S2 := FALSE;
        S3 := TRUE;
    END_IF;
    
    (* T4: Transport zum Band *)
    IF (S3 AND NOT S4 AND Werkstueck_Angesaugt) THEN
        S3 := FALSE;
        S4 := TRUE;
    END_IF;
    
    (* T5: Werkstück ablegen *)
    IF (S4 AND NOT S5 AND Arm_Am_Band) THEN
        S4 := FALSE;
        S5 := TRUE;
        Teile_Zaehler := Teile_Zaehler + 1;
    END_IF;
    
    (* T6: Band starten (Zeittransition) *)
    Timer_Band(IN := S5 AND NOT S6 AND NOT LS1_Frei, PT := T#2s);
    IF Timer_Band.Q THEN
        S5 := FALSE;
        S6 := TRUE;
        Timer_Band(IN := FALSE);
    END_IF;
    
    (* T7: Zyklus beenden *)
    IF (S6 AND NOT S0) THEN
        S6 := FALSE;
        S0 := TRUE;
    END_IF;
    
    (* Ausgangszuweisungen Automatikbetrieb *)
    Schieber_Ausfahren := S1 OR S2 OR S3 OR S4;
    Werkstueck_Ansaugen := S3 OR S4;
    Werkstueck_Loslassen := S5;
    Arm_Zum_Lager := S2;
    Arm_Zum_Band := S4 OR S5;
    
    IF S6 THEN
        Bandgeschwindigkeit := 32500;
    ELSE
        Bandgeschwindigkeit := 0;
    END_IF;
END_IF;

(* Ausgänge zurücksetzen wenn nicht aktiv *)
IF S_INIT THEN
    Schieber_Ausfahren := FALSE;
    Werkstueck_Ansaugen := FALSE;
    Werkstueck_Loslassen := FALSE;
    Arm_Zum_Lager := FALSE;
    Arm_Zum_Band := FALSE;
    Vereinzeler_Auf_Out := FALSE;
    Bandgeschwindigkeit := 0;
    Band_Drehrichtung := FALSE;
END_IF;

END_PROGRAM
```

## 4. Visualisierung

### 4.1 Hauptbildschirm-Layout

```
┌─────────────────────────────────────────────────────────────┐
│  LAGERBEREICH STEUERUNG                                     │
├─────────────────────────────────────────────────────────────┤
│  Betriebsart: [AUTO] [HAND]     Status: [START] [STOP]     │
│                                                             │
│  ┌─ Lagerbereich ─────────┐  ┌─ Pufferstrecke ────────────┐ │
│  │                         │  │                            │ │
│  │  [LAGER] → [ARM] → [○] │  │  LS1  LS2  LS3            │ │
│  │     ↑        ↓          │  │  [○]  [○]  [○]            │ │
│  │  [SCHIEBER]            │  │                            │ │
│  │                         │  │  ←─────[BAND]─────→       │ │
│  └─────────────────────────┘  │                            │ │
│                               │  [VEREINZELER]             │ │
│  Teile-Zähler: [0042]        └────────────────────────────┘ │
│                                                             │
│  ┌─ Handbetrieb ─────────────────────────────────────────┐  │
│  │  [Schieber Aus] [Ansaugen] [Loslassen]               │  │
│  │  [Arm→Lager] [Arm→Band] [Band Start]                │  │
│  │  Geschwindigkeit: [____] [Vereinzeler]               │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌─ Status ──────────────────────────────────────────────┐  │
│  │  Aktuelle Stelle: [S3]                               │  │
│  │  Lager leer: [NEIN]  Werkstück angesaugt: [JA]      │  │
│  │  Schieber: [AUS]     Transportarm: [AM_LAGER]       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Visualisierungscode (vereinfacht)

```pascal
(* Statusanzeigen *)
IF S0 THEN Status_Text := 'Bereit'; END_IF;
IF S1 THEN Status_Text := 'Schieber ausfahren'; END_IF;
IF S2 THEN Status_Text := 'Arm zum Lager'; END_IF;
IF S3 THEN Status_Text := 'Werkstück ansaugen'; END_IF;
IF S4 THEN Status_Text := 'Transport zum Band'; END_IF;
IF S5 THEN Status_Text := 'Werkstück ablegen'; END_IF;
IF S6 THEN Status_Text := 'Band läuft'; END_IF;

(* Farbanzeigen *)
Lager_Farbe := 16#FF0000; (* Rot wenn leer *)
IF NOT Lager_Leer THEN Lager_Farbe := 16#00FF00; END_IF; (* Grün wenn voll *)

LS1_Farbe := 16#808080; (* Grau wenn frei *)
IF NOT LS1_Frei THEN LS1_Farbe := 16#FFFF00; END_IF; (* Gelb wenn belegt *)
```

## 5. Test-Szenarien

### 5.1 Handbetrieb-Tests

**Test 1: Einzelkomponenten**
1. START = TRUE, AUTO = FALSE
2. Handbetrieb-Schaltflächen einzeln testen
3. Verriegelung prüfen (Ansaugen/Loslassen, Arm Lager/Band)

**Test 2: Manueller Zyklus**
1. Schieber ausfahren → warten auf Schieber_Ausgefahren
2. Arm zum Lager → warten auf Arm_Am_Lager  
3. Ansaugen → warten auf Werkstueck_Angesaugt
4. Arm zum Band → warten auf Arm_Am_Band
5. Loslassen → Band starten

### 5.2 Automatikbetrieb-Tests

**Test 3: Normaler Automatikzyklus**
1. START = TRUE, AUTO = TRUE
2. Lager nicht leer, LS1 frei
3. Zyklus durchlaufen lassen
4. Zähler prüfen

**Test 4: Grenzbedingungen**
1. Lager leer → kein Zyklus
2. LS1 belegt → warten
3. START = FALSE während Zyklus → Zyklus beenden

**Test 5: Zeittransition**
1. Werkstück auf LS1 platzieren
2. Band-Timer (2s) prüfen
3. Maximalgeschwindigkeit prüfen

### 5.3 Betriebsarten-Umschaltung

**Test 6: Umschaltung nur bei STOP**
1. START = TRUE → Umschaltung blockiert
2. START = FALSE → Umschaltung möglich
3. START-Flankenauswertung prüfen

## 6. Erweiterte Funktionen

### 6.1 Störungsbehandlung

```pascal
(* Störungsüberwachung *)
VAR
    Stoerung_Timeout : TON;
    Stoerung_Aktiv : BOOL := FALSE;
END_VAR

(* Timeout-Überwachung pro Stelle *)
Stoerung_Timeout(IN := S1 OR S2 OR S3 OR S4, PT := T#30s);
IF Stoerung_Timeout.Q THEN
    Stoerung_Aktiv := TRUE;
    (* Alle Ausgänge zurücksetzen *)
    S0 := TRUE; S1 := FALSE; S2 := FALSE; S3 := FALSE;
    S4 := FALSE; S5 := FALSE; S6 := FALSE;
END_IF;
```

### 6.2 Warteschlange (Queue)

```pascal
(* Erweiterte Funktionalität: Werkstück-Warteschlange *)
VAR
    Queue_Zaehler : INT := 0;
    Max_Queue : INT := 5;
END_VAR

IF S5 AND Arm_Am_Band THEN
    IF Queue_Zaehler < Max_Queue THEN
        (* Werkstück ablegen *)
        Werkstueck_Loslassen := TRUE;
        Queue_Zaehler := Queue_Zaehler + 1;
    ELSE
        (* Warten bis Platz frei *)
        Werkstueck_Loslassen := FALSE;
    END_IF;
END_IF;
```

## 7. Inbetriebnahme und Validierung

### 7.1 Checkliste vor Inbetriebnahme

- [ ] Alle I/O-Adressen korrekt zugeordnet
- [ ] Petrinetz-Logik implementiert und getestet
- [ ] Sicherheitsverriegelungen aktiv
- [ ] Visualisierung funktional
- [ ] Handbetrieb getestet
- [ ] Automatikbetrieb getestet
- [ ] Störungsbehandlung implementiert

### 7.2 Abnahmekriterien

1. **Handbetrieb:** Alle Komponenten einzeln steuerbar
2. **Automatikbetrieb:** Vollständiger Zyklus ohne Eingriff
3. **Sicherheit:** Keine gleichzeitige Ansteuerung komplementärer Ausgänge
4. **Zählfunktion:** Korrekte Teile-Erfassung
5. **Zeittransition:** 2s Band-Timer funktional
6. **Betriebsarten:** Umschaltung nur bei STOP möglich

## 8. Fazit

Das entwickelte SIPN erfüllt alle Anforderungen des Laborversuchs:
- Vollständige Hand- und Automatikbetrieb-Implementierung
- Sicherheitsverriegelungen für komplementäre Ausgänge
- Zeittransition für Bandsteuerung
- Zählerfunktion für Teile-Erfassung
- Robuste Betriebsarten-Umschaltung

Die Lösung demonstriert die praktische Anwendung von Petrinetzen in der Automatisierungstechnik und zeigt deren Vorteile für übersichtliche, wartbare Steuerungssoftware.
