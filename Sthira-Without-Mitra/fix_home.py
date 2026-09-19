import re

with open('lib/screens/home/home_screen.dart', 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace(\"import '../../theme/app_colors.dart';\", \"import '../../theme/app_colors.dart';\nimport '../../theme/app_spacing.dart';\")
c = c.replace(\"const SizedBox(height: 24)\", \"const SizedBox(height: Spacing.section)\")
c = c.replace(\"const SizedBox(height: 12)\", \"const SizedBox(height: Spacing.stack)\")
c = c.replace(\"const SizedBox(height: 20)\", \"const SizedBox(height: Spacing.section)\")
c = c.replace(\"const SizedBox(height: 100)\", \"const SizedBox(height: kShellScrollBottomPadding)\")

c = re.sub(r'const Align\(alignment: Alignment\.topCenter\),\s*', '', c)

with open('lib/screens/home/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(c)

