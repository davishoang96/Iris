# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Build (must run from the See/ directory containing See.xcodeproj)
cd /Users/davis/repos/See
xcodebuild -project See.xcodeproj -scheme See -destination 'platform=macOS' build

# Build — errors/result only
xcodebuild -project See.xcodeproj -scheme See -destination 'platform=macOS' build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | grep -v appintents

# Run
open ~/Library/Developer/Xcode/DerivedData/See-*/Build/Products/Debug/See.app
```

No tests exist. `ui-design-guideline/` contains standalone JSX reference files (not part of the build, not runnable).

## Architecture

macOS SwiftUI app. Single Xcode project at `/Users/davis/repos/See/See.xcodeproj`, sources in `See/`.

**`PBXFileSystemSynchronizedRootGroup`** — Xcode 16+ feature. Any `.swift` file added to `See/` is automatically compiled. No pbxproj edits needed.

### State

`AppState` in `ContentView.swift` is the single `@MainActor ObservableObject` source of truth:
- Folder URL, photo list, loading flag
- `selectedIndex: Int` — `didSet` calls `resetTransforms()` on change
- Transform state: `rotation: Angle`, `flipH/V: Bool`, `zoom: Double`, `zoomMode: ZoomMode`
- UI flags: `infoOpen`, `slideshowActive`
- Actions: `navigate(_:)`, `nudgeZoom(_:)`, `setFit()`, `setHundred()`

`zoom` is a multiplier **relative to fit scale** (1.0 = fit, 2.0 = 2× fit). `StageView` computes `effectiveScale = fitScale * zoom` for `.custom` mode. `ZoomMode` enum (fit / hundred / custom) lives in `StageView.swift` at module scope.

### View hierarchy

```
ContentView
├── VStack
│   ├── ViewerToolbar        — custom 3-column toolbar (.ultraThinMaterial)
│   └── HStack
│       ├── mainColumn
│       │   ├── StageView        — image display with transforms + pinch zoom
│       │   ├── FilmstripView    — 64×64 thumbnail strip (.ultraThinMaterial)
│       │   └── MetaBarView      — File/Resolution/Size/Captured + stars (.ultraThinMaterial)
│       └── InfoPanelView        — 280px right panel, shown when infoOpen
└── SlideshowView overlay    — shown when slideshowActive
```

Keyboard shortcuts (←→ nav, +−fF1iI zoom/info, Esc slideshow) are `.onKeyPress` modifiers on the root VStack. `@FocusState` (`focused`) is set `.onAppear`.

### View files

- `ViewerToolbar.swift` — `ViewerToolbar` (left/center/right sections) + `TBButton` helper. `TBButton` struct: `systemImage`, `help`, `active` (default false), `action` — `active` must come before `action` in property order so trailing closure syntax works for callsites without `active:`.
- `FilmstripView.swift` — `ScrollViewReader` + `LazyHStack`. `ThumbnailCell` 64×64, index number overlay, lift `offset(y: -2)` on selected, opacity 0.85 non-selected.
- `MetaBarView.swift` — bottom bar: File / Resolution / Size / Captured cells + star rating + "N of M" counter.
- `InfoPanelView.swift` — 280px right panel with Camera / File / Location sections, scrollable, border-left.
- `StageView.swift` — image display. `MagnifyGesture` for pinch-to-zoom (not `MagnificationGesture`).
- `SlideshowView.swift` — black overlay, tap/Esc closes, loads via `loadDisplayImage`.

### Image loading pipeline

`RAWDecoder.swift` — `loadDisplayImage(url:)` handles all formats:
1. Non-RAW (jpg/png/heic/webp/tiff): `NSImage(contentsOf:)` directly
2. RAW (raf/dng/nef/cr2/cr3/arw):
   - Check `$TMPDIR/see_{hash}.jpg` cache first
   - RAF: manual byte extraction (magic `"FUJIFILMCCD-RAW "`, offsets at 84/88)
   - Others: `CGImageSourceCreateThumbnailAtIndex` with `MaxPixelSize: 9000`, require ≥ 1500 px
   - Fallback: `CIRAWFilter.previewImage` (slow, no `draftMode` in macOS 26 SDK)
   - Write result to disk cache

`ImageScanner.swift` — `scanFolder(_:)` + `buildPhotoMeta(url:)`: reads EXIF via `CGImageSource` / `ImageIO`.

All image I/O runs in `Task.detached` (off main thread) and updates state via `await MainActor.run`.

### Swift concurrency constraints (Xcode 26)

**`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`** is set — all top-level functions are implicitly `@MainActor`. Mark any function doing file I/O or called from `Task.detached` as `nonisolated`. Avoid module-level `let` constants in files with `nonisolated` functions — inline them as locals instead (contradictory Xcode 26 warnings otherwise).

**`import Combine` must be explicit** — `@Published` and `ObservableObject` are not transitively available from SwiftUI in Xcode 26. Always add it to files using those types.

**Text concatenation with `+` is deprecated in macOS 26** — use a single `Text` with string interpolation instead.

## Design reference

`ui-design-guideline/` has JSX files (`viewer.jsx`, `tweaks-panel.jsx`, `icons.jsx`, etc.) used as visual specs. Not compiled, not runnable — reference only. `viewer.jsx` is the primary layout spec.
