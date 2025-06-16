# Testplan für Laborversuch 2: Petrinetze Lagerbereich

## Test-Setup
- CoDeSys Entwicklungsumgebung
- Simuliertes oder reales Lager-/Puffersystem
- I/O-Simulation für Tests ohne Hardware

## 1. Inbetriebnahme-Tests

### Test 1.1: Basis-Funktionalität
**Ziel:** Grundfunktionen des Systems prüfen
```
☐ I/O-Adressen korrekt zugeordnet
☐ Programm kompiliert fehlerfrei  
☐ Visualisierung lädt korrekt
☐ START/STOP-Funktion arbeitet
☐ AUTO/HAND-Umschaltung funktioniert
```

### Test 1.2: Sicherheitsverriegelungen
**Ziel:** Komplementäre Ausgänge prüfen
```
☐ Ansaugen/Loslassen: nie gleichzeitig aktiv
☐ Arm Lager/Band: nie gleichzeitig aktiv
☐ Betriebsarten-Wechsel nur bei START=FALSE
☐ START nur bei vorherigem FALSE aktivierbar
```

## 2. Handbetrieb-Tests

### Test 2.1: Einzelkomponenten
**Vorbedingung:** START=TRUE, AUTO=FALSE

| Aktion | Erwartetes Verhalten | Status |
|--------|---------------------|--------|
| Hand_Schieber_Aus = TRUE | QX1.0 = TRUE | ☐ |
| Hand_Ansaugen = TRUE | QX1.1 = TRUE, QX1.2 = FALSE | ☐ |
| Hand_Loslassen = TRUE | QX1.2 = TRUE, QX1.1 = FALSE | ☐ |
| Hand_Arm_Lager = TRUE | QX1.3 = TRUE, QX1.4 = FALSE | ☐ |
| Hand_Arm_Band = TRUE | QX1.4 = TRUE, QX1.3 = FALSE | ☐ |
| Hand_Band_Start = TRUE | QW2 = Hand_Bandgeschw | ☐ |

### Test 2.2: Verriegelungen im Handbetrieb
```
☐ Ansaugen + Loslassen gleichzeitig → nur eines aktiv
☐ Arm_Lager + Arm_Band gleichzeitig → nur eines aktiv
☐ Bandgeschwindigkeit nur bei Hand_Band_Start
```

## 3. Automatikbetrieb-Tests

### Test 3.1: Normaler Zyklus
**Vorbedingung:** START=TRUE, AUTO=TRUE, Lager nicht leer, LS1 frei

| Schritt | Eingangssignal | Erwartete Stelle | Erwarteter Ausgang | Status |
|---------|----------------|------------------|-------------------|--------|
| Start | - | S0=TRUE | Alle Ausgänge FALSE | ☐ |
| T1 | IX1.1=FALSE, IX0.2=TRUE | S1=TRUE | QX1.0=TRUE | ☐ |
| T2 | IX1.3=TRUE | S2=TRUE | QX1.0=TRUE, QX1.3=TRUE | ☐ |
| T3 | IX1.5=TRUE | S3=TRUE | QX1.0=TRUE, QX1.1=TRUE | ☐ |
| T4 | IX1.0=TRUE | S4=TRUE | QX1.1=TRUE, QX1.4=TRUE | ☐ |
| T5 | IX1.4=TRUE | S5=TRUE | QX1.2=TRUE, Zähler+1 | ☐ |
| T6 | IX0.2=FALSE, Timer 2s | S6=TRUE | QW2=32500 | ☐ |
| T7 | Timer abgelaufen | S0=TRUE | QW2=0 | ☐ |

### Test 3.2: Grenzbedingungen
```
☐ Lager leer (IX1.1=TRUE) → S0 bleibt aktiv, T1 schaltet nicht
☐ LS1 belegt (IX0.2=FALSE) → S0 bleibt aktiv, T1 schaltet nicht
☐ Werkstück nicht angesaugt → S3 bleibt aktiv, T4 schaltet nicht
☐ START=FALSE während Zyklus → System geht zu INIT
```

### Test 3.3: Zählfunktion
```
☐ Zähler bei START initialisiert (=0)
☐ Zähler erhöht sich bei T5 (Werkstück ablegen)
☐ Mehrere Zyklen: Zähler korrekt inkrementiert
```

### Test 3.4: Zeittransition
```
☐ Timer startet bei S5 + LS1_belegt
☐ Timer läuft 2 Sekunden
☐ T6 schaltet erst nach Timer-Ablauf
☐ Band läuft mit Maximalgeschwindigkeit (32500)
```

## 4. Störungsbehandlung-Tests

### Test 4.1: Timeout-Überwachung
**Vorbedingung:** Automatikbetrieb aktiv

| Szenario | Simulation | Erwartetes Verhalten | Status |
|----------|------------|---------------------|--------|
| Schieber klemmt | S1 aktiv, IX1.3 bleibt FALSE | Nach 30s → STÖRUNG | ☐ |
| Arm bewegt nicht | S2 aktiv, IX1.5 bleibt FALSE | Nach 30s → STÖRUNG | ☐ |
| Ansaugen fehlerhaft | S3 aktiv, IX1.0 bleibt FALSE | Nach 30s → STÖRUNG | ☐ |

### Test 4.2: Störungs-Recovery
```
☐ Störung erkannt → alle Ausgänge sicher
☐ Status_Text zeigt Störungsinfo
☐ START=FALSE quittiert Störung
☐ Neustart nach Störungsquittierung möglich
```

## 5. Betriebsarten-Wechsel Tests

### Test 5.1: Erlaubte Wechsel
```
☐ INIT → HAND bei START=TRUE, AUTO=FALSE
☐ INIT → AUTO bei START=TRUE, AUTO=TRUE  
☐ HAND → INIT bei START=FALSE
☐ AUTO → INIT bei START=FALSE
```

### Test 5.2: Verhinderte Wechsel
```
☐ AUTO/HAND-Wechsel bei START=TRUE → blockiert
☐ START-Flanke erkannt → nur einmalige Aktivierung
☐ START dauerhaft TRUE → keine Mehrfach-Aktivierung
```

## 6. Visualisierung-Tests

### Test 6.1: Statusanzeigen
```
☐ Aktueller_Schritt zeigt korrekte Stelle
☐ Status_Text beschreibt aktuelle Aktion
☐ Teile_Zaehler zeigt korrekte Anzahl
☐ Störungsanzeige bei Fehlern aktiv
```

### Test 6.2: Bedienelemente
```
☐ START/STOP-Button funktional
☐ AUTO/HAND-Umschalter funktional  
☐ Handbetrieb-Taster reagieren korrekt
☐ Bandgeschwindigkeit-Eingabe funktional
```

## 7. Performance-Tests

### Test 7.1: Zykluszeiten
```
☐ Normaler Zyklus: 15-30s (je nach Hardware)
☐ Minimaler Zyklus: alle Signale sofort TRUE
☐ Maximaler Zyklus: mit realistischen Verzögerungen
☐ Kontinuierlicher Betrieb: 100+ Zyklen ohne Fehler
```

### Test 7.2: Speicherverbrauch
```
☐ Programm-Speicher: < 50KB
☐ Daten-Speicher: < 10KB
☐ CPU-Last: < 10% bei kontinuierlichem Betrieb
```

## 8. Abnahme-Checkliste

### Funktionale Anforderungen
```
☐ Handbetrieb: alle Komponenten einzeln steuerbar
☐ Automatikbetrieb: vollständiger Zyklus ohne Eingriff
☐ Sicherheit: komplementäre Ausgänge verriegelt
☐ Zählung: korrekte Teile-Erfassung
☐ Zeittransition: 2s Band-Timer funktional
☐ Betriebsarten: Umschaltung nur bei STOP
```

### Nicht-funktionale Anforderungen  
```
☐ Code-Qualität: strukturiert, kommentiert
☐ Visualisierung: übersichtlich, vollständig
☐ Dokumentation: vollständig, verständlich
☐ Test-Abdeckung: alle Funktionen getestet
☐ Fehlerbehandlung: robust, rücksetzbar
```

## 9. Test-Protokoll

**Test durchgeführt von:** _________________  
**Datum:** _________________  
**Hardware/Simulation:** _________________  

**Gesamtbewertung:**
- [ ] Alle Tests bestanden
- [ ] Tests bestanden mit Anmerkungen  
- [ ] Tests nicht bestanden

**Anmerkungen:**
```
_________________________________________________
_________________________________________________
_________________________________________________
```

**Freigabe für Produktionseinsatz:**
- [ ] Freigegeben
- [ ] Freigegeben mit Auflagen
- [ ] Nicht freigegeben

**Unterschrift Prüfer:** _________________
