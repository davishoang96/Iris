# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run full app (Tauri + React dev server)
npm run tauri dev

# Frontend-only dev server (no native shell, port 1420)
npm run dev

# Build for distribution
npm run tauri build

# Type-check frontend
npx tsc --noEmit

# Build Rust only (from src-tauri/)
cargo build
cargo check
```

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run single test file
npx vitest run src/icons.test.tsx
```

## Architecture

Tauri v2 desktop app. Two separate processes:

**Frontend** (`src/`) — React 18 + TypeScript, bundled by Vite on port 1420.
- Entry: `src/main.tsx` → `src/App.tsx`
- Calls Rust via `invoke("command_name", { args })` from `@tauri-apps/api/core`

**Backend** (`src-tauri/src/`) — Rust.
- `lib.rs` — defines `#[tauri::command]` functions and registers them in `invoke_handler`
- `main.rs` — thin entry point that calls `lib::run()`
- New commands must be: defined with `#[tauri::command]`, added to `tauri::generate_handler![...]`

**Capabilities** (`src-tauri/capabilities/default.json`) — controls which Tauri APIs the frontend can use. Add permissions here when using new Tauri plugins.

**Design reference** (`ui-design-guideline/`) — standalone JSX files (not part of the build) used as visual design specs.

## TDD workflow

Write tests before implementation. Order per feature:
1. Write failing test asserting the contract (render output, DOM structure, behavior)
2. Implement minimum code to pass
3. Refactor

Test stack: **Vitest** + **React Testing Library** + **@testing-library/jest-dom**. Test files colocated: `src/foo.test.tsx` beside `src/foo.tsx`. jsdom environment simulates DOM.

For UI components, test behavior not implementation: check rendered output and user interactions, not internal state or CSS classes. For theme switching, assert `document.documentElement` attribute changes. For icons, assert SVG paths render.

Rust backend: use `cargo test` inside `src-tauri/`.

## Key constraints

- Vite port is hardcoded to 1420 (`vite.config.ts` + `tauri.conf.json` `devUrl`). Don't change it.
- App identifier: `viethg.see.app` (used for code signing and app data paths — changing breaks existing installs).
- `src-tauri/` changes require Rust recompile; frontend changes hot-reload.
