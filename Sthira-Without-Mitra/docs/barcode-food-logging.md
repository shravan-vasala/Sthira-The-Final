# Packaged food barcode logging

The meal screen now offers **Scan packaged food** inside each meal slot, replacing the Visual Plate Calculator. The existing photo/description flow remains available for prepared meals.

## User flow

1. Scan an EAN/UPC retail barcode, or enter its printed digits when the camera is unavailable or permission is denied.
2. Review the product name, brand and label nutrition. Missing values stay unknown. If the database cannot establish grams versus millilitres, confirm the basis from the package label.
3. Enter the amount eaten in grams, millilitres or servings. Serving/half-pack/whole-pack shortcuts appear only when their units can be used without guessing.
4. Review the calculated portion and add it to the selected meal/date. Existing foods and photos are preserved.
5. Previously added products appear as device-local shortcuts for the same account. Their last amount remains editable and the saved product works offline.

A missing product or network error offers manual label entry. All four nutrition values and an explicit basis are required; zero must be entered explicitly. Values edited here are saved locally, not published to Open Food Facts.

## India and data quality

Lookup uses Open Food Facts API v3 with India (`cc=in`) and English (`lc=en`) context. These parameters do not guarantee coverage of every Indian product. A successful live lookup of Amul Taaza barcode `8901262150217` returned nutrients but no reliable mass/volume unit. The parser deliberately requires confirmation for that entry; it never infers millilitres from the product name. One product is not a coverage benchmark. Test actual household products before making coverage claims.

Open Food Facts calls per-100-ml nutrient fields `_100g` too. The parser checks explicit package/serving units, keeps uncertain bases unset, converts kJ to kcal only when kcal is absent, and leaves missing/qualified nutrient values unknown. It does not convert ml to g. Product responses with a mismatching barcode, unexpected status or non-food type are rejected.

Source attribution links directly to the Open Food Facts product page. The data is community maintained: users should compare it with their current pack. This flow does not use AI to invent a missing product or its nutrients.

## Persistence and responsiveness

- A barcode scan returns once, stops the camera during manual entry/backgrounding/navigation, and expands detected UPC-E codes before lookup.
- Lookups request selected fields, have a 10-second deadline, and give retry or label-entry options on failure. Stale results cannot replace a later user choice.
- Saved shortcuts are bounded to 60 products per account/market, keyed by barcode rather than product name. Equivalent UPC-A/EAN/GTIN representations reuse a shortcut.
- Each meal stores its own label and calculated nutrition snapshot, barcode, brand, basis and explicit consumed quantity. Database or shortcut updates do not alter historical meals.
- Append reads the existing meal inside an Isar transaction and includes the cloud sync queue item. The original account/database is retained for an in-flight write. A later shortcut or sync-scheduling failure does not invite a duplicate meal submission.
- Copy/repeat and the existing meal editor retain barcode metadata. Free-text portion changes clear stale numeric amounts; scaling uses the recorded nutrition snapshot.

Shortcuts stay on this device. Meal snapshots use the existing meal backup/sync path. No API key is needed for public product lookup.

## Validation

At the barcode implementation checkpoint, the full Flutter suite passed **270 tests**, with one pre-existing platform-channel integration placeholder skipped. The 11 barcode review-flow tests were rerun after the final action placement change. New barcode production files have a clean targeted analyzer result; the existing meal screen retains its prior unused/protected-member warnings. Visual checks passed in light/dark mode and at 320 px with 2x text. Validation used Flutter 3.47.5 / Dart 3.13.4.

Automated tests cover parsing, units, missing values, HTTP errors/timeouts, cache isolation/corruption, camera lifecycle, label validation, portion calculations, concurrent appends, selected dates and legacy log compatibility. Widget checks cover narrow screens, large text and keyboard insets. See `test/models/packaged_food_test.dart`, `test/services/barcode_food_service_test.dart`, `test/repositories/*barcode*`, `test/repositories/packaged_meal_append_test.dart` and `test/screens/meals/`.

Native APK/device validation is pending: this workspace has Flutter but no Android SDK. Verify camera focus, torch, permission deny/retry and EAN/UPC decoding on a physical Android phone, including several real Indian packages and poor lighting. This repository currently has Android configuration only; adding an iOS target would also need camera usage permission text.

References: [Open Food Facts product API](https://openfoodfacts.github.io/documentation/docs/Product-Opener/v3/products/get-api-v3-product-code/), [Open Food Facts API introduction](https://openfoodfacts.github.io/openfoodfacts-server/api/), [mobile_scanner](https://pub.dev/packages/mobile_scanner).
