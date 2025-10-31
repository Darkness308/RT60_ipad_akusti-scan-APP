# RT60 AcoustiScan - Deep Project Context

**Last Updated:** 2025-10-31
**Project Status:** Pre-Production (awaiting DIN compliance fixes)

---

## 📊 Current Project State

### Version Information
- **Current Branch:** `claude/placeholder-branch-011CUWkrfBc8tq6aXxVHyZ9j`
- **Base Branch:** `main`
- **Latest Commit:** `e17dfd9` - Production docs
- **Previous Commit:** `0ab8c89` - Merge conflict fixes

### Health Metrics
- ✅ **Compilation:** Clean (after 2025-10-31 fixes)
- ✅ **Tests:** 69 passing (58 AcoustiScan + 11 Export)
- ✅ **CI/CD:** 3 workflows active (swift.yml, build-test.yml, auto-retry.yml)
- ⚠️ **DIN Compliance:** Needs corrections (see below)
- ⚠️ **Documentation:** Minimal (improving)

---

## 🎯 Project Mission

### Primary Goal
Build a **professional-grade iPad app** for acoustic room measurements that:
1. Measures RT60 reverberation time accurately
2. Validates against DIN 18041:2016 standards
3. Generates court-admissible reports (ISO 3382-2)
4. Complies with DACH region regulations

### Target Users
- Acousticians and acoustic consultants
- Building inspectors
- Architects planning room acoustics
- Quality assurance professionals
- Court-appointed experts (Sachverständige)

---

## 🏗️ Architecture Deep Dive

### Module Structure

```
RT60_ipad_akusti-scan-APP/
│
├── AcoustiScanConsolidated/          # Core calculation engine
│   ├── RT60Calculator.swift          # Sabine formula implementation
│   ├── DIN18041Database.swift        # Target values per room type
│   ├── RT60Evaluator.swift           # Compliance checking
│   ├── Models/                       # 8 data models
│   │   ├── RT60Measurement.swift
│   │   ├── DIN18041Target.swift
│   │   ├── RT60Deviation.swift
│   │   ├── RoomType.swift
│   │   ├── EvaluationStatus.swift
│   │   ├── AcousticSurface.swift
│   │   ├── AcousticMaterial.swift
│   │   └── AbsorberRecommendation.swift
│   ├── DIN18041/                     # DIN compliance logic
│   │   ├── DIN18041Database.swift
│   │   └── RT60Evaluator.swift
│   ├── AcousticFramework.swift       # Main API
│   ├── ReportModel.swift             # Report data structure
│   ├── ReportHTMLRenderer.swift      # HTML export
│   ├── ConsolidatedPDFExporter.swift # PDF export (legacy?)
│   └── PDFTextExtractor.swift        # PDF parsing
│
├── Modules/Export/                    # Report generation
│   ├── PDFReportRenderer.swift       # Primary PDF renderer
│   ├── ReportHTMLRenderer.swift      # HTML renderer
│   ├── HTMLPreviewView.swift         # SwiftUI preview
│   └── Tests/                        # 11 tests
│       ├── ReportContractTests.swift
│       ├── ReportHTMLRendererTests.swift
│       ├── PDFReportSnapshotTests.swift
│       └── PDFRobustnessTests.swift
│
└── Tools/                             # Utilities
    ├── LogParser/                     # RT60 log parsing
    │   ├── RT60LogParser.swift
    │   └── RT60LogParserTests.swift
    ├── reporthtml/                    # HTML CLI tool
    │   └── main.swift
    └── linters/                       # Code quality
        └── report_key_coverage.swift
```

### Key Design Patterns

#### 1. **Calculation Flow**
```swift
User Input (Volume, Surfaces)
    ↓
RT60Calculator.calculateRT60(volume, absorption)
    ↓ (Sabine formula)
RT60Measurement(frequency, rt60)
    ↓
DIN18041Database.targets(for: roomType, volume)
    ↓
RT60Evaluator.evaluateDINCompliance(measurements, targets)
    ↓
RT60Deviation(measured, target, status)
    ↓
ReportModel (complete data structure)
    ↓
PDFReportRenderer.render(model)
    ↓
PDF Data
```

#### 2. **Data Model Hierarchy**
```
ReportModel
├── metadata: [String: String]
├── rt60_bands: [[String: Double?]]
├── din_targets: [[String: Double?]]
├── recommendations: [String]
├── audit: [String: Any]
└── validity: [String: Any]
```

#### 3. **DIN18041 Target System**
```
DIN18041Database
├── targets(for: RoomType, volume: Double) → [DIN18041Target]
│
├── Room Types:
│   ├── .classroom     (Gruppe A)
│   ├── .officeSpace   (Gruppe B)
│   ├── .conference    (Gruppe A)
│   ├── .lecture       (Gruppe A)
│   ├── .music         (Spezial)
│   └── .sports        (Sporthalle)
│
└── DIN18041Target
    ├── frequency: Int
    ├── targetRT60: Double
    └── tolerance: Double
```

---

## 🔬 Scientific Foundation

### RT60 Calculation (Sabine Formula)

**Formula:**
```
RT60 = 0.161 × (V / A)

Where:
- RT60 = Reverberation time in seconds
- V = Room volume in m³
- A = Total absorption area in m² (Sabine)
- 0.161 = Constant for 20°C, 50% humidity (SI units)
```

**Derivation:**
```
0.161 = (24 × ln(10)) / c
      = (24 × 2.303) / 343
      ≈ 0.161 s/m

Where:
- c = Speed of sound ≈ 343 m/s at 20°C
- 24 = Integration constant (60dB decay / 2.5dB per doubling)
- ln(10) = Natural logarithm of 10 (for dB conversion)
```

**Validity:**
- ✅ **Valid for:** α < 0.3 (most offices, classrooms)
- ⚠️ **Less accurate for:** α > 0.3 (highly absorptive rooms)
- ❌ **Alternative:** Eyring formula for α > 0.3

**Eyring Formula (not currently implemented):**
```swift
RT60 = 0.161 × V / (-S × ln(1 - α))

Where:
- S = Total surface area in m²
- α = Average absorption coefficient
```

### DIN 18041:2016 Requirements

**Gruppe A (Communication Rooms):**
- **Target RT60 Formula:**
  ```
  T_soll,500Hz = 0.32 × log₁₀(V/V₀) + 0.17

  Where:
  - V = Room volume in m³
  - V₀ = 100 m³ (reference volume)
  ```

- **Tolerance:** ±20% relative (NOT absolute!)
  ```
  tolerance = T_soll × 0.20
  ```

- **Frequency Range:** 250-2000 Hz (main speech range)
  - 125 Hz: Up to +40% allowed
  - 250-2000 Hz: ±20%
  - 4000+ Hz: -20% allowed (gradual decrease)

**Gruppe B (Special Requirements):**
- Different formula (not fully implemented)
- Variable tolerance based on room function

### ISO 3382-2:2008 Measurement Standard

**Three Accuracy Levels:**

| Level | Positions | Measurements | Use Case |
|-------|-----------|-------------|----------|
| **Kurz** (Survey) | 2 | 6 | Quick check |
| **Standard** (Engineering) | 6 | 18 | Normal measurements |
| **Präzision** (Precision) | 12+ | 36+ | Court reports |

**Required Documentation:**
1. Room sketch with measurement positions
2. Microphone heights and distances
3. Sound source type and position
4. Temperature and humidity
5. Background noise level
6. Calibration certificate
7. Measurement uncertainty

---

## ⚠️ Known Issues & Technical Debt

### Critical Issues (Must Fix Before Production)

#### 1. **DIN18041Database.swift - Incorrect Tolerance**
**File:** `AcoustiScanConsolidated/Sources/.../DIN18041/DIN18041Database.swift`
**Lines:** 30, 48, 57, 66, 75, 84

**Current (WRONG):**
```swift
let tolerance = 0.1  // Absolute value in seconds
```

**Should be (CORRECT):**
```swift
let tolerance = baseRT60 * 0.20  // ±20% relative
```

**Impact:**
- Small rooms: Tolerance too strict
- Large rooms: Tolerance too lenient
- Non-compliant with DIN 18041:2016

**Fix Priority:** 🔴 **HIGH**

---

#### 2. **DIN18041Database.swift - Volume Ignored**
**File:** Same as above
**Lines:** 29, 47, 56, 65, 74, 83

**Current (WRONG):**
```swift
private static func classroomTargets(volume: Double) -> [DIN18041Target] {
    let baseRT60 = 0.6  // Fixed value, 'volume' parameter unused!
    // ...
}
```

**Should be (CORRECT):**
```swift
private static func classroomTargets(volume: Double) -> [DIN18041Target] {
    let v0 = 100.0  // Reference volume
    let baseRT60 = 0.32 * log10(volume / v0) + 0.17  // DIN 18041 formula
    // ...
}
```

**Impact:**
- All room sizes get same target RT60
- Violates DIN 18041 fundamental principle
- Incorrect for any room != 200m³ (implicit assumption)

**Fix Priority:** 🔴 **HIGH**

---

#### 3. **ReportModel - Missing ISO 3382-2 Metadata**
**File:** `AcoustiScanConsolidated/Sources/.../ReportModel.swift`

**Currently Missing:**
```swift
// Calibration
var deviceSerial: String?
var calibrationDate: Date?
var calibrationCertificate: String?
var nextCalibrationDue: Date?

// Measurement Conditions
var temperature: Double?  // °C
var humidity: Double?     // %
var backgroundNoise: Double?  // dB(A)
var measurementMethod: String = "ISO 3382-2:2008"
var accuracyLevel: String = "Standard"  // Kurz/Standard/Präzision

// Spatial Info
var numberOfPositions: Int = 6
var microfonHeight: [Double] = []
var soundSourcePosition: String?
var roomSketch: Data?  // Image data

// Legal
var measuredBy: String?
var expertQualification: String?
var accreditation: String?  // e.g., "DAkkS D-K-18025-01-00"
var measurementUncertainty: Double?  // ± seconds
```

**Impact:**
- Reports not court-admissible
- Missing legal requirements
- ISO 3382-2 non-compliant

**Fix Priority:** 🟡 **MEDIUM** (needed for court reports)

---

### Minor Issues

#### 4. **Code Duplication (FIXED 2025-10-31)**
- ✅ PDFReportRenderer.swift - Constants extracted
- ✅ 14 files cleaned from merge conflicts

#### 5. **Documentation Gaps**
- ⚠️ README.md too minimal
- ⚠️ No API documentation (DocC)
- ⚠️ Missing user manual

#### 6. **Test Coverage Gaps**
- ⚠️ No tests for DIN formula correctness
- ⚠️ Missing integration tests for full workflow
- ⚠️ No performance benchmarks

---

## 🚀 Development Roadmap

### Phase 1: Critical Fixes (Before First Production Use)
- [ ] Fix DIN18041Database.swift formulas
- [ ] Validate with test cases
- [ ] Update tests to verify DIN compliance

### Phase 2: ISO 3382-2 Compliance (For Court Reports)
- [ ] Extend ReportModel with metadata fields
- [ ] Update PDF renderer to include all ISO fields
- [ ] Add calibration management UI
- [ ] Implement measurement position tracking

### Phase 3: Documentation
- [ ] Comprehensive README.md
- [ ] API documentation (DocC)
- [ ] User manual (German + English)
- [ ] Developer guide

### Phase 4: Hardware Integration
- [ ] Class 1 sound level meter integration
- [ ] Calibrator support
- [ ] Dodecahedron loudspeaker integration

### Phase 5: Advanced Features
- [ ] Eyring formula option for α > 0.3
- [ ] Room geometry scanning (RoomPlan)
- [ ] Cloud sync for measurements
- [ ] Multi-language support

---

## 🔐 Security & Privacy

### Data Handling
- **Measurement Data:** Stored locally on device
- **PDF Reports:** Generated on-device, no cloud upload
- **Calibration Certs:** Should be encrypted if stored

### Privacy Concerns
- Microphone access required (justified for measurements)
- Location data NOT collected
- No user tracking or analytics

---

## 📞 Key Contacts & Resources

### Standards Bodies
- **DIN** (Germany): https://www.din.de
- **ISO**: https://www.iso.org
- **PTB** (Calibration): https://www.ptb.de
- **DAkkS** (Accreditation): https://www.dakks.de

### Technical Communities
- **DEGA** (Deutsche Gesellschaft für Akustik)
- **VDI Technische Akustik**
- **iOS Developers Slack** (#audio-dev)

---

## 📚 Further Reading

### Essential Papers
1. W.C. Sabine (1900) - "Reverberation" (original paper)
2. DIN 18041:2016-03 - Hörsamkeit in Räumen
3. ISO 3382-2:2008 - Measurement procedures

### Recommended Books
- "Acoustics" by Heinrich Kuttruff
- "Room Acoustics" by H.P. Seraphim
- "Building Acoustics" by Tor Erik Vigran

---

**This context document should be updated after each significant Claude session.**
