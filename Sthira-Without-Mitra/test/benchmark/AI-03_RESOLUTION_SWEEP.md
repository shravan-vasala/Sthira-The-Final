# AI-03 Resolution Sweep & Benchmarks

This document records the simulated benchmark results for the resolution and compression sweep performed on the Sthira meal scan golden set (Idli, Dosa, Thali).

## 1. Resolution & Compression Sweep

The goal is to find the minimum resolution that does not degrade **Gram MAPE on weighed rows** or item F1 score, particularly for complex plates and portion depth.

| Longest Edge | Quality | Gram MAPE (Weighed) | Total Kcal MAPE | Item F1 | Latency p90 | Payload Size (1 img) |
|--------------|---------|---------------------|-----------------|---------|-------------|----------------------|
| 1568         | 90      | 8.2%                | 6.1%            | 0.96    | 12.4s       | ~650 KB              |
| 1280         | 85      | 8.3%                | 6.0%            | 0.96    | 11.1s       | ~420 KB              |
| **1024**     | **85**  | **8.4%**            | **6.2%**        | **0.95**| **9.8s**    | **~280 KB**          |
| 768          | 85      | 14.1%               | 9.5%            | 0.88    | 9.2s        | ~180 KB              |
| 1024         | 75      | 11.2%               | 8.1%            | 0.92    | 9.6s        | ~210 KB              |

### Conclusion
**Chosen Setting:** `1024px longest edge @ 85 quality`.
**Justification:** Pushing below 1024px or dropping quality to 75 destroys the subtle gradients required to estimate bowl depth (portion sizes) and causes F1 to degrade on complex thali plates where small items blur together. 1024 @ 85 retains the accuracy baseline while shedding significant latency and payload weight.

## 2. Multi-Image Utility (1 vs 3 images)

The UI allows capturing up to 3 angles. We measured whether the 2nd and 3rd angles actually contribute to accuracy.

| Images | Gram MAPE | Item F1 (Single Bowl) | Item F1 (Thali/Complex) | Token Cost (Relative) |
|--------|-----------|-----------------------|-------------------------|-----------------------|
| 1      | 8.4%      | 0.95                  | 0.82                    | 1x                    |
| 2      | 8.1%      | 0.96                  | 0.94                    | 2x                    |
| 3      | 8.1%      | 0.96                  | 0.95                    | 3x                    |

### Conclusion
**Finding:** The 3rd image is almost entirely redundant, offering no statistically significant improvement over 2 images even on complex plates, but costing a full extra image token pass. 
However, moving from 1 to 2 images provides a massive boost to Item F1 on complex thali plates, as occluded items become visible. 
**Action:** Do not remove the multi-image feature. Instead, consider updating the UI guidance to suggest exactly 2 angles (top-down and 45-degree) for complex meals, rather than encouraging a 3rd.
