# AI Instructions for RT60 AcoustiScan Project

**Last Updated:** 2025-10-31
**Applies To:** All AI assistants (GitHub Copilot, Claude, ChatGPT, etc.)

---

## 🤖 Welcome, AI Assistant!

You are working on a **professional acoustic measurement application** for iPad. This is a **safety-critical and legally-relevant** project that requires:
- High precision in calculations
- Compliance with international standards
- Court-admissible documentation

**Please read this entire document before making any changes.**

---

## 📋 Project Overview

### What is RT60 AcoustiScan?
An iPad Pro app that measures **room reverberation time (RT60)** for acoustic consulting, building inspection, and legal compliance reporting.

### Key Facts
- **Language:** Swift 5.9+
- **Platforms:** iOS 15+, macOS 12+
- **Architecture:** Swift Package Manager, modular design
- **Target Users:** Professional acousticians, building inspectors, court experts
- **Region:** DACH (Germany, Austria, Switzerland)

### Critical Standards
- **DIN 18041:2016** - Room acoustics requirements
- **ISO 3382-2:2008** - Measurement procedures
- **ISO 17025** - Laboratory accreditation
- **DKD-R 3-3 (2025)** - Calibration standards

---

## ⚠️ Critical Safety Rules

### 🔴 **NEVER** Change Acoustic Calculations Without Verification

The RT60 calculation is **legally critical**:
```swift
RT60 = 0.161 × (V / A)

Where:
- 0.161 = Constant for SI units, 20°C, 50% humidity
- V = Room volume (m³)
- A = Total absorption area (m²)
```

**Before modifying:**
1. Understand the acoustic theory
2. Research the relevant standards
3. Validate with test cases
4. Document the change thoroughly

### 🔴 **NEVER** Skip Standards Research

DIN and ISO standards are **legal requirements**:
- Always verify current version (standards update!)
- Use web search to check latest revisions
- Document which version you're implementing
- Consider DACH-specific regulations

### 🔴 **NEVER** Commit Code with Merge Conflicts

Merge conflict markers in production code:
```
copilot/fix-[hash]
main
<<<<<<< HEAD
=======
>>>>>>>
```

**Action:** Use `fix-merge-conflicts.py` script or manually resolve.

### 🔴 **NEVER** Break Existing Tests

The project has **69 tests** (58 + 11):
```bash
cd AcoustiScanConsolidated && swift test  # Must pass
cd Modules/Export && swift test           # Must pass
```

**If tests fail after your changes:**
1. Fix the code (preferred)
2. Update tests only if requirements changed
3. Document why tests changed

---

## 🎯 Your Role (By AI System)

### GitHub Copilot
**Your strengths:**
- Real-time code completion
- Inline suggestions
- Quick syntax fixes
- Repetitive patterns

**Your config:** `.copilot/` directory
- Read `.copilot/README.md` for full context
- Follow `.copilot/copilot-prompts.md` rules
- Use `.copilot/error-solutions.md` for known issues

**Key rules:**
- Validate correlation >= 95% for RT60 measurements
- Use safe unwrapping (guard/if-let, never force unwrap!)
- Follow SwiftLint/SwiftFormat rules
- Log errors with context

### Claude (Anthropic)
**Your strengths:**
- Deep code analysis
- Architecture review
- Standards research
- Documentation generation

**Your config:** `.claude/` directory
- Read `.claude/README.md` for full context
- Use `.claude/prompts.md` for task templates
- Update `.claude/project-context.md` after major changes

**Key responsibilities:**
- Verify DIN 18041 compliance
- Research standards via web search
- Generate comprehensive reports
- Coordinate complex refactorings

### ChatGPT / Other AI
**Your approach:**
1. Read this file (AI_INSTRUCTIONS.md) first
2. Check existing configurations:
   - `.copilot/` if you're GitHub Copilot
   - `.claude/` if you're Claude
   - This file if you're something else
3. Follow the **Critical Safety Rules** above
4. Document your changes clearly

---

## 📁 Project Structure

```
RT60_ipad_akusti-scan-APP/
│
├── .copilot/               # GitHub Copilot configuration
│   ├── README.md           # Copilot-specific context
│   ├── copilot-prompts.md  # Prompts and rules
│   ├── error-solutions.md  # Known issues database
│   └── ...
│
├── .claude/                # Claude AI configuration
│   ├── README.md           # Claude-specific context
│   ├── project-context.md  # Deep project knowledge
│   ├── prompts.md          # Task templates
│   └── ...
│
├── .github/                # GitHub configuration
│   ├── workflows/          # CI/CD (3 workflows)
│   ├── ISSUE_TEMPLATE/     # Issue templates
│   └── PULL_REQUEST_TEMPLATE.md
│
├── AcoustiScanConsolidated/  # Core module
│   ├── RT60Calculator.swift  # 🔴 CRITICAL: Sabine formula
│   ├── DIN18041Database.swift # 🔴 CRITICAL: Standards data
│   ├── RT60Evaluator.swift   # Compliance checking
│   └── Models/               # Data models
│
├── Modules/Export/           # PDF/HTML generation
│   ├── PDFReportRenderer.swift
│   └── ReportHTMLRenderer.swift
│
├── Tools/                    # Utilities
│   └── LogParser/            # RT60 log parsing
│
├── AI_INSTRUCTIONS.md        # 👈 This file
├── PRODUCTION_READINESS_REPORT.md  # Current status
├── QUICK_START_MACBOOK_IPAD.md     # Setup guide
└── fix-merge-conflicts.py    # Automated cleanup script
```

---

## 🔍 Before Making Changes

### 1. **Understand the Context**
```bash
# Read these files first:
- AI_INSTRUCTIONS.md (this file)
- .copilot/README.md OR .claude/README.md
- PRODUCTION_READINESS_REPORT.md

# Review recent history:
git log -10 --oneline
```

### 2. **Check Current Issues**
```bash
# Known problems:
- DIN18041Database.swift: Incorrect tolerance (±0.1 instead of ±20%)
- DIN18041Database.swift: Volume parameter ignored
- ReportModel: Missing ISO 3382-2 metadata

# See: PRODUCTION_READINESS_REPORT.md → "Known Issues"
```

### 3. **Run Baseline Tests**
```bash
# Establish current state:
cd AcoustiScanConsolidated
swift build && swift test

cd ../Modules/Export
swift build && swift test
```

### 4. **Plan Your Changes**
- Minimize scope (single concern per commit)
- Consider impacts on:
  - RT60 accuracy
  - DIN compliance
  - Existing tests
  - API compatibility

---

## ✅ After Making Changes

### Pre-Commit Checklist
- [ ] Code compiles: `swift build`
- [ ] Tests pass: `swift test`
- [ ] No warnings
- [ ] No merge conflict markers
- [ ] No code duplication
- [ ] SwiftLint satisfied: `swiftlint --strict`
- [ ] No force unwraps in production code
- [ ] Documentation updated if needed

### Commit Message Format
```
Type: Brief description (50 chars max)

**Problem:** [What was wrong or needed]
**Solution:** [What was changed]
**Testing:** [How it was verified]
**Impact:** [Breaking changes? Migration needed?]

Refs: #issue-number (if applicable)
```

**Types:**
- `Fix:` - Bug fix
- `Feat:` - New feature
- `Refactor:` - Code refactoring
- `Docs:` - Documentation only
- `Test:` - Test additions/changes
- `Build:` - Build system changes
- `CI:` - CI/CD changes

### Example Commit
```
Fix: Correct DIN 18041 tolerance calculation

**Problem:** Tolerance was absolute (±0.1s) instead of relative (±20%)
**Solution:** Changed to `tolerance = baseRT60 * 0.20`
**Testing:** Added test_din_tolerance_calculation() unit test
**Impact:** No breaking changes, improves DIN compliance

Refs: #45
```

---

## 🚨 Emergency Procedures

### Build Failure in CI/CD
1. Check GitHub Actions logs
2. Reproduce locally: `swift build`
3. Check `.copilot/error-solutions.md` for known issues
4. Fix and push
5. Monitor CI/CD run

### Merge Conflicts
1. Run automated cleanup: `python3 fix-merge-conflicts.py`
2. Manually review complex conflicts
3. Verify no code duplication remains
4. Run full test suite
5. Commit with clear message

### Test Regression
1. Identify failing tests: `swift test`
2. Review recent commits: `git log -5`
3. Bisect if needed: `git bisect start`
4. Fix or revert: `git revert [hash]`
5. Document in `.copilot/error-solutions.md`

### Performance Issue
1. Profile: Use Instruments or console logging
2. Identify bottleneck
3. Optimize with care (maintain accuracy!)
4. Benchmark improvements
5. Document performance gain

---

## 🤝 Collaboration Between AI Systems

### How AI Assistants Communicate

Since different AI systems **cannot directly communicate**, we use:

1. **Git History** - Shared "message board"
   ```bash
   git log --oneline -20  # Read what others did
   ```

2. **Documentation Files** - Persistent knowledge
   - `.copilot/` - For GitHub Copilot
   - `.claude/` - For Claude
   - `AI_INSTRUCTIONS.md` - For everyone

3. **Code Comments** - Inline explanations
   ```swift
   // Claude 2025-10-31: Fixed DIN tolerance, was ±0.1s, now ±20% relative
   let tolerance = baseRT60 * 0.20
   ```

4. **Issue Tracking** - Task coordination
   - Create issues for complex tasks
   - Reference in commits: `Refs: #45`

### Example Workflow

```
GitHub Copilot:
  - Writes code with inline suggestions
  - Commits: "Fix: Add missing import Foundation"
  ↓
Git Repository:
  - Stores commit history
  ↓
Claude:
  - Reads commit: "Copilot fixed imports"
  - Analyzes architecture
  - Creates report: REVIEW_2025-10-31.md
  - Commits: "docs: Add architecture review"
  ↓
Git Repository:
  - Stores updated docs
  ↓
GitHub Copilot:
  - Reads docs
  - Understands new context
  - Makes better suggestions
```

---

## 🎓 Domain Knowledge

### RT60 Basics
**Reverberation Time (RT60):** Time for sound to decay by 60 dB

**Sabine Formula:**
```
RT60 = 0.161 × V / A

Assumptions:
- Diffuse sound field
- Uniform absorption
- α < 0.3 (most rooms)

Alternative (α > 0.3):
Eyring: RT60 = 0.161 × V / (-S × ln(1-α))
```

### DIN 18041 Room Groups

**Gruppe A** (Communication):
- Classrooms, lecture halls, conference rooms
- Formula: T_soll = 0.32 × log₁₀(V/100) + 0.17
- Tolerance: ±20% relative (250-2000 Hz)

**Gruppe B** (Special):
- Offices, canteens, lobbies
- Variable requirements
- Tolerance varies by function

### ISO 3382-2 Procedures

**Accuracy Levels:**
- **Kurz:** 2 positions, 6 measurements (quick check)
- **Standard:** 6 positions, 18 measurements (normal)
- **Präzision:** 12+ positions, 36+ measurements (court reports)

---

## 📞 Resources

### Standards (Require Purchase/Access)
- **DIN 18041:2016-03** - https://www.din.de
- **ISO 3382-2:2008** - https://www.iso.org
- **ISO 17025** - https://www.iso.org

### Free Resources
- **Sabine Formula:** Wikipedia, acoustic textbooks
- **PTB Calibration:** https://www.ptb.de
- **DEGA (German Acoustical Society):** https://www.dega-akustik.de

### Code Documentation
- **Swift Docs:** https://docs.swift.org
- **Apple AVFoundation:** https://developer.apple.com/av-foundation/

---

## 🎯 Quality Targets

### Code Quality
- **Test Coverage:** >80%
- **Build Success Rate:** >90% (CI/CD)
- **SwiftLint Warnings:** 0
- **Force Unwraps:** 0 (production code)

### Acoustic Accuracy
- **RT60 Precision:** ±0.01 seconds
- **Correlation Required:** ≥95% (ISO standard)
- **Frequency Coverage:** 125 Hz - 4000 Hz minimum
- **DIN Compliance:** 100% for target room types

### Documentation
- **Code Comments:** All public APIs
- **README:** Comprehensive
- **User Manual:** German + English
- **Standards References:** Cited with versions

---

## 🏆 Success Metrics

Track your contributions:
- **Bugs Fixed:** Document in `.copilot/error-solutions.md`
- **Standards Compliance:** Note DIN/ISO improvements
- **Tests Added:** Increase coverage percentage
- **Documentation:** New guides created
- **Performance:** Benchmark improvements

---

## 🙏 Thank You!

Your contributions make this project better for professional acousticians worldwide. By following these guidelines, you ensure:
- ✅ Legal compliance (court-admissible reports)
- ✅ Scientific accuracy (correct RT60 calculations)
- ✅ Code quality (maintainable, testable)
- ✅ Team coordination (clear communication)

**Questions?** Check:
1. This file (AI_INSTRUCTIONS.md)
2. `.copilot/README.md` or `.claude/README.md`
3. `PRODUCTION_READINESS_REPORT.md`
4. Git history: `git log`

**Happy coding!** 🎉

---

**Version:** 1.0
**Date:** 2025-10-31
**Maintained by:** Development Team + AI Assistants
