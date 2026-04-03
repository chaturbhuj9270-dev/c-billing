#!/usr/bin/env python3
"""Fix broken GlassyToast patterns across the codebase."""
import re
import os

os.chdir('/Users/rahulhajare/Documents/dev/flutter/c-billing')

fixes = []

# Fix 1: ${e.toString( -> ${e.toString()} (missing closing paren and brace)
# Pattern: GlassyToast.show(context, '...${e.toString(, isError: true);
def fix_broken_tostring(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    # Fix: ${e.toString( followed by , (missing )}' before the ,)
    new_content = re.sub(
        r"(\$\{e\.toString\()(, isError)",
        r"${e.toString()}\1_REPLACED_",
        content
    )
    # Actually let me be more precise
    new_content = content
    # Pattern: '...${e.toString(, isError: true);  ->  '...${e.toString()}', isError: true);
    new_content = re.sub(
        r"'([^']*)\$\{e\.toString\(, isError: (true|false)\);",
        r"'\1${e.toString()}', isError: \2);",
        new_content
    )
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        return True
    return False

# Files with broken toString
tostring_files = [
    'lib/core/ui/splash_page.dart',
    'lib/features/shop/presentation/pages/shop_details_page.dart',
    'lib/features/authentication/presentation/pages/change_password_page.dart',
    'lib/features/customer/presentation/pages/customer_detail_page.dart',
    'lib/features/customer/presentation/pages/customer_add_edit_page.dart',
]

for f in tostring_files:
    if fix_broken_tostring(f):
        print(f'  Fixed toString in {f}')
    else:
        print(f'  No match in {f}')

# Fix 2: result.message ??, -> result.message ?? 'Error',
def fix_broken_nullcoalesce(filepath, line_num):
    with open(filepath, 'r') as f:
        lines = f.readlines()
    idx = line_num - 1
    if idx < len(lines):
        old = lines[idx]
        new = old.replace('result.message ??,', "result.message ?? 'Error',")
        if old != new:
            lines[idx] = new
            with open(filepath, 'w') as f:
                f.writelines(lines)
            print(f'  Fixed null coalesce in {filepath}:{line_num}')
            return True
    print(f'  No match for null coalesce in {filepath}:{line_num}')
    return False

fix_broken_nullcoalesce('lib/features/billing/presentation/pages/return_bill_page.dart', 450)
fix_broken_nullcoalesce('lib/common_widgets/print_bill_button.dart', 274)

print('\nDone!')
