PROGRAM POU
VAR
(*
**Lagerbereich – Eingänge:**
| Beschreibung                | Adresse   | Datentyp | Logische Zuordnung                               |
|-----------------------------|-----------|----------|--------------------------------------------------|
| Werkstueck_Angesaugt        | %IX1.0    | BOOL     | TRUE, wenn Werkstück vom Greifer angesaugt ist   |
| Lager_Leer                  | %IX1.1    | BOOL     | TRUE, wenn das Lager keine Werkstücke enthält    |
| Ausschieber_Eingefahren     | %IX1.2    | BOOL     | TRUE, wenn Ausschieber Endposition "eingefahren" erreicht |
| Ausschieber_Ausgefahren     | %IX1.3    | BOOL     | TRUE, wenn Ausschieber Endposition "ausgefahren" erreicht |
| Transportarm_am_Band        | %IX1.4    | BOOL     | TRUE, wenn Transportarm Position "Band" erreicht   |
| Transportarm_am_Lager       | %IX1.5    | BOOL     | TRUE, wenn Transportarm Position "Lager" erreicht  |

**Lagerbereich – Ausgänge:**
| Beschreibung                | Adresse   | Datentyp | Logische Zuordnung                               |
|-----------------------------|-----------|----------|--------------------------------------------------|
| Schieber_Ausfahren          | %QX1.0    | BOOL     | TRUE, um den Schieber auszufahren                |
| Werkstueck_Ansaugen         | %QX1.1    | BOOL     | TRUE, um das Werkstück anzusaugen                |
| Werkstueck_Loslassen        | %QX1.2    | BOOL     | TRUE, um das Werkstück loszulassen               |
| Transportarm_zum_Lager      | %QX1.3    | BOOL     | TRUE, um den Transportarm zum Lager zu bewegen   |
| Transportarm_zum_Band       | %QX1.4    | BOOL     | TRUE, um den Transportarm zum Band zu bewegen    |

**Pufferstrecke – Eingänge:**
| Beschreibung                | Adresse   | Datentyp | Logische Zuordnung                               |
|-----------------------------|-----------|----------|--------------------------------------------------|
| Vereinzeler_ist_auf         | %IX0.0    | BOOL     | TRUE, wenn der Vereinzeler geöffnet ist          |
| Vereinzeler_ist_zu          | %IX0.1    | BOOL     | TRUE, wenn der Vereinzeler geschlossen ist       |
| LS1_Frei                    | %IX0.2    | BOOL     | TRUE, wenn Lichtschranke 1 frei (nicht belegt) |
| LS2_Frei                    | %IX0.3    | BOOL     | TRUE, wenn Lichtschranke 2 frei (nicht belegt) |
| LS3_Frei                    | %IX0.4    | BOOL     | TRUE, wenn Lichtschranke 3 frei (nicht belegt) |

**Pufferstrecke – Ausgänge:**
| Beschreibung                | Adresse   | Datentyp | Logische Zuordnung                               |
|-----------------------------|-----------|----------|--------------------------------------------------|
| Vereinzeler_auf             | %QX0.0    | BOOL     | TRUE, um den Vereinzeler zu öffnen               |
| Band_Drehrichtung           | %QX0.1    | BOOL     | z.B. 0 für Vorwärtslauf, 1 für Rückwärtslauf    |
| Bandgeschwindigkeit         | %QW2      | WORD     | Wert von 0 (Stillstand) bis 32500 (max. Geschw.) |
*)
    (* Betriebsarten *)
    START : BOOL := FALSE; (* Startsignal für das gesamte System *)
    AUTO : BOOL := FALSE; (* Wahlschalter für Automatikbetrieb (TRUE) oder Handbetrieb (FALSE) *)
    
    (* Petrinetz Stellen - Zustände im Automatikbetrieb *)
    S_INIT : BOOL := TRUE;  (* Initialzustand des Systems / Petrinetzes *)
    HANDBETRIEBSMODUS : BOOL := FALSE; (* Flag: Handbetrieb ist aktiv *)
    AUTOMATIKBETRIEB : BOOL := FALSE; (* Flag: Automatikbetrieb ist aktiv *)
    S0 : BOOL := FALSE;     (* Stelle 0: Grundstellung / Warten auf Werkstück oder Freigabe *)
    S1 : BOOL := FALSE;     (* Stelle 1: Werkstück wird aus dem Lager ausgeschoben *)
    S2 : BOOL := FALSE;     (* Stelle 2: Transportarm fährt zum Lager *)
    S3 : BOOL := FALSE;     (* Stelle 3: Werkstück wird am Lager angesaugt *)
    S4 : BOOL := FALSE;     (* Stelle 4: Transportarm fährt mit Werkstück zum Band *)
    S5 : BOOL := FALSE;     (* Stelle 5: Werkstück wird auf dem Band abgelegt *)
    S6 : BOOL := FALSE;     (* Stelle 6: Werkstück wird auf Band bis LS2 transportiert *)
	S7 : BOOL := FALSE;     (* Stelle 7: Werkstück an LS2, Vereinzeler öffnet/schließt *)
    S8 : BOOL := FALSE;     (* Stelle 8: Werkstück wird von LS2 bis LS3 transportiert *)
	
    (* Timer und Zaehler *)
    Timer_Band : TON;       (* Timer für die Laufzeit des Bandes nach Ablegen eines Werkstücks *)
    Teile_Zaehler : INT := 0; (* Zählt die Anzahl der im Automatikbetrieb bearbeiteten Teile *)
    Timer_Band_Zeit : TIME := T#60S; (* Voreingestellte Zeit für den Band-Timer (anpassbar) *)
	
	Timer_Vereinzeler : TON; (* Timer für die Öffnungs-/Schließzeit des Vereinzelers *)
	Timer_Vereinzeler_Zeit : TIME := T#60S; (* Voreingestellte Zeit für den Vereinzeler-Timer (anpassbar, aktuell T#1s im Code) *)
    
    (* Handbetrieb Variablen - Steuersignale für den manuellen Betrieb *)
    Hand_Schieber_Ausfahren : BOOL := FALSE; (* Manueller Befehl: Schieber ausfahren *)
    Hand_WK_Ansaugen : BOOL := FALSE;     (* Manueller Befehl: Werkstück ansaugen *)
    Hand_WK_Loslassen : BOOL := FALSE;    (* Manueller Befehl: Werkstück loslassen *)
    Hand_Arm_zum_Lager : BOOL := FALSE;    (* Manueller Befehl: Transportarm zum Lager fahren *)
    Hand_Arm_zum_Band : BOOL := FALSE;     (* Manueller Befehl: Transportarm zum Band fahren *)
    Hand_Band_Einschalten : BOOL := FALSE;   (* Manueller Befehl: Band einschalten *)
    Hand_Bandgeschwindigkeit : WORD := 0;       (* Manuell einstellbare Bandgeschwindigkeit *)
    Hand_Vereinzeler : BOOL := FALSE;  (* Manueller Befehl: Vereinzeler betätigen *)
    
    (* Hilfsvariablen *)
    START_Alt : BOOL := FALSE;         (* Speichert den vorherigen Zustand des START-Signals zur Flankenerkennung *)
    START_Flanke : BOOL := FALSE;      (* Positive Flanke des START-Signals (TRUE für einen Zyklus) *)
    AUTO_Alt : BOOL := FALSE;          (* Speichert den vorherigen Zustand des AUTO-Wahlschalters *)
    AUTO_Gesperrt : BOOL := FALSE;     (* Sperrt die Umschaltung des AUTO-Modus während des Betriebs (START = TRUE) *)
    Status_Text : STRING := 'System bereit'; (* Textuelle Anzeige des aktuellen Systemstatus für die Visualisierung *)
    
    (* Eingaenge - Abbildung der Hardware-Eingänge auf Variablen *)
    Werkstueck_Angesaugt : BOOL := %IX1.0; (* Sensor: Werkstück ist vom Transportarm angesaugt *)
    Lager_Leer : BOOL := %IX1.1;           (* Sensor: Das Lager enthält keine Werkstücke mehr *)
    Ausschieber_Eingefahren : BOOL := %IX1.2; (* Sensor: Der Ausschieber ist in der hinteren Endlage (eingefahren) *)
    Ausschieber_Ausgefahren : BOOL := %IX1.3; (* Sensor: Der Ausschieber ist in der vorderen Endlage (ausgefahren) *)
    Transportarm_am_Band : BOOL := %IX1.4;          (* Sensor: Der Transportarm befindet sich an der Position "Band" *)
    Transportarm_am_Lager : BOOL := %IX1.5;         (* Sensor: Der Transportarm befindet sich an der Position "Lager" *)
    Vereinzeler_ist_auf : BOOL := %IX0.0;      (* Sensor: Der Vereinzeler ist geöffnet *)
    Vereinzeler_ist_zu : BOOL := %IX0.1;       (* Sensor: Der Vereinzeler ist geschlossen *)
    LS1_Start : BOOL := %IX0.2;             (* Lichtschranke 1 (Start der Pufferstrecke): TRUE, wenn frei *)
    LS2_Vereinzeler : BOOL := %IX0.3;             (* Lichtschranke 2 (vor Vereinzeler): TRUE, wenn frei *)
    LS3_Ende : BOOL := %IX0.4;             (* Lichtschranke 3 (Ende der Pufferstrecke): TRUE, wenn frei *)
    
    (* Ausgaenge - Abbildung der Variablen auf Hardware-Ausgänge *)
    Schieber_Ausfahren : BOOL := %QX1.0;   (* Aktor: Befehl zum Ausfahren des Schiebers *)
    Werkstueck_Ansaugen : BOOL := %QX1.1;  (* Aktor: Befehl zum Ansaugen des Werkstücks *)
    Werkstueck_Loslassen : BOOL := %QX1.2; (* Aktor: Befehl zum Loslassen des Werkstücks *)
    Transportarm_zum_Lager : BOOL := %QX1.3;        (* Aktor: Befehl zum Bewegen des Transportarms Richtung Lager *)
    Transportarm_zum_Band : BOOL := %QX1.4;         (* Aktor: Befehl zum Bewegen des Transportarms Richtung Band *)
    Vereinzeler_auf : BOOL := %QX0.0 :=0;  (* Aktor: Befehl zum Öffnen des Vereinzelers *)
    Band_Drehrichtung : BOOL := %QX0.1 := 0;    (* Aktor: Drehrichtung des Förderbands (Standard = 0) *)
    Bandgeschwindigkeit : WORD := %QW2;    (* Aktor: Geschwindigkeit des Förderbands *)
    Bandgeschwindigkeit_max : WORD := 32500; (* Konstante: Maximalwert für Bandgeschwindigkeit *)
    Bandgeschwindigkeit_min : WORD := 0;     (* Konstante: Minimalwert für Bandgeschwindigkeit (Band Stopp) *)
END_VAR

(* Logik zur Erkennung einer positiven Flanke des START-Signals *)
// Eine positive Flanke liegt vor, wenn START jetzt TRUE ist und im vorherigen Zyklus FALSE war.
START_Flanke := START AND NOT START_Alt;  (* START_Flanke ist TRUE für genau einen SPS-Zyklus *)
START_Alt := START;  (* Aktuellen Zustand von START für den nächsten Zyklus speichern *)

(* AUTO-Sperrung bei START=TRUE - ID 03 *)
// Diese Logik verhindert, dass der Betriebsmodus (Automatik/Hand) geändert wird, während die Anlage läuft (START = TRUE).
IF START THEN // Wenn das System gestartet ist
    AUTO_Gesperrt := TRUE; // Sperre für den AUTO-Wahlschalter aktivieren
    AUTO := AUTO_Alt;  // Den zuletzt gewählten AUTO-Modus beibehalten (einfrieren)
ELSE // Wenn das System nicht gestartet ist (START = FALSE)
	(* System steht: AUTO-Schalter kann frei verwendet werden *)
    AUTO_Gesperrt := FALSE; // Sperre für den AUTO-Wahlschalter deaktivieren
    AUTO_Alt := AUTO;  // Den aktuellen Zustand des AUTO-Wahlschalters für den nächsten Start merken
END_IF;

(* Initialisierung bei START-Flanke - ID 01,02 *)
// Diese Logik wird einmalig ausgeführt, wenn das START-Signal eine positive Flanke hat.
// Sie initialisiert den gewählten Betriebsmodus (Automatik oder Hand).
IF START_Flanke THEN // Wenn eine positive Flanke am START-Eingang erkannt wurde
    IF AUTO THEN // Wenn der Wahlschalter auf Automatikbetrieb steht
        S_INIT := FALSE; // Initialzustand verlassen
        AUTOMATIKBETRIEB := TRUE; // Flag für Automatikbetrieb setzen
        HANDBETRIEBSMODUS := FALSE; // Flag für Handbetrieb zurücksetzen
        S0 := TRUE;         (* Automatikbetrieb startet in Petrinetz-Stelle S0 *)
        Teile_Zaehler := 0; // Teilezähler zurücksetzen
        Status_Text := 'Automatikbetrieb aktiv'; // Statusmeldung aktualisieren
    ELSE // Wenn der Wahlschalter auf Handbetrieb steht
        S_INIT := FALSE; // Initialzustand verlassen
        HANDBETRIEBSMODUS := TRUE; // Flag für Handbetrieb setzen
        AUTOMATIKBETRIEB := FALSE; // Flag für Automatikbetrieb zurücksetzen
        Status_Text := 'Handbetrieb aktiv'; // Statusmeldung aktualisieren
    END_IF;
END_IF;

(* System zuruecksetzen bei START = FALSE *)
// Diese Logik wird ausgeführt, solange das START-Signal FALSE ist.
// Sie setzt das System in den definierten Grundzustand zurück.
IF NOT START THEN // Wenn das System nicht gestartet ist
    S_INIT := TRUE; // System in den Initialzustand versetzen
    HANDBETRIEBSMODUS := FALSE; // Handbetrieb deaktivieren
    AUTOMATIKBETRIEB := FALSE; // Automatikbetrieb deaktivieren
    // Alle Petrinetz-Stellen zurücksetzen
    S0 := FALSE; S1 := FALSE; S2 := FALSE; S3 := FALSE;
    S4 := FALSE; S5 := FALSE; S6 := FALSE; S7 := FALSE; S8 := FALSE; 
    // Timer zurücksetzen und deaktivieren
    Timer_Band(IN := FALSE, PT := Timer_Band_Zeit);
	Timer_Vereinzeler(IN := FALSE, PT := Timer_Vereinzeler_Zeit);
    Status_Text := 'System bereit'; // Statusmeldung aktualisieren
END_IF;

(* Ausgaenge zuruecksetzen bei INIT *)
// Diese Logik wird ausgeführt, wenn sich das System im Initialzustand (S_INIT = TRUE) befindet.
// Alle Aktoren werden in ihren sicheren Grundzustand versetzt.
IF S_INIT THEN
    Schieber_Ausfahren := FALSE; // Schieber einfahren (oder nicht ausfahren)
    Werkstueck_Ansaugen := FALSE; // Ansaugung deaktivieren
    Werkstueck_Loslassen := FALSE; // Loslassen deaktivieren (falls aktiv)
    Transportarm_zum_Lager := FALSE; // Befehl Transportarm zum Lager zurücksetzen
    Transportarm_zum_Band := FALSE; // Befehl Transportarm zum Band zurücksetzen
    Vereinzeler_auf := FALSE; // Vereinzeler schließen
    Band_Drehrichtung := FALSE; // Banddrehrichtung auf Standard (oder Stopp)
    Bandgeschwindigkeit := Bandgeschwindigkeit_min; // Bandgeschwindigkeit auf Minimum (Stopp)
END_IF;

(* HANDBETRIEB *)
// Steuerung der Aktoren direkt über die Handbetriebsvariablen, wenn HANDBETRIEBSMODUS aktiv ist.
IF HANDBETRIEBSMODUS THEN
    Schieber_Ausfahren := Hand_Schieber_Ausfahren; // Schiebersteuerung durch Handeingabe
    // Verriegelung: Ansaugen und Loslassen schließen sich gegenseitig aus
    Werkstueck_Ansaugen := Hand_WK_Ansaugen AND NOT Hand_WK_Loslassen;
    Werkstueck_Loslassen := Hand_WK_Loslassen AND NOT Hand_WK_Ansaugen;
    // Verriegelung: Arm zum Lager und Arm zum Band schließen sich gegenseitig aus
    Transportarm_zum_Lager := Hand_Arm_zum_Lager AND NOT Hand_Arm_zum_Band;
    Transportarm_zum_Band := Hand_Arm_zum_Band AND NOT Hand_Arm_zum_Lager;
    Vereinzeler_auf := Hand_Vereinzeler; // Vereinzelersteuerung durch Handeingabe
    
    // Bandsteuerung im Handbetrieb
    IF Hand_Band_Einschalten THEN
        Bandgeschwindigkeit := Hand_Bandgeschwindigkeit; // Bandgeschwindigkeit gemäß Handeingabe
    ELSE
        Bandgeschwindigkeit := Bandgeschwindigkeit_min; // Band stoppen, wenn nicht explizit eingeschaltet
    END_IF;
END_IF;

(* AUTOMATIKBETRIEB *)
// Ablaufsteuerung des Petrinetzes, wenn AUTOMATIKBETRIEB aktiv ist.
IF AUTOMATIKBETRIEB THEN
    // Petrinetz Transitionen (Schrittschaltwerk)

    (* T1: Werkstueck aus Lager ausfahren *)
    // Bedingung: In S0, LS1 (Start Puffer) frei, LS3 (Ende Puffer) frei, Lager nicht leer, nächster Schritt S1 noch nicht aktiv.
	IF (S0 AND LS1_Start AND LS3_Ende AND NOT S1 AND NOT Lager_Leer) THEN
        S0 := FALSE; // Verlasse S0
        S1 := TRUE;  // Aktiviere S1
    END_IF;
    
    (* T2: Transportarm zum Lager fahren *)
    // Bedingung: In S1, Ausschieber ist ausgefahren, nächster Schritt S2 noch nicht aktiv.
	IF (S1 AND Ausschieber_Ausgefahren AND NOT S2) THEN
        S1 := FALSE; // Verlasse S1
        S2 := TRUE;  // Aktiviere S2
    END_IF;
    
    (* T3: Werkstueck am Lager ansaugen *)
    // Bedingung: In S2, Transportarm ist am Lager, nächster Schritt S3 noch nicht aktiv.
	IF (S2 AND Transportarm_am_Lager AND NOT S3) THEN
        S2 := FALSE; // Verlasse S2
        S3 := TRUE;  // Aktiviere S3
    END_IF;
    
    (* T4: Transportarm mit Werkstueck zum Band fahren *)
    // Bedingung: In S3, Werkstück ist angesaugt, nächster Schritt S4 noch nicht aktiv.
	IF (S3 AND Werkstueck_Angesaugt AND NOT S4) THEN
        S3 := FALSE; // Verlasse S3
        S4 := TRUE;  // Aktiviere S4
    END_IF;
    
    (* T5: Werkstueck auf Band ablegen *)
    // Bedingung: In S4, Transportarm ist am Band, nächster Schritt S5 noch nicht aktiv.
	IF (S4 AND Transportarm_am_Band AND NOT S5) THEN
        S4 := FALSE; // Verlasse S4
        S5 := TRUE;  // Aktiviere S5
        Teile_Zaehler := Teile_Zaehler + 1; // Ein Teil wurde erfolgreich bearbeitet
    END_IF;
    
    (* T6: Band starten und Werkstück bis LS1 transportieren (implizit, da LS1_Frei Bedingung für T1 war) *)
    // Startet einen Timer, wenn in S5, nächster Schritt S6 nicht aktiv und LS1 (Start Puffer) belegt ist (Werkstück liegt darauf).
    IF (S5 AND NOT S6 AND NOT LS1_Start) THEN // LS1_Frei ist FALSE, d.h. LS1 ist belegt
        Timer_Band(IN := TRUE, PT := Timer_Band_Zeit); // Starte Band-Timer
    ELSE
        Timer_Band(IN := FALSE, PT := Timer_Band_Zeit); // Stoppe/resette Band-Timer, falls Bedingung nicht mehr erfüllt
    END_IF;
    
    // Wenn der Band-Timer abgelaufen ist
    IF Timer_Band.Q THEN
        S5 := FALSE; // Verlasse S5
        S6 := TRUE;  // Aktiviere S6 (Werkstück wird nun weiter transportiert)
    END_IF;
    
    (* T7: Werkstück erreicht LS2 - Vorbereitung zum Vereinzeln *)
    // Bedingung: In S6, nächster Schritt S7 nicht aktiv, LS2 (vor Vereinzeler) ist belegt.
    IF (S6 AND NOT S7 AND NOT LS2_Vereinzeler) THEN // LS2_Frei ist FALSE, d.h. LS2 ist belegt
        S6 := FALSE; // Verlasse S6
        S7 := TRUE;  // Aktiviere S7
    END_IF;
    
    (* T8: Vereinzeler aktivieren (öffnen und schließen) - Zeitgesteuert *)
    // Startet einen Timer für den Vereinzeler, wenn in S7 und nächster Schritt S8 nicht aktiv.
    IF (S7 AND NOT S8) THEN
        Timer_Vereinzeler(IN := TRUE, PT := T#1s); // Starte Vereinzeler-Timer (hier fest auf 1 Sekunde)
    ELSE
        Timer_Vereinzeler(IN := FALSE, PT := T#1s); // Stoppe/resette Vereinzeler-Timer
    END_IF;
    
    // Wenn der Vereinzeler-Timer abgelaufen ist
    IF Timer_Vereinzeler.Q THEN
        S7 := FALSE; // Verlasse S7
        S8 := TRUE;  // Aktiviere S8 (Vereinzelung abgeschlossen, Werkstück kann weiter)
    END_IF;
    
    (* T9: Transport von LS2 zu LS3 (Ende Pufferstrecke) *)
    // Bedingung: In S8, nächster Schritt S0 (Grundstellung) nicht aktiv, LS3 (Ende Puffer) ist belegt.
    IF (S8 AND NOT S0 AND NOT LS3_Ende) THEN // LS3_Frei ist FALSE, d.h. LS3 ist belegt
        S8 := FALSE; // Verlasse S8
        S0 := TRUE;  // Aktiviere S0 (Zyklus für ein Teil abgeschlossen, warte auf nächstes)
    END_IF;
    
	(* Ausgangszuweisungen für Automatikbetrieb basierend auf den aktiven Petrinetz-Stellen *)
    
    // Schieber ausfahren in S1 (Beginn Ausschub) und S2 (Warten auf Arm).
    // In S3 fährt Schieber wieder ein (implizit durch `NOT Werkstueck_Angesaugt`, da Ansaugen erst in S3 erfolgt und Schieber dann frei sein muss).
    Schieber_Ausfahren := S1 OR S2 OR (S3 AND NOT Werkstueck_Angesaugt);
	
	// KRITISCH: Ansaugen des Werkstücks
    // Bedingung: In S3 ODER S4 (S4 als Haltebedingung), Transportarm ist am Lager, Ausschieber ist eingefahren (wichtig für Kollisionsfreiheit!).
    Werkstueck_Ansaugen := (S3 OR S4) AND Transportarm_am_Lager AND Ausschieber_Eingefahren AND NOT Ausschieber_Ausgefahren;
    
    // Werkstück loslassen
    // Bedingung: In S5 UND Transportarm ist am Band.
	Werkstueck_Loslassen := S5 AND Transportarm_am_Band;
    
    // Transportarm zum Lager fahren
    // Bedingung: In S2.
    Transportarm_zum_Lager := S2;
    
    // Transportarm zum Band fahren
    // Bedingung: In S4 (Transport) ODER S5 (Ablegen und Halten bis Band läuft).
    Transportarm_zum_Band := S4 OR S5;
	
    // Vereinzeler öffnen
    // Bedingung: In S7 (Vereinzelungsvorgang).
	Vereinzeler_Auf := S7;
    
    // Bandgeschwindigkeit steuern
    // Band läuft mit maximaler Geschwindigkeit in S6 (Transport zu LS2) und S8 (Transport zu LS3).
  	IF S6 OR S8 THEN
        Bandgeschwindigkeit := Bandgeschwindigkeit_max;
    ELSE
        Bandgeschwindigkeit := Bandgeschwindigkeit_min; // Ansonsten Band Stopp
    END_IF;
END_IF;