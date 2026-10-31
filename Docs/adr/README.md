# Architecture Decision Records (ADR)

Kurze, datierte Protokolle der **tatsächlich getroffenen** Architektur-Entscheidungen —
damit externe Entwickler den *Warum*-Kontext haben und nicht versehentlich Bewusstes rückgängig machen.

Format: angelehnt an [MADR](https://adr.github.io/madr/) — *Status · Kontext · Entscheidung · Konsequenzen*.
Jede Entscheidung ist mit dem **PR/Code** verankert, der sie umgesetzt hat (verifizierbar).

| ADR | Titel | Status |
|---|---|---|
| [0001](0001-honest-ci.md) | Ehrliche CI ohne Maskierung; Legacy-Automation gelöscht | Akzeptiert |
| [0002](0002-dual-build-system.md) | Dual-Build: `.xcodeproj` maßgeblich, SPM-Pakete für den Kern | Akzeptiert |
| [0003](0003-duplicated-models.md) | Doppelte Modelle App ↔ Paket (bewusste, dokumentierte Schuld) | Akzeptiert (Schuld) |
| [0004](0004-din18041-asymmetric-tolerance.md) | DIN 18041 normtreu: asymmetrisches Bild-2-Band, keine erfundenen Raumtypen | Akzeptiert |
| [0005](0005-measurement-method.md) | Messmethode: Impulsantwort (ISO 3382-1); Sabine = Prognose/Verifikation | Akzeptiert |

> Neue Entscheidungen als `NNNN-kurztitel.md` ergänzen und hier eintragen. Eine Entscheidung wird
> nicht gelöscht, sondern per Status *„Abgelöst durch ADR-XXXX"* überschrieben.
