# Claude-Specific Prompts for RT60 Project

**Purpose:** Task-specific guidance for Claude AI sessions

---

## 🎯 Task Templates

### Code Review Session

```prompt
You are conducting a comprehensive code review of the RT60 AcoustiScan iPad app.

CONTEXT:
- Professional acoustic measurement tool
- Must comply with DIN 18041:2016 and ISO 3382-2:2008
- Target: DACH region (court-admissible reports)

YOUR TASKS:
1. Identify merge conflicts and code duplication
2. Verify RT60 calculation correctness (Sabine formula)
3. Check DIN 18041 compliance
4. Review Swift best practices
5. Assess test coverage
6. Generate comprehensive report

DELIVERABLES:
- List of issues with severity (🔴 HIGH, 🟡 MEDIUM, 🟢 LOW)
- Code fixes with explanations
- Markdown report (REVIEW_YYYY-MM-DD.md)
- Commit with detailed message

STANDARDS TO CHECK:
- Sabine formula: RT60 = 0.161 × V/A
- DIN 18041 tolerance: ±20% relative (NOT absolute)
- DIN 18041 volume formula: T = 0.32×log₁₀(V/V₀)+0.17
- ISO 3382-2 metadata requirements
```

---

### Standards Compliance Analysis

```prompt
Analyze compliance with DIN 18041:2016 and ISO 3382-2:2008 standards.

RESEARCH TASKS:
1. Web search for latest DIN 18041 requirements (2024/2025)
2. Verify ISO 3382-2 measurement procedures
3. Check DACH-specific legal requirements
4. Research calibration standards (PTB, DAkkS)

ANALYSIS TASKS:
1. Compare code implementation vs. standard requirements
2. Identify deviations and their severity
3. Calculate impact on court-admissibility
4. List missing metadata fields

DELIVERABLES:
- Standards compliance report
- Gap analysis with priorities
- Implementation recommendations
- Legal requirements checklist
```

---

### Documentation Generation

```prompt
Create comprehensive documentation for the RT60 project.

TARGET AUDIENCES:
1. Developers (technical)
2. Acousticians (domain experts)
3. End users (iPad users)
4. Legal reviewers (court experts)

DOCUMENTS TO CREATE:
1. README.md (project overview, quick start)
2. API_DOCUMENTATION.md (code reference)
3. USER_MANUAL.md (German + English)
4. LEGAL_COMPLIANCE.md (standards, regulations)

STYLE GUIDELINES:
- Clear and concise
- Use diagrams where helpful (Mermaid/ASCII)
- Include examples and use cases
- Reference standards with URLs
- Provide troubleshooting sections
```

---

### Architecture Refactoring

```prompt
Analyze and refactor architecture for improved maintainability.

ANALYSIS AREAS:
1. Module boundaries and cohesion
2. Code duplication (DRY violations)
3. Design patterns usage
4. Testability
5. Performance bottlenecks

REFACTORING PRINCIPLES:
- Maintain backward compatibility
- Preserve RT60 calculation accuracy
- Keep existing tests passing
- Document all changes
- Use Swift best practices

DELIVERABLES:
- Architecture analysis report
- Refactoring plan with phases
- Code changes with tests
- Migration guide if needed
```

---

### Bug Investigation

```prompt
Investigate and fix a reported bug in the RT60 app.

INVESTIGATION STEPS:
1. Reproduce the issue
2. Analyze stack traces and logs
3. Identify root cause
4. Review related code
5. Check for similar issues elsewhere

FIX REQUIREMENTS:
- Minimal change scope
- Add regression test
- Verify no side effects
- Document the fix
- Update error-solutions.md

COMMIT MESSAGE FORMAT:
```
Fix: [Brief description]

**Issue:** [Detailed problem description]
**Root Cause:** [What was wrong]
**Solution:** [What was changed]
**Testing:** [How it was verified]
**Impact:** [Who is affected, migration needed?]
```
```

---

### Performance Optimization

```prompt
Optimize performance of RT60 calculations and rendering.

PROFILING TASKS:
1. Identify bottlenecks (CPU, memory, I/O)
2. Measure current performance metrics
3. Set optimization targets
4. Benchmark improvements

OPTIMIZATION AREAS:
- RT60 calculation loops
- PDF rendering (large reports)
- Audio processing callbacks
- UI responsiveness

CONSTRAINTS:
- Maintain accuracy (acoustic calculations)
- Keep real-time capability (<10ms audio latency)
- No algorithm changes without verification
- Document performance gains
```

---

## 🧪 Testing Prompts

### Test Coverage Analysis

```prompt
Analyze test coverage and identify gaps.

ANALYSIS:
1. Current coverage: 69 tests (58 AcoustiScan + 11 Export)
2. Coverage percentage per module
3. Untested critical paths
4. Missing edge cases

RECOMMENDATIONS:
- Which tests to add (priority order)
- What edge cases to cover
- Integration test scenarios
- Performance test cases
```

### Test Writing

```prompt
Write comprehensive tests for [COMPONENT].

TEST TYPES:
1. Unit tests (isolated functionality)
2. Integration tests (component interaction)
3. Snapshot tests (PDF/HTML rendering)
4. Property-based tests (QuickCheck style)

TEST CASES TO COVER:
- Happy path
- Edge cases (empty, nil, extremes)
- Error conditions
- Boundary values
- Regression scenarios

ASSERTIONS:
- Acoustic accuracy (RT60 within tolerance)
- DIN 18041 compliance
- Data integrity
- Performance targets
```

---

## 📋 Standard Checklists

### Pre-Commit Checklist

Before committing changes:
- [ ] Code compiles without warnings
- [ ] All tests pass (swift test)
- [ ] SwiftLint/SwiftFormat satisfied
- [ ] No merge conflict markers
- [ ] No code duplication
- [ ] RT60 accuracy verified
- [ ] DIN compliance maintained
- [ ] Documentation updated
- [ ] Commit message is descriptive

### Pre-PR Checklist

Before creating pull request:
- [ ] Branch is up-to-date with main
- [ ] All commits are atomic and well-described
- [ ] CHANGELOG updated (if applicable)
- [ ] Breaking changes documented
- [ ] Tests cover new functionality
- [ ] CI/CD passes
- [ ] Screenshots added (if UI changes)
- [ ] Reviewed own changes

### Production Release Checklist

Before releasing to production:
- [ ] All critical issues resolved
- [ ] DIN 18041 formulas correct
- [ ] ISO 3382-2 metadata complete
- [ ] Legal compliance verified
- [ ] User documentation complete
- [ ] App Store assets ready
- [ ] TestFlight beta tested
- [ ] Performance benchmarks met
- [ ] Crash reporting configured

---

## 🎨 Communication Style

### For Technical Audience
- Use precise terminology
- Include code examples
- Reference line numbers and files
- Provide architectural diagrams
- Link to standards documents

### For Domain Experts (Acousticians)
- Explain acoustic theory clearly
- Reference DIN/ISO standards
- Use proper units (dB, Hz, seconds)
- Validate against known measurements
- Discuss measurement uncertainty

### For Legal Reviewers
- Focus on compliance aspects
- List all applicable standards
- Document traceability
- Explain calibration procedures
- Provide certification paths

---

## 🚨 Emergency Response Prompts

### Build Failure

```prompt
The build is failing in CI/CD.

IMMEDIATE ACTIONS:
1. Check GitHub Actions logs
2. Identify failing step (lint/build/test)
3. Reproduce locally
4. Apply quick fix if possible
5. Escalate if complex

RESOURCES:
- .copilot/error-solutions.md
- fix-merge-conflicts.py script
- Build logs: [link]
```

### Merge Conflict

```prompt
Multiple merge conflicts detected after branch merge.

RESOLUTION STRATEGY:
1. Run fix-merge-conflicts.py (automated)
2. Manually review complex conflicts
3. Verify no code duplication
4. Run full test suite
5. Commit with clear message

CONFLICT MARKERS TO FIND:
- copilot/fix-[hash]
- main
- <<<<<<< HEAD
- =======
- >>>>>>>
```

### Test Regression

```prompt
Previously passing tests now failing.

INVESTIGATION:
1. Identify failing tests
2. Review recent changes (git log)
3. Check for dependency updates
4. Isolate breaking change
5. Revert or fix forward

ROLLBACK PROCEDURE:
git revert [commit-hash]
# OR
git reset --hard [last-good-commit]
git push --force-with-lease
```

---

## 📚 Learning Resources

### For New Claude Sessions

**First Time on Project:**
1. Read `.claude/README.md` (overview)
2. Read `.claude/project-context.md` (deep context)
3. Read `PRODUCTION_READINESS_REPORT.md` (current state)
4. Review last 10 git commits
5. Check open issues on GitHub

**Before Making Changes:**
1. Read affected files completely
2. Run tests to establish baseline
3. Check .copilot/ rules for alignment
4. Plan changes with minimal scope

**Before Committing:**
1. Use Pre-Commit Checklist (above)
2. Write detailed commit message
3. Update .claude/project-context.md if major change

---

**These prompts ensure consistent, high-quality Claude sessions across different tasks and team members.**
