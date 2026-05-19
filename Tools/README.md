# Tools Directory

This directory contains utility scripts and tools for the RT60 iPad AcoustiScan App project.

## Available Tools

### Character Validation Tool

**Script**: `validate_characters.py`

A comprehensive validation tool that checks for problematic characters in source code and documentation files that could cause build failures, encoding issues, or other problems.

#### Usage

```bash
# Check the entire repository (from any location)
python3 Tools/validate_characters.py

# Check a specific directory
python3 Tools/validate_characters.py /path/to/directory
```

#### What it Checks

The script validates the following:

- **Unicode Issues**:
  - Non-breaking spaces (U+00A0)
  - Zero-width spaces (U+200B, U+200C, U+200D)
  - Zero-width no-break space / BOM (U+FEFF)
  - Line/Paragraph separators (U+2028, U+2029)
  - Directional formatting characters (U+202A-U+202E)

- **Encoding Issues**:
  - UTF-8 BOM markers
  - Invalid UTF-8 sequences

- **Line Ending Issues**:
  - CRLF line endings (Windows-style)
  - CR line endings (old Mac-style)
  - Mixed line endings

- **Control Characters**:
  - Unexpected control characters (except newline, tab, carriage return)

#### File Types Checked

- Swift source files (`.swift`)
- Markdown documentation (`.md`)
- JSON configuration files (`.json`)
- YAML configuration files (`.yml`, `.yaml`)
- Python scripts (`.py`)
- Shell scripts (`.sh`)
- Text files (`.txt`)

#### Output

The script provides:
- ✅ Success message if no issues found
- ❌ Detailed report of any issues found, including:
  - File paths
  - Issue types
  - Line numbers
  - Occurrence counts

#### Exit Codes

- `0`: No issues found (success)
- `1`: Issues found (failure)

Can be used in CI/CD pipelines to prevent problematic characters from being committed.

#### Example Output

```
Validating characters in: /home/user/RT60_ipad_akusti-scan-APP

✓ Checked 141 files

✅ No problematic characters found!

All files have:
  • Proper UTF-8 encoding
  • LF line endings
  • No hidden Unicode characters
  • No control characters
```

### Other Tools

- **LogParser**: Tools for parsing and analyzing log files
- **linters**: Code quality and linting tools
- **reporthtml**: HTML report generation utilities
- **rt60log2json**: Convert RT60 logs to JSON format

## Maintenance

These tools are maintained as part of the main project. Please ensure any new tools added to this directory are:
- Well-documented
- Have clear usage instructions
- Include example output
- Are tested before committing

## Related Documentation

- See `CHAR_VALIDATION_REPORT.md` in the repository root for the latest character validation report
- See `.gitattributes` for line ending enforcement rules
- See `.editorconfig` for encoding and formatting standards
