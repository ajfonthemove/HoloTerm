# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```sh
swift build                  # debug build
swift build -c release       # release build (binary at .build/release/Terminal)
swift run                    # build + launch
```

No test target exists yet. There are no linting or formatting tools configured.

To bundle as a `.app`, copy the binary into `build/HoloTerm.app/Contents/MacOS/HoloTerm` with an `Info.plist` and the `.icns` icon from `build/`.

## What This Is

HoloTerm — a native macOS terminal (macOS 13+, Swift 5.9+) with a transparent glass window so the desktop stays visible behind it. Pure AppKit/SwiftUI, no Electron. Single dependency: [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) for terminal emulation.

## Architecture

All source lives in `Sources/Terminal/`. The app is an `NSApplication` with a programmatic `AppDelegate` (no storyboards, no SwiftUI `App` protocol).

- **main.swift** — Creates `NSApplication`, sets `AppDelegate`, runs the event loop.
- **AppDelegate.swift** — Owns the window, `AppState`, `GlassSettings`, and `TabsModel`. Creates `LocalProcessTerminalView` instances (SwiftTerm), starts login shell processes, installs `NSEvent` key monitor for shortcuts (Cmd-T/W/1-9/Shift-[/]), and reacts to settings changes via Combine to reapply themes.
- **Models.swift** — Three `ObservableObject` classes:
  - `AppState` — selected theme ID, persisted to UserDefaults.
  - `GlassSettings` — all glass/font/text-color sliders, persisted to UserDefaults. Produces a `GlassAppearance` struct for the backdrop and exposes `effectiveTextColor` for SwiftTerm.
  - `TabsModel` — tab list, active tab, activity tracking. Each `Tab` holds a `LocalProcessTerminalView` directly.
- **Views.swift** — SwiftUI views: `ContentView` (root ZStack with backdrop + header + terminal area), `HeaderView` (tab bar + settings gear), `SettingsView` (popover with sliders/pickers), `TerminalArea` (`NSViewRepresentable` that manages a `TerminalContainerView` — all terminals stay attached as subviews, only the active one is visible).
- **Theme.swift** — `Theme` struct with 12 bundled ANSI palettes (Dracula, Nord, Tokyo Night, etc.), hex-to-`SwiftTerm.Color` conversion, `NSColor`/`Color` hex extensions.
- **GradientBackdrop.swift** — Multi-layer glass compositor: two `NSVisualEffectView` layers (material + obfuscation), a gaussian wash with tuneable blur radius, neutral scrim, tint wash, four atmospheric glow ellipses, and a top luminous gradient. Declares `typealias Color = SwiftUI.Color` used project-wide.

## Key Patterns

- Settings flow through Combine: `GlassSettings.objectWillChange` triggers `AppDelegate.applyTheme()` which iterates all tabs and updates SwiftTerm's colors/font.
- The window is `isOpaque = false` with `backgroundColor = .clear` — required for `NSVisualEffectView` behind-window blur to capture the desktop.
- SwiftTerm terminals have `nativeBackgroundColor = .clear` and a clear `CALayer` so the glass backdrop layers show through.
- Terminated shell processes auto-restart via `processTerminated` delegate callback.
