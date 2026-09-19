import os
import re

lib_dir = 'lib'
icon_pattern = re.compile(r'Icons\.([a-zA-Z0-9_]+)')

icons_found = {}

for root, _, files in os.walk(lib_dir):
    for f in files:
        if f.endswith('.dart'):
            filepath = os.path.join(root, f)
            with open(filepath, 'r', encoding='utf-8') as file:
                lines = file.readlines()
                for line_num, line in enumerate(lines, 1):
                    matches = icon_pattern.findall(line)
                    for match in matches:
                        if match not in icons_found:
                            icons_found[match] = []
                        icons_found[match].append(filepath)

print("Exceptions (bare icons):")
exceptions = set()
for icon, paths in icons_found.items():
    if not icon.endswith('_rounded') and not icon.endswith('_outlined') and not icon.endswith('_sharp'):
        print(f"{icon}: found in {len(paths)} places")
        exceptions.add(icon)

print("\narrow_back_ios variations:")
for icon, paths in icons_found.items():
    if 'arrow_back_' in icon or 'chevron_' in icon:
        print(f"{icon}: found in {len(paths)} places")
