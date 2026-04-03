#!/usr/bin/env python3
"""
Replace all ScaffoldMessenger.of(context).showSnackBar(...) calls with GlassyToast.show()
and replace hideCurrentSnackBar()/clearSnackBars() with GlassyToast.dismiss().
Also update _showSnackbar/_showSnackBar wrapper methods.
"""
import re
import os

BASE = "/Users/rahulhajare/Documents/dev/flutter/c-billing"
IMPORT_LINE = "import 'package:c_billing/core/ui/glassy_toast.dart';"

# Files to process (skip .bak, .g.dart, glassy_toast.dart itself)
def get_dart_files():
    result = []
    for root, dirs, files in os.walk(os.path.join(BASE, "lib")):
        for f in files:
            if f.endswith(".dart") and not f.endswith(".g.dart") and not f.endswith(".bak") and f != "glassy_toast.dart":
                path = os.path.join(root, f)
                result.append(path)
    return result

def add_import_if_needed(content):
    """Add GlassyToast import if not already present."""
    if IMPORT_LINE in content:
        return content
    # Add after last existing import
    lines = content.split('\n')
    last_import_idx = -1
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("import ") and stripped.endswith(";"):
            last_import_idx = i
    if last_import_idx >= 0:
        lines.insert(last_import_idx + 1, IMPORT_LINE)
    else:
        lines.insert(0, IMPORT_LINE)
    return '\n'.join(lines)

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    has_scaffold_messenger = 'ScaffoldMessenger.of' in content
    
    if not has_scaffold_messenger:
        return False
    
    # === STEP 1: Replace _showSnackbar/_showSnackBar wrapper method bodies ===
    # These are the 6 files with wrapper methods. Replace the entire method body
    # to delegate to GlassyToast
    
    # Pattern for billing_page.dart style wrapper (has SnackBarAction parameter)
    # We'll handle wrapper methods by replacing their bodies
    
    # === STEP 2: Replace hideCurrentSnackBar() and clearSnackBars() ===
    content = re.sub(
        r'ScaffoldMessenger\.of\(context\)\.hideCurrentSnackBar\(\);',
        'GlassyToast.dismiss();',
        content
    )
    content = re.sub(
        r'ScaffoldMessenger\.of\(context\)\.clearSnackBars\(\);',
        'GlassyToast.dismiss();',
        content
    )

    # === STEP 3: Replace various ScaffoldMessenger.of(context).showSnackBar patterns ===
    
    # Pattern A: Simple SnackBar(content: Text(msg))
    # ScaffoldMessenger.of(context).showSnackBar(
    #   SnackBar(content: Text(msg)),
    # );
    # OR multi-line ScaffoldMessenger.of(\n  context,\n).showSnackBar(SnackBar(content: Text(msg)));
    
    # First handle multi-line ScaffoldMessenger.of(\n  context,\n)
    content = re.sub(
        r'ScaffoldMessenger\.of\(\s*\n\s*context,?\s*\n\s*\)',
        'ScaffoldMessenger.of(context)',
        content
    )
    
    # Now all are single-line ScaffoldMessenger.of(context)
    
    # Pattern: Simple SnackBar with just content: Text(...)
    # Match: ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(EXPR)));
    # or with trailing comma variations
    
    # Pattern for simple one-line-ish snackbars: SnackBar(content: Text(expr))
    # We need to handle nested parens in the Text() arg
    
    def replace_simple_snackbar(match):
        """Replace ScaffoldMessenger.of(context).showSnackBar(\n  SnackBar(content: Text(msg)),\n);"""
        full = match.group(0)
        # Extract the text content
        text_match = re.search(r'Text\((.*?)\)(?:\s*,)?\s*\)', full, re.DOTALL)
        if text_match:
            msg = text_match.group(1).strip()
            # Remove trailing comma if present
            msg = msg.rstrip(',')
            return f'GlassyToast.show(context, {msg});'
        return full
    
    # Handle styled SnackBars (with backgroundColor, behavior, etc.)
    # These wrapper methods create styled snackbars. 
    # We need to detect isError from backgroundColor
    
    def extract_snackbar_info(snackbar_block):
        """Extract message and isError from a SnackBar block."""
        # Try to find the text content
        # Look for content: Text(msg, ...) or content: Row(children:[Icon(...), Text(msg)])
        msg = None
        is_error = False
        
        # Simple: content: Text(MSG)
        text_match = re.search(r'content:\s*Text\(([^,\)]+)', snackbar_block)
        if text_match:
            msg = text_match.group(1).strip()
        
        # Row with Icon + Text pattern
        if msg is None:
            text_match = re.search(r'Text\(\s*\n?\s*(.*?)\s*[,\)]', snackbar_block)
            if text_match:
                msg = text_match.group(1).strip()
        
        # Detect error from backgroundColor
        if 'Colors.red' in snackbar_block or 'red' in snackbar_block.lower():
            if 'isError' not in snackbar_block:
                is_error = True
        
        return msg, is_error
    
    # We need a more robust approach. Let me use a char-by-char parser to find
    # balanced parentheses for the showSnackBar(...) call.
    
    def find_balanced_paren(text, start):
        """Find the matching closing paren for the opening paren at `start`."""
        depth = 0
        i = start
        while i < len(text):
            if text[i] == '(':
                depth += 1
            elif text[i] == ')':
                depth -= 1
                if depth == 0:
                    return i
            elif text[i] == "'" or text[i] == '"':
                # Skip string literals
                quote = text[i]
                i += 1
                while i < len(text) and text[i] != quote:
                    if text[i] == '\\':
                        i += 1
                    i += 1
            i += 1
        return -1
    
    def replace_all_showsnackbar(text):
        """Replace all ScaffoldMessenger.of(context).showSnackBar(...) calls."""
        result = []
        i = 0
        pattern = 'ScaffoldMessenger.of(context).showSnackBar('
        
        while i < len(text):
            idx = text.find(pattern, i)
            if idx == -1:
                result.append(text[i:])
                break
            
            result.append(text[i:idx])
            
            # Find the opening paren of showSnackBar(
            paren_start = idx + len(pattern) - 1
            paren_end = find_balanced_paren(text, paren_start)
            
            if paren_end == -1:
                # Can't find matching paren, keep original
                result.append(text[idx:idx + len(pattern)])
                i = idx + len(pattern)
                continue
            
            # Extract the full showSnackBar(...) content
            snackbar_content = text[paren_start + 1:paren_end].strip()
            
            # Find the trailing semicolon
            after = text[paren_end + 1:paren_end + 10].lstrip()
            
            # Now parse the SnackBar content
            # Check if it's a simple SnackBar(content: Text(msg))
            
            # Try simple pattern first
            simple_match = re.match(
                r'\s*SnackBar\s*\(\s*content:\s*Text\((.+?)\)\s*,?\s*\)\s*,?\s*$',
                snackbar_content,
                re.DOTALL
            )
            
            if simple_match:
                msg = simple_match.group(1).strip()
                # Check if Text() has style arg
                # Text(msg, style: ...) -> extract just msg
                if ',\n' in msg or ', style:' in msg:
                    msg_parts = msg.split(',')
                    msg = msg_parts[0].strip()
                msg = msg.rstrip(',')
                replacement = f'GlassyToast.show(context, {msg})'
                result.append(replacement)
                i = paren_end + 1
                continue
            
            # Complex SnackBar with styling
            # Try to extract message and error state
            msg_text = None
            is_error = None
            has_action = 'action:' in snackbar_content or 'SnackBarAction' in snackbar_content
            
            # Skip SnackBars with actions - keep them as-is (rare, only used for undo)
            if has_action:
                result.append(text[idx:paren_end + 1])
                i = paren_end + 1
                continue
            
            # Extract Text content - handle both simple and Row patterns
            # Pattern: content: Text(MSG, style: ...)
            text_match = re.search(r'content:\s*Text\(([^,\)]+)', snackbar_content)
            if text_match:
                msg_text = text_match.group(1).strip()
            
            # Pattern: content: Row(children: [..., Text(MSG, ...), ...])
            if msg_text is None:
                # Look for Expanded(child: Text(MSG))
                text_match = re.search(r'child:\s*Text\(\s*\n?\s*([^,\)\n]+)', snackbar_content)
                if text_match:
                    msg_text = text_match.group(1).strip()
            
            if msg_text is None:
                # Last resort - find any Text(MSG) 
                text_match = re.search(r'Text\(([^,\)\n]+)', snackbar_content)
                if text_match:
                    msg_text = text_match.group(1).strip()
            
            # Determine error state
            if 'Colors.red' in snackbar_content:
                is_error = True
            elif 'Color(0xFF1B4D3E)' in snackbar_content or 'Colors.green' in snackbar_content or '_kGreen' in snackbar_content or '_successColor' in snackbar_content:
                is_error = False
            
            if msg_text:
                if is_error is True:
                    replacement = f'GlassyToast.show(context, {msg_text}, isError: true)'
                elif is_error is False:
                    replacement = f'GlassyToast.show(context, {msg_text})'
                else:
                    replacement = f'GlassyToast.show(context, {msg_text})'
                result.append(replacement)
                i = paren_end + 1
                continue
            
            # Couldn't parse - keep original
            result.append(text[idx:paren_end + 1])
            i = paren_end + 1
        
        return ''.join(result)
    
    content = replace_all_showsnackbar(content)
    
    if content != original:
        content = add_import_if_needed(content)
        with open(filepath, 'w') as f:
            f.write(content)
        return True
    return False

def main():
    files = get_dart_files()
    changed = []
    for f in files:
        if process_file(f):
            changed.append(os.path.relpath(f, BASE))
    
    print(f"\nModified {len(changed)} files:")
    for f in sorted(changed):
        print(f"  {f}")

if __name__ == '__main__':
    main()
