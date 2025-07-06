PROGRAM POU
VAR
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
    Hand_Schieber_Ausfahren: BOOL := FALSE; (* Manueller Befehl: Schieber ausfahren *)
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
    Werkstueck_Angesaugt AT %IX1.0 : BOOL; (* Sensor: Werkstück ist vom Transportarm angesaugt *)
    Lager_Leer AT %IX1.1 : BOOL;           (* Sensor: Das Lager enthält keine Werkstücke mehr *)
    Ausschieber_Eingefahren AT %IX1.2: BOOL; (* Sensor: Der Ausschieber ist in der hinteren Endlage (eingefahren) *)
    Ausschieber_Ausgefahren AT %IX1.3: BOOL; (* Sensor: Der Ausschieber ist in der vorderen Endlage (ausgefahren) *)
    Transportarm_am_Band AT %IX1.4: BOOL;          (* Sensor: Der Transportarm befindet sich an der Position "Band" *)
    Transportarm_am_Lager : BOOL := %IX1.5;         (* Sensor: Der Transportarm befindet sich an der Position "Lager" *)
    Vereinzeler_ist_auf AT %IX0.0:BOOL;      (* Sensor: Der Vereinzeler ist geöffnet *)
    Vereinzeler_ist_zu AT %IX0.1 : BOOL;       (* Sensor: Der Vereinzeler ist geschlossen *)
    LS1_Start AT %IX0.2:BOOL;             (* Lichtschranke 1 (Start der Pufferstrecke): TRUE, wenn frei *)
    LS2_Vereinzeler AT %IX0.3:BOOL;             (* Lichtschranke 2 (vor Vereinzeler): TRUE, wenn frei *)
    LS3_Ende AT %IX0.4:BOOL;             (* Lichtschranke 3 (Ende der Pufferstrecke): TRUE, wenn frei *)
    
    (* Ausgaenge - Abbildung der Variablen auf Hardware-Ausgänge *)
    Schieber_Ausfahren AT %QX1.0 : BOOL;   (* Aktor: Befehl zum Ausfahren des Schiebers *)
    Werkstueck_Ansaugen AT %QX1.1:BOOL;  (* Aktor: Befehl zum Ansaugen des Werkstücks *)
    Werkstueck_Loslassen AT %QX1.2:BOOL; (* Aktor: Befehl zum Loslassen des Werkstücks *)
    Transportarm_zum_Lager AT %QX1.3: BOOL;        (* Aktor: Befehl zum Bewegen des Transportarms Richtung Lager *)
    Transportarm_zum_Band AT %QX1.4: BOOL;         (* Aktor: Befehl zum Bewegen des Transportarms Richtung Band *)
    Band_Drehrichtung AT %QX0.1:BOOL;    (* Aktor: Drehrichtung des Förderbands (Standard = 0) *)
    Bandgeschwindigkeit AT %QW2:WORD;    (* Aktor: Geschwindigkeit des Förderbands *)
    Bandgeschwindigkeit_max : WORD := 32500; (* Konstante: Maximalwert für Bandgeschwindigkeit *)
    Bandgeschwindigkeit_min : WORD := 0;     (* Konstante: Minimalwert für Bandgeschwindigkeit (Band Stopp) *)
END_VAR



(* START Flankenauswertung - ID 04 *)
START_Flanke := START AND NOT START_Alt;
START_Alt := START;

(* AUTO-Sperrung bei START=TRUE - ID 03 *)
IF START THEN
    AUTO_Gesperrt := TRUE;
    AUTO := AUTO_Alt;  (* AUTO einfrieren *)
ELSE
    AUTO_Gesperrt := FALSE;
    AUTO_Alt := AUTO;  (* AUTO-Wert merken *)
END_IF;

(* Initialisierung bei START-Flanke - ID 01,02 *)
IF START_Flanke THEN
    IF AUTO THEN
        S_INIT := FALSE;
        AUTOMATIKBETRIEB := TRUE;
        S0 := TRUE;         (* Automatik startet in S0 *)
        Teile_Zaehler := 0;
        Status_Text := 'Automatikbetrieb aktiv';
    ELSE
        S_INIT := FALSE;
        HANDBETRIEBSMODUS := TRUE;
        Status_Text := 'Handbetrieb aktiv';
    END_IF;
END_IF;

(* System zuruecksetzen bei START = FALSE *)
IF NOT START THEN
    S_INIT := TRUE;
    HANDBETRIEBSMODUS := FALSE;
    AUTOMATIKBETRIEB := FALSE;
    S0 := FALSE; S1 := FALSE; S2 := FALSE; S3 := FALSE;
    S4 := FALSE; S5 := FALSE; S6 := FALSE;
    Timer_Band(IN := FALSE, PT := T#2s);
    Status_Text := 'System bereit';
END_IF;

(* Ausgaenge zuruecksetzen bei INIT *)
IF S_INIT THEN
    Schieber_Ausfahren := FALSE;
    Werkstueck_Ansaugen := FALSE;
    Werkstueck_Loslassen := FALSE;
    Transportarm_zum_Lager := FALSE;
    Transportarm_zum_Band := TRUE;
    Vereinzeler_Auf := FALSE;
    Band_Drehrichtung := FALSE;
    Bandgeschwindigkeit := 0;
END_IF;

(* HANDBETRIEB *)
IF HANDBETRIEBSMODUS THEN
    Schieber_Ausfahren := Hand_Schieber_Ausfahren;
    Werkstueck_Ansaugen := Hand_WK_Ansaugen AND NOT Hand_WK_Loslassen;
    Werkstueck_Loslassen := Hand_WK_Loslassen AND NOT Hand_WK_Ansaugen;
    Transportarm_zum_Lager := Hand_Arm_zum_Lager AND NOT Hand_Arm_zum_Band;
    Transportarm_zum_Band := Hand_Arm_zum_Band AND NOT Hand_Arm_zum_Lager;
    Vereinzeler_Auf := Hand_Vereinzeler;
    
    IF Hand_Band_Einschalten THEN
        Bandgeschwindigkeit := Hand_Bandgeschwindigkeit;
    ELSE
        Bandgeschwindigkeit := 0;
    END_IF;
END_IF;

(* AUTOMATIKBETRIEB *)
IF AUTOMATIKBETRIEB THEN
    (* T1: Werkstueck ausfahren *)
    IF (S0 AND NOT S1 AND NOT Lager_Leer AND LS1_Start) THEN
        S0 := FALSE;
        S1 := TRUE;
    END_IF;
    
    (* T2: Transportarm zum Lager *)
    IF (S1 AND NOT S2 AND Ausschieber_Ausgefahren) THEN
        S1 := FALSE;
        S2 := TRUE;
    END_IF;
    
    (* T3: Werkstueck ansaugen *)
    IF (S2 AND NOT S3 AND Transportarm_zum_Lager AND NOT Ausschieber_Ausgefahren) THEN
        S2 := FALSE;
        S3 := TRUE;
    END_IF;
    
    (* T4: Transport zum Band *)
    IF (S3 AND NOT S4 AND Werkstueck_Angesaugt) THEN
        S3 := FALSE;
        S4 := TRUE;
    END_IF;
    
    (* T5: Werkstueck ablegen *)
    IF (S4 AND NOT S5 AND Transportarm_am_Band) THEN
        S4 := FALSE;
        S5 := TRUE;
        Teile_Zaehler := Teile_Zaehler + 1;
    END_IF;
    
    (* T6: Band starten - Zeittransition korrigiert *)
    IF (S5 AND LS1_Start AND NOT S6 ) THEN
        Timer_Band(IN := TRUE, PT := T#2s);
    ELSE
        Timer_Band(IN := FALSE, PT := T#2s);
    END_IF;
    
    IF Timer_Band.Q THEN
        S5 := FALSE;
        S6 := TRUE;
    END_IF;
    
    (* T7: Zyklus beenden *)
    IF (S6 AND NOT S0) THEN
        S6 := FALSE;
        S0 := TRUE;
    END_IF;
    
    (* Ausgangszuweisungen *)
    Schieber_Ausfahren := S1;
    Werkstueck_Ansaugen := S3 OR S4;
    Werkstueck_Loslassen := S4 OR S5;
    Transportarm_zum_Lager := S2 OR S3;
    Transportarm_zum_Band := S4 OR S5;
    
   IF S5 OR S6 THEN
        Bandgeschwindigkeit := 32500;
    ELSE
        Bandgeschwindigkeit := 0;
    END_IF;
END_IF;
