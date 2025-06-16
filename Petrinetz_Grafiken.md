# Petrinetz-Grafik für Lagerbereich

## Hauptpetrinetz - Betriebsarten

```
                     START ∧ ¬AUTO
    ●S_INIT ──────────────────────────────→ S_HAND
      │ ●                                      │ ○
      │                                        │
      │ START ∧ AUTO                          │ ¬START  
      ↓                                        │
    S_AUTO ←───────────────────────────────────┘
      │ ○        ¬START
      │
      └─→ [Automatikzyklus]
```

## Automatikzyklus-Petrinetz (detailliert)

```
    ●S0 ──T1──→ S1 ──T2──→ S2 ──T3──→ S3 ──T4──→ S4 ──T5──→ S5 ──T6──→ S6 ──T7──┐
    ↑ Bereit   Schieber  Arm zum   Werkstück  Transport  Werkstück  Band läuft    │
    │           ausfahren Lager     ansaugen   zum Band   ablegen    (2s Timer)   │
    │                                                                              │
    └──────────────────────────────────────────────────────────────────────────────┘
```

## Detaillierte Transitionen mit Bedingungen

```
●S0 ────┬─T1─────┐    Bedingungen:
        │        ↓    T1: ¬Lager_leer ∧ LS1_frei
        │      S1○    T2: Schieber_ausgefahren  
        │        │    T3: Arm_am_Lager
        │     T2─┘    T4: Werkstück_angesaugt
        │        ↓    T5: Arm_am_Band
        │      S2○    T6: LS1_belegt ∧ Timer_2s
        │        │    T7: Timer_abgelaufen
        │     T3─┘
        │        ↓
        │      S3○─── QX1.1 (Ansaugen)
        │        │
        │     T4─┘
        │        ↓
        │      S4○─── QX1.4 (Arm zum Band)
        │        │
        │     T5─┘
        │        ↓
        │      S5○─── QX1.2 (Loslassen) + Zähler++
        │        │
        │     T6─┘
        │        ↓
        │      S6○─── QW2 = 32500 (Max.Geschwindigkeit)
        │        │
        │     T7─┘
        │        │
        └────────┘

Ausgangszuweisungen:
QX1.0 (Schieber) = S1 ∨ S2 ∨ S3 ∨ S4
QX1.1 (Ansaugen) = S3 ∨ S4  
QX1.2 (Loslassen) = S5
QX1.3 (Arm→Lager) = S2
QX1.4 (Arm→Band) = S4 ∨ S5
QW2 (Bandgeschw.) = 32500 bei S6, sonst 0
```

## Synchronisation mit Pufferstrecke

```
Lagerbereich                     Pufferstrecke
                                 
     S4○                         LS1○ LS2○ LS3○
      │                           │    │    │
   Werkstück                      │    │    │
   ablegen ──────────────────────→●    │    │
      │                               │    │
      ↓                               │    │
     S5○ ──── Timer_2s ─────────────→ Band Start
      │                               │
      ↓                               ↓
     S6○ ──── QW2=32500 ────────────→ Band läuft
```

## Kommunikationsplätze und Testkanten

```
Normale Kante:     S1 ──→ T2 ──→ S2
Testkante:         S1 ──┬─→ T2 ──→ S2
                        │
                   LS1_frei (wird nicht verbraucht)

Inhibitorkante:    S1 ──┬─○ T2 ──→ S2  
                        │
                 Störung_aktiv (blockiert bei =1)
```

## Verriegelungen (Schlüsselplätze)

```
Ansaugen/Loslassen-Verriegelung:

    Hand_Ansaugen ──┬──→ QX1.1
                    │
             Verriegelung○ 
                    │
    Hand_Loslassen ──┴──→ QX1.2

Transportarm-Verriegelung:

    Hand_Arm_Lager ──┬──→ QX1.3
                     │
              Verriegelung○
                     │  
    Hand_Arm_Band ────┴──→ QX1.4
```

## Zustandsdiagramm

```
        START=0
    ┌─────────────────┐
    │                 ↓
INIT ←────────────── [System Reset]
 │                     ↑
 │ START=1             │
 ↓                     │ START=0
┌─────────────────────────────────┐
│     Betriebsart wählen          │
└─────────┬───────────┬───────────┘
          │           │
   AUTO=0 │           │ AUTO=1
          ↓           ↓
    HANDBETRIEB   AUTOMATIKBETRIEB
          │           │
          │           └──→ [Zyklus S0→S6]
          │
          └──→ [Manuelle Steuerung]
```

## Zeitverhalten

```
Normaler Zyklus (ca. 15-30s):

S0 ────2s────→ S1 ────3s────→ S2 ────2s────→ S3 
               Schieber      Arm zum        Ansaugen
               ausfahren     Lager          

S3 ────3s────→ S4 ────2s────→ S5 ────2s────→ S6 ────2s────→ S0
               Transport      Ablegen       Band           Bereit
               zum Band                     läuft          

Timeout pro Schritt: 30s (Störungsüberwachung)
Band-Timer: 2s (Zeittransition)
```

## Fehlerzustände

```
Normale Ausführung:  S0 → S1 → S2 → S3 → S4 → S5 → S6 → S0

Fehlerfälle:
- Lager leer:        S0 ⟲ (wartet)
- LS1 belegt:        S0 ⟲ (wartet)  
- Timeout:           Sx → STÖRUNG → S0
- START=0:           Sx → INIT
```

## I/O-Zuordnung kompakt

```
Eingänge:                    Ausgänge:
IX1.0 = Werkstück angesaugt  QX1.0 = Schieber ausfahren
IX1.1 = Lager leer           QX1.1 = Werkstück ansaugen  
IX1.2 = Schieber eingefahren QX1.2 = Werkstück loslassen
IX1.3 = Schieber ausgefahren QX1.3 = Arm zum Lager
IX1.4 = Arm am Band          QX1.4 = Arm zum Band
IX1.5 = Arm am Lager         QW2   = Bandgeschwindigkeit

IX0.2 = LS1 frei             QX0.0 = Vereinzeler auf
IX0.3 = LS2 frei             QX0.1 = Band Drehrichtung  
IX0.4 = LS3 frei
```
