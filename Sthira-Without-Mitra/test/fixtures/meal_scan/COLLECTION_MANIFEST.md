# Meal Scan Ground Truth Collection Protocol

This document outlines the strict protocol for collecting and organizing ground truth data used in the `meal_scan_bench.dart` harness. The goal is to establish trustworthy real-world test sets.

## 1. Supported Cuisine Sets
Collect diverse, real meals representing typical user diets. We explicitly need:
- Indian (Thalis, curries, mixed rice, dosas)
- Continental/Western (Salads, steaks, sandwiches, pasta)
- Mixed Bowls / Fast Food (Chipotle style, burgers, fries)
- Packaged Foods (with clear labels vs without)

## 2. Photographic Challenges (The "Real World" Rules)
Do NOT use perfectly lit, isolated stock photos. Our users take photos in a hurry. You must collect sets containing:
- **Poor Lighting**: Dim kitchen lights, strong shadows, yellowish indoor lighting.
- **Occlusion**: Items partially hidden beneath sauces, wrapped in foil, or overlapping heavily.
- **Multi-Angle Sets**: Always provide 2-3 images of the SAME meal from different angles/distances. The benchmark relies on evaluating multi-image prompts.
- **Unknown/Non-Food Inputs**: Include edge cases (e.g., a photo of a shoe, an empty plate, a dog, a blurry photo of a kitchen counter). The system must gracefully fail or reject these, not hallucinate food.

## 3. Establishing True Portions (Weighed Data)
A visual guess is not ground truth.
- **Weigh Everything**: For at least 30% of the dataset, ingredients must be weighed on a kitchen scale before assembly.
- **Document Recipes**: Document the exact ingredients and weights in a spreadsheet or JSON format that matches the `ground_truth.json` schema. 
- **Canonical Labels**: Do not use vague labels like "Chicken". Use specific labels like "Grilled Chicken Breast (Skinless)".

## 4. `ground_truth.json` Schema
All collected data must be mapped into `test/fixtures/meal_scan/ground_truth.json` using the following schema:
```json
[
  {
    "id": "real_meal_001",
    "images": ["meal1_angle1.jpg", "meal1_angle2.jpg"],
    "total_kcal": 650.0,
    "items": [
      {
        "name": "Grilled Chicken Breast",
        "calories": 250,
        "protein": 50,
        "carbs": 0,
        "fat": 5
      },
      {
        "name": "Steamed White Rice",
        "calories": 400,
        "protein": 8,
        "carbs": 90,
        "fat": 1
      }
    ]
  }
]
```

## 5. Exclusions
- Do NOT use synthetic, AI-generated images as ground truth.
- Do NOT use placeholder nutritional values. If you do not know the exact macros, do not add the meal to the benchmark set.
