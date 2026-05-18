# Design Surface — Protected Boundary

**This folder is the design boundary for Audio Recording Manager.**
Everything inside is a deliberate design decision. Outside this folder, the
rest of the app consumes design tokens, button styles, and view modifiers
from here; it does not define new ones.

## Files

| File | Role |
|------|------|
| `DesignTokens.swift` | `AppColors`, `AppSpacing`, `AppRadius`, `AppSize` — colours, spacing, radii, canonical element sizes |
| `AppFont.swift`      | `AppFont` — semantic typography tokens (`.pillLabel`, `.tableCell`, `.screenTitle`, …) |
| `GlassStyles.swift`  | `GlassButtonStyle`, `HoverButtonStyle`, `glassEffectIfAvailable` |
| `HoverCursor.swift`  | `.hoverCursor()` view modifier — pointing-hand on hover, arrow on exit |
| `PillButton.swift`   | `PillButtonStyle(variant:)`, `RunningPill` — pill-shaped buttons + running-progress pill |
| `StatusChipView.swift` | `StatusChipView` — renders a `StatusChip` (label + tone) as a capsule |
| `WindowChrome.swift` | Canonical window-chrome documentation + `TabContentChrome` + `WindowSize` |

## Rules for editing

### 1. Do not "fix" layout by editing this folder

If the app looks off somewhere, it is more likely that a *callsite* is using
the wrong token, or is missing a chrome hook, than that a design token is
wrong. Start with the callsite. Change a token only when the design owner
has explicitly asked for it.

### 2. Do not add chrome workarounds outside this folder

The following patterns are **banned outside `Design/`** because they
historically fought the canonical chrome pipeline:

- `.ignoresSafeArea(edges: .top)` on the main view tree
- `Spacer().frame(height: 52)` as a manual title-bar inset
- `.toolbarBackground(.hidden, for: .windowToolbar)`
- `.navigationTitle("")` added solely to suppress chrome
- Direct `NSWindow` manipulation via `DispatchQueue.main.async` in
  `AppDelegate` (titlebarAppearsTransparent, fullSizeContentView, styleMask,
  titleVisibility)

These were all attempts to wrestle SwiftUI into a particular look. The
current chrome lets SwiftUI do its job via `.windowStyle(.hiddenTitleBar)`
and `.windowToolbarStyle(.unified(showsTitle: false))` on the `WindowGroup`,
plus a single zero-size `.toolbar { }` item in the `.principal` slot to
trigger unified chrome.

**One AppKit exception is sanctioned:** `AppDelegate` configures the
underlying `NSToolbar` on every key window to set
`allowsUserCustomization = false`, `autosavesConfiguration = false`, and
`displayMode = .iconOnly`. This is the only way to suppress the visible
display-mode picker button that NSToolbar would otherwise render for our
chrome-trigger toolbar item. `.toolbar(removing: .sidebarToggle)` on the
SwiftUI side alone proved insufficient on the current macOS build. The
ban above is specifically about four NSWindow properties; NSToolbar is a
separate object and is not on the banned list.

### 3. `VirginProjectApp.body` chrome modifiers and `WindowChrome.swift` must stay in sync

SwiftUI requires the `.windowStyle()` and `.windowToolbarStyle()` modifiers
to be attached directly to the `Scene` in `VirginProjectApp.body`. They
can't be factored into a `ViewModifier`. So the actual modifiers live in
`main.swift`, but the canonical shape is documented in
`WindowChrome.swift`. If you change one, change the other.

### 4. Never hardcode

- A colour → use an `AppColors.*` value. If no token fits, add one here
  first, then use it. **Don't use `Color.gray.opacity(...)` etc. at the
  callsite** — that's what `AppColors.neutralSurface`,
  `AppColors.neutralBorder`, etc. exist for.
- A padding or margin → use an `AppSpacing.*` value.
- A corner radius → use an `AppRadius.*` value.
- A font → use an `AppFont.*` token. **Don't use `.font(.system(size: 11))`
  etc. at the callsite** — if no role fits, add one to `AppFont.swift`
  first.
- A standard element size → use an `AppSize.*` value (pill width, nav-item
  size). Don't sprinkle `.frame(width: 130, height: 26)` literals.

### 5. Adding new tokens is cheap; renaming or removing is not

Adding `AppColors.newFoo = Color(...)` is safe — nothing depends on it yet.
Renaming or removing is a breaking change across the app; `grep` before
deleting.

### 6. Reach for the shared component before rolling your own

If a view needs:
- A pill action button → use `PillButtonStyle(variant:)`, not an inline
  `Capsule().fill(...)`.
- A running-progress pill (cancel while in flight) → use `RunningPill`.
- A clickable surface that should show a pointer cursor → apply
  `.hoverCursor()`, not an inline `.onHover { NSCursor.pointingHand.set() ... }`.
- A status chip rendering a `StatusChip` value → use `StatusChipView`.

Inline copies of these patterns are a code smell. If the shared component
doesn't fit your case, extend the shared component (with an additional
variant or parameter) rather than forking.

## For future Claude sessions

If the user reports a UI regression, the fix is almost certainly **not** in
`Design/`. Start by reading `main.swift` and the view involved — look for
chrome workarounds the list in rule 2 says not to add. Remove them. The
canonical chrome in `VirginProjectApp.body` should carry the rendering.

Do not edit this folder speculatively. If you believe a token needs to
change, ask the user first. Reverting is always cheaper than re-guessing.

When you add a new shared style or view modifier in this folder, also
update this README to mention it under "Files" and the relevant rule.
