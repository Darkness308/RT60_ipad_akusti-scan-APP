# RT60 iPad AcoustiScan App

[![Swift CI](https://github.com/Darkness308/RT60_ipad_akusti-scan-APP/actions/workflows/swift-ci.yml/badge.svg)](https://github.com/Darkness308/RT60_ipad_akusti-scan-APP/actions/workflows/swift-ci.yml)
[![SwiftLint](https://github.com/Darkness308/RT60_ipad_akusti-scan-APP/actions/workflows/swiftlint.yml/badge.svg)](https://github.com/Darkness308/RT60_ipad_akusti-scan-APP/actions/workflows/swiftlint.yml)
[![Test Coverage](https://github.com/Darkness308/RT60_ipad_akusti-scan-APP/actions/workflows/test-coverage.yml/badge.svg)](https://github.com/Darkness308/RT60_ipad_akusti-scan-APP/actions/workflows/test-coverage.yml)

**AcoustiScan** - iPad Raumakustik-App für orientierende RT60-Messungen mit LiDAR und DIN 18041 Compliance.

## 🚀 Automatisierte Workflows

Dieses Repository verfügt über vollständig optimierte Swift-Entwicklungsworkflows:

- **✅ Continuous Integration**: Automatische Builds und Tests bei jedem Push/PR
- **✅ Code Quality**: SwiftLint-Integration mit projektspezifischen Regeln  
- **✅ Test Coverage**: Automatische Coverage-Berichterstattung
- **✅ Release Automation**: Tag-basierte Release-Erstellung

### 🛠 Lokale Entwicklung

```bash
# Setup (einmalig)
make setup

# Entwicklungsworkflow
make build    # Build
make test     # Tests ausführen
make lint     # Code-Style prüfen
make check    # Vollständige Qualitätsprüfung

# Hilfreich für CI-Simulation
make ci       # Lokale CI-Simulation
```

Siehe [WORKFLOW_SETUP.md](WORKFLOW_SETUP.md) für detaillierte Dokumentation.