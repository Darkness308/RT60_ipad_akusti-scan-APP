# AcoustiScan — Docs

Ergänzende Dokumentation. **Maßgeblich** für den Projektstand ist
[`../HANDOFF.md`](../HANDOFF.md); für die Arbeitsregeln von Claude-Code-Instanzen
[`../CLAUDE.md`](../CLAUDE.md).

## Inhalt

- [design-system.md](./design-system.md) — UI/UX- & Accessibility-Richtlinien
  (Farbsystem, Typografie, 8-pt-Spacing, Touch-Targets, VoiceOver, Komponenten).
- [dsp_filtering.md](./dsp_filtering.md) — DSP-Filter-Spezifikation für die Audio-/
  Impulsverarbeitung.
- [iso3382_report_checklist.md](./iso3382_report_checklist.md) — Checkliste für
  ISO-3382-1-konforme Reports (Messbedingungen, EDT/T20/T30, Unsicherheiten, Audit).

## Normen

- **DIN 18041:2016-03** — raumakustische Anforderungen/Planung; Kern der Bewertung
  (Nutzungsgruppen A1–A5, `T_soll = a·lg(V)+b`, asymmetrisches Bild-2-Toleranzband).
- **ISO 3382-1** — Messung raumakustischer Parameter.

---

> **Hinweis (Bereinigung vor dem Fork):** Eine frühere `agents.md` samt
> „Architektur-Analyse"-Dokumenten beschrieb ein Agenten-/„AI-Manipulation"-System,
> das **nicht im Code existierte** (kein einziges der genannten Symbole, kein
> LLM-Aufruf). Diese Dateien wurden entfernt. Agenten/Automation kehren nur mit
> **echter Durchsetzung** (Git-Hooks / GitHub Actions) **und ausführbaren Tests**
> zurück — siehe `CLAUDE.md`.
