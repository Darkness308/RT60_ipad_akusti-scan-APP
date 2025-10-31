# 🚀 Quick Start Guide: RT60 App auf MacBook & iPad

## Schritt 1: Build auf MacBook testen

### A) Repository klonen/pullen
```bash
cd ~/Developer  # Oder dein bevorzugtes Verzeichnis
git clone https://github.com/Darkness308/RT60_ipad_akusti-scan-APP.git
cd RT60_ipad_akusti-scan-APP

# ODER wenn bereits geklont:
git checkout main
git pull origin main
git merge claude/placeholder-branch-011CUWkrfBc8tq6aXxVHyZ9j  # Merge die Fixes
```

### B) Build-Test (Terminal)
```bash
# AcoustiScan Modul bauen
cd AcoustiScanConsolidated
swift build

# ✅ Erwartete Ausgabe:
# Build complete! (X.Xs)

# Tests ausführen
swift test

# ✅ Erwartete Ausgabe:
# Test Suite 'All tests' passed at ...
# Executed 58 tests, with 0 failures (0 unexpected)
```

### C) Export-Modul testen
```bash
cd ../Modules/Export
swift build
swift test

# ✅ Erwartete Ausgabe:
# Executed 11 tests, with 0 failures
```

---

## Schritt 2: Xcode-Projekt öffnen

### A) Xcode öffnen
```bash
# Vom Hauptverzeichnis:
cd ~/Developer/RT60_ipad_akusti-scan-APP/AcoustiScanConsolidated
open Package.swift
```

**ODER:**
1. Xcode öffnen
2. "Open Existing Project"
3. `AcoustiScanConsolidated/Package.swift` auswählen

### B) Scheme auswählen
1. In Xcode oben: Schema-Dropdown
2. Wähle: **"AcoustiScanConsolidated"** oder **"AcoustiScanTool"**
3. Ziel wählen: **"My Mac"** (für ersten Test)

### C) Build & Run
- **⌘ + B** (Build)
- **⌘ + R** (Run)
- **⌘ + U** (Tests)

---

## Schritt 3: iPad Pro Deployment vorbereiten

### A) Code Signing einrichten

**Voraussetzungen:**
- Apple Developer Account (99€/Jahr ODER kostenlos für persönliche Apps)
- iPad Pro in Xcode registriert

**Schritte:**
1. Xcode → Preferences → Accounts
2. Apple ID hinzufügen
3. Team auswählen (Personal Team ODER Organization)

### B) Projekt-Einstellungen

1. In Xcode: **AcoustiScanConsolidated** Projekt auswählen
2. Target: **AcoustiScanTool** auswählen
3. Tab: **Signing & Capabilities**

**Einstellungen:**
```
✅ Automatically manage signing
Team: [Dein Team auswählen]
Bundle Identifier: com.[yourname].rt60-acoustiscan
```

4. **Deployment Info** anpassen:
   - iOS Deployment Target: **15.0**
   - Devices: **iPad**

### C) iPad verbinden

1. iPad Pro per USB-C/Lightning verbinden
2. iPad entsperren
3. "Diesem Computer vertrauen" → Bestätigen
4. In Xcode: Schema-Ziel auf **"Dein iPad"** ändern
5. **⌘ + R** → App wird gebaut und installiert

**Beim ersten Mal:**
- iPad: Einstellungen → Allgemein → VPN & Geräteverwaltung
- Developer App: **[Dein Name]** → Vertrauen

---

## Schritt 4: Live-Test durchführen

### A) App-Start auf iPad
1. App **"AcoustiScanTool"** öffnen
2. Mikrofon-Zugriff erlauben

### B) Test-Messung (ohne echtes Messgerät)
```
⚠️ WICHTIG: Dies ist nur ein Software-Test!
Für gerichtsfeste Messungen ist ein kalibriertes Klasse-1 Messgerät nötig.
```

**Test-Szenario:**
1. Gehe in einen Raum (z.B. Wohnzimmer)
2. Raumabmessungen messen:
   - Länge, Breite, Höhe
   - Volumen berechnen: V = L × B × H
3. In App eingeben:
   - Raumtyp: z.B. "Büro"
   - Volumen: z.B. 50 m³
4. Messung starten (Testschall erzeugen):
   - Klatschen
   - ODER: Lautsprecher mit Impulsschall
5. RT60-Werte ablesen
6. PDF-Report exportieren

### C) PDF-Export testen
1. In App: "Bericht generieren"
2. PDF sollte enthalten:
   - ✅ Metadaten (Gerät, Version, Datum)
   - ✅ RT60-Werte je Frequenz (125, 1000, 4000 Hz)
   - ✅ DIN 18041 Zielwerte
   - ✅ Abweichungsanalyse
   - ✅ Core Tokens
3. PDF per AirDrop / E-Mail exportieren

---

## Schritt 5: Produktiv-Vorbereitung

### Für NICHT-gerichtsfeste Messungen (sofort nutzbar):
- ✅ Interne Raum-Audits
- ✅ Erste Planungs-Abschätzungen
- ✅ Vergleichsmessungen
- ✅ Monitoring von Verbesserungen

### Für gerichtsfeste Gutachten (weitere Schritte nötig):

**Hardware:**
- [ ] Klasse-1 Schallpegelmesser beschaffen
  - z.B. Brüel & Kjær, NTi Audio, SVANTEK
  - Kosten: ca. 2.000-5.000 €
- [ ] Kalibrator (94 dB @ 1 kHz)
- [ ] Optional: Dodecahedron-Lautsprecher (omnidirektional)

**Software-Erweiterungen:**
- [ ] Metadaten-Felder ergänzen (siehe PRODUCTION_READINESS_REPORT.md)
- [ ] PDF-Template erweitern
- [ ] Kalibrierungs-Management integrieren

**Qualifikation:**
- [ ] Schulung ISO 3382-2 Messverfahren
- [ ] Optional: Sachverständigen-Zertifizierung

**Kalibrierung:**
- [ ] Messgerät zu DAkkS-Labor senden
- [ ] Jährliche Re-Kalibrierung einplanen
- [ ] Kalibrierzertifikate aufbewahren

---

## Troubleshooting

### Problem: Swift Build fehlt auf macOS
```bash
# Xcode Command Line Tools installieren:
xcode-select --install
```

### Problem: "Developer cannot be verified" auf iPad
```
Lösung:
Einstellungen → Allgemein → VPN & Geräteverwaltung
→ Developer App → Vertrauen
```

### Problem: Code-Signing Fehler
```
Lösung:
1. Xcode → Preferences → Accounts → Team neu auswählen
2. Projekt → Signing & Capabilities → "Automatically manage signing" deaktivieren/reaktivieren
3. Bundle Identifier ändern (z.B. com.yourname.rt60-acoustiscan)
```

### Problem: iPad wird nicht erkannt
```
Lösungen:
1. iPad entsperren
2. USB-Kabel wechseln (originales Lightning/USB-C)
3. Xcode neustarten
4. iPad neustarten
5. "Diesem Computer vertrauen" erneut bestätigen
```

### Problem: Tests schlagen fehl
```bash
# Build-Cache löschen:
cd AcoustiScanConsolidated
swift package clean
rm -rf .build

# Neu bauen:
swift build
swift test
```

---

## Nächste Schritte nach erfolgreichem Test

1. **Code-Review:**
   - Durchgehe `PRODUCTION_READINESS_REPORT.md`
   - Priorisiere DIN-Compliance-Fixes

2. **DIN 18041 Formel korrigieren:**
   - `DIN18041Database.swift` anpassen
   - Volume-Abhängigkeit implementieren
   - Relative Toleranz (±20%)

3. **Dokumentation:**
   - README.md erweitern
   - Benutzerhandbuch schreiben
   - API-Docs generieren

4. **Feldtest:**
   - Vergleichsmessung mit Referenzgerät
   - Reproduzierbarkeit prüfen

5. **App Store / TestFlight:**
   - Falls gewünscht: Distribution vorbereiten
   - Screenshots, Beschreibung

---

## Kontakt & Support

**GitHub:** https://github.com/Darkness308/RT60_ipad_akusti-scan-APP
**Issues:** https://github.com/Darkness308/RT60_ipad_akusti-scan-APP/issues

---

**Viel Erfolg mit deiner RT60 Akustik-App! 🎉**

Bei Fragen einfach melden.
