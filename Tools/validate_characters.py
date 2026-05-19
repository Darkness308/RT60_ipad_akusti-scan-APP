#!/usr/bin/env python3
"""
Character Validation Script for RT60 iPad AcoustiScan App

This script checks for problematic characters in text files that could cause
build failures, encoding issues, or other problems.

Usage:
    python3 validate_characters.py [directory]

If no directory is specified, checks the current repository root.
"""

import os
import sys
import unicodedata
from pathlib import Path

# Threshold for ASCII control characters
ASCII_CONTROL_THRESHOLD = 32

# Characters to check for
PROBLEMATIC_CHARS = {
    '\u00A0': 'Non-breaking space (NBSP)',
    '\u200B': 'Zero-width space (ZWSP)',
    '\u200C': 'Zero-width non-joiner (ZWNJ)',
    '\u200D': 'Zero-width joiner (ZWJ)',
    '\uFEFF': 'Zero-width no-break space (BOM)',
    '\u2028': 'Line separator',
    '\u2029': 'Paragraph separator',
    '\u202A': 'Left-to-right embedding',
    '\u202B': 'Right-to-left embedding',
    '\u202C': 'Pop directional formatting',
    '\u202D': 'Left-to-right override',
    '\u202E': 'Right-to-left override',
}

# File extensions to check
EXTENSIONS = ('.swift', '.md', '.txt', '.json', '.yml', '.yaml', '.py', '.sh')

# Directories to exclude
EXCLUDE_DIRS = {'.git', '.github', '.copilot', '.claude', 'node_modules', 'build', '.build', '.swiftpm'}


def check_file(filepath):
    """
    Check a file for problematic characters.

    Returns:
        list: List of (issue_type, description, count, line_numbers) tuples
    """
    try:
        with open(filepath, 'rb') as f:
            raw_content = f.read()

        issues = []

        # Check for BOM
        if raw_content.startswith(b'\xef\xbb\xbf'):
            issues.append(('BOM', 'UTF-8 BOM at start of file', 1, [1]))

        # Decode content
        try:
            content = raw_content.decode('utf-8')
        except UnicodeDecodeError as e:
            issues.append(('ENCODING', f'Not valid UTF-8: {e}', 1, []))
            return issues

        # Build line offset map for efficient line number lookup
        line_offsets = [0]  # Start of first line is position 0
        for i, char in enumerate(content):
            if char == '\n':
                line_offsets.append(i + 1)

        def get_line_number(position):
            """Get line number for a character position using binary search."""
            # Binary search would be more efficient, but for simplicity use simple loop
            for line_num, offset in enumerate(line_offsets, 1):
                if line_num == len(line_offsets):
                    return line_num
                if offset <= position < line_offsets[line_num]:
                    return line_num
            return len(line_offsets)

        # Check for problematic Unicode characters
        for char, description in PROBLEMATIC_CHARS.items():
            if char in content:
                positions = [i for i, c in enumerate(content) if c == char]
                line_numbers = [get_line_number(pos) for pos in positions[:5]]
                issues.append(('UNICODE', f'{description} (U+{ord(char):04X})', len(positions), line_numbers))

        # Check for control characters (except \n, \t, \r)
        control_chars = []
        for i, char in enumerate(content):
            if ord(char) < ASCII_CONTROL_THRESHOLD and char not in '\n\t\r':
                line_num = get_line_number(i)
                control_chars.append((line_num, ord(char)))

        if control_chars:
            line_numbers = [line for line, _ in control_chars[:5]]
            char_codes = set(code for _, code in control_chars)
            description = f'Control characters: {", ".join(f"0x{c:02x}" for c in sorted(char_codes))}'
            issues.append(('CONTROL', description, len(control_chars), line_numbers))

        # Check for CRLF line endings
        if '\r\n' in content:
            crlf_count = content.count('\r\n')
            issues.append(('LINE-ENDING', 'CRLF line endings (should be LF)', crlf_count, []))

        # Check for CR-only line endings
        if '\r' in content.replace('\r\n', ''):
            cr_count = content.replace('\r\n', '').count('\r')
            issues.append(('LINE-ENDING', 'CR line endings (should be LF)', cr_count, []))

        return issues

    except Exception as e:
        return [('ERROR', f'Error reading file: {e}', 0, [])]


def main():
    # Determine root directory
    if len(sys.argv) > 1:
        root_dir = Path(sys.argv[1])
    else:
        # Try to find repository root
        current = Path.cwd()
        while current != current.parent:
            if (current / '.git').exists():
                root_dir = current
                break
            current = current.parent
        else:
            root_dir = Path.cwd()

    print(f"Validating characters in: {root_dir}\n")

    # Scan files
    all_files_checked = 0
    files_with_issues = []

    for dirpath, dirnames, filenames in os.walk(root_dir):
        # Remove excluded directories
        dirnames[:] = [d for d in dirnames if d not in EXCLUDE_DIRS]

        for filename in filenames:
            if filename.endswith(EXTENSIONS):
                filepath = Path(dirpath) / filename
                rel_path = filepath.relative_to(root_dir)

                all_files_checked += 1
                issues = check_file(filepath)
                if issues:
                    files_with_issues.append((str(rel_path), issues))

    # Report results
    print(f"✓ Checked {all_files_checked} files\n")

    if files_with_issues:
        print(f"❌ Found {len(files_with_issues)} files with issues:\n")

        for filepath, issues in sorted(files_with_issues):
            print(f"  File: {filepath}")
            for issue_type, description, count, line_numbers in issues:
                if line_numbers:
                    lines_str = ', '.join(map(str, line_numbers))
                    if count > len(line_numbers):
                        lines_str += f" (+{count - len(line_numbers)} more)"
                    print(f"    [{issue_type}] {description}: {count} occurrences on lines: {lines_str}")
                else:
                    print(f"    [{issue_type}] {description}: {count} occurrences")
            print()

        return 1  # Exit with error code
    else:
        print("✅ No problematic characters found!")
        print("\nAll files have:")
        print("  • Proper UTF-8 encoding")
        print("  • LF line endings")
        print("  • No hidden Unicode characters")
        print("  • No control characters")
        return 0


if __name__ == '__main__':
    sys.exit(main())
