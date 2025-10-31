# Claude AI Configuration for RT60 AcoustiScan Project

**Last Updated:** 2025-10-31
**Claude Instance:** Sonnet 4.5 (claude-sonnet-4-5-20250929)

---

## 🎯 Purpose

This directory contains configuration and context for **Claude AI** (Anthropic) when working on the RT60 iPad Akustik-Scan-APP. This is complementary to the existing `.copilot/` configuration for GitHub Copilot.

**Key Difference:**
- **GitHub Copilot** (OpenAI) → Autocomplete, inline suggestions, SWE agent
- **Claude** (Anthropic) → Deep reasoning, architecture review, documentation

**Both systems work independently** but share the same codebase and Git history as "common language."

---

## 📁 File Structure

```
.claude/
├── README.md              # This file - Claude-specific guidance
├── project-context.md     # Deep project context for Claude sessions
├── review-checklist.md    # Code review checklist
└── prompts.md             # Claude-specific prompts and tasks
```

---

## 🧠 Project Context (Quick Brief)

### What is RT60 AcoustiScan?
Professional iOS/iPadOS app for **acoustic room measurements**:
- Measures **RT60** (Reverberation Time) using Sabine formula
- Validates against **DIN 18041:2016** and **ISO 3382-2:2008** standards
- Generates **professional PDF reports** for acousticians
- Target: DACH region (Germany, Austria, Switzerland)

### Tech Stack
- **Language:** Swift 5.9+
- **Platforms:** iOS 15+, macOS 12+ (iPad Pro target)
- **Build:** Swift Package Manager
- **Architecture:** Modular (AcoustiScanConsolidated, Export, Tools)
- **Testing:** 69 unit/integration tests
- **CI/CD:** GitHub Actions with auto-retry

### Critical Standards
- **DIN 18041:2016-03** - Hörsamkeit in Räumen
- **ISO 3382-2:2008** - Messung der Nachhallzeit
- **ISO 17025** - Labor-Akkreditierung (für Gerichtsfestigkeit)

---

## 🎓 Claude's Role in This Project

### Primary Responsibilities

1. **Architecture & Design Review**
   - Analyze code structure and modularity
   - Identify anti-patterns and suggest refactorings
   - Validate design decisions against best practices

2. **Acoustic Domain Expertise**
   - Verify RT60 calculations (Sabine/Eyring formulas)
   - Check DIN 18041 / ISO 3382-2 compliance
   - Validate acoustic measurement methodology

3. **Documentation Generation**
   - Create comprehensive README files
   - Generate API documentation
   - Write technical reports (like PRODUCTION_READINESS_REPORT.md)

4. **Code Quality & Standards**
   - Identify merge conflicts and duplications
   - Enforce DRY principles
   - Review Swift best practices

5. **Legal & Regulatory Compliance**
   - Ensure court-admissible report requirements
   - Verify DACH region standards compliance
   - Document calibration and measurement protocols

---

## 🔧 How Claude Works on This Project

### Session Workflow

1. **Context Loading**
   - Read `.claude/project-context.md` first
   - Review recent Git commits and issues
   - Understand current development phase

2. **Task Execution**
   - Deep analysis before making changes
   - Research standards/norms via web search if needed
   - Document all decisions and reasoning

3. **Deliverables**
   - Code fixes with detailed explanations
   - Comprehensive reports (Markdown)
   - Commit messages with full context

4. **Handoff**
   - Create detailed documentation for next session
   - Update `.claude/project-context.md` with new findings
   - Provide clear next steps

---

## 📋 Recent Claude Sessions

### Session 2025-10-31 (This Session)
**Task:** Code review, merge conflict resolution, production readiness assessment

**Completed:**
- ✅ Fixed 14 files with merge conflicts (automated via Python script)
- ✅ Eliminated code duplication in PDFReportRenderer
- ✅ Verified RT60 Sabine formula correctness (0.161 constant)
- ✅ Analyzed DIN 18041:2016 compliance (identified 3 critical issues)
- ✅ Researched ISO 3382-2 requirements for court-admissible reports
- ✅ Created PRODUCTION_READINESS_REPORT.md (817 lines)
- ✅ Created QUICK_START_MACBOOK_IPAD.md
- ✅ Documented DACH region legal requirements

**Key Findings:**
- ⚠️ DIN 18041 tolerance calculation INCORRECT (absolute instead of ±20% relative)
- ⚠️ Volume-dependent RT60 formula MISSING (T = 0.32×log₁₀(V/V₀)+0.17)
- ⚠️ Metadata for ISO 3382-2 compliance INCOMPLETE

**Next Steps:**
1. Correct DIN18041Database.swift formulas
2. Extend ReportModel with calibration/measurement metadata
3. Add ISO 3382-2 compliant PDF sections

**Commits:**
- `0ab8c89` - Fix: Remove all merge conflict markers
- `e17dfd9` - docs: Add production readiness report

---

## 🤝 Collaboration with GitHub Copilot

### Division of Labor

**GitHub Copilot handles:**
- ✅ Real-time code suggestions
- ✅ Autocomplete while typing
- ✅ Quick error fixes (syntax, imports)
- ✅ Repetitive code patterns

**Claude handles:**
- ✅ Deep architectural analysis
- ✅ Standards/regulations research
- ✅ Complex refactorings
- ✅ Comprehensive documentation
- ✅ Multi-file coordinated changes

### Communication Protocol
Since we can't directly communicate, we use:
- **Git commits** - Our shared "message board"
- **Documentation files** - Persistent knowledge
- **Code comments** - In-line explanations
- **Issue tracking** - Task coordination

**Example:**
```
Copilot fixes a bug → Commits with message
↓
Claude reads commit history → Understands change
↓
Claude writes report → Documents for both systems
↓
Copilot reads report → Learns context for next suggestions
```

---

## 📚 Key Documentation to Read

### Before Starting a Session
1. `.claude/project-context.md` - Current project state
2. `PRODUCTION_READINESS_REPORT.md` - Latest assessment
3. Recent Git commits (`git log -10`)
4. Open issues on GitHub

### Standards References
- `.copilot/copilot-prompts.md` - Copilot's rules (good baseline)
- `BUILD_AUTOMATION.md` - CI/CD documentation
- `CONSOLIDATION_REPORT.md` - Project structure

### Domain Knowledge
- DIN 18041:2016 standard (web search if needed)
- ISO 3382-2:2008 measurement procedures
- Sabine formula: RT60 = 0.161 × V/A

---

## 🎯 Quality Standards

### Code Review Checklist
- [ ] No merge conflict markers (`copilot/fix-`, `main`)
- [ ] No code duplication (DRY principle)
- [ ] Swift best practices (guard, optionals, error handling)
- [ ] RT60 calculation accuracy verified
- [ ] DIN 18041 compliance checked
- [ ] Test coverage maintained (>80%)
- [ ] Documentation updated

### Communication Standards
- **Be precise**: Include line numbers, file paths
- **Be thorough**: Explain reasoning and alternatives
- **Be actionable**: Provide clear next steps
- **Be educational**: Explain "why" not just "what"

---

## 🚨 Critical Don'ts for Claude

1. **Never modify acoustic calculations without verification**
   - RT60 precision is legally critical
   - Always validate against standards

2. **Never skip web research for standards**
   - DIN/ISO standards evolve
   - Check current versions (2024/2025)

3. **Never make assumptions about legal requirements**
   - DACH regulations are specific
   - Research current PTB/DAkkS requirements

4. **Never create code without understanding existing architecture**
   - Read existing files first
   - Understand module boundaries

5. **Never ignore test failures**
   - All 69 tests must pass
   - Test modifications require analysis

---

## 🔄 Session Handoff Template

At end of each Claude session, update this file:

```markdown
### Session YYYY-MM-DD
**Task:** [Brief description]

**Completed:**
- ✅ [Item 1]
- ✅ [Item 2]

**Key Findings:**
- ⚠️ [Finding 1]
- ⚠️ [Finding 2]

**Next Steps:**
1. [Step 1]
2. [Step 2]

**Commits:**
- `hash` - message
```

---

## 📞 Emergency Contacts

**Critical Build Issues:**
- Check `.copilot/error-solutions.md` first
- Run `fix-merge-conflicts.py` for merge issues
- Review GitHub Actions logs

**Standards Questions:**
- DIN 18041: https://www.din.de
- ISO 3382: https://www.iso.org
- PTB Calibration: https://www.ptb.de

---

## 🏆 Success Metrics

Track Claude's effectiveness:
- **Code Quality:** Reduced duplications, no merge conflicts
- **Standards Compliance:** DIN/ISO conformance
- **Documentation:** Comprehensive reports generated
- **Knowledge Transfer:** Clear handoffs between sessions

---

**This configuration enables Claude to provide maximum value to the RT60 project while maintaining coordination with GitHub Copilot and human developers.**
