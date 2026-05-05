# See — Design Plan

Photo viewer desktop app (Tauri + React + TypeScript).
Design spec: `ui-design-guideline/See.html`

---

## Phase 1: Foundation
*CSS design system + icon library + layout shell*

- [x] Port CSS vars — 3 themes (light / dim / dark), all tokens (`--bg`, `--surface`, `--surface-solid`, `--hairline`, `--hairline-strong`, `--ink`, `--ink-2`, `--ink-3`, `--accent`, `--shadow`, `--canvas`, `--mono`, `--sans`)
- [x] Load Inter Tight + JetBrains Mono (Google Fonts)
- [x] Port 18 SVG icons to `src/icons.tsx` — hairline style, 20×20 viewbox (RotateLeft, RotateRight, FlipH, FlipV, Crop, Straighten, Fit, OneToOne, Fill, ZoomOut, ZoomIn, Share, Info, Slideshow, Chevron, Folder, Star, Search)
- [x] Replace `App.tsx` with CSS Grid shell — areas: `top / stage / strip / bottom / panel`
- [x] Theme switcher wired to `<html data-theme>`

**Gate:** App launches, correct grid regions visible, theme toggle works. No content. ✅

---

## Phase 2: Core Viewer (mock data)
*Toolbar + Stage + Filmstrip + MetaBar*

- [x] `Photo` TypeScript type (id, w, h, camera, lens, focal, aperture, shutter, iso, title, location, gps, rating, full, thumb, aspect, size, date, profile)
- [x] Mock photo data — port 20 Iceland / Faroe Islands photos from `ui-design-guideline/photos.jsx`
- [x] `Toolbar` component — 3-column layout:
  - Left: folder breadcrumb, prev/next buttons, photo counter
  - Center: photo title + filename
  - Right: rotate L/R, flip H/V, crop, straighten, zoom −/+/%, fit/1:1/fill, slideshow, share, info toggle
- [x] `Stage` component — photo canvas with:
  - Zoom modes: fit / fill / 1:1
  - Rotation (90° steps), flip H/V transforms
  - Backdrop tones: charcoal / black / paper / checker
  - Resolution overlay (top-right corner)
- [x] `Filmstrip` component — horizontal scroll, 64×64 thumbs, selected lift + outline, rating dot (⭐5), sequence numbers
- [x] `MetaBar` component — bottom bar: File / Resolution / Size / Captured / star rating / count
- [x] Keyboard shortcuts: `←` `→` navigate · `+` `-` zoom · `F` fit · `1` 1:1 · `I` info · `Esc` slideshow exit

**Gate:** Fully navigable viewer, all UI chrome rendered, mock Unsplash photos loading. ✅

---

## Phase 3: Info Panel + Slideshow
*Right panel (320px) + full-screen slideshow overlay*

- [ ] Collapsible right panel — animated via `grid-template-columns` transition (0.25s)
- [ ] `InfoPanel` component:
  - Header: title + location
  - Histogram (deterministic SVG seeded from photo id)
  - Camera section: camera / lens / focal / aperture / shutter / ISO
  - File section: filename / dimensions / size / captured / color profile
  - Location section: GPS coords + abstract MiniMap
- [ ] `Slideshow` overlay — fullscreen black bg, click or `Esc` to exit

**Gate:** Complete pixel-faithful implementation of `See.html` prototype. All interactions working.

---

## Phase 4: Real Files via Tauri Backend
*Replace mock data with actual local photos*

- [ ] Rust: `open_folder` command — native folder picker dialog
- [ ] Rust: `list_images` command — scan dir for JPEG / PNG / RAF / HEIC, return file metadata
- [ ] Rust: `read_exif` command — parse EXIF using `kamadak-exif` crate, return structured metadata
- [ ] Frontend: load `file://` URLs via Tauri asset protocol for thumbnails + full images
- [ ] Replace hardcoded `PHOTOS` array with state loaded from disk
- [ ] Empty state screen when no folder selected

**Gate:** App works on real photos from disk — folder open → browse → EXIF displayed.

---

## Status

| Phase | Status |
|-------|--------|
| 1 — Foundation | ✅ Done |
| 2 — Core Viewer | ✅ Done |
| 3 — Info Panel | Not started |
| 4 — Real Files | Not started |
