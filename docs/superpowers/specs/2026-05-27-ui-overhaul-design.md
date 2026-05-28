# FitTrack — UI Overhaul Design Spec
**Date:** 2026-05-27  
**Status:** Approved (prototype reviewed)

---

## Overview

Full visual redesign of FitTrack from stock iOS to a **Cyber Athletic** aesthetic: electric cyan (#00F5FF) + deep purple (#B000FF) on near-black (#0A0A0A). Navigation structure is unchanged (Dark Hybrid approach — keep iOS NavigationStack/TabView/List, restyle everything inside). Animation level: HUD Energy — spring entrances, momentum charts, PR neon burst, no scan-lines.

---

## Design System

### Palette
| Token | Value | Usage |
|-------|-------|-------|
| `bg` | `#0A0A0A` | App background |
| `surface` | `#0D1117` | Card/row background |
| `surfaceDeep` | `#080B10` | Nested surfaces |
| `borderSubtle` | `#FFFFFF11` | Row separators |
| `borderCyan` | `#00F5FF22` | Card borders (cyan) |
| `borderPurple` | `#B000FF33` | Card borders (purple) |
| `cyan` | `#00F5FF` | Primary accent, data values |
| `cyanDim` | `#00F5FF66` | Muted cyan labels |
| `purple` | `#B000FF` | Secondary accent, CTAs |
| `purpleDim` | `#B000FF44` | Muted purple |
| `textPrimary` | `#FFFFFF` | Main text |
| `textSecondary` | `#FFFFFF99` | Supporting text |
| `textMuted` | `#FFFFFF44` | Labels, captions |

### Typography
Three font roles — all available via Google Fonts / apple system fallback:
| Role | Font | Weight | Usage |
|------|------|--------|-------|
| Display | Orbitron (custom) | 700 | Screen titles, tab labels |
| Label | Rajdhani (custom) / SF Pro Rounded | 600–700 | Pill labels, category tags |
| Data | JetBrains Mono / SF Mono | 400–700 | Numbers, weights, timers |
| Body | SF Pro Text (system) | 400–500 | Descriptions, lists |

Custom fonts registered in Info.plist and loaded via `Font.custom()`.

### Spacing & Radius
- Card corner radius: 16pt
- Inner element radius: 10–12pt
- Button radius: 10pt
- Standard padding: 16pt horizontal, 12pt vertical
- Card gap: 12pt

---

## Architecture: Theme System

### `FitTrack/Theme/Theme.swift`
Central namespace with nested enums:

```swift
enum Theme {
    enum Colors { static let bg, surface, cyan, purple... }
    enum Fonts { static func orbitron(_ size: CGFloat) -> Font }
    enum Animation {
        static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let bounce = Animation.spring(response: 0.35, dampingFraction: 0.6)
    }
    enum Shadow {
        static func glow(_ color: Color, radius: CGFloat = 8) -> some ViewModifier
    }
}
```

### Custom Components (`FitTrack/Theme/Components/`)

| Component | Purpose |
|-----------|---------|
| `NeonCard` | Dark surface card with colored border + optional glow |
| `CyberButton` | Full-width purple gradient button with letter-spaced label |
| `GlowRing` | Circular progress ring using `trim` + `strokeStyle` |
| `StatTile` | Small 3-column metric tile (value + label) |
| `SectionHeader` | All-caps cyan label with letter spacing |
| `NeonBadge` | Colored pill badge (recovery score, session type) |
| `CyberDivider` | Thin line with `#FFFFFF11` |

All components accept a `color: Color` parameter defaulting to `Theme.Colors.cyan`.

---

## Animation System

### Load Animations
Every screen applies `.opacity(0)` + `.offset(y: 20)` → `.opacity(1)` + `.offset(y: 0)` with `Theme.Animation.spring` on `.onAppear`. Cards stagger with `0.05s` delays per index using `.animation(.spring.delay(Double(index) * 0.05))`.

### Tab Transitions
`TabView` wrapped in `.transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))`. State change triggers `.animation(Theme.Animation.spring)`.

### PR Achievement Burst
When `prsHit > 0` in `ActiveSessionView`, a `ZStack` overlay fires:
- Neon cyan ring expands from center (scale 0→1.5 + opacity 1→0) over 0.6s
- "PR" text pulses once with scale bounce
- Implemented as a local `@State var showPRBurst` toggled in `finishSession`

### Data Animations
- Recovery ring: `GlowRing` animates `trim` from 0 to value on `.onAppear`
- Chart lines: `Chart` content appears with `.chartPlotStyle` clip + opacity transition
- Progress bars: `frame(width:)` animated from 0 to target width on appear
- Number counters: not implemented in v1 (SwiftUI lacks a clean count-up modifier without timers)

---

## Per-Screen Changes

### `ContentView.swift` — Tab Bar
- `.tabViewStyle(.automatic)` kept, toolbar appearance overridden
- `UITabBar.appearance()` set: `backgroundColor = .clear`, `backgroundImage = UIImage()`, `shadowImage = UIImage()`
- Custom tab bar NOT built — instead use `toolbarBackground(.hidden, for: .tabBar)` + overlay trick if needed
- Tab icons: SF Symbols, tinted with `Theme.Colors.cyan` when selected, `Theme.Colors.textMuted` when inactive
- Background: solid `Theme.Colors.bg` set as `.background(Theme.Colors.bg.ignoresSafeArea())`

### `TodayView.swift`
**Hero layout — scrollable `VStack` with:**
1. Top row: greeting ("TUESDAY 27 MAY") in Rajdhani 11pt muted, `SectionHeader` for title
2. `NeonCard` (cyan border): recovery ring `GlowRing` + score + recommendation text
3. `NeonCard` (purple border): today's session name, exercise preview, `CyberButton("START SESSION")`
4. `StatTile` row: week number, current body weight, volume this week
5. If no session scheduled: rest day card (muted surface, no border glow)

### `ActiveSessionView.swift`
- Navigation bar: dark, `SectionHeader` title in Orbitron
- Each exercise: `NeonCard` with exercise name in Rajdhani + set rows inside
- Set row (`SetLogRowView`): reps/weight on dark surface rows, completed = cyan checkmark + row tints to `cyanDim` bg
- Whoop badge in toolbar: `NeonBadge` (green/yellow/red based on score)
- Finish button: `CyberButton` at bottom, full width
- PR burst overlay on session complete (see Animation System)

### `ProgressView_.swift`
- Tab segments replaced with styled `Picker` using `.pickerStyle(.segmented)` + custom segment background
- Weight chart: `Chart` with line mark in cyan, point marks in purple, area mark in cyan at 10% opacity
- Goal cards: `NeonCard` per goal, `GlowRing` showing % progress, target date badge

### `ProgramView.swift` / `WeeklyScheduleGridView.swift`
- Week grid: 7-column grid, each cell a `NeonCard` mini-size with colored border per slot type
  - Gym = purple border, Sport = cyan border, Competition = orange (#FF6B00), Rest = muted
- Program header: Orbitron title, week progress bar in cyan
- Session type pills: `NeonBadge` per slot

### `WorkoutTemplateEditorView.swift`
- Exercise list rows: `surface` background, cyan exercise name, muted set/rep/increment detail
- Add exercise button: `CyberButton` style (full-width purple)
- `ExercisePickerSheet`: grouped list with `SectionHeader` per muscle group, cyan checkmark on selected

### `HistoryView.swift`
- Session rows: `NeonCard` with date in Orbitron, session type badge, volume stat
- Per-exercise chart sheets: same Chart styling as ProgressView

### `MusclesView.swift`
- Muscle bars: horizontal `RoundedRectangle` bars colored by fatigue (cyan = fresh, yellow = moderate, red = fatigued)
- Bar height animated on appear
- Suggestion text below each bar in SF Pro Text

### `SettingsView.swift`
- `List` with `.listStyle(.insetGrouped)` — `UITableView.appearance()` set to clear background
- Row backgrounds: `surface` color
- Section headers: `SectionHeader` component
- Whoop connect button: `CyberButton`

### `RecoveryBadgeView.swift`
- Replace with `NeonBadge` — colored capsule, number in JetBrains Mono, label in Rajdhani

---

## Font Registration

Add to `Info.plist`:
```xml
<key>UIAppFonts</key>
<array>
  <string>Orbitron-Bold.ttf</string>
  <string>Rajdhani-SemiBold.ttf</string>
  <string>JetBrainsMono-Regular.ttf</string>
  <string>JetBrainsMono-Bold.ttf</string>
</array>
```

Font files added to `FitTrack/Resources/Fonts/` and registered in Xcode target.

**Fallback:** If fonts fail to load, `Theme.Fonts.orbitron()` returns `.system(.headline, design: .rounded)` etc. — app remains functional.

---

## Implementation Order

1. `Theme.swift` + component files — foundation for everything else
2. Font files added to project
3. `ContentView.swift` — background + tab bar styling
4. `TodayView.swift` — most visible, validates the design direction
5. `ActiveSessionView.swift` + `SetLogRowView.swift` — core workout flow
6. `ProgressView_.swift` + `WeighInEntryView.swift` + `GoalEditorView.swift`
7. `ProgramView.swift` + `WeeklyScheduleGridView.swift` + `WorkoutTemplateEditorView.swift`
8. `HistoryView.swift` + `MusclesView.swift` + `SettingsView.swift` + `RecoveryBadgeView.swift`

---

## Out of Scope for This Pass

- Custom tab bar widget (keep native TabView)
- Dark/light mode toggle (dark only)
- Haptics (can add post-MVP)
- watchOS companion
