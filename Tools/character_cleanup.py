#!/usr/bin/env python3
"""
Character Cleanup Utility
=========================

This script identifies and removes disruptive characters from text files.
It checks for:
- Zero-width characters (ZWSP, ZWNJ, ZWJ, etc.)
- Non-breaking spaces and special spaces
- BOM (Byte Order Mark)
- Soft hyphens and formatting characters
- Directional formatting characters
- Control characters
- Mixed line endings
- Trailing whitespace

Usage:
    python3 character_cleanup.py [--check-only] [--fix]
"""

import os
import sys
import argparse
from pathlib import Path

# Define disruptive characters to remove
DISRUPTIVE_CHARS = {
    # Zero-width characters
    '\u200B': 'Zero Width Space',
    '\u200C': 'Zero Width Non-Joiner',
    '\u200D': 'Zero Width Joiner',
    '\uFEFF': 'Zero Width No-Break Space/BOM',
    '\u2060': 'Word Joiner',
    '\u180E': 'Mongolian Vowel Separator',

    # Directional formatting (can cause security issues)
    '\u202A': 'Left-To-Right Embedding',
    '\u202B': 'Right-To-Left Embedding',
    '\u202C': 'Pop Directional Formatting',
    '\u202D': 'Left-To-Right Override',
    '\u202E': 'Right-To-Left Override',
    '\u2066': 'Left-To-Right Isolate',
    '\u2067': 'Right-To-Left Isolate',
    '\u2068': 'First Strong Isolate',
    '\u2069': 'Pop Directional Isolate',

    # Line/paragraph separators (should use \n instead)
    '\u2028': 'Line Separator',
    '\u2029': 'Paragraph Separator',
}

# Characters to potentially replace
REPLACEABLE_CHARS = {
    '\u00A0': ' ',  # Non-Breaking Space -> Normal Space
    '\u00AD': '',   # Soft Hyphen -> Remove
    '\u2002': ' ',  # En Space -> Normal Space
    '\u2003': ' ',  # Em Space -> Normal Space
    '\u2004': ' ',  # Three-Per-Em Space -> Normal Space
    '\u2005': ' ',  # Four-Per-Em Space -> Normal Space
    '\u2006': ' ',  # Six-Per-Em Space -> Normal Space
    '\u2007': ' ',  # Figure Space -> Normal Space
    '\u2008': ' ',  # Punctuation Space -> Normal Space
    '\u2009': ' ',  # Thin Space -> Normal Space
    '\u200A': ' ',  # Hair Space -> Normal Space
    '\u202F': ' ',  # Narrow No-Break Space -> Normal Space
    '\u205F': ' ',  # Medium Mathematical Space -> Normal Space
}

# File extensions to process
TEXT_EXTENSIONS = {
    '.swift', '.md', '.yml', '.yaml', '.json', '.txt',
    '.py', '.sh', '.xml', '.plist', '.strings', '.h', '.m'
}


def check_file(filepath):
    """Check a file for disruptive characters."""
    try:
        with open(filepath, 'rb') as f:
            content = f.read()

        # Try to decode as UTF-8
        try:
            text = content.decode('utf-8')
        except UnicodeDecodeError:
            return {'encoding_error': 'Not valid UTF-8'}

        issues = {}

        # Check for BOM at start of file
        if content.startswith(b'\xef\xbb\xbf'):
            issues['UTF-8 BOM'] = 1

        # Check for disruptive characters
        for char, name in DISRUPTIVE_CHARS.items():
            if char in text:
                issues[name] = text.count(char)

        # Check for replaceable characters
        for char, _ in REPLACEABLE_CHARS.items():
            if char in text:
                issues[f'Replaceable: {REPLACEABLE_CHARS[char]!r} ({char!r})'] = text.count(char)

        # Check for control characters (except allowed ones)
        control_chars = []
        for c in text:
            code = ord(c)
            if code < 32 and c not in ['\n', '\r', '\t']:
                control_chars.append(hex(code))
        if control_chars:
            issues['Control characters'] = len(control_chars)

        # Check line endings
        has_crlf = '\r\n' in text
        has_lf_only = '\n' in text.replace('\r\n', '')
        if has_crlf and has_lf_only:
            issues['Mixed line endings'] = 'CRLF and LF'
        elif has_crlf:
            issues['Line endings'] = 'CRLF (should be LF)'

        # Check for trailing whitespace
        lines = text.split('\n')
        trailing_count = sum(1 for line in lines if line.rstrip() != line.rstrip('\r').rstrip(' \t'))
        if trailing_count > 0:
            issues['Trailing whitespace'] = f'{trailing_count} lines'

        # Check for missing final newline
        if text and not text.endswith('\n'):
            issues['Missing final newline'] = True

        return issues if issues else None

    except Exception as e:
        return {'error': str(e)}


def fix_file(filepath):
    """Fix disruptive characters in a file."""
    try:
        with open(filepath, 'rb') as f:
            content = f.read()

        # Remove BOM if present
        if content.startswith(b'\xef\xbb\xbf'):
            content = content[3:]

        # Decode
        text = content.decode('utf-8')

        # Remove disruptive characters
        for char in DISRUPTIVE_CHARS.keys():
            text = text.replace(char, '')

        # Replace problematic characters
        for char, replacement in REPLACEABLE_CHARS.items():
            text = text.replace(char, replacement)

        # Remove control characters (except \n, \r, \t)
        cleaned_chars = []
        for c in text:
            code = ord(c)
            if code >= 32 or c in ['\n', '\r', '\t']:
                cleaned_chars.append(c)
        text = ''.join(cleaned_chars)

        # Normalize line endings to LF
        text = text.replace('\r\n', '\n').replace('\r', '\n')

        # Remove trailing whitespace from each line
        lines = text.split('\n')
        lines = [line.rstrip() for line in lines]
        text = '\n'.join(lines)

        # Ensure file ends with newline (per .editorconfig)
        if text and not text.endswith('\n'):
            text += '\n'

        # Write back
        with open(filepath, 'wb') as f:
            f.write(text.encode('utf-8'))

        return True

    except Exception as e:
        print(f"Error fixing {filepath}: {e}", file=sys.stderr)
        return False


def scan_repository(root_dir, check_only=True):
    """Scan repository for files with issues."""
    root_path = Path(root_dir)
    results = {}
    fixed_count = 0

    for filepath in root_path.rglob('*'):
        # Skip directories and .git
        if filepath.is_dir() or '.git' in filepath.parts:
            continue

        # Only process text files
        if filepath.suffix not in TEXT_EXTENSIONS:
            continue

        issues = check_file(filepath)
        if issues:
            rel_path = filepath.relative_to(root_path)
            results[str(rel_path)] = issues

            if not check_only:
                if fix_file(filepath):
                    fixed_count += 1

    return results, fixed_count


def main():
    parser = argparse.ArgumentParser(description='Identify and remove disruptive characters from text files')
    parser.add_argument('--fix', action='store_true', help='Fix issues (default is check-only)')
    parser.add_argument('--check-only', action='store_true', help='Only check for issues (default)')
    args = parser.parse_args()

    check_only = not args.fix
    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    print(f"Scanning repository: {root_dir}")
    print(f"Mode: {'CHECK ONLY' if check_only else 'FIX'}\n")

    results, fixed_count = scan_repository(root_dir, check_only)

    if results:
        print(f"Found {len(results)} files with issues:\n")
        for filepath, issues in sorted(results.items()):
            print(f"{filepath}:")
            for issue_type, count in issues.items():
                print(f"  - {issue_type}: {count}")
            print()

        if not check_only:
            print(f"\nFixed {fixed_count} files")
        else:
            print(f"\nRun with --fix to automatically fix these issues")

        return 1
    else:
        print("✓ No disruptive characters found in any files")
        print("✓ All files are clean and compliant")
        return 0


if __name__ == '__main__':
    sys.exit(main())
