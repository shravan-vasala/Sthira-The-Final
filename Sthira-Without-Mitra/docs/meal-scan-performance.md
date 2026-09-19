# Meal scanning: responsiveness and accuracy review

Reviewed 19 September 2026. These findings come from source inspection and local regression tests, not a timed production Gemini experiment.

## Findings and changes

| Finding | User impact | Change |
|---|---|---|
| The JSON request put `thinking_level` directly in the generation config and included unsupported `candidate_count`. | Requests can fail before food analysis; fallback repeats the same invalid request. | Use `generationConfig.thinkingConfig.thinkingLevel`; remove obsolete sampling/candidate fields. Keep the existing `low` reasoning intent and model order. |
| The service created an unused deadline; connection/header timeouts did not cover the response body. | A stalled response can leave the scanner waiting indefinitely. | Enforce a shared 30-second photo-service budget and include the response body. Image preparation in the UI has a separate 10-second bound. |
| Cancellation only raced the request future. Retry delays, uploads and body reads could continue. | Cancelled scans compete with new scans and waste API work. | Cancel retry waits, abort the individual request, cancel body subscriptions and suppress late results by scan session. |
| A new HTTP client was created for every attempt. | Repeated scans/retries pay connection setup again. | Reuse the connection pool; cancelling one request leaves other requests alone. |
| Image preprocessing fully decoded small images on the UI isolate and sometimes labeled PNG bytes as JPEG. The picker constrained only width. | Animation stalls, avoidable image work, oversized portrait uploads and incorrect MIME labels. | Prepare selected images in the background while the user adds a hint. Read JPEG dimensions without pixel decoding, preserve suitable JPEG bytes exactly, normalize other supported formats and cap both dimensions at 1024. |
| Retries read photos again; hashing and JSON/base64 encoding ran on the UI isolate. | Extra local work and frame stalls on slower phones. | Retain prepared bytes for selected photos, prepare multiple photos concurrently and move hashing/request encoding to isolates. |
| Nutrition assets loaded after inference. | Cold scans wait for independent local work after AI finishes. | Warm the table when opening the scanner and overlap loading with inference. Allow retry after a failed asset load. |
| Status always said “Analyzing”; text analysis could render no progress area. | A working scan looks stuck. | Show actual preparation, inference, retry and nutrition stages; show a truthful slow-request message and accessible Cancel control. |
| Profiling referenced undefined symbols/arguments, discarded sessions before rendering and accumulated repeated timer stops. The benchmark simulated file reads. | The path could not compile and measurements could not substantiate performance claims. | Repair session plumbing; record attempts, bytes, token usage and the first usable frame; read real fixture files in the benchmark. |
| Malformed detections could produce empty successful meals; results omitted their nutrition basis and overwrote provenance. Raw response maps were mutated during an asynchronous cache write. | Misleading totals, portion corrections and repeat-scan behavior. | Validate items and positive finite portions, retain nutrition basis/provenance, copy responses before resolving nutrition and leave unknown values marked for review. |

Google’s [generateContent migration guide](https://ai.google.dev/gemini-api/docs/generate-content/latest-model?hl=en) documents the nested thinking configuration and removal of unsupported candidate/sampling parameters. The [model catalog](https://ai.google.dev/gemini-api/docs/models) confirms the existing model IDs.

## Accuracy boundaries

The dish-identification prompt, regional cuisine guidance, selected vision models and 1024-pixel target are retained. Multiple photos still represent different angles of one meal. There is no speculative switch to a smaller model, shorter prompt or partial JSON results.

Nutrition uses exact/alias database matches where available. Unknown or unusable nutrition stays marked for review. Empty food detections and incomplete AI responses are rejected. Photo-based portions and recipe macros remain estimates.

The fixture set contains three synthetic, unweighed images. It can support pipeline smoke checks, but cannot establish calorie accuracy or accuracy parity on real meals. Unsupported comments claiming measured p90 rankings, zero hallucinations or seven-second savings were removed.

## Validation and measurement

Validation completed: **29 regression tests passed**. The optional live benchmark was explicitly skipped. Changed source/test files have **zero analyzer errors and zero warnings** (style suggestions remain). Analysis of the full app library found no errors and 134 warnings in other files; those unrelated warnings were left unchanged.

Automated coverage exercises real loopback HTTP requests (including stalled bodies and cancellation isolation), image formats/dimensions, concurrent nutrition loading, invalid portions, unresolved nutrition and the scanner UI lifecycle.

Use `--dart-define=AI_PROFILE=true` on a profile build to emit session timings. `totalMs` and `firstUsableFrameMs` start at Analyze, excluding time spent selecting photos or writing hints.

To explicitly run the live diagnostic benchmark:

```sh
flutter test test/benchmark/meal_scan_bench.dart --dart-define=RUN_BENCH=true --dart-define=AI_PROFILE=true --dart-define=GEMINI_API_KEY=YOUR_KEY --dart-define=ITERATIONS=3
```

The benchmark fails when explicitly enabled without prerequisites, includes real file-read timing, reports actual model/attempts and labels unweighed fixtures. It no longer advertises an ignored `MODEL` argument.

No live API benchmark was run. Compare Analyze-to-first-frame p50/p90 and frame timing on target Android devices using the same real meal photos and network conditions. Validate portions against weighed meals before making model, reasoning, prompt or resolution tradeoffs.

Local validation uses a temporary Flutter 3.47.5 / Dart 3.13.4 SDK under the ignored build directory. Its SDK requires four newer transitive test packages; the repository’s original lockfile and analyzer settings are preserved.
