# Suggested meals follow-up review

Scope: the Meal ideas card, its screen context, food service, text transport, cache ownership and the boundary with actual food logging. This was a source/test review followed by bounded fixes. No live AI request, nutrition-accuracy study or device timing run was performed.

## Existing controls retained

- Account, date, exact remaining budget, meal count and food history partition persisted ideas. The service provider captures the active account; the card cancels and clears on account generation, selected date or food-log changes.
- Historical dates, unset calorie targets and incomplete logged nutrition do not offer precise remaining-target ideas. Over-target copy is neutral.
- Suggestions are text only. They cannot directly create a food log or change expert plan guidance. Actual intake still uses the existing portion/nutrition review flow.
- Text transport validates STOP completion, rejects blocked/truncated or prematurely closed responses, filters thought parts, cancels stale work and uses a bounded deadline. These are already covered by the shared transport tests.

## Confirmed issues and resulting changes

| Priority | Confirmed behavior before this follow-up | Bounded correction |
| --- | --- | --- |
| P2 | Suggest something else made an identical cached request, so it replayed the same meal. | The explicit alternative action bypasses cache and includes the previous completed idea as something to vary. Normal reopen keeps cache reuse. Service: gemini_food_service.dart:624-680; card: ai_meal_suggestion_card.dart:82-128,353. |
| P2 | Optional preferences initialization/removal/write could fail the request or report a completed answer as interrupted. | Cache reads/writes fail open and waits are bounded. The request deadline includes cache preparation; only completed text is cached. Service: gemini_food_service.dart:674-720,792-811. |
| P2 | An aggregate-only saved meal counted as unlogged; zero/unset macro targets became zero or negative remaining requirements. | Use MealSlotLog.isLogged, pass absent macro targets as null and represent reached targets distinctly. Screen: meal_detail_screen.dart:179-205; service: gemini_food_service.dart:640-650,745-750. |
| P2 | Prompt history retained only the first two food names and treated absent names as proof this was the first meal. It also reused a long photo-analysis prompt with unprovided equipment assumptions. | Include up to 20 distinct recorded names, explicitly acknowledge missing food names, handle no remaining scheduled slots as optional, and use a concise text-specific Indian-meal prompt without assumed equipment. Service: gemini_food_service.dart:724-780. |
| P3 | Streaming cursor ignored reduced-motion preferences. | Cursor animation now respects the same setting as the loading state. Card: ai_meal_suggestion_card.dart:332-343. |

The prompt requests estimated nutrition and realistic portions without requiring the person to finish a numerical remainder. These are input/UX corrections, not proof that a generated meal or its approximate macros are accurate.

## Regression coverage

New maintained suites:

- test/services/suggested_meals_regression_test.dart: fresh alternatives plus subsequent reuse; nullable/reached targets and later food history; optional extra meal; failing/stalled cache reads; failing writes; interrupted responses never cached as completed.
- test/screens/meals/suggested_meals_card_test.dart: alternative action; stale account/log cancellation; interrupted retry; reduced motion and 320px/200% text; aggregate-only logged slots; unknown nutrition gating.

Existing relevant suites remain ai_service_regressions_test.dart (exact account/date/context cache partition), ai_transport_test.dart (real loopback SSE completion and cancellation), ai_boundary_test.dart (expert guidance boundary), and meal_experience_test.dart (history/target gating and neutral over-target copy).

Direct Dart analysis: no errors or warnings in the changed production files; focused test files have no analyzer issues. git diff --check passed. The 13 new meal-suggestion regressions passed centrally and are included in the full 757-pass / 1-existing-skip suite. See [combined verification](tests-trophies-and-guidance-review.md).
