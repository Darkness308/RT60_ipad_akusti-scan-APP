# Mess- & Belegketten-Validierung (L4/L5)

> **Zweck:** Dieses Dokument ist die **Definition of Done für den physikalischen Teil**
> der App — die Mess- und Belegkette, die **keine CI leisten kann** und die auf echtem
> Gerät + Referenzinstrument validiert werden muss. Es trennt klar: *indikativ* (was eine
> Consumer-App kann) von *metrologisch valide* (was eine Norm-Messung verlangt).
>
> Begleitend: [HANDOFF.md](../HANDOFF.md) · [FORK_READINESS.md](../FORK_READINESS.md) ·
> [ROADMAP.md](../ROADMAP.md) · [Docs/iso3382_report_checklist.md](iso3382_report_checklist.md) ·
> Schemas: [`report.schema.json`](../Schemas/report.schema.json), [`audit.schema.json`](../Schemas/audit.schema.json)

---

## 0. Ehrliche Vorbemerkung (die reale Grenze)

Ein **lückenloser** Nachweis einer akustischen *Messung* ist grundsätzlich **nur auf echtem
Gerät gegen eine kalibrierte Referenz** zu führen — kein Unit-Test und kein CI-Lauf kann das
ersetzen. Die bisherigen Tests (`ImpulseCaptureProcessingTests`, `AcousticsTests`) belegen die
**Rechen-Mathematik** anhand *synthetischer* Signale (Schroeder-Rückintegration invertiert einen
bekannten Abkling­vorgang). Sie belegen **nicht**, dass die App einen **realen Raum** korrekt misst.

Konsequenz für Freigaben: Der rechnerische Teil der Kette ist belegt; der **physikalische/metro­
logische** Teil (L4/L5) ist bis zur Geräte-/Referenzvalidierung **„rot" und muss rot bleiben** —
im Report ehrlich als *Prognose/Indikation* vs. *validierte Messung* zu kennzeichnen.

---

## 1. Die Messkette (End-to-End)

| # | Glied | Komponente (Code) | Was validiert werden muss | Akzeptanzkriterium | Prüfbar wo |
|---|---|---|---|---|---|
| G1 | Anregung | Impuls (Klatsch/Ballon) **oder** Interrupted Noise | Reproduzierbare, breitbandige Anregung über alle Oktavbänder 125–4000 Hz | Anregung deckt jedes Band mit ausreichend Pegel (SNR-Gate, s. G4) | Gerät |
| G2 | Aufnahme | `AudioManager` (AVAudioEngine / **USB-Audio**) | Keine Übersteuerung (Clipping), bekannte Abtastrate, Mono-Kanal, Mikrofon-ID | 0 Clipping-Samples; Abtastrate ≥ 44,1 kHz dokumentiert | Gerät |
| G3 | Impulsantwort | `ImpulseCaptureProcessing.extractImpulseResponse` | Onset-Erkennung + Pre-Roll korrekt; vollständiger Abklingschwanz erfasst | IR beginnt vor dem Onset, endet im Rauschboden | ✅ CI (synthetisch) + Gerät |
| G4 | SNR-Gate | `estimateSNRdB` / `measureRT60(minimumSNRdB:)` | Dynamikumfang reicht für T20 (≥ 35 dB) bzw. T30 (≥ 45 dB) | Unter Gate → `insufficientSNR`, **kein** stiller Falschwert | ✅ CI (Logik) + Gerät (reale Pegel) |
| G5 | Oktavband-RT60 | `ImpulseResponseAnalyzer.rt60PerOctaveBand` | Schroeder-Integration je Band; T20/T30; Krümmung C | Werte je Band plausibel (0 < T < 10 s); C dokumentiert | ✅ CI (synthetisch) + Gerät |
| G6 | Geometrie/Volumen | RoomPlan/LiDAR → V | Raumvolumen V (geht in DIN-`T_soll` **und** Sabine-Prognose ein) | V innerhalb ± 5 % ggü. Bandmaß im Referenzraum | Gerät |
| G7 | DIN-Bewertung | `RT60Evaluator.evaluateDINCompliance` | Asymmetrisches Bild-2-Band, Gruppe A1–A5 | Bewertung = Referenz­rechnung von Hand | ✅ CI |
| G8 | Report/Beleg | `ConsolidatedPDFExporter` + Audit-Block | Alle Rohdaten/Parameter rückverfolgbar im PDF/JSON | Belegkette vollständig (s. §5) | ✅ CI (Rendering) + Gerät (Inhalt) |

**Lesart:** G3, G5, G7, G8 sind rechnerisch in CI abgedeckt. **G1, G2, G4(real), G6** sind der
Geräte-Engpass (L4). Die *metrologische* Gültigkeit über alle Glieder ist L5.

---

## 2. Verifikationsstufen (Reifetreppe der Messung)

1. **S1 — Synthetisch (✅ erreicht, CI):** bekannte Signale rein → bekanntes RT60 raus.
2. **S2 — Simulator-Build (✅ erreicht, CI):** App + Messpfad kompilieren und laufen im iPad-Simulator (`xcodebuild test`). *Kein* echtes Audio/LiDAR.
3. **S3 — Gerät, indikativ (🔴 offen, L4):** echte Aufnahme mit **iPad-internem** Mikrofon. Liefert eine **Indikation**, keine Norm-Messung (Mikro unkalibriert, Frequenzgang/Dynamik begrenzt).
4. **S4 — Gerät, engineering-grade (🔴 offen, L5):** externes **kalibriertes** Messmikrofon über USB-Audio-Interface; Vergleich gegen Referenzinstrument.
5. **S5 — Feld/Ringversuch (🔴 offen, L5):** Mehrere Räume, mehrere Positionen, Vergleich gegen Klasse-1-Messkette; dokumentiertes Unsicherheitsbudget.

> **Produktaussage koppeln:** Erst ab **S4** darf der Report das Wort *„Messung nach ISO 3382-1 /
> DIN 18041"* ohne Einschränkung führen. Bis dahin: *„indikative Messung (iPad-Mikrofon,
> unkalibriert)"* bzw. *„Prognose nach Sabine"*.

---

## 3. Metrologische Validierung (ISO 3382-1)

- **Methode:** Integrierte Impulsantwort (bevorzugt) **oder** Interrupted-Noise. Rückwärtsintegration
  nach Schroeder; Auswertung **T20** (−5…−25 dB) und **T30** (−5…−35 dB), extrapoliert auf 60 dB.
- **Dynamikbereich (SNR-Gate G4):** T20 benötigt ≥ 35 dB, T30 ≥ 45 dB über dem Rauschboden.
- **Trunkierung/Rauschkorrektur:** Abbruchpunkt + Rauschkompensation (Lundeby-Verfahren) implementieren/validieren; Krümmung `C = (T30/T20 − 1)·100 %` je Band berichten.
- **Positionen:** ISO 3382-1 unterscheidet **Survey / Engineering / Precision** (Annex A) über die
  Anzahl Quell-/Empfängerpositionen. Zielklasse festlegen und Mindestzahl Positionen einhalten;
  räumlich mitteln.
- **Frequenzbereich:** Oktav 125–4000 Hz (Produktziel; DIN-Bewertung nutzt `roomType.evaluationFrequencies`).
- **Referenz:** kalibriertes Klasse-1-Messsystem (Messmikrofon + Analysator) als „wahrer Wert";
  App-Ergebnis gilt als valide, wenn es innerhalb der normativen Wiederhol-/Vergleichs­präzision liegt.

> ⚠️ Exakte Klausel-/Tabellennummern **gegen die gekaufte ISO 3382-1** prüfen — hier bewusst nur
> die etablierten Eckwerte, nicht verbatim aus der Norm zitiert (gleiche Ehrlichkeitsregel wie bei
> der DIN-Bild-2-Figur, HANDOFF §10.5).

---

## 4. Unsicherheitsbudget (GUM) — Beitragstabelle (auszufüllen bei S4/S5)

| Beitrag | Quelle | Typische Größenordnung | Minderung |
|---|---|---|---|
| Räumliche Streuung | zu wenige/ungünstige Positionen | **dominant** bei RT60 | mehr Positionen, mitteln |
| SNR / Trunkierung | Rauschboden, Abbruchpunkt | mittel–groß, v. a. tiefe Bänder | SNR-Gate, Lundeby |
| Mikrofon-/Analysator-Kalibrierung | Frequenzgang, Pegelfehler | klein–mittel (groß bei iPad-Mikro!) | kalibriertes Messmikro (S4) |
| Quellen-Reproduzierbarkeit | Klatsch/Ballon variiert | mittel | mehrere Anregungen, mitteln |
| Bandbegrenzung/Filter-Ringing | kurze IR bei tiefen Frequenzen | groß bei 125 Hz | ausreichende IR-Länge |
| Temperatur/Feuchte | Luftabsorption (hohe Bänder) | klein–mittel | erfassen & dokumentieren |
| **Volumen V (LiDAR)** | RoomPlan-Schätzung (Decke=Boden, H=2,5 m Default) | geht in `T_soll` & Sabine ein | gegen Bandmaß prüfen (G6) |

→ Erweiterte Unsicherheit `U = k·u_c` (k = 2) je Oktavband berichten.

---

## 5. Belegkette / Chain of Custody (pro Messung aufzuzeichnen)

Damit ein Ergebnis **rückverfolgbar und reproduzierbar** ist, muss der Audit-Block (vgl.
`Schemas/audit.schema.json`) je Messung festhalten:

- Zeitstempel, Geräte-/App-Version (SemVer, s. [CHANGELOG.md](../CHANGELOG.md))
- Mikrofon-ID + **Kalibrierdatum** (bei externem Messmikro)
- Methode (Impuls/Noise), Abtastrate, Anzahl Mittelungen
- Pro Band: T20, T30, Krümmung C, SNR
- Positionen (Quelle/Empfänger), Raum-ID, Volumen V + dessen Quelle (LiDAR/Bandmaß)
- Temperatur/Feuchte
- Rohdaten-/IR-Referenz + **Hash** (Integrität); Report validiert gegen `report.schema.json`

> Ohne diese Felder ist das Ergebnis eine Zahl ohne Beleg. **Vor Freigabe** eines Berichts muss der
> Audit-Block vollständig sein (das ist der „lückenlose Nachweis", soweit er real erreichbar ist).

---

## 6. DoD — abhakbar auf echtem Gerät

**L4 — Geräte-Laufzeit (iPad):**
- [ ] App installiert + startet auf echtem iPad (nicht nur Simulator)
- [ ] Mikrofon-Permission + Aufnahme ohne Clipping; SNR-Gate greift bei lautem Umfeld
- [ ] LiDAR/RoomPlan-Volumen innerhalb ± 5 % ggü. Bandmaß (Referenzraum, G6)
- [ ] End-to-End: Aufnahme → RT60 → DIN-Bewertung → PDF **am Gerät**, kein Crash
- [ ] Ergebnis + Audit-Block persistiert und im PDF enthalten (§5)

**L5 — Metrologie:**
- [ ] Externes **kalibriertes** Messmikro über USB-Audio validiert (S4)
- [ ] Gemessenes RT60 je Oktavband innerhalb ISO-3382-1-Präzision vs. Referenzinstrument
- [ ] Validierung über ≥ 3 Räume (S5), Unsicherheitsbudget (§4) dokumentiert
- [ ] Report-Wortlaut an die erreichte Stufe (S3/S4/S5) gekoppelt (§2)

---

## 7. Was hier (Linux/CI) NICHT geht — und wer es tut

| Stufe | Hier (CI) | Wer/Wo |
|---|---|---|
| S1/S2 | ✅ automatisiert | CI (`ci-honest.yml`) |
| S3 | ❌ | Entwickler + iPad |
| S4 | ❌ | Entwickler + iPad + kalibriertes Messmikro/USB-Interface |
| S5 | ❌ | Akustik-Labor / Ringversuch gegen Klasse-1-Kette |

Dieses Dokument ist die Übergabe-Spezifikation für genau diese nicht-automatisierbaren Stufen.
