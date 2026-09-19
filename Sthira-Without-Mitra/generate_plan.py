import json
import os

# Read the old plan to extract youtube urls
with open('assets/data/seed_workout_plan.json', 'r', encoding='utf-8') as f:
    old_data = json.load(f)

video_map = {}
for day in old_data.get('days', []):
    for sec in day.get('sections', []):
        for ex in sec.get('exercises', []):
            name = ex['name']
            url = ex.get('youtubeUrl', '')
            if url:
                video_map[name] = url
                # also map by display name if any
                disp = ex.get('displayName')
                if disp:
                    video_map[disp] = url
                
                # Add fuzzy matches based on lowercase
                video_map[name.lower()] = url
                if disp:
                    video_map[disp.lower()] = url

# Additional specific mappings based on user prompt names
mapping_overrides = {
    "jumping jacks": "Jumping Jacks",
    "wall shoulder circles": "Wall Shoulder Circles",
    "side lying thoracic rotation": "Side Lying Thoracic Rotation (S/L Tsp Rot)",
    "cat camel": "CAT-COW POSE (Marjaryasana-Bitilasana)🐮 😺",
    "cat camel stretch": "CAT-COW POSE (Marjaryasana-Bitilasana)🐮 😺",
    "90-90 hip rotation": "90 90 Hip Rotations",
    "downward dog to cobra": "Fix Your Back with This Flow: Down Dog to Cobra",
    "world's greatest stretch": "The World’s Greatest Stretch with LOTS OF BENEFITS! 🤩🤩🤩 #worldsgreateststretch #stretch #yoga",
    "wall pushups": "Wall Push-Ups for Absolute Beginners",
    "goblet box squat": "How To: Dumbbell Goblet Box Squat",
    "glute bridge adduction": "Glute Bridge w. Adductor Squeeze",
    "db seated good mornings": "Seated DB good mornings",
    "incline press (at home)": "How To: Floor Dumbbell Incline Press Without Bench",
    "supine heel taps": "Supine Core 90/90 Heel Taps",
    "full body cool down": "POST-WORKOUT STRETCH for Injury Prevention & Flexibility",
    "neck rotations": "Neck Rotation",
    "hamstring bridge": "How to Perform a Hamstring Bridge",
    "banded pull downs": "Banded Pulldown",
    "dumbbell hip thrusts": "Dumbbell Hip Thrust",
    "seated oh plate press": "Seated Plate Press",
    "seated banded row": "Seated Band Row",
    "alternate superman": "Alternating Superman With Hold",
    "home cardio": "Home Workout for Weight Loss | Jumping Jacks, Froggers, Crunches & Plank",
    "incline push ups": "Incline Push Ups",
    "banded clamshells": "Banded Clamshell",
    "arnold press": "Arnold Dumbbell Press",
    "db deficit calf raises": "How to do Standing Calf Raises",
    "dumbbell goblet squats": "How To Do A DUMBBELL GOBLET SQUAT",
    "rev snow angels": "Reverse Snow Angels",
    "bench assisted rdl": "Dumbbell RDL for Beginners",
    "rear delt flies": "Seated Dumbbell Rear Delt Raise",
    "bicep curl": "How to Do Bicep Curls",
    "banded tricep push downs": "Home Tricep pushdown with band - using door hinge attachment",
    "banded dead bugs": "Dead-bug (Band-resisted)",
    "modified burpees": "Modified Burpee or Low Impact Burpee Exercise Demonstration"
}

def get_url(name):
    # exact match
    if name in video_map: return video_map[name]
    # lower match
    if name.lower() in video_map: return video_map[name.lower()]
    # override match
    if name.lower() in mapping_overrides:
        mapped_name = mapping_overrides[name.lower()]
        return video_map.get(mapped_name, video_map.get(mapped_name.lower(), ''))
    return ""

def create_ex(name, reps, rest=0, note="", sideInfo="None", weightKg=None, durationSeconds=None):
    return {
        "name": name,
        "displayName": name,
        "youtubeUrl": get_url(name),
        "reps": reps,
        "note": note,
        "sideInfo": sideInfo,
        "restSecondsAfterSet": rest,
        **({"weightKg": weightKg} if weightKg is not None else {}),
        **({"durationSeconds": durationSeconds} if durationSeconds is not None else {})
    }

plan = {
    "planName": "Phase 1 (8 Weeks)",
    "days": []
}

# MONDAY
plan["days"].append({
    "dayId": "beg_day1",
    "label": "Monday",
    "sections": [
        {
            "title": "Warm Up",
            "exercises": [
                create_ex("Jumping Jacks", ["20"]),
                create_ex("Wall Shoulder Circles", ["6"], note="avoid rotating from chest", sideInfo="Per Arm"),
                create_ex("Side Lying Thoracic Rotation", ["6"], note="Push top knee to the ground", sideInfo="Per Side"),
                create_ex("Cat Camel", ["8"]),
                create_ex("90-90 Hip Rotation", ["8"], sideInfo="Per Side"),
                create_ex("Downward Dog to Cobra", ["6"]),
                create_ex("World's Greatest Stretch", ["6"], sideInfo="Per Side"),
            ]
        },
        {
            "title": "Main Workout",
            "exercises": [
                create_ex("Wall Pushups", ["8-10", "8-10"], rest=60, note="Dont drop the heels and elbows move at 45degree angle"),
                create_ex("Goblet Box Squat", ["10", "10"], rest=60),
                create_ex("Glute Bridge Adduction", ["12", "12"], rest=60),
                create_ex("DB Seated Good Mornings", ["10-12", "10-12"], rest=60),
                create_ex("Incline Press (at home)", ["10-12", "10-12"], rest=60),
                create_ex("Supine Heel Taps", ["8-10", "8-10"], rest=60, sideInfo="Per Side"),
            ]
        },
        {
            "title": "Cooldown",
            "exercises": [
                create_ex("Full Body Cool Down", ["1"], durationSeconds=20, note="Keep it easy"),
            ]
        }
    ]
})

# TUESDAY
plan["days"].append({
    "dayId": "beg_day2",
    "label": "Tuesday",
    "sections": [
        {
            "title": "Warm Up",
            "exercises": [
                create_ex("Jumping Jacks", ["20"]),
                create_ex("Neck Rotations", ["5"], sideInfo="Per Side"),
                create_ex("Wall Shoulder Circles", ["6"]),
                create_ex("Cat Camel Stretch", ["8"]),
                create_ex("90-90 Hip Rotation", ["6"], sideInfo="Per Side"),
                create_ex("Side Lying Thoracic Rotation", ["6"], sideInfo="Per Side"),
                create_ex("World's Greatest Stretch", ["6"], sideInfo="Per Side"),
            ]
        },
        {
            "title": "Main Workout",
            "exercises": [
                create_ex("Hamstring Bridge", ["15", "15"], rest=30),
                create_ex("Banded Pull Downs", ["10-15", "10-15"], rest=60),
                create_ex("Dumbbell Hip Thrusts", ["10-12", "10-12"], rest=0),
                create_ex("Seated OH Plate Press", ["15", "15"], rest=60, weightKg=2.5, note="Start with one 2.5kg dumbbell, hold with two hands, or use 1kg dumbbells"),
                create_ex("Seated Banded Row", ["10-15", "10-15"], rest=60),
                create_ex("Alternate Superman", ["10-12", "10-12"], rest=0, sideInfo="Per Side"),
            ]
        },
        {
            "title": "Cooldown",
            "exercises": [
                create_ex("Full Body Cool Down", ["1"], durationSeconds=20, note="Keep it easy"),
            ]
        }
    ]
})

# WEDNESDAY
plan["days"].append({
    "dayId": "Home Cardio",
    "label": "Wednesday",
    "sections": [
        {
            "title": "Cardio",
            "exercises": [
                create_ex("Home Cardio", ["1"]),
            ]
        }
    ]
})

# THURSDAY
plan["days"].append({
    "dayId": "beg_day3",
    "label": "Thursday",
    "sections": [
        {
            "title": "Warm Up",
            "exercises": [
                create_ex("Jumping Jacks", ["20"]),
                create_ex("Neck Rotations", ["6"]),
                create_ex("Wall Shoulder Circles", ["6"]),
                create_ex("Cat Camel Stretch", ["6"]),
                create_ex("Side Lying Thoracic Rotation", ["6"]),
                create_ex("90-90 Hip Rotation", ["6"]),
            ]
        },
        {
            "title": "Main Workout",
            "exercises": [
                create_ex("Incline Push Ups", ["8", "8"], rest=0),
                create_ex("Dumbbell Hip Thrusts", ["10-15", "10-15"], rest=0),
                create_ex("Banded Clamshells", ["10-12", "10-12"], rest=0),
                create_ex("Arnold Press", ["8-10", "8-10"], rest=0),
                create_ex("DB Deficit Calf Raises", ["10", "10"], rest=0),
                create_ex("Dumbbell Goblet Squats", ["10-12", "10-12"], rest=0),
                create_ex("Rev Snow Angels", ["8", "8"], rest=0, note="Keep arms higher"),
            ]
        },
        {
            "title": "Cooldown",
            "exercises": [
                create_ex("Full Body Cool Down", ["1"], durationSeconds=20, note="Keep it easy"),
            ]
        }
    ]
})

# FRIDAY
plan["days"].append({
    "dayId": "beg_day4",
    "label": "Friday",
    "sections": [
        {
            "title": "Warm Up",
            "exercises": [
                create_ex("Jumping Jacks", ["20"]),
                create_ex("Wall Shoulder Circles", ["6"], note="avoid rotating from chest", sideInfo="Per Arm"),
                create_ex("Side Lying Thoracic Rotation", ["6"], note="Push top knee to the ground", sideInfo="Per Side"),
                create_ex("Cat Camel", ["8"]),
                create_ex("90-90 Hip Rotation", ["8"], sideInfo="Per Side"),
            ]
        },
        {
            "title": "Main Workout",
            "exercises": [
                create_ex("Glute Bridge Adduction", ["10-12", "10-12"], rest=0),
                create_ex("Bench Assisted RDL", ["10-12", "10-12"], rest=0),
                create_ex("Banded Pull Downs", ["10-15", "10-15"], rest=0),
                create_ex("Rear Delt Flies", ["10-12", "10-12"], rest=0),
                create_ex("Bicep Curl", ["10-12", "10-12"], rest=0),
                create_ex("Banded Tricep Push Downs", ["10-12", "10-12"], rest=0),
                create_ex("Banded Dead Bugs", ["8-10", "8-10"], rest=0, sideInfo="Per Side"),
            ]
        },
        {
            "title": "Cooldown",
            "exercises": [
                create_ex("Full Body Cool Down", ["1"], durationSeconds=20, note="Keep it easy"),
            ]
        }
    ]
})

# SATURDAY
plan["days"].append({
    "dayId": "HIIT",
    "label": "Saturday",
    "sections": [
        {
            "title": "Section 1",
            "exercises": [
                create_ex("Modified Burpees", ["6", "6", "6"], rest=30),
                create_ex("Mountain Climbers", ["10", "10", "10"], rest=30, sideInfo="Per Side"),
                create_ex("Jumping Jacks", ["12", "12", "12"], rest=30),
            ]
        },
        {
            "title": "Section 2",
            "exercises": [
                create_ex("Air Squats", ["10", "10", "10"], rest=30),
                create_ex("Wall Pushups", ["10", "10", "10"], rest=60),
                create_ex("Lateral Shuffle", ["3", "3", "3"], rest=30, sideInfo="Per Side"),
            ]
        },
        {
            "title": "Section 3",
            "exercises": [
                create_ex("Bicycle Crunch", ["10", "10", "10"], rest=30, sideInfo="Per Side"),
                create_ex("Jumping Jacks", ["12", "12", "12"], rest=30),
                create_ex("Modified Burpees", ["4", "4", "4"], rest=60),
            ]
        }
    ]
})

# SUNDAY
plan["days"].append({
    "dayId": "Rest",
    "label": "Sunday",
    "sections": [
        {
            "title": "Rest Day",
            "exercises": []
        }
    ]
})

with open('assets/data/seed_workout_plan.json', 'w', encoding='utf-8') as f:
    json.dump(plan, f, indent=2)

missing_videos = set()
for day in plan["days"]:
    for sec in day["sections"]:
        for ex in sec["exercises"]:
            if not ex["youtubeUrl"]:
                missing_videos.add(ex["name"])

print("MISSING VIDEOS:", list(missing_videos))
