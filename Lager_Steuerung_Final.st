PROGRAM POU
VAR
    (* Betriebsarten *)
    START : BOOL := FALSE;
    AUTO : BOOL := FALSE;
    
    (* Petrinetz Stellen *)
    S_INIT : BOOL := TRUE;  (* Startzustand *)
    S_HAND : BOOL := FALSE;
    S_AUTO : BOOL := FALSE;
    S0 : BOOL := FALSE;
    S1 : BOOL := FALSE;
    S2 : BOOL := FALSE;
    S3 : BOOL := FALSE;
    S4 : BOOL := FALSE;
    S5 : BOOL := FALSE;
    S6 : BOOL := FALSE;
    
    (* Timer und Zaehler *)
    Timer_Band : TON;
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
    AUTO_Alt : BOOL := FALSE;
    AUTO_Gesperrt : BOOL := FALSE;
    Status_Text : STRING := 'System bereit';
    
    (* Eingaenge *)
    Werkstueck_Angesaugt : BOOL := %IX1.0;
    Lager_Leer : BOOL := %IX1.1;
    Schieber_Eingefahren : BOOL := %IX1.2;
    Schieber_Ausgefahren : BOOL := %IX1.3;
    Arm_Am_Band : BOOL := %IX1.4;
    Arm_Am_Lager : BOOL := %IX1.5;
    Vereinzeler_Auf : BOOL := %IX0.0;
    Vereinzeler_Zu : BOOL := %IX0.1;
    LS1_Frei : BOOL := %IX0.2;
    LS2_Frei : BOOL := %IX0.3;
    LS3_Frei : BOOL := %IX0.4;
    
    (* Ausgaenge *)
    Schieber_Ausfahren : BOOL := %QX1.0;
    Werkstueck_Ansaugen : BOOL := %QX1.1;
    Werkstueck_Loslassen : BOOL := %QX1.2;
    Arm_Zum_Lager : BOOL := %QX1.3;
    Arm_Zum_Band : BOOL := %QX1.4;
    Vereinzeler_Auf_Out : BOOL := %QX0.0;
    Band_Drehrichtung : BOOL := %QX0.1;
    Bandgeschwindigkeit : WORD := %QW2;
	Bandgeschwindigkeit_max : WORD := 32500;
	Bandgeschwindigkeit_min : WORD := 0;
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
        S_AUTO := TRUE;
        S0 := TRUE;         (* Automatik startet in S0 *)
        Teile_Zaehler := 0;
        Status_Text := 'Automatikbetrieb aktiv';
    ELSE
        S_INIT := FALSE;
        S_HAND := TRUE;
        Status_Text := 'Handbetrieb aktiv';
    END_IF;
END_IF;

(* System zuruecksetzen bei START = FALSE *)
IF NOT START THEN
    S_INIT := TRUE;
    S_HAND := FALSE;
    S_AUTO := FALSE;
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
    Arm_Zum_Lager := FALSE;
    Arm_Zum_Band := FALSE;
    Vereinzeler_Auf_Out := FALSE;
    Band_Drehrichtung := FALSE;
    Bandgeschwindigkeit := 0;
END_IF;

(* HANDBETRIEB *)
IF S_HAND THEN
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

(* AUTOMATIKBETRIEB *)
IF S_AUTO THEN
    (* T1: Werkstueck ausfahren *)
    IF (S0 AND NOT S1 AND NOT Lager_Leer AND LS1_Frei) THEN
        S0 := FALSE;
        S1 := TRUE;
    END_IF;
    
    (* T2: Transportarm zum Lager *)
    IF (S1 AND NOT S2 AND Schieber_Ausgefahren) THEN
        S1 := FALSE;
        S2 := TRUE;
    END_IF;
    
    (* T3: Werkstueck ansaugen *)
    IF (S2 AND NOT S3 AND Arm_Am_Lager) THEN
        S2 := FALSE;
        S3 := TRUE;
    END_IF;
    
    (* T4: Transport zum Band *)
    IF (S3 AND NOT S4 AND Werkstueck_Angesaugt) THEN
        S3 := FALSE;
        S4 := TRUE;
    END_IF;
    
    (* T5: Werkstueck ablegen *)
    IF (S4 AND NOT S5 AND Arm_Am_Band) THEN
        S4 := FALSE;
        S5 := TRUE;
        Teile_Zaehler := Teile_Zaehler + 1;
    END_IF;
    
    (* T6: Band starten - Zeittransition korrigiert *)
    IF (S5 AND NOT S6 AND NOT LS1_Frei) THEN
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