import os
import re

lib_dir = 'lib'
icon_pattern = re.compile(r'(?<![A-Za-z0-9_])Icons\.([A-Za-z0-9_]+)')

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

print("Actual exceptions (bare icons):")
exceptions = set()
for icon, paths in icons_found.items():
    if not icon.endswith('_rounded') and not icon.endswith('_outlined') and not icon.endswith('_sharp'):
        print(f"{icon}: found {len(paths)} times")
        exceptions.add(icon)
