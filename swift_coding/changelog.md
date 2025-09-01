# Changelog

## 0.1.0 – 29.08.25 – Sprint 0 (Kick‑off)
* Neues Repository mit strukturierter Ordnerhierarchie angelegt.
* Bestandscode aus dem früheren Prototyp übertragen (Scanner, RT60,
  DIN18041, Material, Absorber, Export).
* `AppEntry` und `TabRootView` implementiert, um einen
  Tab‑basierten Navigationsrahmen zu schaffen.
* Erste Dokumente erstellt: README, Messleitfaden, Changelog, Backlog, Risiko-Log.

## 0.2.0 – 29.08.25 – Sprint 1 (RT60 & DIN)
* **RT60‑Pipeline:** Neues Modul `ImpulseResponseAnalyzer` für Schroeder‑Integration, T20/T30-Berechnung.
* **DIN‑Formeln:** Implementierung der Tsoll-Berechnungen für Musik-, Sprach- und Unterrichtsräume gemäß DIN 18041.
* **Klassifikation:** `classifyRT60` mit dynamischer Toleranz (max 0.2s oder 10% von Tsoll).
* **RoomType:** Neuer Raumtyp `musicRoom` ergänzt.
* **Tests & QA:** Anpassungen an Klassifikations-Tests.

## 0.3.0 – 29.08.25 – Sprint 2 (RoomPlan & Material)
* **RoomPlan‑Integration (Skeleton):** Neues Modul `RoomScanView` mit Coordinator für LiDAR‑Scan via RoomPlan.
* **Materialdaten:** `MaterialCSVImporter` implementiert für CSV‑Import/Export.
* **MaterialManager:** Erweiterung um Import‑ und Exportfunktionen.
* **Docs:** Backlog und Changelog aktualisiert; User Stories US‑1 und US‑2 als „in Arbeit“ markiert.

