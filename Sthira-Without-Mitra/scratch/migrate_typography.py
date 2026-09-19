import os
import re
import sys

def parse_textstyle(content, start_idx):
    # Find the end of the TextStyle(...) block
    open_parens = 0
    in_string = False
    string_char = ''
    i = start_idx
    while i < len(content):
        c = content[i]
        if in_string:
            if c == '\\':
                i += 2
                continue
            if c == string_char:
                in_string = False
        else:
            if c in ["'", '"']:
                in_string = True
                string_char = c
            elif c == '(':
                open_parens += 1
            elif c == ')':
                open_parens -= 1
                if open_parens == 0:
                    return i
        i += 1
    return -1

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    offset = 0
    while True:
        # Find next const TextStyle or TextStyle
        match = re.search(r'(const\s+)?TextStyle\s*\(', content[offset:])
        if not match:
            break
        
        start_idx = offset + match.end() - 1 # points to (
        end_idx = parse_textstyle(content, start_idx)
        if end_idx == -1:
            break
            
        full_match_start = offset + match.start()
        full_match_end = end_idx + 1
        
        block = content[start_idx+1:end_idx]
        
        # Extract properties
        font_size_m = re.search(r'fontSize:\s*([\d.]+)', block)
        font_weight_m = re.search(r'fontWeight:\s*(FontWeight\.\w+)', block)
        color_m = re.search(r'color:\s*([^,]+)', block)
        
        fs = float(font_size_m.group(1)) if font_size_m else None
        fw = font_weight_m.group(1) if font_weight_m else None
        c = color_m.group(1).strip() if color_m else None
        
        # Determine token
        token = None
        if fs == 14:
            token = 'body'
        elif fs == 13:
            token = 'caption'
        elif fs == 12:
            token = 'caption' if 'w500' in (fw or '') or 'w400' in (fw or '') else 'micro'
        elif fs == 16:
            token = 'bodyStrong' if fw == 'FontWeight.w700' else 'bodyStrong'
        elif fs in [10, 9, 11]:
            token = 'micro'
        elif fs in [17, 18]:
            token = 'cardTitle'
        elif fs in [15]:
            token = 'bodyStrong' if 'w7' in str(fw) or 'bold' in str(fw) else 'body'
        elif fs in [20, 22, 24, 26]:
            token = 'screenTitle'
        elif fs in [28, 32]:
            token = 'display'
        elif fs and fs >= 40:
            token = 'metric'
        else:
            token = 'body' # Default fallback
            
        if token:
            replacement = f'context.text.{token}'
            if c:
                replacement += f'.copyWith(color: {c})'
            
            # print(f"{filepath}: replaced {fs}/{fw} with {replacement}")
            
            content = content[:full_match_start] + replacement + content[full_match_end:]
            offset = full_match_start + len(replacement)
        else:
            offset = full_match_end

    if content != original_content:
        # Check if we need to add import
        if 'app_typography.dart' not in content:
            # find last import
            imports = list(re.finditer(r'^import\s+.*;', content, re.MULTILINE))
            if imports:
                last_import = imports[-1]
                
                # Determine relative path correctly based on filepath
                # Assuming lib/widgets/.. etc.
                rel_path = '../theme/app_typography.dart'
                if 'theme\\' in filepath or 'theme/' in filepath:
                    rel_path = 'app_typography.dart'
                elif filepath.count('\\') > 3 or filepath.count('/') > 3:
                     # Very naive, but we can fix later
                     pass
                     
                insert_pos = last_import.end()
                content = content[:insert_pos] + f"\nimport 'package:trufit_bodamma/theme/app_typography.dart';" + content[insert_pos:]
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

if __name__ == '__main__':
    for path in sys.argv[1:]:
        if os.path.isfile(path) and path.endswith('.dart'):
            process_file(path)
        elif os.path.isdir(path):
            for root, dirs, files in os.walk(path):
                for f in files:
                    if f.endswith('.dart'):
                        process_file(os.path.join(root, f))
