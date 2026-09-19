# AI, nutrition, barcode and coaching services audit

Read-only audit, 19 September 2026. Production code and maintained tests were not edited. Six temporary observation cases ran through the actual app services with deterministic mock inference and the bundled nutrition asset. They intentionally assert the current defects; their completion does not mean the affected behaviour is correct. Results are in `build/service-audit/ai-observations.json`; harness is `build/service-audit/ai-review_test.dart`. Root owns Flutter execution and final regression results.

## Verdict

Keep the recent meal transport and barcode architecture. It has useful isolation, bounded requests, validation, local calculations and recovery. The remaining high-value work is nutrition-basis correctness, food identity, streaming lifecycle and personalized cache ownership. No evidence supports changing the current vision model, reducing image resolution or adding speculative parallel model calls. Real latency/accuracy claims still require representative device and weighed-food measurements.

## Complete service coverage

| Service | Reviewed behaviour and positive controls | Remaining work |
| --- | --- | --- |
| `lib/services/ai_client.dart` | JSON inference, model fallback, per-attempt and total deadlines, full HTTP body timeout, request abort, cancellation, preprocessing/hash/JSON offload, response schema, finish reason and thought filtering, raw caching, circuit breakers, concurrent streams, API-key errors, reusable clients and disposal. Vision models `gemini-3.8-flash`/`gemini-3.7-flash`; text `gemini-3.5-flash-lite`/`gemini-3.1-flash-lite` exist in current official model list. | Text streams lack a complete token-cancellation terminal path and complete-response validation. See AI-03 and AI-07. JSON path is substantially stronger. |
| `lib/services/ai_cache.dart` | 24-hour expiry, SHA-256 key across prompt/instruction/images/schema, invalid/expired data treated as miss, configured database resolver, no fallback to another account if resolver returns null, `forRequest()` pins deferred write to original database, asynchronous write, separate startup prune, unique key. | Keep. Add capacity/chunked pruning only if size/timing measurements justify it. There is no demonstrated cache leak between accounts in this service; suggestion caching is separate and weaker. |
| `lib/services/gemini_food_service.dart` | Image/text analysis, local parser, ambiguous serving/volume rejection, concurrent asset load plus inference, nonfood/invalid response rejection, local vs AI merge, immutable raw response copy before enrichment, personal nutrition refresh on raw cache hits, unknown data handling, suggestions, key verification. | AI-01/02/04/05/06/08/09/10. The parser's returned nutrition basis, not AI speed, is the first correctness fix. |
| `lib/services/nutrition_lookup_service.dart` | Shared in-flight asset loading, normalized O(1) exact/alias index, no risky subset matches, per-account personal-food lookup, no cross-account implicit fallback, retryable asset load failure. All 119 bundled rows contain the four macro fields. | AI-02/04/06/08. Preserve exact matching; fix unsafe aliases and normalization mismatch instead of reintroducing fuzzy subset matching. |
| `lib/services/barcode_food_service.dart` | India/English locale, string GTIN identity, bounded 10-second full-response request using AbortableRequest, cancellation on completion/timeout, redirect refusal, 1MB body cap, status and identity checks, non-food rejection, no auto-retry storm, numeric parsing, kJ conversion, missing/modifier values remain unknown, explicit serving basis, mass/volume ambiguity, safe unit parsing and resource ownership. | No release-blocking defect found in reviewed service. Keep label confirmation and manual fallback. Request cancellation on selecting another product would be a modest efficiency improvement, not needed to repair current totals. Native camera and real Indian product coverage remain device/network checks. |
| `lib/services/coach_service.dart` | Local fallback with missing key/no logs, 10-second bounded remote note, AI/local provenance markers, partial stream fallback reset, prompt context, short output, cancellation integration and error handling. | AI-03/07/11. Local fallback should respect cancellation too; notifier needs stale request/account checks while consuming chunks. |
| `lib/services/ai_logger.dart` | Bounded in-memory last-20 attempt records; purpose/model/durations/outcome only. No API keys, meal photos, prompt bodies or food text recorded by this helper. | Keep. Optional quality-of-diagnostics improvement: log cache/local completions and a request correlation ID if diagnosing latency warrants it. No need to add persistent analytics. |
| `lib/services/ai_profiler.dart` | Compile-time timing flag off by default; named stopwatches, additive phases, model/attempt/image/token metadata, user-visible terminal outcomes, first-usable-frame and durable-save timing hooks. | Keep with metric definitions: nested/overlapping phases are not additive wall time; image byte count is prepared bytes once, not retry/base64 wire volume; token metadata reflects latest attempt. Benchmark UI/device phases separately. |
| `lib/services/image_preprocessor.dart` | Codec/hash work runs via compute; prepared JPEG below 1024px/1MB retained byte-for-byte; PNG/other supported codecs normalized to JPEG; orientation baked when decoding; both dimensions scaled preserving aspect; decode failure before network. | Keep current 1024px/quality85 until measured. Test EXIF orientation and actual gallery/camera formats on supported devices. Small retained JPEG metadata/orientation should be included in fixtures; no demonstrated failure currently. |

Related coverage: `BarcodeFoodStore`, `PackagedFood`, `FoodNutrition`, `NutritionLookupResult`, `MealItemLog` mapping/scaling/personal-memory save, food/AI/coach/barcode providers and scanner/suggestion/coach callers. Barcode shortcuts are account/market scoped, bounded to60, reject corrupt rows individually, normalize equivalent zero-padded GTINs and store immutable snapshots; meal save succeeds independently of optional shortcut persistence. The barcode sheet watches the auto-disposed service, so it is retained during an active lookup.

## Ranked findings

### AI-01 - P1: explicit grams corrupt the returned per-serving basis

- Location: `lib/services/gemini_food_service.dart:287-323`, especially assignment at293 and returned `serving_grams` at323; downstream `lib/screens/home/widgets/photo_calorie_scanner_sheet.dart:266-271,918-927`.
- Trigger: a remembered food has100kcal per50g serving; enter `100 g my oats`, then use the half-portion control.
- Effect: first calculation correctly gives200kcal, but the returned basis says one serving is100g instead of50g. The same downstream calculation used by the portion control then gives50kcal for half the original portion; it should be100kcal. Switching back to1x also recomputes using the wrong basis. The result can be saved.
- Evidence: actual-service deterministic reproduction: `initial_kcal=200`, `returned_serving_grams=100`, `half_portion_kcal=50`, expected100. This is a calculation defect independent of model accuracy.
- Minimal fix: keep source serving mass separate from consumed mass/display portion. Return `localMatch.servingGrams` as the basis; store explicit grams only in consumed/estimated grams. Cover per-serving memory at a different consumed mass, both scale directions and save/reopen.
- Existing coverage: explicit gram tests only use per100g nutrition, where replacing serving mass does not affect gram calculation. Per-serving memory tests cover unresolved missing mass, not this downstream scaling invariant.

### AI-02 - P1: dry whey protein is mapped to a prepared diluted shake

- Location: `assets/data/nutrition_table.json:1` protein_shake row; `lib/services/nutrition_lookup_service.dart:40-45,93-96`; `lib/services/gemini_food_service.dart:262-348`.
- Trigger: enter `30 g whey protein`, a normal way to describe a measured powder serving.
- Effect: the alias `whey protein` maps to Protein Shake, whose default prepared portion is300g and base is50kcal/8gprotein per100g. Actual app result is15kcal and2.4gprotein for30g, labelled internally high confidence. Powder and prepared drink are different food states; a mass-only alias cannot safely use the drink's diluted composition. No specific brand nutrition was assumed to identify this error.
- Evidence: reproduced using the actual bundled asset, no AI call. Output includes `matched_name=Protein Shake`,30g,15kcal,2.4gprotein.
- Minimal fix: remove the ambiguous powder alias from prepared-shake nutrition. Use explicit dry/prepared identities; measured packaged powder should use the barcode/label snapshot or a user-confirmed powder entry. Audit aliases that conflate cooking state or preparation, without broad fuzzy matching.
- Existing coverage: exact names and Telugu Romanized aliases, but no preparation-state invariants or powder-vs-drink case.

### AI-03 - P2: cancelling a silent text stream can leave it open

- Location: `lib/services/ai_client.dart:749-1022`, especially `tryNextModel` early return at784-787, cancellation checks at859-862, and onListen at987-1014; `_callModelStream:1057-1064`.
- Trigger: cancel a CancellationToken before the first token, or supply an already-cancelled token and listen.
- Effect: the cancellation flag is polled only at selected callbacks, not subscribed to. In a silent stream, cancellation is noticed by fallback after inactivity; the upstream subscription is cancelled but the returned controller is never closed or errored. An already-cancelled stream makes no request and stays open. Without overallDeadline it remains open indefinitely. Current coach/suggestion wrappers supply10/15-second deadlines, so their visible bound remains, but a cancelled operation can stay alive until that deadline and report timeout rather than cancellation.
- Evidence: two deterministic reproductions. After token cancellation, source_cancelled=true but completed=false and no error; before-listen cancellation gives calls0/completedfalse/noerror.
- Minimal fix: subscribe to token.onCancelled at stream creation/listen; end exactly once with cancelled outcome, close controller, release token listener/timers and cancel/abort the per-request transport. Check already-cancelled state synchronously. Do not close a shared client just to cancel one request.
- Transport caveat: installed googleai_dart11.0.0 exposes abortTrigger, but its implementation begins abort monitoring after awaiting HTTP response headers (`models_resource.dart:120-135`). Use a transport that can abort header wait too; merely wiring that optional argument is insufficient proof of full cancellation. Also bound/avoid awaiting a stuck subscription cancellation before starting fallback.
- Existing coverage: cancellation test cancels StreamSubscription, not CancellationToken; JSON cancellation tests are good but exercise another code path.

### AI-04 - P2: ordinary unlisted foods can require manual entry after successful recognition

- Location: `lib/services/gemini_food_service.dart:117-129,487-533`; `lib/services/nutrition_lookup_service.dart:93-100`; bundled table.
- Trigger: AI correctly identifies a common food absent from the119-item index and follows the schema instruction to provide nutrition fallback only for rare/complex foods.
- Effect: Apple, Banana, Boiled Egg, Oats, Milk and Peanuts have no exact/alias match in the current asset. A valid recognition-only Apple result becomes unresolved with zero totals. The UI correctly prevents unknown values silently becoming a complete meal, but the user must manually repair common foods despite successful inference.
- Evidence: actual asset lookup confirmed all six misses; mocked valid Apple recognition produced resolvedfalse and unresolved_count1. This does not predict how often the live model omits fallback.
- Minimal fix: provide a bounded nutrition fallback for every identified item that is not guaranteed to have a canonical database ID, or use a two-step canonical-ID contract with reliable fallback. Expand common Indian household staples using documented source/preparation metadata. Keep unresolved status when trustworthy numbers remain missing; do not zero-fill or add fuzzy rice/chicken subset matches.
- Existing coverage: deliberately invalid fallback/unrecognized result remains unresolved; no test aligns schema optionality with actual database coverage.

### AI-05 - P2: suggestion cache lacks account ownership and reuses materially different targets

- Location: `lib/services/gemini_food_service.dart:604-645,708`; caller `lib/screens/home/widgets/ai_meal_suggestion_card.dart:93-112,56-62`.
- Trigger: switch accounts on the same device or request suggestions at199 and100 remaining calories, with other bucketed inputs unchanged. The calorie key rounds both down to100. Similar buckets apply to protein/carbs/fat. The caller reads selected date but never passes targetDate; service therefore keys historical requests as today. Caller reset also omits mealsLeft.
- Effect: cached text generated for a different personalized context can appear unchanged. The low remaining-calorie range makes100kcal bucket width especially material. It also leaves misleading date ownership for historical requests. This is separate from the correctly account-bound raw AiCache.
- Evidence: deterministic mock: two services with different credentials and199/100 exact targets used one network call and the same output. Source confirms key includes no account/prompt version and caller omits targetDate. No real private account data was accessed.
- Minimal fix: scope to captured account and prompt version; pass selected targetDate; invalidate on mealsLeft/history/account changes. Cache structured exact context or constrain approximation so cached meal macros are checked against the current budget. Read a valid account cache before requiring a key if offline reuse is desired.
- Existing coverage: no direct suggestion service tests found; scanner raw cache tests do not cover this path.

### AI-06 - P2: remembered-food normalization differs at write and lookup

- Location: `lib/screens/home/widgets/photo_calorie_scanner_sheet.dart:1029-1046` versus `lib/services/nutrition_lookup_service.dart:59-77,128-138`.
- Trigger: save a correction whose name contains punctuation or repeated whitespace, for example Mom's Dal or Iced  Coffee.
- Effect: save stores lowercase only; lookup strips punctuation and collapses whitespace before exact query. The user's own correction is not found, causing unnecessary network use or fallback to generic nutrition. Dart's ASCII word-character normalization also excludes native-script food names, so Romanized Telugu aliases do not imply Telugu-script support.
- Evidence: direct mismatch in production write/read canonicalization. Not exercised through Isar in the new harness.
- Minimal fix: share a canonical food-name function for storage and lookup; migrate/read legacy names safely. Preserve meaningful script characters and keep raw display names. Add punctuation/whitespace/Unicode correction round-trip tests.
- Existing coverage: capitalization/spacing tests cover only bundled lookup entries, not personal persistence.

### AI-07 - P2: streamed text discards finish status before declaring success

- Location: `lib/services/ai_client.dart:1057-1064` maps SDK responses to text only; `952-971` treats any nonempty stream completion as success. `gemini_food_service.dart:697-708` caches successful-looking buffer; CoachNoteNotifier saves it.
- Trigger: provider returns text followed by a non-success finish reason such as token limit or blocked/incomplete termination without a transport error.
- Effect: the partial sentence/meal idea is treated as complete and can be cached. The JSON path already rejects non-STOP finish reasons, but text path loses that information.
- Evidence: source-confirmed metadata discard. Installed SDK's response.text concatenates text and does not validate finishReason; it does correctly exclude thought parts. Official API distinguishes STOP, MAX_TOKENS and other finish reasons. No live provider failure was induced.
- Minimal fix: retain the terminal candidate status and only cache a confirmed complete answer. Keep partial text reviewable with a clear retry state when appropriate. Add raw SDK/SSE fixture tests including terminal-only chunks and premature stream closure.
- Existing coverage: current stream mocks return String, so they cannot represent finishReason or blocked candidate responses.

### AI-08 - P2: nutrition confidence does not distinguish estimated recipes from measured data

- Location: all119 rows of `assets/data/nutrition_table.json` have estimatedtrue; `nutrition_lookup_service.dart:103-124` discards that field; `gemini_food_service.dart:348` returns high for all fully local results, including remembered ai_estimate entries.
- Trigger: use an exact database match or remembered model estimate.
- Effect: internal/persisted confidence is promoted by a lookup match even when portion/recipe data remain estimated. This is not proof of inaccurate arithmetic, but it undermines a trustworthy confidence metric. The current scanner already says AI estimate/check foods and portions, which mitigates user overconfidence; preserve that copy.
- Minimal fix: retain provenance, preparation and estimation metadata separately from recognition confidence. Treat exact measured grams as known quantity, not proof of a standard recipe's nutrition. Avoid presenting a calibrated accuracy percentage until measured.
- Existing coverage: cache confidence immutability tested; calibration/data-source semantics not tested.

### AI-09 - P2: finite but implausible AI nutrition is accepted, and very large portions are silently clamped

- Location: `gemini_food_service.dart:481-482,502-535`; `lib/models/food_nutrition.dart` compute clamps values to large fixed maxima.
- Trigger: an otherwise-valid model payload has an extreme finite per100g nutrient value, or reports an item above1500g (for example a batch/family portion described by the user).
- Effect: validation requires nonnegative finite values but does not catch impossible per100g composition; calculation may cap it into a large accepted resolved value. Grams above1500 are changed silently while the original portion text remains. These are contract gaps, not observed live model error rates.
- Minimal fix: validate generous plausible unit-specific bounds, mark questionable items for review, and request clarification instead of silently changing explicit mass. Do not use strict 4/4/9 equality because labels/fibre/rounding can differ.
- Existing coverage: negative, zero and missing estimated grams and negative fallback are tested; extreme finite values and clamp/portion consistency are not.

### AI-10 - P2: accuracy and latency evidence is not sufficient for a model/quality change

- Location: `test/fixtures/meal_scan/ground_truth.json`, README and COLLECTION_MANIFEST; `test/benchmark/meal_scan_bench.dart`; `image_preprocessor.dart:27-49`; UI preparation at `photo_calorie_scanner_sheet.dart:395-431`.
- Evidence: only three synthetic fixtures exist and all have weighedfalse. Benchmark correctly warns their accuracy values are diagnostics, not measured food accuracy. The service30-second budget begins after UI photo preparation, which can separately wait10seconds; common preparation starts at selection so much is overlapped, but worst-case tap-to-result is not simply30seconds.
- Effect: current test results establish resilience and arithmetic, not actual meal accuracy or phone p95 responsiveness. Model swap, lower image resolution, shorter aggressive cutoff or concurrent model racing would be speculation.
- Minimal next measurement: record real phone tap-to-first-usable-frame, cold/warm preparation, p50/p95, retry rate, cancellation and durable save alongside a representative real-food set including weighed meals, multi-angle meals, household staples, lighting/occlusion and nonfood inputs. Agree accuracy criteria before comparison; retain current models in the meantime.
- No production refactor recommended solely because these measurements are missing.

### AI-11 - P2: coach fallback/consumer can apply stale work during refresh or account transition

- Location: `coach_service.dart:109-126`; `lib/providers/coach_note_notifier.dart:19-24,85-87,166-190`.
- Trigger: force-refresh a note while a prior generation is in flight, or change account without changing selected date.
- Effect: service catch/fallback yields LOCAL and text even if its token was cancelled. Notifier checks date while consuming chunks but does not check requestId until after streaming. Old fallback chunks may overwrite visible state of a new same-date request. Build watches date, not account, and four-hour timestamp key is globally scoped. Source indicates stale/account-state risk; no live account note write was tested.
- Minimal fix: capture request ID/token/account/date and verify each before every state/write; stop fallback on cancellation; watch account lifecycle; scope timestamp key. Keep cached/local notes available rather than a prolonged loader.
- Existing coverage: cache hit, forced refresh, no-key fallback; no competing streams/account transition/disposal cases.

### AI-12 - P2: HTTP errors are misclassified by unrelated request-ID/latency digits

- Location: `lib/services/ai_client.dart:103-141` (`contains('403')` at112 before404 at124); SDK callers `gemini_food_service.dart:764` and `ai_client.dart:878-881`.
- Trigger: a genuine404/not-found SDK exception includes403 in its timestamp-based correlation ID or takes403milliseconds. A429 substring in metadata can similarly turn404 into rateLimited. Error formatting includes request URL, request ID and latency.
- Effect: model unavailability can incorrectly tell the user their API key is invalid, preventing fallback; other errors can enter the wrong retry/cooldown path. This is a runtime correctness issue and explains a source-supported mechanism for the intermittent maintained `gemini_api_key_test` case9 failure in the root regression run.
- Evidence: SDK11.0.0 `errors/exceptions.dart:122-139` appends metadata to ApiException.toString, `utils/request_id.dart:12-15` generates request IDs from millisecondsSinceEpoch; the production classifier scans the entire diagnostic string. Original failing run wrapped the error and did not retain its raw metadata, so the exact offending digits in that occurrence cannot be retrospectively proven. Deterministic observation harness is `build/service-audit/ai-error-classification_test.dart`, using actual SDK exception objects with synthetic metadata; root executed it separately: all four metadata variants reproduced the stated classifications. The clean 404 control remained notFound.
- Minimal fix: classify exception types and numeric `ApiException.statusCode` first, using parsed provider reason/message only where needed (for example invalid key returned as400). For raw HTTP transport, pass numeric status separately. Never infer status from arbitrary digits in a diagnostic string or URL. Handle401/403 explicitly. Keep sanitized user-facing text separate from diagnostics.
- Existing coverage: all-models404 case uses naturally generated timestamps and therefore intermittently exposes this. Add deterministic status-plus-conflicting-metadata tests; do not dismiss a later passing rerun as proof the production issue disappeared.

## Preserve these controls

- Unknown packaged nutrients stay unknown, never silently zero; package label confirmation stays required.
- Mass, volume and servings stay distinct; no universal1ml=1g conversion.
- Barcode logging is deterministic arithmetic and can use saved foods offline; keep it outside photo inference.
- The scanner cancels/guards stale sessions, captures account/date before save and keeps manual recovery. Raw cache failures do not block network or durable save.
- Reject nonfood/empty detections, invalid quantities and malformed JSON; never call an empty meal a successful zero-calorie scan.
- Keep current hero/scan UI and honest progress stages. Service fixes need no new visual system.

## Test coverage and limits

Existing relevant suites inspected: ai_transport_test (HTTP body stall, abort isolation, payload/schema/finish checks), ai_cache_test (TTL, invalid data, transactions and account pinning), ai_resilience_test (inactivity, subscription cancellation, fallback and JSON parse), meal_scan_service_test (cache immutability, nutrition overlap, unresolved values, local parser ambiguity and cancellation), image_preprocessor_test (JPEG retention, PNG MIME conversion, portrait dimensions, corrupt image), nutrition_lookup_service_test (four bundled lookup cases), barcode_food_service_test (27 declared cases covering lookup/unit/schema/errors/timeout), packaged_food_test, barcode_food_store_test and barcode sheet/camera/editor tests, coach_note_notifier_test (three core behaviour cases). Root reported the maintained services/encryption run completed with133 passed,1 skipped and1 failure (`gemini_api_key_test`, all models404). That exact case passed on an isolated rerun; retain the intermittent classification finding AI-12 rather than reporting an entirely clean first run. Broader final totals are recorded by root.

No live API-key verification, model inference, public product request or native camera/HEIC/device-memory benchmark was run. No real user photos/keys were opened or logged. SDK source was read at installed googleai_dart11.0.0/http1.6.0/image4.9.2 to verify actual local semantics.

## Primary references checked

- [Current Gemini models](https://ai.google.dev/gemini-api/docs/models): confirms the four configured IDs exist as of this audit; listing does not establish measured suitability or speed for this app.
- [Gemini generateContent model guidance](https://ai.google.dev/gemini-api/docs/generate-content/latest-model): current configuration documentation; keep model-specific options verified.
- [Gemini response and finish reason reference](https://ai.google.dev/api/generate-content#FinishReason): completion and truncation are different outcomes.
- [Open Food Facts API documentation](https://openfoodfacts.github.io/openfoodfacts-server/api/): read API is public, versioned, rate-limited and community-maintained; custom client identification and honest unknown/manual states are appropriate.

## Suggested implementation order

1. Correct explicit-mass/per-serving metadata and remove powder/drink alias conflation, with end-to-end scaling/logging regression tests.
2. Complete streaming cancellation/terminal handling and protect note/suggestion state with account/date/request ownership.
3. Align food-memory normalization, fallback schema, common-food coverage and provenance.
4. Measure representative phone latency/accuracy; only then compare model, prompt or image-quality changes.
