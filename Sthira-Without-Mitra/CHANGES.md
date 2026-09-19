# Changelog

## [Premium Share Export Engine]
- **Exporter Engine:** Rebuilt `share_card_exporter.dart` into a pure stateless off-stage rendering pipeline. Cards are now natively painted at fixed internal sizes (logical 360x450 for Post, 360x640 for Story) independent of phone resolution, ignoring screen text scaling or padding. Rendered at `3.0` Pixel Ratio to yield an exact WhatsApp/Instagram native `1080px` wide PNG.
- **Daily Share Layout:** Created `daily_share_layout.dart`. Abandoned the legacy text-theme inheritance and bright gradient. Uses rigid `Cabinet Grotesk` fonts overriding the prompt's `Quicksand` alongside a pure Sthira `#171F1B` surface and glowing `Sandy Peach` aura. Prevents long names from breaking bounds via active `FittedBox`.
- **Preview Sheet Upgrade:** Restructured `share_preview_sheet.dart` to feature Post (4:5) / Story (9:16) format toggle chips. The display now previews the ACTUAL `daily_share_layout.dart` scaled into a local bounds box via `FittedBox` constraint binding rather than relying on a look-alike widget.
- **Weekly Share Integration:** Created `weekly_share_layout.dart` mirroring the premium Export layout containing a 7-core stat overview and an intrinsic bar graph. Refactored `weekly_summary_screen.dart` to automatically default to this image generation flow while preserving classic text sharing on a secondary button click.

## [Sthira Aesthetic & AI Polish]
- **Surface Cards:** Refined light-mode hierarchy by utilizing a 1px `border` hairline and subduing shadow blur radii away from a floating card visual into a grounded tile style. 
- **Scanner Experience:** Added a 4px dominant macro (Protein/Carb/Fat) color identifier strip to each resolved item inside the calorie breakdown. Subdued the confidence output into a small Sthira chip element.
- **Scanner Photo Context:** Restored context at the payload level by injecting a 48px thumbnail derived directly from `_selectedImages.first` right onto the `TOTAL` sum block.
- **AI Suggestion Stream:** Swapped the loading ring for a `flutter_animate` skeleton shimmer mapping to exact line lengths. Stream text output now pulses a dynamic cursor (`▍`) immediately as it generates for better feedback.

## [AI Meal System: Final Accuracy & Speed Pass]
- **Silent-Zero Defeated:** Stopped caching failed macroscopic lookups disguised as `kcal: 0`. Items that cannot be resolved now explicitly raise a `resolved: false` flag.
- **Accuracy Fallback UI:** Unresolved items dynamically update the UI to exclude their zeroes from the total count and display a Sthira-styled dashed outline prompting the user, "+N to review".
- **Portion Multiplier Chips:** Injected instant ½, 1×, 1½ scale toggles directly onto scanner rows to allow one-tap portion sizing.
- **Latency Overhaul:** Updated the AI `GenerationConfig` generation properties to limit thinking overhead and reduce total latency by utilizing `temperature: 0.1` and explicit extraction optimization.

## [Premium Trophy Room Update]
- **Phase 0:** Consolidated achievement systems. Deleted `lib/models/achievement_badge.dart` and `lib/screens/profile/widgets/badge_card_widget.dart` as they were redundant. Profile now exclusively renders the unified `Badge` system via `TrophyRoomCard`.
- **Phase 1:** Fixed achievement unlock bug where rapid unlocks overwrote each other. `badgeUnlockEventProvider` is now a queue (`Notifier<List<Badge>>`) that sequentially processes unlocks with a 400ms delay between celebrations.
- **Phase 2:** Upgraded the `BadgeOverlayHost` unlock moment. Added a Glass banner with a gold Medallion, `flutter_animate` elastic entry, shine shimmer, and `confetti` bursts on unlock. Tap navigates to the Trophy Room; swipe up dismisses.
- **Phase 3:** Rebuilt `TrophyRoomCard`. Improved type safety (removed `dynamic`). Added "Next Up" spotlight. Tiles are now sorted and differentiate clearly between unlocked (gold medallion with shimmer and 'NEW' tag) and locked (grayscale with progress rings). Added a bottom sheet (`AppSheet`) detail view for all badges.

## [AI Architecture Simplification]
- **Root Cause & Fix:** The `useFirebase` flag silently rerouted signed-in users from their Google AI Studio API key to a deactivated Firebase Vertex AI backend, causing food scanning and coach generation to fail. The entire Firebase path has been stripped. All AI features now exclusively use the user's provided Gemini API key.
- **Error Hygiene:** Upgraded `AiErrorCause` classifier to intercept `PERMISSION_DENIED`, `SERVICE_DISABLED`, and deactivated keywords, mapping them to a clear human-readable message instructing the user to check their Google AI Studio project status.
- **Settings Clarity:** Cleaned up the AI Setup Sheet in the Profile screen to clearly state that food scanning and coach depend on the Gemini API key, removing outdated statements about Cloud Sync exceptions.
