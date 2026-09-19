# AI-06: Model selection evidence status

The earlier version of this note presented production success rates, model latency rankings and calorie/portion accuracy figures without a reproducible run report or weighed ground truth in this repository. Those figures have been withdrawn; they must not be used as evidence for model choice or product claims.

The current meal-scanning changes retain the configured models, prompts and image resolution. They improve local preparation, cancellation, cache reliability, validation and review behavior. Tests establish those behaviors; they do not establish a measured end-to-end speedup or real-meal calorie accuracy.

The three synthetic, unweighed image fixtures support pipeline diagnostics only. Before changing the model order, image resolution or reasoning settings:

1. Capture dated runs with the exact model IDs, parameters, device/network conditions and per-attempt timings.
2. Use representative Indian meals with weighed portions and independently documented nutrition, including multi-dish plates, mixed recipes and difficult lighting.
3. Compare identification errors, portion error, unresolved items, cancellation, fallback success and Analyze-to-first-usable-frame p50/p90 using the same inputs.
4. Keep the existing configuration unless the measured tradeoff adds value.

See [meal-scan performance](../../docs/meal-scan-performance.md) and the current [meal/score review](../../docs/meal-and-score-experience-review.md) for implemented changes and validation limits. No live provider benchmark was run for the current review.
