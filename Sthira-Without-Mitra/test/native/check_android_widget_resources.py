#!/usr/bin/env python3
"""Static Android widget/resource checks; does not replace aapt or device tests."""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

ANDROID = "{http://schemas.android.com/apk/res/android}"
RESOURCE_REF = re.compile(r"@(\+?)(?:([\w.]+):)?([\w]+)/([\w.]+)")
LOCAL_TYPES = {"color", "drawable", "font", "layout", "mipmap", "string", "style", "xml"}
REMOTE_VIEWS = {
    "AdapterViewFlipper", "FrameLayout", "GridLayout", "GridView", "LinearLayout",
    "ListView", "RelativeLayout", "StackView", "ViewFlipper", "AnalogClock",
    "Button", "Chronometer", "ImageButton", "ImageView", "ProgressBar",
    "TextClock", "TextView", "ViewStub",
}
REMOTE_VIEWS_31 = {"CheckBox", "RadioButton", "RadioGroup", "Switch"}
SHARED_IDS = {"tv_updated_at", "tv_steps_value", "tv_steps_goal", "pb_steps"}
STANDARD_IDS = SHARED_IDS | {
    "widget_steps_area", "widget_meals_area", "widget_habits_area",
    "tv_meals_value", "tv_habits_value",
}
REQUIRED_IDS = {
    "compact": SHARED_IDS | {"widget_root_compact"},
    "standard": STANDARD_IDS | {"widget_root_standard"},
    "expanded": STANDARD_IDS | {
        "widget_root_expanded", "widget_nutrition_area", "tv_nutrition_energy",
        "tv_nutrition_protein", "widget_workout_area", "tv_workout_title", "tv_workout_sub",
    },
}


def _api(folder: str) -> int:
    match = re.search(r"(?:^|-)v(\d+)(?:-|$)", folder)
    return int(match[1]) if match else 1


def _kotlin_functions(source: str) -> dict[str, tuple[list[tuple[str, str | None]], str]]:
    """Read the small local populate functions, excluding strings/comments when balancing."""
    functions = {}
    for match in re.finditer(r"fun\s+(populate\w+)\s*\(([^)]*)\)\s*\{", source):
        parameters = []
        for raw in match[2].split(","):
            name, _, declaration = raw.strip().partition(":")
            _, separator, default = declaration.partition("=")
            parameters.append((name.strip(), default.strip() if separator else None))
        index = match.end()
        start = index
        depth = 1
        while index < len(source) and depth:
            if source.startswith("//", index):
                newline = source.find("\n", index)
                index = len(source) if newline < 0 else newline + 1
                continue
            if source.startswith("/*", index):
                close = source.find("*/", index + 2)
                index = len(source) if close < 0 else close + 2
                continue
            if source[index] in ('"', "'"):
                quote = source[index]
                index += 1
                while index < len(source):
                    if source[index] == "\\":
                        index += 2
                    elif source[index] == quote:
                        index += 1
                        break
                    else:
                        index += 1
                continue
            if source[index] == "{":
                depth += 1
            elif source[index] == "}":
                depth -= 1
            index += 1
        if depth:
            raise ValueError(f"Could not parse Kotlin function {match[1]}")
        functions[match[1]] = (parameters, source[start:index - 1])
    return functions


def _updated_ids(functions, function: str, args: list[str], inherited=None, stack=()) -> set[str]:
    """Resolve setter IDs through populate calls, including a passed rootId."""
    if function in stack or function not in functions:
        raise ValueError(f"Unknown or recursive population function: {function}")
    parameters, body = functions[function]
    scope = dict(inherited or {})
    for index, (name, default) in enumerate(parameters):
        expression = args[index].strip() if index < len(args) else default
        if expression is None:
            raise ValueError(f"Missing argument {function}.{name}")
        scope[name] = scope.get(expression, expression)
    ids = set()
    # IDs in RemoteViews setters are the first argument, never text payloads.
    for match in re.finditer(r"views\.set\w+\(\s*([^,\n)]+)", body):
        target = match[1].strip()
        target = scope.get(target, target)
        identifier = re.fullmatch(r"R\.id\.(\w+)", target)
        if identifier is None:
            raise ValueError(f"Unresolved RemoteViews ID in {function}: {target}")
        ids.add(identifier[1])
    for match in re.finditer(r"\b(populate\w+)\s*\(([^)]*)\)", body):
        ids.update(_updated_ids(
            functions, match[1], match[2].split(","), scope, (*stack, function)
        ))
    return ids


def validate(project: Path) -> tuple[list[str], str]:
    project = project.resolve()
    resource_root = project / "android/app/src/main/res"
    provider = project / "android/app/src/main/kotlin/com/trufit/trufit_bodamma/TrufitWidgetProvider.kt"
    errors = []
    if not resource_root.is_dir() or not provider.is_file():
        return ["Android resources or TrufitWidgetProvider.kt not found"], ""

    trees = {}
    resources = set()
    definitions = {}
    for path in resource_root.rglob("*"):
        if not path.is_file():
            continue
        folder = path.parent.name
        resource_type = folder.split("-")[0]
        if resource_type != "values":
            name = path.stem.removesuffix(".9")
            resources.add((resource_type, name))
        if path.suffix != ".xml":
            continue
        try:
            tree = ET.parse(path).getroot()
            trees[path] = tree
        except (ET.ParseError, UnicodeError) as error:
            errors.append(f"{path.relative_to(project)}: invalid XML: {error}")
            continue
        if resource_type == "values":
            for child in tree:
                name = child.get("name")
                if name:
                    kind = child.get("type") if child.tag == "item" else child.tag
                    resources.add((kind, name))
                    definitions.setdefault((kind, name), []).append((folder, child))
    for path, tree in trees.items():
        for element in tree.iter():
            for value in [*element.attrib.values(), element.text or ""]:
                for create, package, kind, name in RESOURCE_REF.findall(value):
                    if create or package or kind not in LOCAL_TYPES:
                        continue
                    if (kind, name) not in resources:
                        errors.append(f"{path.relative_to(project)}: unresolved @{kind}/{name}")

    functions = {}
    try:
        functions = _kotlin_functions(provider.read_text(encoding="utf-8"))
    except (ValueError, UnicodeError) as error:
        errors.append(str(error))
    for variant, required in REQUIRED_IDS.items():
        candidates = [
            (path, tree) for path, tree in trees.items()
            if path.parent.name.startswith("layout") and path.stem == f"widget_layout_{variant}"
        ]
        if not candidates:
            errors.append(f"Missing widget_layout_{variant}.xml")
        for path, tree in candidates:
            ids = {
                value.split("/")[-1]
                for node in tree.iter()
                if (value := node.get(ANDROID + "id")) is not None
            }
            for identifier in sorted(required - ids):
                errors.append(f"{path.relative_to(project)}: missing required ID {identifier}")
            supported = REMOTE_VIEWS | (REMOTE_VIEWS_31 if _api(path.parent.name) >= 31 else set())
            for node in tree.iter():
                tag = node.tag.removeprefix("android.widget.").removeprefix("android.view.")
                if tag not in supported:
                    errors.append(f"{path.relative_to(project)}: unsupported RemoteViews class {node.tag}")
            if functions:
                try:
                    used = _updated_ids(functions, "populate" + variant.title(), ["views", "0"])
                    for identifier in sorted(used - ids):
                        errors.append(
                            f"{variant}: provider updates {identifier}, absent from {path.name}"
                        )
                except ValueError as error:
                    errors.append(str(error))

    def select(kind, name, night, api):
        candidates = []
        for folder, element in definitions.get((kind, name), []):
            is_night = "night" in folder.split("-")
            if is_night and not night or _api(folder) > api:
                continue
            candidates.append(((int(is_night), _api(folder)), element))
        return max(candidates, key=lambda item: item[0])[1] if candidates else None

    def style_items(name, night, api, stack=()):
        if name in stack:
            errors.append(f"Style inheritance cycle: {name}")
            return {}
        style = select("style", name, night, api)
        if style is None:
            errors.append(f"Missing style {name} for night={night}, API{api}")
            return {}
        parent = style.get("parent", "")
        inherited = {}
        if parent and not parent.startswith("@android:"):
            inherited = style_items(parent.removeprefix("@style/"), night, api, (*stack, name))
        inherited.update({node.get("name"): (node.text or "").strip() for node in style if node.tag == "item"})
        return inherited

    for night in (False, True):
        selected_color = select("color", "launch_surface", night, 31)
        expected_folder = "values-night" if night else "values"
        explicit_colors = [element for folder, element in definitions.get(("color", "launch_surface"), [])
                           if folder == expected_folder]
        if not explicit_colors or selected_color is None:
            errors.append(f"Missing launch_surface in {expected_folder}")
        elif not re.fullmatch(r"#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?", (selected_color.text or "").strip()):
            errors.append(f"{expected_folder}: launch_surface must be an opaque or ARGB hex color")
        for api in (26, 31):
            launch = style_items("LaunchTheme", night, api)
            normal = style_items("NormalTheme", night, api)
            if launch.get("android:windowBackground") != "@drawable/launch_background":
                errors.append(f"LaunchTheme night={night} API{api}: missing launch_background")
            if normal.get("android:windowBackground") != "@color/launch_surface":
                errors.append(f"NormalTheme night={night} API{api}: mismatched launch_surface")
            if api >= 31:
                if launch.get("android:windowSplashScreenBackground") != "@color/launch_surface":
                    errors.append(f"LaunchTheme night={night} API31: missing splash background (check qualifier precedence)")
                if not launch.get("android:windowSplashScreenAnimatedIcon"):
                    errors.append(f"LaunchTheme night={night} API31: missing splash icon")
            expected_light = "false" if night else "true"
            for title, items in (("LaunchTheme", launch), ("NormalTheme", normal)):
                if items.get("android:windowLightStatusBar") != expected_light:
                    errors.append(f"{title} night={night} API{api}: status-bar contrast setting mismatch")

    for path, tree in trees.items():
        if path.stem == "launch_background" and path.parent.name.startswith("drawable"):
            refs = {value for node in tree.iter() for value in node.attrib.values()}
            if "@color/launch_surface" not in refs:
                errors.append(f"{path.relative_to(project)}: launch background does not use launch_surface")

    summary = (
        f"Checked {len(trees)} XML files, {len(REQUIRED_IDS)} widget variants, "
        "local references, provider IDs, and light/night startup at API26/API31."
    )
    return sorted(set(errors)), summary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args()
    errors, summary = validate(args.project_root)
    if summary:
        print(summary)
    for error in errors:
        print("ERROR: " + error, file=sys.stderr)
    if errors:
        return 1
    print("Static checks passed. Android compilation and native rendering were not run.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
