#!/usr/bin/env python3
"""Fix GlassyToast.show(...)); -> GlassyToast.show(...); across all files."""
import re
import glob

pattern = re.compile(r'(GlassyToast\.show\([^;]*)\)\);')

import os
os.chdir('/Users/rahulhajare/Documents/dev/flutter/c-billing')

total_fixes = 0
for f in glob.glob('lib/**/*.dart', recursive=True):
    with open(f, 'r') as fh:
        content = fh.read()
    new_content, count = pattern.subn(r'\1);', content)
    if count > 0:
        with open(f, 'w') as fh:
            fh.write(new_content)
        total_fixes += count
        print(f'  Fixed {count} in {f}')

print(f'\nTotal fixes: {total_fixes}')
