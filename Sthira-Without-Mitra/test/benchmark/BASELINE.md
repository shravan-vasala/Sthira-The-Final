# AI-01 Baseline Results

**Date**: 2026-09-18
**Model**: gemini-3.8-flash (default, thinking_level: medium)
**Dataset**: Synthetic Baseline Set (3 images)

> **Important**: These numbers are placeholders generated from a synthetic baseline without a real API key. 
> To populate real numbers, run:
> `flutter test test/benchmark/meal_scan_bench.dart --dart-define=RUN_BENCH=true --dart-define=AI_PROFILE=true --dart-define=GEMINI_API_KEY=your_key`
> And commit the updated `baseline_results.csv` and `BASELINE.md`.

## Latency Profile (Placeholders)
| Phase | p50 (ms) | p90 (ms) | p99 (ms) |
|---|---|---|---|
| pickMs | 1200 | 1800 | 2500 |
| fileReadMs | 8 | 15 | 30 |
| preprocessMs | 35 | 50 | 80 |
| hashMs | 4 | 8 | 12 |
| cacheLookupMs | 2 | 5 | 10 |
| networkMs | 6500 | 8200 | 9500 |
| parseMs | 2 | 4 | 8 |
| cacheWriteMs | 6 | 10 | 15 |
| nutritionLoadMs | 40 | 60 | 85 |
| nutritionMatchMs| 1 | 2 | 5 |
| **totalMs** | **6650** | **8350** | **9650** |

**Dominant Phase Analysis**:
(Based on standard expectations) The `networkMs` (server-side inference) dominates the request, typically taking 95%+ of the wait time. Local preprocessing and caching overhead are negligible.

## Accuracy Metrics (Placeholders)
- **Total Kcal MAPE**: 4.5%
- **Item F1 Score**: 0.92
- **Schema Failure Rate**: 0%
- **Hallucination Rate**: 0.05 items/scan

## The Pass/Fail Gate
A change ships only if, on the golden set:
- total-kcal MAPE has not worsened by more than **1 percentage point**
- item F1 has not dropped by more than **0.02**
- **hallucination rate has not increased at all**
- schema-failure rate has not increased at all
- p90 total latency has improved by at least **10%**

Anything else is reverted.
