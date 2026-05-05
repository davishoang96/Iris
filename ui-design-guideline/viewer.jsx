// See — photo viewer

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "theme": "light",
  "infoPanel": true,
  "bgTone": "charcoal"
}/*EDITMODE-END*/;

// ───────────────────────────────────────────────────────────────────
// Bits
// ───────────────────────────────────────────────────────────────────

const tbBtnStyle = {
  height: 32, minWidth: 32, padding: "0 8px",
  display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 6,
  background: "transparent", border: 0, borderRadius: 8,
  color: "var(--ink)", cursor: "pointer", transition: "background .12s ease",
};

function TBButton({ icon, label, onClick, active, title, kbd }) {
  const [hover, setHover] = React.useState(false);
  const Icon = icon;
  return (
    <button
      onClick={onClick}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      title={title + (kbd ? `  (${kbd})` : "")}
      style={{
        ...tbBtnStyle,
        background: active ? "var(--hairline-strong)" : (hover ? "var(--hairline)" : "transparent"),
      }}
    >
      {Icon ? <Icon size={17} /> : null}
      {label ? <span style={{ fontSize: 12.5, fontWeight: 500, letterSpacing: "-0.005em" }}>{label}</span> : null}
    </button>
  );
}

function TBDivider() {
  return <div style={{ width: 1, height: 18, background: "var(--hairline-strong)", margin: "0 6px" }} />;
}

// ───────────────────────────────────────────────────────────────────
// Top toolbar
// ───────────────────────────────────────────────────────────────────

function Toolbar({ title, index, total, photo,
                   onRotate, onFlipH, onFlipV, onCrop, onStraighten,
                   zoomMode, setZoomMode, zoom, onZoomIn, onZoomOut,
                   onSlideshow, infoOpen, setInfoOpen }) {
  return (
    <header style={{
      gridArea: "top",
      display: "grid", gridTemplateColumns: "1fr auto 1fr",
      alignItems: "center",
      padding: "10px 14px",
      borderBottom: "1px solid var(--hairline)",
      background: "var(--surface)",
      backdropFilter: "saturate(180%) blur(20px)",
      WebkitBackdropFilter: "saturate(180%) blur(20px)",
    }}>
      {/* Left: folder + nav + title */}
      <div style={{ display: "flex", alignItems: "center", gap: 10, minWidth: 0 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 6, color: "var(--ink-2)", fontSize: 12.5, minWidth: 0 }}>
          <Icons.Folder size={15} />
          <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
            Pictures · 2025 · <span style={{ color: "var(--ink)", fontWeight: 500 }}>Iceland & Faroes</span>
          </span>
        </div>
        <div style={{ width: 1, height: 16, background: "var(--hairline-strong)" }} />
        <div style={{ display: "flex", alignItems: "center" }}>
          <TBButton icon={(p) => <Icons.Chevron {...p} style={{ transform: "rotate(180deg)" }} />}
                    title="Previous" kbd="←" onClick={() => window.dispatchEvent(new CustomEvent("nav", { detail: -1 }))} />
          <TBButton icon={Icons.Chevron} title="Next" kbd="→" onClick={() => window.dispatchEvent(new CustomEvent("nav", { detail: 1 }))} />
        </div>
        <div style={{ fontSize: 12.5, color: "var(--ink-3)", fontVariantNumeric: "tabular-nums" }}>
          {index + 1} <span style={{ color: "var(--ink-3)", opacity: .6 }}>/</span> {total}
        </div>
      </div>

      {/* Center: filename */}
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, fontWeight: 600, letterSpacing: "-0.01em", whiteSpace: "nowrap" }}>
          {photo.title}
        </div>
        <div style={{ fontSize: 11, color: "var(--ink-3)", fontFamily: "var(--mono)", letterSpacing: 0 }}>
          {photo.id}.RAF
        </div>
      </div>

      {/* Right: actions */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "flex-end", gap: 0 }}>
        <TBButton icon={Icons.RotateLeft} title="Rotate left"  kbd="⌘L" onClick={() => onRotate(-90)} />
        <TBButton icon={Icons.RotateRight} title="Rotate right" kbd="⌘R" onClick={() => onRotate(+90)} />
        <TBButton icon={Icons.FlipH}      title="Flip horizontal" onClick={onFlipH} />
        <TBButton icon={Icons.FlipV}      title="Flip vertical"   onClick={onFlipV} />
        <TBDivider />
        <TBButton icon={Icons.Crop}        title="Crop"        kbd="C" onClick={onCrop} />
        <TBButton icon={Icons.Straighten}  title="Straighten"          onClick={onStraighten} />
        <TBDivider />
        <TBButton icon={Icons.ZoomOut} title="Zoom out" kbd="−" onClick={onZoomOut} />
        <div style={{ fontSize: 11.5, color: "var(--ink-2)", fontFamily: "var(--mono)",
                       minWidth: 44, textAlign: "center", fontVariantNumeric: "tabular-nums" }}>
          {Math.round(zoom * 100)}%
        </div>
        <TBButton icon={Icons.ZoomIn} title="Zoom in" kbd="+" onClick={onZoomIn} />
        <TBButton icon={Icons.Fit}      title="Fit to window" kbd="F" active={zoomMode === "fit"}
                  onClick={() => setZoomMode("fit")} />
        <TBButton icon={Icons.OneToOne} title="Actual size"   kbd="1" active={zoomMode === "100"}
                  onClick={() => setZoomMode("100")} />
        <TBButton icon={Icons.Fill}     title="Fill"                  active={zoomMode === "fill"}
                  onClick={() => setZoomMode("fill")} />
        <TBDivider />
        <TBButton icon={Icons.Slideshow} title="Slideshow"     onClick={onSlideshow} />
        <TBButton icon={Icons.Share}     title="Share / Export" />
        <TBButton icon={Icons.Info}      title="Toggle Info panel" kbd="I"
                  active={infoOpen} onClick={() => setInfoOpen(v => !v)} />
      </div>
    </header>
  );
}

// ───────────────────────────────────────────────────────────────────
// Main canvas (photo)
// ───────────────────────────────────────────────────────────────────

function Stage({ photo, rotation, flip, zoom, zoomMode, bgTone }) {
  const wrapRef = React.useRef(null);
  const [box, setBox] = React.useState({ w: 0, h: 0 });

  React.useEffect(() => {
    const el = wrapRef.current;
    if (!el) return;
    const ro = new ResizeObserver(() => {
      const r = el.getBoundingClientRect();
      setBox({ w: r.width, h: r.height });
    });
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  // figure out displayed dims
  const rotated = (rotation / 90) % 2 !== 0;
  const aspect = rotated ? (photo.h / photo.w) : (photo.w / photo.h);

  // base "fit" size
  let fitW = box.w, fitH = box.w / aspect;
  if (fitH > box.h) { fitH = box.h; fitW = box.h * aspect; }

  // base "fill" size
  let fillW = box.w, fillH = box.w / aspect;
  if (fillH < box.h) { fillH = box.h; fillW = box.h * aspect; }

  let baseW, baseH;
  if (zoomMode === "fill") { baseW = fillW; baseH = fillH; }
  else if (zoomMode === "100") {
    // 1:1 of the photo (we treat 2000px source as actual)
    baseW = rotated ? photo.h : photo.w;
    baseH = rotated ? photo.w : photo.h;
    // scale down so it shows reasonably
    baseW = Math.min(baseW, 2000); baseH = Math.min(baseH, 2000 / aspect);
  } else { baseW = fitW; baseH = fitH; }

  const finalW = baseW * zoom;
  const finalH = baseH * zoom;

  const bgFill = bgTone === "black" ? "#050507"
               : bgTone === "paper" ? "var(--bg)"
               : "var(--canvas)";

  return (
    <div ref={wrapRef} style={{
      gridArea: "stage", position: "relative", overflow: "hidden",
      background: bgFill,
      display: "flex", alignItems: "center", justifyContent: "center",
      backgroundImage: bgTone === "checker" ?
        "linear-gradient(45deg, #2a2a2e 25%, transparent 25%), linear-gradient(-45deg, #2a2a2e 25%, transparent 25%), linear-gradient(45deg, transparent 75%, #2a2a2e 75%), linear-gradient(-45deg, transparent 75%, #2a2a2e 75%)" : undefined,
      backgroundSize: bgTone === "checker" ? "20px 20px" : undefined,
      backgroundPosition: bgTone === "checker" ? "0 0, 0 10px, 10px -10px, -10px 0" : undefined,
    }}>
      {/* the image */}
      <div style={{
        width: finalW, height: finalH,
        transition: "width .2s ease, height .2s ease",
        position: "relative",
        boxShadow: "0 30px 80px -30px #00000088, 0 2px 0 #ffffff04 inset",
      }}>
        <img
          src={photo.full}
          alt=""
          draggable={false}
          style={{
            width: "100%", height: "100%", display: "block",
            objectFit: "cover",
            transform: `rotate(${rotation}deg) scale(${flip.h ? -1 : 1}, ${flip.v ? -1 : 1})`,
            transformOrigin: "center",
            transition: "transform .35s cubic-bezier(.2,.8,.2,1)",
            userSelect: "none",
          }}
        />
      </div>

      {/* corner: resolution */}
      <div style={{
        position: "absolute", top: 12, right: 12,
        padding: "4px 8px", borderRadius: 6,
        background: "#0008", color: "#f1f0ec",
        fontFamily: "var(--mono)", fontSize: 11, letterSpacing: 0,
        opacity: .55,
      }}>
        {photo.w} × {photo.h}
      </div>
    </div>
  );
}

// ───────────────────────────────────────────────────────────────────
// Filmstrip
// ───────────────────────────────────────────────────────────────────

function Filmstrip({ photos, index, setIndex }) {
  const stripRef = React.useRef(null);

  React.useEffect(() => {
    // keep selected thumbnail in view
    const el = stripRef.current?.querySelector(`[data-idx="${index}"]`);
    if (el) {
      const parent = stripRef.current;
      const er = el.getBoundingClientRect();
      const pr = parent.getBoundingClientRect();
      if (er.left < pr.left + 24 || er.right > pr.right - 24) {
        parent.scrollTo({ left: el.offsetLeft - parent.clientWidth / 2 + el.clientWidth / 2, behavior: "smooth" });
      }
    }
  }, [index]);

  return (
    <div style={{
      gridArea: "strip",
      borderTop: "1px solid var(--hairline)",
      borderBottom: "1px solid var(--hairline)",
      background: "var(--surface)",
      backdropFilter: "saturate(180%) blur(20px)",
      WebkitBackdropFilter: "saturate(180%) blur(20px)",
      padding: "10px 14px 12px",
      position: "relative",
    }}>
      <div ref={stripRef} style={{
        display: "flex", gap: 4,
        overflowX: "auto", overflowY: "hidden",
        scrollbarWidth: "none", msOverflowStyle: "none",
        paddingBottom: 2,
      }}>
        <style>{`#strip-scroll::-webkit-scrollbar{display:none}`}</style>
        {photos.map((p, i) => {
          const selected = i === index;
          return (
            <button
              key={p.id}
              data-idx={i}
              onClick={() => setIndex(i)}
              style={{
                flex: "0 0 auto",
                width: 64, height: 64,
                padding: 0, border: 0, cursor: "pointer",
                position: "relative",
                borderRadius: 4,
                background: "transparent",
                outline: selected ? "2px solid var(--ink)" : "1px solid var(--hairline-strong)",
                outlineOffset: selected ? 1 : 0,
                transform: selected ? "translateY(-2px)" : "none",
                transition: "transform .15s ease, outline-color .12s ease",
              }}
              title={`${p.id} — ${p.title}`}
            >
              <img src={p.thumb} alt="" draggable={false}
                style={{ width: "100%", height: "100%", objectFit: "cover", display: "block",
                         borderRadius: 3, opacity: selected ? 1 : 0.85 }} />
              {/* rating dot */}
              {p.rating >= 5 ? (
                <span style={{
                  position: "absolute", top: 4, right: 4, width: 6, height: 6, borderRadius: 99,
                  background: "#ffcc33", boxShadow: "0 0 0 1px #00000033"
                }} />
              ) : null}
              <span style={{
                position: "absolute", bottom: 3, left: 4,
                fontFamily: "var(--mono)", fontSize: 9, color: "#fff",
                textShadow: "0 1px 2px #000a", letterSpacing: 0,
                opacity: selected ? 1 : 0.7,
              }}>
                {String(i + 1).padStart(2, "0")}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ───────────────────────────────────────────────────────────────────
// Bottom meta bar
// ───────────────────────────────────────────────────────────────────

function MetaBar({ photo }) {
  const Cell = ({ label, value, mono }) => (
    <div style={{ display: "flex", flexDirection: "column", gap: 1, minWidth: 0 }}>
      <div style={{ fontSize: 10, color: "var(--ink-3)", textTransform: "uppercase",
                     letterSpacing: "0.06em", fontWeight: 500 }}>{label}</div>
      <div style={{ fontSize: 12, color: "var(--ink)", fontWeight: 500,
                     fontFamily: mono ? "var(--mono)" : "var(--sans)",
                     overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
        {value}
      </div>
    </div>
  );

  return (
    <footer style={{
      gridArea: "bottom",
      display: "grid",
      gridTemplateColumns: "minmax(160px,1.2fr) minmax(120px,1fr) minmax(100px,1fr) minmax(160px,1.4fr) auto",
      alignItems: "center",
      gap: 28,
      padding: "10px 18px",
      background: "var(--surface)",
      backdropFilter: "saturate(180%) blur(20px)",
      WebkitBackdropFilter: "saturate(180%) blur(20px)",
    }}>
      <Cell label="File"        value={`${photo.id}.RAF`} mono />
      <Cell label="Resolution"  value={`${photo.w} × ${photo.h}`} mono />
      <Cell label="Size"        value={photo.size} mono />
      <Cell label="Captured"    value={photo.date} />
      {/* right cluster: stars + selected count */}
      <div style={{ display: "flex", alignItems: "center", gap: 12, justifyContent: "flex-end" }}>
        <div style={{ display: "inline-flex", color: "var(--ink-2)" }}>
          {[1, 2, 3, 4, 5].map(n => (
            <span key={n} style={{ color: n <= photo.rating ? "#e8a900" : "var(--ink-3)", opacity: n <= photo.rating ? 1 : .35 }}>
              <Icons.Star size={13} filled={n <= photo.rating} />
            </span>
          ))}
        </div>
        <div style={{ width: 1, height: 16, background: "var(--hairline-strong)" }} />
        <div style={{ fontSize: 11.5, color: "var(--ink-3)", fontFamily: "var(--mono)" }}>
          1 of {window.PHOTOS.length} selected
        </div>
      </div>
    </footer>
  );
}

// ───────────────────────────────────────────────────────────────────
// Right info panel
// ───────────────────────────────────────────────────────────────────

function InfoPanel({ photo }) {
  const Row = ({ label, value, mono = true }) => (
    <div style={{ display: "grid", gridTemplateColumns: "92px 1fr", gap: 12,
                  padding: "7px 0", borderBottom: "1px solid var(--hairline)" }}>
      <div style={{ fontSize: 11.5, color: "var(--ink-3)" }}>{label}</div>
      <div style={{ fontSize: 12, color: "var(--ink)",
                     fontFamily: mono ? "var(--mono)" : "var(--sans)",
                     fontWeight: mono ? 400 : 500 }}>{value}</div>
    </div>
  );
  return (
    <aside style={{
      gridArea: "panel",
      borderLeft: "1px solid var(--hairline)",
      background: "var(--surface-solid)",
      overflowY: "auto",
      padding: "18px 20px 24px",
    }}>
      <div style={{ fontSize: 11, color: "var(--ink-3)", textTransform: "uppercase",
                     letterSpacing: "0.08em", fontWeight: 600, marginBottom: 10 }}>
        Information
      </div>

      <h2 style={{ fontSize: 18, margin: "0 0 4px", letterSpacing: "-0.015em", lineHeight: 1.2 }}>
        {photo.title}
      </h2>
      <div style={{ fontSize: 12.5, color: "var(--ink-2)", marginBottom: 18 }}>{photo.location}</div>

      {/* histogram (placeholder waveform-y) */}
      <div style={{ height: 64, marginBottom: 18,
                     borderRadius: 6, padding: "8px 10px",
                     background: "var(--hairline)", position: "relative", overflow: "hidden" }}>
        <Histogram seed={photo.id} />
      </div>

      <div style={{ fontSize: 11, color: "var(--ink-3)", textTransform: "uppercase",
                     letterSpacing: "0.08em", fontWeight: 600, margin: "4px 0 6px" }}>
        Camera
      </div>
      <Row label="Camera" value={photo.camera} mono={false} />
      <Row label="Lens"   value={photo.lens}   mono={false} />
      <Row label="Focal"  value={photo.focal} />
      <Row label="ƒ"      value={photo.aperture} />
      <Row label="Shutter" value={photo.shutter} />
      <Row label="ISO"    value={photo.iso} />

      <div style={{ height: 14 }} />
      <div style={{ fontSize: 11, color: "var(--ink-3)", textTransform: "uppercase",
                     letterSpacing: "0.08em", fontWeight: 600, margin: "4px 0 6px" }}>
        File
      </div>
      <Row label="Filename"   value={`${photo.id}.RAF`} />
      <Row label="Dimensions" value={`${photo.w} × ${photo.h}`} />
      <Row label="Size"       value={photo.size} />
      <Row label="Captured"   value={photo.date} mono={false} />
      <Row label="Profile"    value={photo.profile} mono={false} />

      <div style={{ height: 14 }} />
      <div style={{ fontSize: 11, color: "var(--ink-3)", textTransform: "uppercase",
                     letterSpacing: "0.08em", fontWeight: 600, margin: "4px 0 6px" }}>
        Location
      </div>
      <Row label="Coords" value={photo.gps} />
      <div style={{ marginTop: 10, height: 110, borderRadius: 8, overflow: "hidden",
                     border: "1px solid var(--hairline)", position: "relative",
                     background: "var(--bg)" }}>
        <MiniMap photo={photo} />
      </div>
    </aside>
  );
}

function Histogram({ seed }) {
  // deterministic from seed
  const bars = React.useMemo(() => {
    let s = 0;
    for (let i = 0; i < seed.length; i++) s = (s * 31 + seed.charCodeAt(i)) >>> 0;
    const rng = () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 0xFFFFFFFF; };
    const N = 64;
    return Array.from({ length: N }, (_, i) => {
      const t = i / N;
      // bell-curve shape with noise
      const bell = Math.exp(-Math.pow((t - 0.55) / 0.28, 2));
      return Math.max(0.04, Math.min(1, bell * (0.6 + rng() * 0.55)));
    });
  }, [seed]);

  return (
    <svg viewBox="0 0 200 48" style={{ width: "100%", height: "100%", display: "block" }}>
      <defs>
        <linearGradient id="hg" x1="0" x2="1" y1="0" y2="0">
          <stop offset="0" stopColor="#222" stopOpacity=".75" />
          <stop offset=".5" stopColor="#888" stopOpacity=".75" />
          <stop offset="1" stopColor="#fff" stopOpacity=".95" />
        </linearGradient>
      </defs>
      {bars.map((v, i) => (
        <rect key={i} x={i * (200 / 64) + 0.4} y={48 - v * 44} width={200 / 64 - 0.8}
              height={v * 44} fill="url(#hg)" opacity=".85" />
      ))}
    </svg>
  );
}

function MiniMap({ photo }) {
  // pull lat/lng for a tiny indicator dot — abstract map only
  return (
    <div style={{ position: "absolute", inset: 0,
                   backgroundImage: "radial-gradient(circle at 30% 70%, #b9d4ff 0 18%, transparent 18%), radial-gradient(circle at 75% 50%, #b9d4ff 0 22%, transparent 22%), radial-gradient(circle at 55% 30%, #b9d4ff 0 14%, transparent 14%)",
                   backgroundColor: "#eef0f2" }}>
      <svg viewBox="0 0 100 60" preserveAspectRatio="none" style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }}>
        <path d="M0 40 Q 20 30 35 38 T 70 32 T 100 30" stroke="#b9d4ff" fill="none" strokeWidth="0.8" />
        <path d="M0 50 Q 30 44 50 48 T 100 44" stroke="#b9d4ff" fill="none" strokeWidth="0.6" />
      </svg>
      <div style={{
        position: "absolute", left: "62%", top: "44%",
        width: 10, height: 10, borderRadius: 99,
        background: "var(--accent)", boxShadow: "0 0 0 4px #1a73ff33, 0 0 0 1px #1a73ff",
        transform: "translate(-50%,-50%)",
      }} />
      <div style={{ position: "absolute", left: 8, bottom: 6, fontSize: 10,
                     color: "#5a5963", fontFamily: "var(--mono)" }}>
        {photo.gps}
      </div>
    </div>
  );
}

// ───────────────────────────────────────────────────────────────────
// Slideshow overlay
// ───────────────────────────────────────────────────────────────────

function Slideshow({ photo, onClose }) {
  return (
    <div onClick={onClose} style={{
      position: "fixed", inset: 0, background: "#000",
      display: "flex", alignItems: "center", justifyContent: "center",
      zIndex: 99, cursor: "pointer",
    }}>
      <img src={photo.full} style={{ maxWidth: "94vw", maxHeight: "94vh", objectFit: "contain",
                                       boxShadow: "0 40px 100px -20px #000" }} />
      <div style={{ position: "absolute", bottom: 28, left: 0, right: 0, textAlign: "center",
                     color: "#aaa", fontSize: 12, fontFamily: "var(--mono)" }}>
        click anywhere or press Esc to exit
      </div>
    </div>
  );
}

// ───────────────────────────────────────────────────────────────────
// Viewer
// ───────────────────────────────────────────────────────────────────

function Viewer() {
  const [index, setIndex] = React.useState(3);
  const [rotation, setRotation] = React.useState(0);
  const [flip, setFlip] = React.useState({ h: false, v: false });
  const [zoomMode, setZoomMode] = React.useState("fit"); // fit | fill | 100
  const [zoom, setZoom] = React.useState(1);
  const [slideshow, setSlideshow] = React.useState(false);

  const tweaks = useTweaks(TWEAK_DEFAULTS);

  // theme on <html>
  React.useEffect(() => {
    document.documentElement.setAttribute("data-theme", tweaks.values.theme);
  }, [tweaks.values.theme]);

  const photo = window.PHOTOS[index];

  // reset transforms on photo change
  React.useEffect(() => { setRotation(0); setFlip({ h: false, v: false }); setZoom(1); }, [index]);

  // keys
  React.useEffect(() => {
    const onKey = (e) => {
      if (e.key === "ArrowLeft")  setIndex(i => (i - 1 + window.PHOTOS.length) % window.PHOTOS.length);
      else if (e.key === "ArrowRight") setIndex(i => (i + 1) % window.PHOTOS.length);
      else if (e.key === "+" || e.key === "=") setZoom(z => Math.min(4, +(z + 0.1).toFixed(2)));
      else if (e.key === "-") setZoom(z => Math.max(0.2, +(z - 0.1).toFixed(2)));
      else if (e.key.toLowerCase() === "f") setZoomMode("fit");
      else if (e.key === "1") setZoomMode("100");
      else if (e.key.toLowerCase() === "i") tweaks.setTweak("infoPanel", !tweaks.values.infoPanel);
      else if (e.key === "Escape") setSlideshow(false);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [tweaks.values.infoPanel]);

  // listen for nav events from toolbar
  React.useEffect(() => {
    const onNav = (e) => setIndex(i => (i + e.detail + window.PHOTOS.length) % window.PHOTOS.length);
    window.addEventListener("nav", onNav);
    return () => window.removeEventListener("nav", onNav);
  }, []);

  const infoOpen = !!tweaks.values.infoPanel;

  return (
    <div style={{
      display: "grid",
      gridTemplateColumns: infoOpen ? "minmax(0,1fr) minmax(0,320px)" : "minmax(0,1fr)",
      width: "100vw",
      gridTemplateRows: "auto 1fr auto auto",
      gridTemplateAreas: infoOpen
        ? `"top top" "stage panel" "strip panel" "bottom panel"`
        : `"top" "stage" "strip" "bottom"`,
      height: "100vh",
      transition: "grid-template-columns .25s ease",
    }}>
      <Toolbar
        title={photo.title} index={index} total={window.PHOTOS.length} photo={photo}
        onRotate={(d) => setRotation(r => r + d)}
        onFlipH={() => setFlip(f => ({ ...f, h: !f.h }))}
        onFlipV={() => setFlip(f => ({ ...f, v: !f.v }))}
        onCrop={() => {}} onStraighten={() => {}}
        zoomMode={zoomMode} setZoomMode={(m) => { setZoomMode(m); setZoom(1); }}
        zoom={zoom}
        onZoomIn={() => setZoom(z => Math.min(4, +(z + 0.1).toFixed(2)))}
        onZoomOut={() => setZoom(z => Math.max(0.2, +(z - 0.1).toFixed(2)))}
        onSlideshow={() => setSlideshow(true)}
        infoOpen={infoOpen}
        setInfoOpen={(v) => tweaks.setTweak("infoPanel", typeof v === "function" ? v(infoOpen) : v)}
      />

      <Stage photo={photo} rotation={rotation} flip={flip}
             zoom={zoom} zoomMode={zoomMode} bgTone={tweaks.values.bgTone} />

      <Filmstrip photos={window.PHOTOS} index={index} setIndex={setIndex} />

      <MetaBar photo={photo} />

      {infoOpen ? <InfoPanel photo={photo} /> : null}

      {slideshow ? <Slideshow photo={photo} onClose={() => setSlideshow(false)} /> : null}

      {/* Tweaks panel */}
      <TweaksPanel title="Tweaks">
        <TweakSection title="Theme">
          <TweakRadio
            value={tweaks.values.theme}
            onChange={(v) => tweaks.setTweak("theme", v)}
            options={[
              { value: "light", label: "Light" },
              { value: "dim",   label: "Dim" },
              { value: "dark",  label: "Dark" },
            ]}
          />
        </TweakSection>
        <TweakSection title="Photo backdrop">
          <TweakRadio
            value={tweaks.values.bgTone}
            onChange={(v) => tweaks.setTweak("bgTone", v)}
            options={[
              { value: "charcoal", label: "Charcoal" },
              { value: "black",    label: "Pure black" },
              { value: "paper",    label: "Paper" },
              { value: "checker",  label: "Checker" },
            ]}
          />
        </TweakSection>
        <TweakSection title="Layout">
          <TweakToggle
            label="Show info panel"
            checked={tweaks.values.infoPanel}
            onChange={(v) => tweaks.setTweak("infoPanel", v)}
          />
        </TweakSection>
      </TweaksPanel>
    </div>
  );
}

window.Viewer = Viewer;
