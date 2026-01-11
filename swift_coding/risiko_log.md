# Risiko‑Log

Dieses Dokument sammelt technische und betriebliche Risiken, die während
der Entwicklung des MVPs identifiziert werden. Jedes Risiko erhält eine
Einschätzung (hoch/mittel/niedrig) und ggf. eine Gegenmaßnahme.

| Risiko | Bewertung | Gegenmaßnahme |
|--------|-----------|---------------|
| **Mikrofon‑Kalibrierung** - unkalibrierte Mikrofone führen zu falschen RT60‑Werten. | hoch | Anleitung im Messleitfaden; optionale Kalibrierdatei laden |
| **Störgeräusche** - Straßenlärm, HVAC oder Personen verfälschen Messungen. | hoch | Benutzerführung mit Hinweisen; Rauschunterdrückung |
| **Messdauer** - zu lange Messungen unpraktisch im Feld. | mittel | Optimierte Testsignale (MLS, Sweeps) verwenden |
| **Speicher/Performance** - FFT‑Analysen und RoomPlan‑Daten belasten Ressourcen. | mittel | FFT‑Größe begrenzen; Threads nutzen |
| **Compliance (EU AI Act)** - fehlende Transparenz zu Algorithmen könnte kritisch sein. | hoch | Dokumentation aller Berechnungen; Audit‑Trail JSON |
| **Fehlerhafte Materialdaten** - ungenaue Absorptionswerte verfälschen Ergebnisse. | mittel | Referenz‑CSV pflegen; Importvalidierung |
| **UX‑Risiken** - Nutzer versteht Wizard nicht, Barrierefreiheit fehlt. | mittel | Iteratives UX‑Testing; klare Tooltips |
| **Geräteabhängigkeit** - RoomPlan läuft nur auf LiDAR‑fähigen iPads. | mittel | Gerätekompatibilität dokumentieren; Fallback anbieten |

