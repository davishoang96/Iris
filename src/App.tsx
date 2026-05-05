import "./App.css";
import { ThemeProvider, useTheme, type Theme } from "./theme";
import { ViewerShell } from "./layout";
import {
  IconFolder, IconChevron, IconRotateLeft, IconRotateRight,
  IconFlipH, IconFlipV, IconCrop, IconStraighten,
  IconZoomOut, IconZoomIn, IconFit, IconOneToOne, IconFill,
  IconSlideshow, IconShare, IconInfo,
} from "./icons";

/* ── Placeholder chrome ─────────────────────────────────────────────────────── */

function PlaceholderToolbar() {
  const { theme, setTheme } = useTheme();
  const themes: Theme[] = ["light", "dim", "dark"];

  return (
    <header style={{
      display: "grid",
      gridTemplateColumns: "1fr auto 1fr",
      alignItems: "center",
      padding: "10px 14px",
      borderBottom: "1px solid var(--hairline)",
      background: "var(--surface)",
      backdropFilter: "saturate(180%) blur(20px)",
      WebkitBackdropFilter: "saturate(180%) blur(20px)",
    }}>
      {/* Left */}
      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 6, color: "var(--ink-2)", fontSize: 12.5 }}>
          <IconFolder size={15} />
          <span>Pictures · 2025 · <strong style={{ color: "var(--ink)" }}>Iceland & Faroes</strong></span>
        </div>
        <div style={{ width: 1, height: 16, background: "var(--hairline-strong)" }} />
        <button style={tbBtn}>
          <IconChevron size={17} style={{ transform: "rotate(180deg)" }} />
        </button>
        <button style={tbBtn}>
          <IconChevron size={17} />
        </button>
        <span style={{ fontSize: 12.5, color: "var(--ink-3)", fontVariantNumeric: "tabular-nums" }}>
          1 / 20
        </span>
      </div>

      {/* Center */}
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 1 }}>
        <div style={{ fontSize: 13, fontWeight: 600, letterSpacing: "-0.01em" }}>Reynisfjara at dawn</div>
        <div style={{ fontSize: 11, color: "var(--ink-3)", fontFamily: "var(--mono)" }}>DSCF1042.RAF</div>
      </div>

      {/* Right */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "flex-end", gap: 0 }}>
        <button style={tbBtn}><IconRotateLeft size={17} /></button>
        <button style={tbBtn}><IconRotateRight size={17} /></button>
        <button style={tbBtn}><IconFlipH size={17} /></button>
        <button style={tbBtn}><IconFlipV size={17} /></button>
        <Divider />
        <button style={tbBtn}><IconCrop size={17} /></button>
        <button style={tbBtn}><IconStraighten size={17} /></button>
        <Divider />
        <button style={tbBtn}><IconZoomOut size={17} /></button>
        <span style={{ fontSize: 11.5, color: "var(--ink-2)", fontFamily: "var(--mono)", minWidth: 44, textAlign: "center" }}>100%</span>
        <button style={tbBtn}><IconZoomIn size={17} /></button>
        <button style={tbBtn}><IconFit size={17} /></button>
        <button style={tbBtn}><IconOneToOne size={17} /></button>
        <button style={tbBtn}><IconFill size={17} /></button>
        <Divider />
        <button style={tbBtn}><IconSlideshow size={17} /></button>
        <button style={tbBtn}><IconShare size={17} /></button>
        <button style={tbBtn}><IconInfo size={17} /></button>
        <Divider />
        {/* Theme switcher */}
        <div style={{ display: "flex", gap: 4, marginLeft: 6 }}>
          {themes.map(t => (
            <button
              key={t}
              onClick={() => setTheme(t)}
              style={{
                ...tbBtn,
                fontSize: 10,
                fontWeight: theme === t ? 700 : 400,
                background: theme === t ? "var(--hairline-strong)" : "transparent",
                borderRadius: 6,
                padding: "0 8px",
              }}
            >
              {t}
            </button>
          ))}
        </div>
      </div>
    </header>
  );
}

function PlaceholderStage() {
  return (
    <div style={{
      gridArea: "stage",
      background: "var(--canvas)",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      color: "var(--ink-3)",
      fontFamily: "var(--mono)",
      fontSize: 12,
    }}>
      stage — photo canvas
    </div>
  );
}

function PlaceholderFilmstrip() {
  return (
    <div style={{
      gridArea: "strip",
      borderTop: "1px solid var(--hairline)",
      borderBottom: "1px solid var(--hairline)",
      background: "var(--surface)",
      padding: "10px 14px",
      display: "flex",
      gap: 4,
      alignItems: "center",
      color: "var(--ink-3)",
      fontFamily: "var(--mono)",
      fontSize: 11,
    }}>
      {Array.from({ length: 20 }, (_, i) => (
        <div key={i} style={{
          width: 64, height: 64, borderRadius: 4, flexShrink: 0,
          background: "var(--hairline-strong)",
          border: i === 0 ? "2px solid var(--ink)" : "1px solid var(--hairline-strong)",
        }} />
      ))}
    </div>
  );
}

function PlaceholderMetaBar() {
  return (
    <footer style={{
      gridArea: "bottom",
      display: "flex",
      alignItems: "center",
      gap: 28,
      padding: "10px 18px",
      background: "var(--surface)",
      borderTop: "1px solid var(--hairline)",
      fontSize: 12,
      color: "var(--ink-3)",
      fontFamily: "var(--mono)",
    }}>
      <span>DSCF1042.RAF</span>
      <span>6000 × 4000</span>
      <span>12.4 MB</span>
      <span style={{ fontFamily: "var(--sans)" }}>Jul 18, 2025 · 06:42</span>
    </footer>
  );
}

/* ── Helpers ────────────────────────────────────────────────────────────────── */

const tbBtn: React.CSSProperties = {
  height: 32, minWidth: 32, padding: "0 8px",
  display: "inline-flex", alignItems: "center", justifyContent: "center",
  background: "transparent", border: 0, borderRadius: 8,
  color: "var(--ink)", cursor: "pointer",
};

function Divider() {
  return <div style={{ width: 1, height: 18, background: "var(--hairline-strong)", margin: "0 6px" }} />;
}

/* ── Root ───────────────────────────────────────────────────────────────────── */

export default function App() {
  return (
    <ThemeProvider initial="light">
      <ViewerShell
        toolbar={<PlaceholderToolbar />}
        stage={<PlaceholderStage />}
        filmstrip={<PlaceholderFilmstrip />}
        metabar={<PlaceholderMetaBar />}
      />
    </ThemeProvider>
  );
}
