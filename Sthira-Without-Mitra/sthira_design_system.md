# Sthira Design System Reference

Here is your beautifully structured **Sthira Design System** cheat sheet, reflecting our dark, grounded, borderless, and premium "Steady Aura" aesthetic!

<br>

<div style="background: #181818; padding: 40px; border-radius: 24px; color: white; font-family: 'General Sans', system-ui, -apple-system, sans-serif; max-width: 700px; box-shadow: 0 20px 40px rgba(0,0,0,0.4);">
  
  <div style="display: flex; justify-content: space-between; align-items: flex-end; margin-bottom: 32px;">
    <div>
      <h2 style="margin: 0; font-family: 'Cabinet Grotesk', sans-serif; font-size: 32px; font-weight: 800; color: #E29B65; letter-spacing: -1px;">Sthira</h2>
      <div style="color: #7FA35C; font-weight: 500; font-size: 16px; margin-top: 4px;">steady, borderless, every day</div>
    </div>
    <div style="text-align: right;">
      <div style="font-size: 12px; color: rgba(255,255,255,0.4); text-transform: uppercase; letter-spacing: 2px;">Design System</div>
    </div>
  </div>

  <!-- Typography -->
  <div style="display: flex; gap: 16px; margin-bottom: 32px;">
    <div style="background: #171F1B; padding: 24px; border-radius: 16px; flex: 1; border: 1px solid rgba(255,255,255,0.05);">
      <div style="font-size: 13px; color: #B5A5AA; margin-bottom: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 1px;">Headline</div>
      <div style="font-family: 'Cabinet Grotesk', sans-serif; font-size: 32px; font-weight: 800; color: #E29B65; letter-spacing: -0.5px; line-height: 1.1;">Cabinet<br>Grotesk</div>
    </div>
    <div style="background: #171F1B; padding: 24px; border-radius: 16px; flex: 1; border: 1px solid rgba(255,255,255,0.05);">
      <div style="font-size: 13px; color: #B5A5AA; margin-bottom: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 1px;">Body</div>
      <div style="font-family: 'General Sans', sans-serif; font-size: 32px; font-weight: 400; color: #EFE8EA; line-height: 1.1;">General<br>Sans</div>
    </div>
  </div>

  <!-- Colors -->
  <div style="display: flex; flex-direction: column; gap: 12px;">
    
    <div style="background: #0F1513; padding: 20px 24px; border-radius: 16px; display: flex; justify-content: space-between; align-items: center; border: 1px solid rgba(255,255,255,0.1);">
      <span style="font-weight: 700; font-size: 18px; color: white;">Deep Forest Black <span style="font-weight: 400; font-size: 14px; opacity: 0.6; margin-left: 8px;">Scaffold Background</span></span>
      <span style="font-family: monospace; font-size: 16px; color: white; opacity: 0.8;">#0F1513</span>
    </div>
    
    <div style="background: #171F1B; padding: 20px 24px; border-radius: 16px; display: flex; justify-content: space-between; align-items: center; border: 1px solid rgba(255,255,255,0.05);">
      <span style="font-weight: 700; font-size: 18px; color: white;">Dark Surface <span style="font-weight: 400; font-size: 14px; opacity: 0.6; margin-left: 8px;">Cards & Bottom Sheets</span></span>
      <span style="font-family: monospace; font-size: 16px; color: white; opacity: 0.8;">#171F1B</span>
    </div>
    
    <div style="background: #E29B65; padding: 20px 24px; border-radius: 16px; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 4px 12px rgba(0,0,0,0.2);">
      <span style="font-weight: 700; font-size: 18px; color: #2D1A25;">Sandy Peach <span style="font-weight: 500; font-size: 14px; opacity: 0.7; margin-left: 8px;">Primary Accent & Buttons</span></span>
      <span style="font-family: monospace; font-size: 16px; color: #2D1A25; opacity: 0.9;">#E29B65</span>
    </div>
    
    <div style="background: #EFE8EA; padding: 20px 24px; border-radius: 16px; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 4px 12px rgba(0,0,0,0.2);">
      <span style="font-weight: 700; font-size: 18px; color: #2D1A25;">Off-White <span style="font-weight: 500; font-size: 14px; opacity: 0.7; margin-left: 8px;">Primary Text</span></span>
      <span style="font-family: monospace; font-size: 16px; color: #2D1A25; opacity: 0.9;">#EFE8EA</span>
    </div>
    
    <div style="background: #B5A5AA; padding: 20px 24px; border-radius: 16px; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 4px 12px rgba(0,0,0,0.2);">
      <span style="font-weight: 700; font-size: 18px; color: #2D1A25;">Muted Sage/Sand <span style="font-weight: 500; font-size: 14px; opacity: 0.7; margin-left: 8px;">Secondary Text</span></span>
      <span style="font-family: monospace; font-size: 16px; color: #2D1A25; opacity: 0.9;">#B5A5AA</span>
    </div>
    
  </div>
</div>

## DESIGN CONTEXT: "Sthira Minimalist Tile Style"

When building or refactoring lists, menus, or repeating items—such as the "MEALS" or "HABITS" sections—strictly adhere to the **Sthira Minimalist Tile Style** based on the exact visual anatomy:
1. **The Tile Foundation (Rounded Cards):** Use distinct, softly lifted cards (`SurfaceCard` or bounded `Container`) floating on the dark scaffold. The tile's background color should be the slightly lighter `Dark Surface` (`#171F1B`) using a substantial corner radius (e.g., `24px`). Do NOT make them entirely transparent/flush; the tile boundary is crucial.
2. **Elegant Typography Hierarchy:** Inside the tile, primary titles are cleanly weighted (e.g., bold `w700`, ~18px, `Off-White` text). Directly beneath them, subtitles sit flush with a lighter weight and muted color (e.g., `Muted Sage`).
3. **Muted Structural Separators:** Instead of harsh 1px `Divider` lines, use thick but heavily subdued horizontal bars (e.g., a 4px tall progress track where the background color nearly blends into the card background) to separate header context from numeric data.
4. **Data Rows & Pill Tags:** Secondary metrics (like `0/4 meals • 0/1400 kcal`) remain purely typographic, while distinct entities like macros (`P: 0g`, `C: 0g`, `F: 0g`) should be placed in highly compact, outlined, pill-shaped tags with distinct but muted accent colors to denote their type without overpowering the dark aesthetic.
5. **Minimal Trailing Elements:** Navigable tiles should place a simple, un-boxed chevron (e.g., `Icons.arrow_forward_ios_rounded`, size 16, muted grey) cleanly on the far right. No heavy button backgrounds.
6. **Negative Space over Clutter:** Maintain generous internal padding inside the tiles (e.g., `padding: EdgeInsets.all(20)`) so the typography and elements have maximum breathing room.

## DESIGN CONTEXT: "Section Headers & Hero Metrics"

When organizing sections (like "HABITS", "MEALS", or "DAILY PROGRESS") and presenting hero scores, strictly replicate the following typographic anatomy:
1. **Section Headers (Sentence Case):** Headings that introduce entire sections must act as clean dividers. Use sentence case, a small font size (~15-16px), medium/bold weight (`w600`), and normal tracking. Their color is usually an accent (like the `#E29B65` Sandy Peach) to clearly delineate areas on the dark scaffold. Do not force all-caps or extreme spacing.
2. **Integrated Header Scores:** Instead of massive distinct metric cards, integrate the hero score for a section directly into the section header text using parentheses if applicable (e.g., `HABITS (0/3)`). This provides an instant summary without occupying vertical space.
3. **Header Decorators:** Feel free to use tiny, simple leading or trailing icons (like a small line chart or a pencil edit icon) perfectly baselined with the section header text.
4. **Hero Stats within Tiles:** When hero data lives *inside* a tile (like `Today's Meals`), it must avoid thick structural rings or colored pie charts. Instead, list the core progressive stats on a single typographic line (`0/4 meals • 0/1400 kcal`). This maximizes data density while relying absolutely zero on "boxiness" or generic gamified styles.

## BOTTOM NAVIGATION STYLE: "Floating Pill Navigation"

Our Bottom Navigation Bar breaks away from the standard material design to provide a highly tactile, premium feel:
1. **Floating Pill Layout:** The bar is not anchored directly to the bottom edge. It uses `SafeArea` and floats above the screen bottom (`padding: EdgeInsets.only(left: 32, right: 32, bottom: 16)`). The container height is `64` with `BorderRadius.circular(40)` and the `Dark Surface` color (`#171F1B`).
2. **Animated Selection Pills:** Navigation items use an `AnimatedContainer` (`250ms`, `Curves.easeOutCubic`) that expands horizontally when selected (`horizontal: 24` padding when active vs `12` when inactive). The active item receives a pill background in `Sandy Peach` (`#E29B65`) with `BorderRadius.circular(32)`.
3. **Icon State Swapping:** We use distinctly different icons for active vs inactive states to enhance feedback:
   - **Inactive:** Use `_outlined` icons (e.g., `Icons.home_outlined`) colored in a muted grey-green (`Color(0xFF8A9A93)`).
   - **Active:** Use `_rounded` (filled) icons (e.g., `Icons.home_rounded`) colored in dark text (`OnPrimary`).
4. **Haptics:** Tapping a navigation item must trigger a light haptic feedback (`Haptics.tap()`).

## APP ARCHITECTURE & SYSTEM DESIGN

When building or modifying core features, adhere to the following system architecture:

### 1. State Management (Riverpod)
- Use **Riverpod** for all state management.
- Prefer `NotifierProvider` and `AsyncNotifierProvider` over `StateProvider` for complex logic.
- UI components should only use `ref.watch()` to react to state changes, not to handle heavy computation. Keep business logic in the Notifiers or Providers.
- Provide dependencies globally in `app_providers.dart` (e.g., `dailyLogRepoProvider`).

### 2. Data Layer (Repository Pattern & Isar)
- Use **Isar** for local, offline-first data storage.
- All database interactions must go through a **Repository** (e.g., `HabitRepository`, `DailyLogRepository`).
- Repositories should hide Isar-specific syntax from the rest of the app.
- For generated models, ensure all Isar collections (`@collection`) have `part 'model_name.g.dart';` and run `build_runner` after changes.

### 3. Service Layer
- External APIs, third-party integrations, and complex operations go into the **Services** layer (e.g., `HealthConnectService`, `GeminiFoodService`).
- Services are stateless and injected via Riverpod.

### 4. Code Organization
- **`/models`**: Isar collections and pure data classes.
- **`/repositories`**: DB wrapper classes.
- **`/services`**: External API and sync logic.
- **`/providers`**: Riverpod state and dependency injection.
- **`/screens`**: Feature-based UI organization.
- **`/theme`**: Global styles (`app_colors.dart`, `app_theme.dart`).
