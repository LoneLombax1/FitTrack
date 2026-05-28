# FitTrack UI Overhaul — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign every FitTrack screen to the Cyber Athletic aesthetic — electric cyan (#00F5FF) + deep purple (#B000FF) on near-black (#0A0A0A) — with HUD Energy spring animations, using a shared Theme system and reusable SwiftUI components.

**Architecture:** Dark Hybrid — keep all NavigationStack/TabView/List structure intact. New `FitTrack/Theme/` folder provides color constants, font helpers, animation presets, and 7 reusable SwiftUI components. Views are restyled in-place using these components. No data model changes.

**Tech Stack:** SwiftUI, SwiftData, iOS 17+, custom fonts (Orbitron Bold, Rajdhani SemiBold, JetBrains Mono Regular + Bold), Swift Charts

**Note on testing:** This is a visual overhaul with no new business logic. All "test" steps are build-and-verify in the iOS Simulator rather than unit tests.

---

## File Map

**New files (create):**
- `FitTrack/Theme/Theme.swift` — color/font/animation constants
- `FitTrack/Theme/Components/NeonCard.swift` — dark surface card
- `FitTrack/Theme/Components/CyberButton.swift` — full-width purple CTA button
- `FitTrack/Theme/Components/GlowRing.swift` — animated progress ring
- `FitTrack/Theme/Components/StatTile.swift` — small metric tile
- `FitTrack/Theme/Components/SectionHeader.swift` — all-caps cyan label
- `FitTrack/Theme/Components/NeonBadge.swift` — colored capsule badge
- `FitTrack/Theme/Components/CyberDivider.swift` — subtle divider
- `FitTrack/Resources/Fonts/Orbitron-Bold.ttf` — display font
- `FitTrack/Resources/Fonts/Rajdhani-SemiBold.ttf` — label font
- `FitTrack/Resources/Fonts/JetBrainsMono-Regular.ttf` — data font
- `FitTrack/Resources/Fonts/JetBrainsMono-Bold.ttf` — data font bold

**Modified files:**
- `FitTrack.xcodeproj/project.pbxproj` — register all new Swift files + font resources
- `FitTrack/Info.plist` — register custom fonts
- `FitTrack/ContentView.swift` — tab bar dark styling
- `FitTrack/Views/Today/TodayView.swift` — full hero layout
- `FitTrack/Views/Today/RecoveryBadgeView.swift` — GlowRing + NeonBadge
- `FitTrack/Views/Session/SetLogRowView.swift` — dark row styling
- `FitTrack/Views/Session/ActiveSessionView.swift` — dark cards + PR burst
- `FitTrack/Views/Progress/ProgressView_.swift` — styled charts + goal cards
- `FitTrack/Views/Progress/WeighInEntryView.swift` — dark form
- `FitTrack/Views/Progress/GoalEditorView.swift` — dark form
- `FitTrack/Views/Program/ProgramView.swift` — NeonCard program rows
- `FitTrack/Views/History/HistoryView.swift` — dark session rows
- `FitTrack/Views/Muscles/MusclesView.swift` — animated fatigue bars
- `FitTrack/Views/Settings/SettingsView.swift` — dark form styling

---

## Task 1: Theme.swift

**Files:**
- Create: `FitTrack/Theme/Theme.swift`

- [ ] **Step 1: Create the Theme directory and file**

```bash
mkdir -p "/Users/tristancummins/Desktop/Claude Projects/FitTrack/FitTrack/Theme/Components"
```

- [ ] **Step 2: Write Theme.swift**

```swift
// FitTrack/Theme/Theme.swift
import SwiftUI

enum Theme {

    // MARK: - Colors
    enum Colors {
        static let bg          = Color(hex: "0A0A0A")
        static let surface     = Color(hex: "0D1117")
        static let surfaceDeep = Color(hex: "080B10")

        static let borderSubtle = Color.white.opacity(0.067)
        static let borderCyan   = Color(hex: "00F5FF").opacity(0.13)
        static let borderPurple = Color(hex: "B000FF").opacity(0.20)

        static let cyan       = Color(hex: "00F5FF")
        static let cyanDim    = Color(hex: "00F5FF").opacity(0.4)
        static let purple     = Color(hex: "B000FF")
        static let purpleDim  = Color(hex: "B000FF").opacity(0.27)

        static let textPrimary   = Color.white
        static let textSecondary = Color.white.opacity(0.6)
        static let textMuted     = Color.white.opacity(0.27)

        static func recovery(_ score: Int) -> Color {
            switch score {
            case 75...: return Color(hex: "00FF88")
            case 50..<75: return Color(hex: "FFB800")
            default: return Color(hex: "FF3B5C")
            }
        }
    }

    // MARK: - Typography
    enum Fonts {
        static func orbitron(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            if UIFont(name: "Orbitron-Bold", size: size) != nil {
                return Font.custom("Orbitron-Bold", size: size)
            }
            return .system(size: size, weight: weight, design: .rounded)
        }

        static func rajdhani(_ size: CGFloat) -> Font {
            if UIFont(name: "Rajdhani-SemiBold", size: size) != nil {
                return Font.custom("Rajdhani-SemiBold", size: size)
            }
            return .system(size: size, weight: .semibold, design: .rounded)
        }

        static func mono(_ size: CGFloat, bold: Bool = false) -> Font {
            let name = bold ? "JetBrainsMono-Bold" : "JetBrainsMono-Regular"
            if UIFont(name: name, size: size) != nil {
                return Font.custom(name, size: size)
            }
            return .system(size: size, weight: bold ? .bold : .regular, design: .monospaced)
        }
    }

    // MARK: - Animation
    enum Anim {
        static let spring = Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let bounce = Animation.spring(response: 0.35, dampingFraction: 0.6)
        static let fast   = Animation.spring(response: 0.25, dampingFraction: 0.8)
    }

    // MARK: - Layout
    enum Layout {
        static let cardRadius: CGFloat = 16
        static let innerRadius: CGFloat = 10
        static let buttonRadius: CGFloat = 10
        static let screenPadding: CGFloat = 16
        static let cardGap: CGFloat = 12
    }
}

// MARK: - Color hex init
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Glow shadow modifier
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}

extension View {
    func neonGlow(_ color: Color = Theme.Colors.cyan, radius: CGFloat = 8) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Appear animation modifier
struct AppearAnimationModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(Theme.Anim.spring.delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func appearAnimation(delay: Double = 0) -> some View {
        modifier(AppearAnimationModifier(delay: delay))
    }
}
```

- [ ] **Step 3: Commit**

```bash
cd "/Users/tristancummins/Desktop/Claude Projects/FitTrack"
git add FitTrack/Theme/Theme.swift
git commit -m "feat: add Theme.swift — colors, fonts, animations, glow modifier"
```

---

## Task 2: Core Components

**Files:**
- Create: `FitTrack/Theme/Components/NeonCard.swift`
- Create: `FitTrack/Theme/Components/CyberButton.swift`
- Create: `FitTrack/Theme/Components/GlowRing.swift`
- Create: `FitTrack/Theme/Components/StatTile.swift`
- Create: `FitTrack/Theme/Components/SectionHeader.swift`
- Create: `FitTrack/Theme/Components/NeonBadge.swift`
- Create: `FitTrack/Theme/Components/CyberDivider.swift`

- [ ] **Step 1: Write NeonCard.swift**

```swift
// FitTrack/Theme/Components/NeonCard.swift
import SwiftUI

struct NeonCard<Content: View>: View {
    var borderColor: Color = Theme.Colors.borderCyan
    var glow: Bool = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(Theme.Layout.screenPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .if(glow) { $0.neonGlow(borderColor, radius: 10) }
    }
}

extension View {
    @ViewBuilder func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition { transform(self) } else { self }
    }
}
```

- [ ] **Step 2: Write CyberButton.swift**

```swift
// FitTrack/Theme/Components/CyberButton.swift
import SwiftUI

struct CyberButton: View {
    let title: String
    let action: () -> Void
    var color: Color = Theme.Colors.purple

    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(Theme.Anim.bounce) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(Theme.Anim.bounce) { pressed = false }
                action()
            }
        }) {
            Text(title)
                .font(Theme.Fonts.rajdhani(15))
                .kerning(2)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.buttonRadius))
                .neonGlow(color, radius: 6)
                .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 3: Write GlowRing.swift**

```swift
// FitTrack/Theme/Components/GlowRing.swift
import SwiftUI

struct GlowRing: View {
    let value: Double   // 0.0 – 1.0
    var size: CGFloat = 72
    var lineWidth: CGFloat = 6
    var color: Color = Theme.Colors.cyan
    var label: String = ""

    @State private var animatedValue: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: animatedValue)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .neonGlow(color, radius: 6)
            if !label.isEmpty {
                Text(label)
                    .font(Theme.Fonts.mono(size * 0.22, bold: true))
                    .foregroundStyle(color)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(Theme.Anim.spring.delay(0.1)) {
                animatedValue = min(max(value, 0), 1)
            }
        }
        .onChange(of: value) { _, newVal in
            withAnimation(Theme.Anim.spring) {
                animatedValue = min(max(newVal, 0), 1)
            }
        }
    }
}
```

- [ ] **Step 4: Write StatTile.swift**

```swift
// FitTrack/Theme/Components/StatTile.swift
import SwiftUI

struct StatTile: View {
    let value: String
    let label: String
    var color: Color = Theme.Colors.cyan

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Theme.Fonts.mono(18, bold: true))
                .foregroundStyle(color)
            Text(label)
                .font(Theme.Fonts.rajdhani(10))
                .kerning(1.5)
                .foregroundStyle(Theme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.innerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Layout.innerRadius)
                .stroke(Theme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}
```

- [ ] **Step 5: Write SectionHeader.swift**

```swift
// FitTrack/Theme/Components/SectionHeader.swift
import SwiftUI

struct SectionHeader: View {
    let title: String
    var color: Color = Theme.Colors.cyan

    var body: some View {
        Text(title.uppercased())
            .font(Theme.Fonts.rajdhani(11))
            .kerning(2.5)
            .foregroundStyle(color)
    }
}
```

- [ ] **Step 6: Write NeonBadge.swift**

```swift
// FitTrack/Theme/Components/NeonBadge.swift
import SwiftUI

struct NeonBadge: View {
    let text: String
    var color: Color = Theme.Colors.cyan

    var body: some View {
        Text(text)
            .font(Theme.Fonts.rajdhani(11))
            .kerning(1.5)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }
}
```

- [ ] **Step 7: Write CyberDivider.swift**

```swift
// FitTrack/Theme/Components/CyberDivider.swift
import SwiftUI

struct CyberDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Colors.borderSubtle)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}
```

- [ ] **Step 8: Commit all components**

```bash
cd "/Users/tristancummins/Desktop/Claude Projects/FitTrack"
git add FitTrack/Theme/Components/
git commit -m "feat: add 7 reusable Cyber Athletic SwiftUI components"
```

---

## Task 3: Register Theme files in Xcode project

The new `Theme/` Swift files must be added to `FitTrack.xcodeproj/project.pbxproj`. Use the pattern below — generate unique 24-char hex IDs for each file.

**Files:**
- Modify: `FitTrack.xcodeproj/project.pbxproj`

- [ ] **Step 1: Generate UUIDs for the 8 new Swift files**

Run this to generate 16 UUIDs (one PBXFileReference + one PBXBuildFile per Swift file — 8 files = 16 UUIDs):

```bash
for i in $(seq 1 16); do uuidgen | tr -d '-' | cut -c1-24; done
```

Label the output pairs as follows (file ref first, build file second):
1. Theme.swift → REF_THEME, BUILD_THEME
2. NeonCard.swift → REF_NEONCARD, BUILD_NEONCARD
3. CyberButton.swift → REF_CYBERBTN, BUILD_CYBERBTN
4. GlowRing.swift → REF_GLOWRING, BUILD_GLOWRING
5. StatTile.swift → REF_STATTILE, BUILD_STATTILE
6. SectionHeader.swift → REF_SECTIONHDR, BUILD_SECTIONHDR
7. NeonBadge.swift → REF_NEONBADGE, BUILD_NEONBADGE
8. CyberDivider.swift → REF_CYBERDIV, BUILD_CYBERDIV

- [ ] **Step 2: Add PBXFileReference entries**

In `project.pbxproj`, locate the `/* Begin PBXFileReference section */` block. Add these lines inside it (replace placeholders with actual UUIDs):

```
		REF_THEME /* Theme.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Theme.swift; sourceTree = "<group>"; };
		REF_NEONCARD /* NeonCard.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NeonCard.swift; sourceTree = "<group>"; };
		REF_CYBERBTN /* CyberButton.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CyberButton.swift; sourceTree = "<group>"; };
		REF_GLOWRING /* GlowRing.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = GlowRing.swift; sourceTree = "<group>"; };
		REF_STATTILE /* StatTile.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = StatTile.swift; sourceTree = "<group>"; };
		REF_SECTIONHDR /* SectionHeader.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SectionHeader.swift; sourceTree = "<group>"; };
		REF_NEONBADGE /* NeonBadge.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NeonBadge.swift; sourceTree = "<group>"; };
		REF_CYBERDIV /* CyberDivider.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CyberDivider.swift; sourceTree = "<group>"; };
```

- [ ] **Step 3: Add PBXBuildFile entries**

Locate `/* Begin PBXBuildFile section */`. Add:

```
		BUILD_THEME /* Theme.swift in Sources */ = {isa = PBXBuildFile; fileRef = REF_THEME /* Theme.swift */; };
		BUILD_NEONCARD /* NeonCard.swift in Sources */ = {isa = PBXBuildFile; fileRef = REF_NEONCARD /* NeonCard.swift */; };
		BUILD_CYBERBTN /* CyberButton.swift in Sources */ = {isa = PBXBuildFile; fileRef = REF_CYBERBTN /* CyberButton.swift */; };
		BUILD_GLOWRING /* GlowRing.swift in Sources */ = {isa = PBXBuildFile; fileRef = REF_GLOWRING /* GlowRing.swift */; };
		BUILD_STATTILE /* StatTile.swift in Sources */ = {isa = PBXBuildFile; fileRef = REF_STATTILE /* StatTile.swift */; };
		BUILD_SECTIONHDR /* SectionHeader.swift in Sources */ = {isa = PBXBuildFile; fileRef = REF_SECTIONHDR /* SectionHeader.swift */; };
		BUILD_NEONBADGE /* NeonBadge.swift in Sources */ = {isa = PBXBuildFile; fileRef = REF_NEONBADGE /* NeonBadge.swift */; };
		BUILD_CYBERDIV /* CyberDivider.swift in Sources */ = {isa = PBXBuildFile; fileRef = REF_CYBERDIV /* CyberDivider.swift */; };
```

- [ ] **Step 4: Add PBXGroup entries for Theme and Components**

Generate 2 more UUIDs: GROUP_THEME, GROUP_COMPONENTS.

Locate the `9FB3C778B1465DF47506BDE5 /* FitTrack */` group (the main app group). Add `GROUP_THEME /* Theme */,` to its `children` array alongside `387104CC675EEA5789191431 /* Engines */`.

Add these two group definitions in the `/* Begin PBXGroup section */`:

```
		GROUP_THEME /* Theme */ = {
			isa = PBXGroup;
			children = (
				REF_THEME /* Theme.swift */,
				GROUP_COMPONENTS /* Components */,
			);
			path = Theme;
			sourceTree = "<group>";
		};
		GROUP_COMPONENTS /* Components */ = {
			isa = PBXGroup;
			children = (
				REF_NEONCARD /* NeonCard.swift */,
				REF_CYBERBTN /* CyberButton.swift */,
				REF_GLOWRING /* GlowRing.swift */,
				REF_STATTILE /* StatTile.swift */,
				REF_SECTIONHDR /* SectionHeader.swift */,
				REF_NEONBADGE /* NeonBadge.swift */,
				REF_CYBERDIV /* CyberDivider.swift */,
			);
			path = Components;
			sourceTree = "<group>";
		};
```

- [ ] **Step 5: Add build files to Sources phase**

Locate `522D69FECDF3C6955ABB05AD /* Sources */` section. Add all 8 BUILD_* entries to its `files` array:

```
				BUILD_THEME /* Theme.swift in Sources */,
				BUILD_NEONCARD /* NeonCard.swift in Sources */,
				BUILD_CYBERBTN /* CyberButton.swift in Sources */,
				BUILD_GLOWRING /* GlowRing.swift in Sources */,
				BUILD_STATTILE /* StatTile.swift in Sources */,
				BUILD_SECTIONHDR /* SectionHeader.swift in Sources */,
				BUILD_NEONBADGE /* NeonBadge.swift in Sources */,
				BUILD_CYBERDIV /* CyberDivider.swift in Sources */,
```

- [ ] **Step 6: Build to verify all Theme files compile**

```bash
cd "/Users/tristancummins/Desktop/Claude Projects/FitTrack"
xcodebuild -scheme FitTrack -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: Commit**

```bash
git add FitTrack.xcodeproj/project.pbxproj
git commit -m "chore: register Theme/ Swift files in Xcode project"
```

---

## Task 4: Custom Fonts

**Files:**
- Create: `FitTrack/Resources/Fonts/` (4 font files — manual download)
- Modify: `FitTrack/Info.plist`

- [ ] **Step 1: Create font directory and download fonts**

```bash
mkdir -p "/Users/tristancummins/Desktop/Claude Projects/FitTrack/FitTrack/Resources/Fonts"
cd "/Users/tristancummins/Desktop/Claude Projects/FitTrack/FitTrack/Resources/Fonts"

# Orbitron Bold
curl -L "https://github.com/google/fonts/raw/main/ofl/orbitron/static/Orbitron-Bold.ttf" -o Orbitron-Bold.ttf

# Rajdhani SemiBold  
curl -L "https://github.com/google/fonts/raw/main/ofl/rajdhani/Rajdhani-SemiBold.ttf" -o Rajdhani-SemiBold.ttf

# JetBrains Mono
curl -L "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip" -o jbmono.zip
unzip -j jbmono.zip "fonts/ttf/JetBrainsMono-Regular.ttf" "fonts/ttf/JetBrainsMono-Bold.ttf" -d .
rm jbmono.zip
ls -la  # verify: Orbitron-Bold.ttf, Rajdhani-SemiBold.ttf, JetBrainsMono-Regular.ttf, JetBrainsMono-Bold.ttf
```

- [ ] **Step 2: Register fonts in Info.plist**

Read `FitTrack/Info.plist`. Add the `UIAppFonts` key. The file uses XML plist format. Add before the closing `</dict>`:

```xml
	<key>UIAppFonts</key>
	<array>
		<string>Orbitron-Bold.ttf</string>
		<string>Rajdhani-SemiBold.ttf</string>
		<string>JetBrainsMono-Regular.ttf</string>
		<string>JetBrainsMono-Bold.ttf</string>
	</array>
```

- [ ] **Step 3: Register font files as bundle resources in pbxproj**

Generate 8 UUIDs: REF_F1..REF_F4 (file refs), BUILD_F1..BUILD_F4 (build files).

Add PBXFileReference entries in project.pbxproj:
```
		REF_F1 /* Orbitron-Bold.ttf */ = {isa = PBXFileReference; lastKnownFileType = file; path = "Orbitron-Bold.ttf"; sourceTree = "<group>"; };
		REF_F2 /* Rajdhani-SemiBold.ttf */ = {isa = PBXFileReference; lastKnownFileType = file; path = "Rajdhani-SemiBold.ttf"; sourceTree = "<group>"; };
		REF_F3 /* JetBrainsMono-Regular.ttf */ = {isa = PBXFileReference; lastKnownFileType = file; path = "JetBrainsMono-Regular.ttf"; sourceTree = "<group>"; };
		REF_F4 /* JetBrainsMono-Bold.ttf */ = {isa = PBXFileReference; lastKnownFileType = file; path = "JetBrainsMono-Bold.ttf"; sourceTree = "<group>"; };
```

Add PBXBuildFile entries (target = Copy Bundle Resources, not Sources):
```
		BUILD_F1 /* Orbitron-Bold.ttf in Resources */ = {isa = PBXBuildFile; fileRef = REF_F1 /* Orbitron-Bold.ttf */; };
		BUILD_F2 /* Rajdhani-SemiBold.ttf in Resources */ = {isa = PBXBuildFile; fileRef = REF_F2 /* Rajdhani-SemiBold.ttf */; };
		BUILD_F3 /* JetBrainsMono-Regular.ttf in Resources */ = {isa = PBXBuildFile; fileRef = REF_F3 /* JetBrainsMono-Regular.ttf */; };
		BUILD_F4 /* JetBrainsMono-Bold.ttf in Resources */ = {isa = PBXBuildFile; fileRef = REF_F4 /* JetBrainsMono-Bold.ttf */; };
```

Create a `GROUP_FONTS` group (generate 1 UUID) and a `GROUP_RESOURCES` group (generate 1 UUID). Add GROUP_RESOURCES to `9FB3C778B1465DF47506BDE5 /* FitTrack */` children:

```
		GROUP_RESOURCES /* Resources */ = {
			isa = PBXGroup;
			children = (
				GROUP_FONTS /* Fonts */,
			);
			path = Resources;
			sourceTree = "<group>";
		};
		GROUP_FONTS /* Fonts */ = {
			isa = PBXGroup;
			children = (
				REF_F1 /* Orbitron-Bold.ttf */,
				REF_F2 /* Rajdhani-SemiBold.ttf */,
				REF_F3 /* JetBrainsMono-Regular.ttf */,
				REF_F4 /* JetBrainsMono-Bold.ttf */,
			);
			path = Fonts;
			sourceTree = "<group>";
		};
```

Find the `PBXResourcesBuildPhase` section (look for `/* Resources */` with `files =` containing `.xcassets`). Add the 4 font BUILD_F* entries to its `files` array.

- [ ] **Step 4: Build and verify fonts load**

```bash
xcodebuild -scheme FitTrack -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
cd "/Users/tristancummins/Desktop/Claude Projects/FitTrack"
git add FitTrack/Resources/Fonts/ FitTrack/Info.plist FitTrack.xcodeproj/project.pbxproj
git commit -m "feat: add custom fonts — Orbitron, Rajdhani, JetBrains Mono"
```

---

## Task 5: ContentView — dark tab bar

**Files:**
- Modify: `FitTrack/ContentView.swift`

- [ ] **Step 1: Restyle ContentView**

Replace the entire file content:

```swift
import SwiftUI

struct ContentView: View {
    init() {
        // Tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.Colors.surface)
        appearance.shadowColor = UIColor(Theme.Colors.borderSubtle)

        let normal = UITabBarItemAppearance()
        normal.normal.iconColor = UIColor(Theme.Colors.textMuted)
        normal.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.Colors.textMuted),
            .font: UIFont.systemFont(ofSize: 10)
        ]
        normal.selected.iconColor = UIColor(Theme.Colors.cyan)
        normal.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.Colors.cyan),
            .font: UIFont.systemFont(ofSize: 10)
        ]
        appearance.stackedLayoutAppearance = normal
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Theme.Colors.bg)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.Colors.textPrimary)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Theme.Colors.textPrimary)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        // List / table view background
        UITableView.appearance().backgroundColor = UIColor(Theme.Colors.bg)
        UITableViewCell.appearance().backgroundColor = UIColor(Theme.Colors.surface)
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "bolt.fill") }
            ProgramView()
                .tabItem { Label("Program", systemImage: "list.clipboard.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
            MusclesView()
                .tabItem { Label("Muscles", systemImage: "figure.strengthtraining.traditional") }
            ProgressView_()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .background(Theme.Colors.bg.ignoresSafeArea())
    }
}
```

- [ ] **Step 2: Build and verify**

```bash
xcodebuild -scheme FitTrack -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add FitTrack/ContentView.swift
git commit -m "feat: dark tab bar + nav bar global UIKit appearance"
```

---

## Task 6: RecoveryBadgeView

**Files:**
- Modify: `FitTrack/Views/Today/RecoveryBadgeView.swift`

- [ ] **Step 1: Rewrite RecoveryBadgeView**

Replace entire file:

```swift
import SwiftUI

struct RecoveryBadgeView: View {
    let score: Int

    private var color: Color { Theme.Colors.recovery(score) }

    private var recommendation: String {
        switch score {
        case 75...: return "Optimal · push for overload targets"
        case 50..<75: return "Moderate · maintain current weights"
        default: return "Low · consider deload today"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            GlowRing(
                value: Double(score) / 100.0,
                size: 64,
                lineWidth: 5,
                color: color,
                label: "\(score)"
            )
            VStack(alignment: .leading, spacing: 4) {
                SectionHeader(title: "Whoop Recovery", color: color)
                Text(recommendation)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(Theme.Layout.screenPadding)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme FitTrack -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add FitTrack/Views/Today/RecoveryBadgeView.swift
git commit -m "feat: restyle RecoveryBadgeView with GlowRing"
```

---

## Task 7: TodayView

**Files:**
- Modify: `FitTrack/Views/Today/TodayView.swift`

- [ ] **Step 1: Rewrite TodayView**

Replace the entire file:

```swift
import SwiftUI
import SwiftData

private struct ActiveSessionContext: Identifiable {
    let id = UUID()
    let session: TrainingSession
    let template: WorkoutTemplate
}

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var whoopService: WhoopService
    @AppStorage("deloadThreshold") private var deloadThreshold: Int = 50

    @Query(filter: #Predicate<Program> { $0.isActive }) private var activePrograms: [Program]
    @Query(sort: \TrainingSession.date, order: .reverse) private var recentSessions: [TrainingSession]
    @Query(sort: \WhoopCycleCache.date, order: .reverse) private var cachedCycles: [WhoopCycleCache]

    @State private var sessionContext: ActiveSessionContext?
    @State private var showProgramComplete = false
    @State private var showSettings = false

    private var activeProgram: Program? { activePrograms.first }

    private var todaySlot: WeeklyScheduleSlot? {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let mondayBased = weekday == 1 ? 7 : weekday - 1
        return activeProgram?.scheduleSlots.first { $0.dayOfWeek == mondayBased }
    }

    private var todayCycle: WhoopCycleCache? {
        let today = Calendar.current.startOfDay(for: Date())
        return cachedCycles.first { Calendar.current.startOfDay(for: $0.date) == today }
    }

    private var dateLabel: String {
        Date().formatted(.dateTime.weekday(.wide).day().month(.abbreviated)).uppercased()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Layout.cardGap) {
                        // Date header
                        HStack {
                            Text(dateLabel)
                                .font(Theme.Fonts.rajdhani(12))
                                .kerning(2)
                                .foregroundStyle(Theme.Colors.textMuted)
                            Spacer()
                            Button { showSettings = true } label: {
                                Image(systemName: "gearshape")
                                    .foregroundStyle(Theme.Colors.textMuted)
                                    .font(.system(size: 18))
                            }
                        }
                        .padding(.horizontal, Theme.Layout.screenPadding)
                        .padding(.top, 8)
                        .appearAnimation(delay: 0)

                        // Recovery card
                        if let cycle = todayCycle {
                            RecoveryBadgeView(score: cycle.recoveryScore)
                                .padding(.horizontal, Theme.Layout.screenPadding)
                                .appearAnimation(delay: 0.05)
                        }

                        // Today's session card
                        sessionCard
                            .padding(.horizontal, Theme.Layout.screenPadding)
                            .appearAnimation(delay: 0.1)

                        // Stats row
                        if let program = activeProgram {
                            statsRow(program: program)
                                .padding(.horizontal, Theme.Layout.screenPadding)
                                .appearAnimation(delay: 0.15)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 4)
                }
            }
            .navigationBarHidden(true)
            .task { await refreshWhoop() }
            .fullScreenCover(item: $sessionContext) { ctx in
                ActiveSessionView(
                    session: ctx.session,
                    template: ctx.template,
                    recoveryScore: todayCycle?.recoveryScore
                )
            }
            .onChange(of: activeProgram?.id) {
                if activeProgram?.isComplete == true && !showProgramComplete {
                    showProgramComplete = true
                }
            }
            .sheet(isPresented: $showProgramComplete) {
                if let program = activeProgram {
                    ProgramCompleteView(program: program)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView().environmentObject(WhoopService.shared)
            }
        }
    }

    @ViewBuilder private var sessionCard: some View {
        if let slot = todaySlot {
            slotCard(slot)
        } else {
            NeonCard(borderColor: Theme.Colors.borderSubtle) {
                VStack(alignment: .leading, spacing: 6) {
                    SectionHeader(title: "Today")
                    Text("No program active")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Text("Create one in the Program tab.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textMuted)
                }
            }
        }
    }

    @ViewBuilder private func slotCard(_ slot: WeeklyScheduleSlot) -> some View {
        switch slot.type {
        case .gym:
            if let template = slot.workoutTemplate {
                NeonCard(borderColor: Theme.Colors.borderPurple) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Today's Session", color: Theme.Colors.purple)
                        Text(template.name)
                            .font(Theme.Fonts.orbitron(18))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(template.sortedExercises.prefix(3)) { ex in
                                let key = "suggested_\(ex.name)_\(template.id)"
                                let w = UserDefaults.standard.double(forKey: key)
                                Text("· \(ex.name)  \(ex.targetSets)×\(ex.targetReps)\(w > 0 ? " @ \(w.formatted()) lbs" : "")")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                            if template.sortedExercises.count > 3 {
                                Text("+ \(template.sortedExercises.count - 3) more")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.Colors.textMuted)
                            }
                        }
                        CyberButton(title: "START SESSION ›") {
                            startGymSession(template: template)
                        }
                    }
                }
            } else {
                NeonCard(borderColor: Theme.Colors.borderPurple) {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionHeader(title: "Gym Day", color: Theme.Colors.purple)
                        Text("No template assigned")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        case .sport:
            NeonCard(borderColor: Theme.Colors.borderCyan) {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Sport")
                    Text(slot.activityName ?? "Sport Session")
                        .font(Theme.Fonts.orbitron(16))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    CyberButton(title: "LOG ACTIVITY ›", color: Theme.Colors.cyan) {
                        logActivity(slot: slot)
                    }
                }
            }
        case .competition:
            NeonCard(borderColor: Color(hex: "FF6B00").opacity(0.3)) {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Competition", color: Color(hex: "FF6B00"))
                    Text(slot.activityName ?? "Game Day")
                        .font(Theme.Fonts.orbitron(16))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    CyberButton(title: "LOG GAME ›", color: Color(hex: "FF6B00")) {
                        logActivity(slot: slot)
                    }
                }
            }
        case .rest:
            NeonCard(borderColor: Theme.Colors.borderSubtle) {
                HStack(spacing: 14) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.Colors.textMuted)
                    VStack(alignment: .leading, spacing: 3) {
                        SectionHeader(title: "Rest Day", color: Theme.Colors.textMuted)
                        Text("Recovery in progress")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.Colors.textMuted)
                    }
                }
            }
        }
    }

    @ViewBuilder private func statsRow(program: Program) -> some View {
        HStack(spacing: 8) {
            if let week = program.currentWeek {
                StatTile(value: "W\(week)", label: "OF \(program.durationWeeks)")
            }
            if let cycle = todayCycle {
                StatTile(value: "\(cycle.recoveryScore)%", label: "RECOVERY", color: Theme.Colors.recovery(cycle.recoveryScore))
            }
            StatTile(value: "\(recentSessions.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }.count)", label: "THIS WEEK", color: Theme.Colors.purple)
        }
    }

    private func startGymSession(template: WorkoutTemplate) {
        let session = TrainingSession(date: Date(), type: .gym)
        session.workoutTemplateId = template.id
        session.workoutTemplateName = template.name
        session.programId = activeProgram?.id
        session.weekNumber = activeProgram?.currentWeek
        context.insert(session)
        prepareSession(session, template: template, recoveryScore: todayCycle?.recoveryScore, deloadThreshold: deloadThreshold, context: context)
        sessionContext = ActiveSessionContext(session: session, template: template)
    }

    private func logActivity(slot: WeeklyScheduleSlot) {
        let session = TrainingSession(date: Date(), type: slot.type)
        session.activityName = slot.activityName
        session.muscleGroups = slot.muscleGroups
        session.intensity = slot.intensity
        session.programId = activeProgram?.id
        session.weekNumber = activeProgram?.currentWeek
        context.insert(session)
    }

    @MainActor private func refreshWhoop() async {
        guard whoopService.isConnected else { return }
        guard todayCycle?.isStale != false else { return }
        guard let result = try? await whoopService.fetchTodayCycle() else { return }
        if let score = result.recoveryScore, let strain = result.strainScore {
            let cache = WhoopCycleCache(date: Date(), recoveryScore: score, strainScore: strain)
            context.insert(cache)
        }
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme FitTrack -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add FitTrack/Views/Today/TodayView.swift
git commit -m "feat: restyle TodayView — hero card layout with Cyber Athletic theme"
```

---

## Task 8: SetLogRowView + ActiveSessionView

**Files:**
- Modify: `FitTrack/Views/Session/SetLogRowView.swift`
- Modify: `FitTrack/Views/Session/ActiveSessionView.swift`

- [ ] **Step 1: Rewrite SetLogRowView**

```swift
import SwiftUI
import SwiftData

struct SetLogRowView: View {
    @Bindable var log: SetLog

    var body: some View {
        HStack(spacing: 10) {
            Text("SET \(log.setNumber)")
                .font(Theme.Fonts.rajdhani(11))
                .kerning(1.5)
                .foregroundStyle(Theme.Colors.textMuted)
                .frame(width: 46, alignment: .leading)

            HStack(spacing: 3) {
                TextField("0", value: $log.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 58)
                    .font(Theme.Fonts.mono(15, bold: true))
                    .foregroundStyle(Theme.Colors.cyan)
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.surfaceDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Text("lbs")
                    .font(Theme.Fonts.rajdhani(10))
                    .foregroundStyle(Theme.Colors.textMuted)
            }

            HStack(spacing: 3) {
                TextField("\(log.targetReps)", value: $log.repsCompleted, format: .number)
                    .keyboardType(.numberPad)
                    .frame(width: 36)
                    .font(Theme.Fonts.mono(15, bold: true))
                    .foregroundStyle(Theme.Colors.purple)
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.surfaceDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Text("/ \(log.targetReps)")
                    .font(Theme.Fonts.rajdhani(10))
                    .foregroundStyle(Theme.Colors.textMuted)
            }

            Spacer()

            Button {
                withAnimation(Theme.Anim.bounce) {
                    log.completed.toggle()
                    if log.completed && log.repsCompleted == 0 {
                        log.repsCompleted = log.targetReps
                    }
                }
            } label: {
                Image(systemName: log.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(log.completed ? Theme.Colors.cyan : Theme.Colors.textMuted)
                    .font(.system(size: 22))
                    .neonGlow(Theme.Colors.cyan, radius: log.completed ? 6 : 0)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Layout.screenPadding)
        .padding(.vertical, 10)
        .background(log.completed ? Theme.Colors.cyan.opacity(0.05) : Color.clear)
        .animation(Theme.Anim.spring, value: log.completed)
    }
}
```

- [ ] **Step 2: Rewrite ActiveSessionView**

```swift
import SwiftUI
import SwiftData

struct ActiveSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let session: TrainingSession
    let template: WorkoutTemplate
    let recoveryScore: Int?

    @State private var showFinishConfirm = false
    @State private var showPRBurst = false
    @State private var prsHit = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Layout.cardGap) {
                        if let recovery = recoveryScore {
                            RecoveryBadgeView(score: recovery)
                                .padding(.horizontal, Theme.Layout.screenPadding)
                                .appearAnimation(delay: 0)
                        }

                        ForEach(Array(template.sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                            exerciseCard(exercise, delay: Double(index) * 0.05 + 0.05)
                        }

                        CyberButton(title: "FINISH SESSION") { showFinishConfirm = true }
                            .padding(.horizontal, Theme.Layout.screenPadding)
                            .padding(.bottom, 32)
                            .appearAnimation(delay: Double(template.sortedExercises.count) * 0.05 + 0.1)
                    }
                    .padding(.top, 8)
                }

                // PR burst overlay
                if showPRBurst {
                    PRBurstOverlay(count: prsHit)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation { showPRBurst = false }
                            }
                        }
                }
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .confirmationDialog("Finish session?", isPresented: $showFinishConfirm) {
                Button("Finish Session") { finishSession() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    @ViewBuilder private func exerciseCard(_ exercise: TemplateExercise, delay: Double) -> some View {
        NeonCard(borderColor: Theme.Colors.borderPurple) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(exercise.name)
                        .font(Theme.Fonts.orbitron(14))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    NeonBadge(text: "\(exercise.targetSets)×\(exercise.targetReps)", color: Theme.Colors.purple)
                }
                .padding(.bottom, 10)

                CyberDivider()

                VStack(spacing: 0) {
                    ForEach(logsFor(exercise)) { log in
                        SetLogRowView(log: log)
                        if log.setNumber < logsFor(exercise).count {
                            CyberDivider().padding(.horizontal, Theme.Layout.screenPadding)
                        }
                    }
                }
                .padding(.horizontal, -Theme.Layout.screenPadding)
            }
        }
        .padding(.horizontal, Theme.Layout.screenPadding)
        .appearAnimation(delay: delay)
    }

    private func logsFor(_ exercise: TemplateExercise) -> [SetLog] {
        session.setLogs
            .filter { $0.exerciseName == exercise.name }
            .sorted { $0.setNumber < $1.setNumber }
    }

    private func finishSession() {
        var newPRs = 0
        for exercise in template.sortedExercises {
            let snapshots = logsFor(exercise).map { $0.toSnapshot() }
            if let next = ProgressionEngine.nextWeight(for: exercise.name, logs: snapshots, increment: exercise.incrementLbs) {
                let key = "suggested_\(exercise.name)_\(template.id)"
                let previous = UserDefaults.standard.double(forKey: key)
                if next > previous { newPRs += 1 }
                UserDefaults.standard.set(next, forKey: key)
            }
        }
        if newPRs > 0 {
            prsHit = newPRs
            withAnimation(Theme.Anim.bounce) { showPRBurst = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { dismiss() }
        } else {
            dismiss()
        }
    }
}

struct PRBurstOverlay: View {
    let count: Int
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 1

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            ZStack {
                Circle()
                    .stroke(Theme.Colors.cyan, lineWidth: 3)
                    .frame(width: 200, height: 200)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
                    .neonGlow(Theme.Colors.cyan, radius: 12)
                VStack(spacing: 4) {
                    Text("PR")
                        .font(Theme.Fonts.orbitron(48))
                        .foregroundStyle(Theme.Colors.cyan)
                        .neonGlow(Theme.Colors.cyan, radius: 16)
                    if count > 1 {
                        Text("\(count) NEW PRs")
                            .font(Theme.Fonts.rajdhani(14))
                            .kerning(2)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .onAppear {
                withAnimation(Theme.Anim.spring) { ringScale = 1.4 }
                withAnimation(Theme.Anim.spring.delay(0.3)) { ringOpacity = 0 }
            }
        }
    }
}

func prepareSession(
    _ session: TrainingSession,
    template: WorkoutTemplate,
    recoveryScore: Int?,
    deloadThreshold: Int,
    context: ModelContext
) {
    for exercise in template.sortedExercises {
        let key = "suggested_\(exercise.name)_\(template.id)"
        var suggestedWeight = UserDefaults.standard.double(forKey: key)
        if suggestedWeight == 0 { suggestedWeight = 45.0 }
        if let recovery = recoveryScore {
            suggestedWeight = ProgressionEngine.applyRecoveryModifier(baseWeight: suggestedWeight, recoveryScore: recovery, deloadThreshold: deloadThreshold)
        }
        guard exercise.targetSets > 0 else { continue }
        for i in 1...exercise.targetSets {
            let log = SetLog(exerciseName: exercise.name, setNumber: i, targetReps: exercise.targetReps, weight: suggestedWeight)
            session.setLogs.append(log)
            context.insert(log)
        }
    }
}
```

- [ ] **Step 3: Build**

```bash
xcodebuild -scheme FitTrack -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add FitTrack/Views/Session/SetLogRowView.swift FitTrack/Views/Session/ActiveSessionView.swift
git commit -m "feat: restyle active session — dark exercise cards + PR burst animation"
```

---

## Task 9: ProgressView_ + GoalRowView

**Files:**
- Modify: `FitTrack/Views/Progress/ProgressView_.swift`

- [ ] **Step 1: Rewrite ProgressView_.swift**

```swift
import SwiftUI
import SwiftData
import Charts

struct ProgressView_: View {
    @Query(sort: \WeighIn.date, order: .forward) private var weighIns: [WeighIn]
    @Query private var goals: [Goal]
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]

    @State private var showWeighIn = false
    @State private var showGoalEditor = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Layout.cardGap) {
                        weightCard
                            .padding(.horizontal, Theme.Layout.screenPadding)
                            .appearAnimation(delay: 0)

                        goalsCard
                            .padding(.horizontal, Theme.Layout.screenPadding)
                            .appearAnimation(delay: 0.05)

                        photosCard
                            .padding(.horizontal, Theme.Layout.screenPadding)
                            .appearAnimation(delay: 0.1)

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showWeighIn = true } label: {
                        Image(systemName: "scalemass.fill")
                            .foregroundStyle(Theme.Colors.cyan)
                    }
                }
            }
            .sheet(isPresented: $showWeighIn) { WeighInEntryView() }
            .sheet(isPresented: $showGoalEditor) { GoalEditorView() }
        }
    }

    @ViewBuilder private var weightCard: some View {
        NeonCard(borderColor: Theme.Colors.borderCyan) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Weight Trend")
                if weighIns.count > 1 {
                    Chart(weighIns) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("lbs", entry.bodyWeightLbs)
                        )
                        .foregroundStyle(Theme.Colors.cyan)
                        .interpolationMethod(.catmullRom)
                        AreaMark(
                            x: .value("Date", entry.date),
                            y: .value("lbs", entry.bodyWeightLbs)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.Colors.cyan.opacity(0.15), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("lbs", entry.bodyWeightLbs)
                        )
                        .foregroundStyle(Theme.Colors.purple)
                        .symbolSize(30)
                    }
                    .frame(height: 130)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Theme.Colors.borderSubtle)
                            AxisValueLabel()
                                .foregroundStyle(Theme.Colors.textMuted)
                                .font(Theme.Fonts.mono(9))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Theme.Colors.borderSubtle)
                            AxisValueLabel()
                                .foregroundStyle(Theme.Colors.textMuted)
                                .font(Theme.Fonts.mono(9))
                        }
                    }
                    .chartBackground { _ in Theme.Colors.surface }

                    if let latest = weighIns.last {
                        HStack {
                            Text("\(latest.bodyWeightLbs, format: .number) lbs")
                                .font(Theme.Fonts.mono(20, bold: true))
                                .foregroundStyle(Theme.Colors.cyan)
                            if let bf = latest.bodyFatPercent {
                                Spacer()
                                Text("\(bf, format: .number)% BF")
                                    .font(Theme.Fonts.mono(14))
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                    }
                } else {
                    Text("No weigh-ins yet. Tap the scale icon to log your first.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(height: 60)
                }
            }
        }
    }

    @ViewBuilder private var goalsCard: some View {
        NeonCard(borderColor: Theme.Colors.borderPurple) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionHeader(title: "Goals", color: Theme.Colors.purple)
                    Spacer()
                    Button { showGoalEditor = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.Colors.purple)
                            .font(.system(size: 16))
                    }
                }
                let active = goals.filter { !$0.isAchieved }
                if active.isEmpty {
                    Text("No goals set yet.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textMuted)
                } else {
                    ForEach(active) { goal in
                        GoalRowView(goal: goal, sessions: sessions, weighIns: weighIns)
                        if goal.id != active.last?.id { CyberDivider() }
                    }
                }
                if !goals.filter({ $0.isAchieved }).isEmpty {
                    CyberDivider()
                    DisclosureGroup {
                        ForEach(goals.filter { $0.isAchieved }) { goal in
                            GoalRowView(goal: goal, sessions: sessions, weighIns: weighIns)
                                .opacity(0.6)
                        }
                    } label: {
                        Text("Achieved")
                            .font(Theme.Fonts.rajdhani(12))
                            .foregroundStyle(Theme.Colors.textMuted)
                    }
                    .tint(Theme.Colors.textMuted)
                }
            }
        }
    }

    @ViewBuilder private var photosCard: some View {
        NeonCard(borderColor: Theme.Colors.borderSubtle) {
            NavigationLink(destination: ProgressPhotoGridView()) {
                HStack {
                    SectionHeader(title: "Progress Photos")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textMuted)
                }
            }
        }
    }
}

struct GoalRowView: View {
    @Bindable var goal: Goal
    let sessions: [TrainingSession]
    let weighIns: [WeighIn]

    private var currentValue: Double? {
        switch goal.type {
        case .strength:
            guard let name = goal.linkedExerciseName else { return nil }
            let allLogs = sessions.flatMap(\.setLogs).filter { $0.exerciseName == name && $0.completed && $0.repsCompleted >= 1 }
            return allLogs.map(\.weight).max()
        case .bodyComposition:
            switch goal.linkedMetric {
            case .bodyWeight: return weighIns.last?.bodyWeightLbs
            case .bodyFatPercent: return weighIns.compactMap(\.bodyFatPercent).last
            case nil: return nil
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                if goal.isAchieved {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.Colors.cyan)
                        .neonGlow(Theme.Colors.cyan, radius: 4)
                }
            }
            if let current = currentValue {
                let progress = min(current / goal.targetValue, 1.0)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.Colors.borderSubtle)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(progress >= 1.0 ? Theme.Colors.cyan : Theme.Colors.purple)
                            .frame(width: geo.size.width * progress, height: 6)
                            .neonGlow(progress >= 1.0 ? Theme.Colors.cyan : Theme.Colors.purple, radius: 4)
                            .animation(Theme.Anim.spring.delay(0.2), value: progress)
                    }
                }
                .frame(height: 6)
                HStack {
                    Text("\(current, format: .number)")
                        .font(Theme.Fonts.mono(11, bold: true))
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Spacer()
                    Text("→ \(goal.targetValue, format: .number)")
                        .font(Theme.Fonts.mono(11))
                        .foregroundStyle(Theme.Colors.textMuted)
                    if let date = goal.targetDate {
                        Text("by \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.textMuted)
                    }
                }
            } else {
                Text("No data yet")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.textMuted)
            }
        }
        .padding(.vertical, 4)
        .onChange(of: currentValue) { _, newValue in
            if let value = newValue, value >= goal.targetValue, !goal.isAchieved {
                goal.isAchieved = true
                goal.achievedDate = Date()
            }
        }
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme FitTrack -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add FitTrack/Views/Progress/ProgressView_.swift
git commit -m "feat: restyle ProgressView — dark charts, neon goal bars"
```

---

## Task 10: WeighInEntryView + GoalEditorView

**Files:**
- Modify: `FitTrack/Views/Progress/WeighInEntryView.swift`
- Modify: `FitTrack/Views/Progress/GoalEditorView.swift` (dark form only — logic unchanged)

- [ ] **Step 1: Rewrite WeighInEntryView**

```swift
import SwiftUI
import SwiftData

struct WeighInEntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var bodyWeight = ""
    @State private var bodyFat = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                VStack(spacing: Theme.Layout.cardGap) {
                    NeonCard(borderColor: Theme.Colors.borderCyan) {
                        VStack(spacing: 16) {
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .colorScheme(.dark)
                                .foregroundStyle(Theme.Colors.textPrimary)

                            CyberDivider()

                            HStack {
                                Text("WEIGHT")
                                    .font(Theme.Fonts.rajdhani(12))
                                    .kerning(2)
                                    .foregroundStyle(Theme.Colors.textMuted)
                                Spacer()
                                TextField("0.0", text: $bodyWeight)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(Theme.Fonts.mono(22, bold: true))
                                    .foregroundStyle(Theme.Colors.cyan)
                                    .frame(width: 80)
                                Text("lbs")
                                    .font(Theme.Fonts.rajdhani(13))
                                    .foregroundStyle(Theme.Colors.textMuted)
                            }

                            CyberDivider()

                            HStack {
                                Text("BODY FAT")
                                    .font(Theme.Fonts.rajdhani(12))
                                    .kerning(2)
                                    .foregroundStyle(Theme.Colors.textMuted)
                                Spacer()
                                TextField("optional", text: $bodyFat)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(Theme.Fonts.mono(22, bold: true))
                                    .foregroundStyle(Theme.Colors.purple)
                                    .frame(width: 80)
                                Text("%")
                                    .font(Theme.Fonts.rajdhani(13))
                                    .foregroundStyle(Theme.Colors.textMuted)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Layout.screenPadding)

                    CyberButton(title: "SAVE WEIGH-IN", action: save)
                        .disabled(bodyWeight.isEmpty)
                        .padding(.horizontal, Theme.Layout.screenPadding)

                    Spacer()
                }
                .padding(.top, 12)
            }
            .navigationTitle("Log Weigh-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
    }

    private func save() {
        guard let weight = Double(bodyWeight) else { return }
        let fatPercent = Double(bodyFat)
        let weighIn = WeighIn(date: date, bodyWeightLbs: weight, bodyFatPercent: fatPercent)
        context.insert(weighIn)
        dismiss()
    }
}
```

- [ ] **Step 2: Apply dark form styling to GoalEditorView**

Read `FitTrack/Views/Progress/GoalEditorView.swift`. Locate the `Form {` wrapper and its containing `NavigationStack`. Add these modifiers to the `Form`:

```swift
.scrollContentBackground(.hidden)
.background(Theme.Colors.bg)
```

Add to the `NavigationStack`:
```swift
.toolbarBackground(Theme.Colors.bg, for: .navigationBar)
.toolbarColorScheme(.dark, for: .navigationBar)
```

- [ ] **Step 3: Build**

```bash
xcodebuild -scheme FitTrack -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -5
```

- [ ] **Step 4: Commit**

```bash
git add FitTrack/Views/Progress/WeighInEntryView.swift FitTrack/Views/Progress/GoalEditorView.swift
git commit -m "feat: restyle WeighInEntryView and GoalEditorView dark forms"
```

---

## Task 11: ProgramView

**Files:**
- Modify: `FitTrack/Views/Program/ProgramView.swift`

- [ ] **Step 1: Restyle ProgramView — replace ProgramRow and add dark styling**

Replace the entire file:

```swift
import SwiftUI
import SwiftData

struct ProgramView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Program.startDate, order: .reverse) private var programs: [Program]
    @State private var showBuilder = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Layout.cardGap) {
                        ForEach(Array(programs.enumerated()), id: \.element.id) { index, program in
                            NavigationLink(destination: ProgramDetailView(program: program)) {
                                ProgramRow(program: program)
                            }
                            .buttonStyle(.plain)
                            .appearAnimation(delay: Double(index) * 0.05)
                        }
                        if programs.isEmpty {
                            NeonCard(borderColor: Theme.Colors.borderSubtle) {
                                VStack(spacing: 8) {
                                    SectionHeader(title: "No Programs")
                                    Text("Tap + to create your first training program.")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                }
                            }
                            .appearAnimation()
                        }
                    }
                    .padding(.horizontal, Theme.Layout.screenPadding)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Programs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showBuilder = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.Colors.cyan)
                    }
                }
            }
            .sheet(isPresented: $showBuilder) { ProgramBuilderView() }
        }
    }
}

private struct ProgramRow: View {
    let program: Program

    var body: some View {
        NeonCard(borderColor: program.isActive ? Theme.Colors.borderPurple : Theme.Colors.borderSubtle) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(program.name)
                            .font(Theme.Fonts.orbitron(14))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        if program.isActive {
                            NeonBadge(text: "ACTIVE", color: Theme.Colors.purple)
                        }
                    }
                    if let week = program.currentWeek {
                        HStack(spacing: 6) {
                            Text("Week \(week) of \(program.durationWeeks)")
                                .font(Theme.Fonts.mono(12))
                                .foregroundStyle(Theme.Colors.textSecondary)
                            let progress = Double(week) / Double(program.durationWeeks)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Theme.Colors.borderSubtle)
                                        .frame(height: 3)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Theme.Colors.cyan)
                                        .frame(width: geo.size.width * progress, height: 3)
                                }
                            }
                            .frame(height: 3)
                        }
                    } else {
                        Text(program.startDate.formatted(date: .abbreviated, time: .omitted))
                            .font(Theme.Fonts.mono(11))
                            .foregroundStyle(Theme.Colors.textMuted)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.textMuted)
            }
        }
    }
}

struct ProgramDetailView: View {
    @Bindable var program: Program
    @Environment(\.modelContext) private var context
    @Query private var allTemplates: [WorkoutTemplate]
    @State private var showAddTemplate = false

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()
            List {
                Section {
                    NavigationLink("Edit schedule") {
                        WeeklyScheduleGridView(program: program)
                    }
                    .foregroundStyle(Theme.Colors.cyan)
                } header: { SectionHeader(title: "Weekly Schedule") }

                Section {
                    ForEach(allTemplates) { template in
                        NavigationLink(template.name) {
                            WorkoutTemplateEditorView(template: template)
                        }
                        .foregroundStyle(Theme.Colors.textPrimary)
                    }
                    Button("Add workout template") { showAddTemplate = true }
                        .foregroundStyle(Theme.Colors.cyan)
                } header: { SectionHeader(title: "Workout Templates") }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(program.name)
        .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showAddTemplate) { AddTemplateView(program: program) }
    }
}

struct AddTemplateView: View {
    let program: Program
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var templateName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                VStack(spacing: Theme.Layout.cardGap) {
                    NeonCard(borderColor: Theme.Colors.borderCyan) {
                        HStack {
                            Text("NAME")
                                .font(Theme.Fonts.rajdhani(11))
                                .kerning(2)
                                .foregroundStyle(Theme.Colors.textMuted)
                            TextField("Push Day, Pull Day…", text: $templateName)
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .padding(.horizontal, Theme.Layout.screenPadding)

                    CyberButton(title: "CREATE TEMPLATE") { createTemplate() }
                        .disabled(templateName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .padding(.horizontal, Theme.Layout.screenPadding)

                    Spacer()
                }
                .padding(.top, 12)
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
    }

    private func createTemplate() {
        let template = WorkoutTemplate(name: templateName.trimmingCharacters(in: .whitespaces))
        context.insert(template)
        dismiss()
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme FitTrack -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add FitTrack/Views/Program/ProgramView.swift
git commit -m "feat: restyle ProgramView — NeonCard rows, dark detail/add-template views"
```

---

## Task 12: HistoryView

**Files:**
- Modify: `FitTrack/Views/History/HistoryView.swift`

- [ ] **Step 1: Restyle HistoryView**

Replace the entire file:

```swift
import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @State private var selectedExercise: String?

    private var gymSessions: [TrainingSession] { sessions.filter { $0.type == .gym } }
    private var allExerciseNames: [String] {
        Array(Set(gymSessions.flatMap { $0.setLogs.map(\.exerciseName) })).sorted()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Layout.cardGap) {
                        if !allExerciseNames.isEmpty {
                            NeonCard(borderColor: Theme.Colors.borderCyan) {
                                VStack(alignment: .leading, spacing: 12) {
                                    SectionHeader(title: "Exercise Progress")
                                    Picker("Exercise", selection: $selectedExercise) {
                                        Text("Select…").tag(String?.none)
                                        ForEach(allExerciseNames, id: \.self) { name in
                                            Text(name).tag(String?.some(name))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Theme.Colors.cyan)

                                    if let name = selectedExercise {
                                        ExerciseChartView(exerciseName: name, sessions: gymSessions)
                                            .frame(height: 140)
                                    }
                                }
                            }
                            .padding(.horizontal, Theme.Layout.screenPadding)
                            .appearAnimation(delay: 0)
                        }

                        ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                            NavigationLink(destination: SessionDetailView(session: session)) {
                                SessionRowView(session: session)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, Theme.Layout.screenPadding)
                            .appearAnimation(delay: Double(min(index, 8)) * 0.04 + 0.05)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("History")
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct SessionRowView: View {
    let session: TrainingSession

    private var typeColor: Color {
        switch session.type {
        case .gym: return Theme.Colors.purple
        case .sport: return Theme.Colors.cyan
        case .competition: return Color(hex: "FF6B00")
        case .rest: return Theme.Colors.textMuted
        }
    }

    var body: some View {
        NeonCard(borderColor: typeColor.opacity(0.2)) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(session.workoutTemplateName ?? session.activityName ?? session.type.rawValue.capitalized)
                        .font(Theme.Fonts.orbitron(13))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    if session.type == .gym {
                        Text("\(session.setLogs.filter(\.completed).count) sets completed")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    NeonBadge(text: session.type.rawValue.uppercased(), color: typeColor)
                    Text(session.date.formatted(date: .abbreviated, time: .omitted))
                        .font(Theme.Fonts.mono(10))
                        .foregroundStyle(Theme.Colors.textMuted)
                }
            }
        }
    }
}

struct SessionDetailView: View {
    let session: TrainingSession

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()
            List {
                let grouped = Dictionary(grouping: session.setLogs, by: \.exerciseName)
                ForEach(grouped.keys.sorted(), id: \.self) { name in
                    Section {
                        ForEach(grouped[name, default: []].sorted { $0.setNumber < $1.setNumber }) { log in
                            HStack {
                                Text("Set \(log.setNumber)")
                                    .font(Theme.Fonts.rajdhani(12))
                                    .foregroundStyle(Theme.Colors.textMuted)
                                Spacer()
                                Text("\(log.weight, format: .number) lbs × \(log.repsCompleted) reps")
                                    .font(Theme.Fonts.mono(13))
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Image(systemName: log.completed ? "checkmark.circle.fill" : "xmark.circle")
                                    .foregroundStyle(log.completed ? Theme.Colors.cyan : Color(hex: "FF3B5C"))
                            }
                        }
                    } header: { SectionHeader(title: name) }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(session.workoutTemplateName ?? "Session")
        .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct ExerciseChartView: View {
    let exerciseName: String
    let sessions: [TrainingSession]

    private var dataPoints: [(date: Date, maxWeight: Double)] {
        sessions.compactMap { session in
            let relevant = session.setLogs.filter { $0.exerciseName == exerciseName && $0.completed }
            guard let max = relevant.map(\.weight).max() else { return nil }
            return (date: session.date, maxWeight: max)
        }
        .sorted { $0.date < $1.date }
        .suffix(12)
        .map { $0 }
    }

    var body: some View {
        Chart(dataPoints, id: \.date) { point in
            LineMark(x: .value("Date", point.date), y: .value("lbs", point.maxWeight))
                .foregroundStyle(Theme.Colors.cyan)
                .interpolationMethod(.catmullRom)
            PointMark(x: .value("Date", point.date), y: .value("lbs", point.maxWeight))
                .foregroundStyle(Theme.Colors.purple)
                .symbolSize(30)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Theme.Colors.borderSubtle)
                AxisValueLabel().foregroundStyle(Theme.Colors.textMuted).font(Theme.Fonts.mono(9))
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Theme.Colors.borderSubtle)
                AxisValueLabel().foregroundStyle(Theme.Colors.textMuted).font(Theme.Fonts.mono(9))
            }
        }
        .chartBackground { _ in Theme.Colors.surface }
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme FitTrack -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add FitTrack/Views/History/HistoryView.swift
git commit -m "feat: restyle HistoryView — NeonCard session rows, dark charts"
```

---

## Task 13: MusclesView

**Files:**
- Modify: `FitTrack/Views/Muscles/MusclesView.swift`

- [ ] **Step 1: Restyle MusclesView**

Replace the entire file:

```swift
import SwiftUI
import SwiftData

struct MusclesView: View {
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @Query private var templates: [WorkoutTemplate]

    private var snapshots: [TrainingSessionSnapshot] {
        sessions.map { session in
            let template = templates.first { $0.id == session.workoutTemplateId }
            return session.toFatigueSnapshot(template: template)
        }
    }

    private var lastTrained: [MuscleGroup: Date] {
        FatigueEngine.lastTrainedDates(from: snapshots)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(MuscleGroup.allCases.enumerated()), id: \.element) { index, muscle in
                            MuscleRowView(muscle: muscle, lastTrained: lastTrained[muscle])
                                .padding(.horizontal, Theme.Layout.screenPadding)
                                .appearAnimation(delay: Double(index) * 0.04)
                        }
                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Muscles")
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct MuscleRowView: View {
    let muscle: MuscleGroup
    let lastTrained: Date?

    private var fatigueColor: FatigueColor {
        FatigueEngine.fatigueColor(lastTrained: lastTrained, today: Date())
    }

    private var themeColor: Color {
        switch fatigueColor {
        case .green:  return Color(hex: "00FF88")
        case .yellow: return Color(hex: "FFB800")
        case .red:    return Color(hex: "FF3B5C")
        }
    }

    private var subtitle: String {
        guard let date = lastTrained else { return "Never trained" }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return days == 0 ? "Trained today" : "\(days)d ago"
    }

    @State private var barWidth: CGFloat = 0
    private var barFraction: CGFloat {
        guard let date = lastTrained else { return 0.0 }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return max(0, CGFloat(1.0 - Double(days) / 7.0))
    }

    var body: some View {
        NeonCard(borderColor: themeColor.opacity(0.2)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(muscle.rawValue.capitalized)
                        .font(Theme.Fonts.orbitron(13))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Text(subtitle)
                        .font(Theme.Fonts.mono(11))
                        .foregroundStyle(themeColor)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.Colors.borderSubtle)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(themeColor)
                            .frame(width: geo.size.width * barWidth, height: 4)
                            .neonGlow(themeColor, radius: 3)
                    }
                }
                .frame(height: 4)
                .onAppear {
                    withAnimation(Theme.Anim.spring.delay(0.2)) {
                        barWidth = barFraction
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme FitTrack -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add FitTrack/Views/Muscles/MusclesView.swift
git commit -m "feat: restyle MusclesView — NeonCard rows with animated fatigue bars"
```

---

## Task 14: SettingsView

**Files:**
- Modify: `FitTrack/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Restyle SettingsView**

Replace the entire file:

```swift
import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @EnvironmentObject private var whoopService: WhoopService
    @AppStorage("deloadThreshold") private var deloadThreshold: Int = 50
    @AppStorage("programDurationWeeks") private var programDurationWeeks: Int = 8
    @State private var windowContext = WindowContextProvider()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                List {
                    Section {
                        if whoopService.isConnected {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color(hex: "00FF88"))
                                Text("Connected")
                                    .foregroundStyle(Theme.Colors.textPrimary)
                            }
                            Button("Disconnect", role: .destructive) { whoopService.disconnect() }
                                .foregroundStyle(Color(hex: "FF3B5C"))
                        } else {
                            HStack {
                                Image(systemName: "xmark.circle")
                                    .foregroundStyle(Theme.Colors.textMuted)
                                Text("Not connected")
                                    .foregroundStyle(Theme.Colors.textMuted)
                            }
                            Button("Connect Whoop") {
                                Task { try? await whoopService.connect(presentationContext: windowContext) }
                            }
                            .foregroundStyle(Theme.Colors.cyan)
                        }
                    } header: { SectionHeader(title: "Whoop") }

                    Section {
                        HStack {
                            Text("Deload below")
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            Stepper("\(deloadThreshold)% recovery", value: $deloadThreshold, in: 10...90, step: 5)
                                .fixedSize()
                                .foregroundStyle(Theme.Colors.cyan)
                        }
                    } header: { SectionHeader(title: "Progressive Overload") }

                    Section {
                        HStack {
                            Text("Default duration")
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            Stepper("\(programDurationWeeks) weeks", value: $programDurationWeeks, in: 1...52)
                                .fixedSize()
                                .foregroundStyle(Theme.Colors.cyan)
                        }
                    } header: { SectionHeader(title: "Programs") }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

final class WindowContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme FitTrack -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add FitTrack/Views/Settings/SettingsView.swift
git commit -m "feat: restyle SettingsView — dark list with themed section headers"
```

---

## Task 15: WeeklyScheduleGridView + WorkoutTemplateEditorView

**Files:**
- Modify: `FitTrack/Views/Program/WeeklyScheduleGridView.swift`
- Modify: `FitTrack/Views/Program/WorkoutTemplateEditorView.swift`

- [ ] **Step 1: Restyle WeeklyScheduleGridView — replace SlotTypeBadge with NeonBadge**

Apply these targeted changes to `WeeklyScheduleGridView.swift`:

1. Add `.scrollContentBackground(.hidden)` and `.background(Theme.Colors.bg.ignoresSafeArea())` after the `List { ... }` block.
2. Add `.toolbarBackground(Theme.Colors.bg, for: .navigationBar)` and `.toolbarColorScheme(.dark, for: .navigationBar)` modifiers.
3. Replace the `SlotTypeBadge` struct entirely:

```swift
private struct SlotTypeBadge: View {
    let type: SessionType

    private var color: Color {
        switch type {
        case .gym:         return Theme.Colors.purple
        case .sport:       return Theme.Colors.cyan
        case .competition: return Color(hex: "FF6B00")
        case .rest:        return Theme.Colors.textMuted
        }
    }

    var body: some View {
        NeonBadge(text: type.rawValue.uppercased(), color: color)
    }
}
```

4. In the row for a set slot, change `Text(dayNames[day - 1])` to use `Theme.Colors.textPrimary`:
   `.foregroundStyle(Theme.Colors.textPrimary)` on each day label Text.

5. Change the "Not set" text: `.foregroundStyle(Theme.Colors.textMuted)` and font to `Theme.Fonts.rajdhani(12)`.

6. In `ScheduleSlotEditorView` (further down in the same file): add `.scrollContentBackground(.hidden)`, `.background(Theme.Colors.bg.ignoresSafeArea())`, `.toolbarBackground(Theme.Colors.bg, for: .navigationBar)`, `.toolbarColorScheme(.dark, for: .navigationBar)` to the `Form` and `NavigationStack`.

- [ ] **Step 2: Restyle WorkoutTemplateEditorView — dark list rows**

Apply these targeted changes to `WorkoutTemplateEditorView.swift`:

1. After the `List { ... }` closing brace, add:
```swift
.scrollContentBackground(.hidden)
.background(Theme.Colors.bg.ignoresSafeArea())
```

2. Add toolbar appearance modifiers:
```swift
.toolbarBackground(Theme.Colors.bg, for: .navigationBar)
.toolbarColorScheme(.dark, for: .navigationBar)
```

3. Replace the exercise row `VStack` inside `ForEach`:
```swift
VStack(alignment: .leading, spacing: 3) {
    Text(exercise.name)
        .font(Theme.Fonts.orbitron(13))
        .foregroundStyle(Theme.Colors.textPrimary)
    Text("\(exercise.targetSets)×\(exercise.targetReps)  ·  +\(exercise.incrementLbs.formatted()) lbs")
        .font(Theme.Fonts.mono(11))
        .foregroundStyle(Theme.Colors.textSecondary)
}
.padding(.vertical, 4)
```

4. In `AddExerciseView` (further down in the same file): replace `Form {` wrapper approach with:
   - Add `.scrollContentBackground(.hidden)` to the Form
   - Add `.toolbarBackground(Theme.Colors.bg, for: .navigationBar)` and `.toolbarColorScheme(.dark, for: .navigationBar)` to the NavigationStack

- [ ] **Step 3: Build**

```bash
xcodebuild -scheme FitTrack -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add FitTrack/Views/Program/WeeklyScheduleGridView.swift FitTrack/Views/Program/WorkoutTemplateEditorView.swift
git commit -m "feat: restyle program schedule and template editor views"
```

---

## Task 16: Final verification

- [ ] **Step 1: Full clean build**

```bash
cd "/Users/tristancummins/Desktop/Claude Projects/FitTrack"
xcodebuild clean build -scheme FitTrack -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | tail -10
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Launch in simulator and verify visually**

```bash
xcrun simctl boot "iPhone 17" 2>/dev/null || true
open -a Simulator
xcodebuild -scheme FitTrack -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -3
xcrun simctl install booted "$(find ~/Library/Developer/Xcode/DerivedData -name 'FitTrack.app' -not -path '*/Index.noindex/*' | head -1)"
xcrun simctl launch booted com.fittrack.FitTrack
```

Verify in Simulator:
- [ ] All tabs have dark `#0A0A0A` background
- [ ] Tab bar is dark with cyan active tint
- [ ] Today tab shows hero card layout, no white backgrounds
- [ ] Recovery GlowRing animates on appear
- [ ] Session card has purple border + CyberButton
- [ ] Active session shows dark exercise cards
- [ ] Progress charts have cyan lines on dark background
- [ ] Muscles tab shows animated colored bars
- [ ] Custom fonts loading (Orbitron/Rajdhani visible) OR system fallbacks showing cleanly

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat: complete Cyber Athletic UI overhaul — all screens restyled" 
```
