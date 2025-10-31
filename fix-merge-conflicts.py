#!/usr/bin/env python3
"""
Automated Merge Conflict Cleanup Script
Removes git merge markers and duplicate code blocks from Swift files
"""

import re
import os
from pathlib import Path

def clean_merge_conflicts(file_path):
    """Remove merge conflict markers from a Swift file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # Remove copilot branch markers
    content = re.sub(r'^copilot/fix-[a-f0-9-]+\s*$', '', content, flags=re.MULTILINE)

    # Remove standalone 'main' lines that are merge markers
    lines = content.split('\n')
    cleaned_lines = []
    for i, line in enumerate(lines):
        # Skip 'main' if it's a standalone line and likely a merge marker
        if line.strip() == 'main':
            # Check context: skip if surrounded by whitespace or other markers
            if i > 0 and i < len(lines) - 1:
                prev_stripped = lines[i-1].strip()
                next_stripped = lines[i+1].strip() if i+1 < len(lines) else ""
                # Skip if it looks like a merge marker
                if prev_stripped == "" or next_stripped == "" or prev_stripped.startswith('}'):
                    continue
        cleaned_lines.append(line)

    content = '\n'.join(cleaned_lines)

    # Remove excessive blank lines (more than 2 consecutive)
    content = re.sub(r'\n{4,}', '\n\n\n', content)

    # Write back only if changed
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    """Find and clean all Swift files with merge conflicts"""
    base_dir = Path('.')
    swift_files = list(base_dir.glob('**/*.swift'))

    fixed_count = 0
    for swift_file in swift_files:
        if clean_merge_conflicts(swift_file):
            print(f"✅ Fixed: {swift_file}")
            fixed_count += 1

    print(f"\n🎉 Fixed {fixed_count} files with merge conflicts")

if __name__ == '__main__':
    main()
