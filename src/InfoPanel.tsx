import React, { useMemo } from "react";
import type { Photo } from "./photos";

interface InfoPanelProps {
  photo: Photo;
}

function Row({ label, value, mono = true }: { label: string; value: string; mono?: boolean }) {
  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "92px 1fr",
        gap: 12,
        padding: "7px 0",
        borderBottom: "1px solid var(--hairline)",
      }}
    >
      <div style={{ fontSize: 11.5, color: "var(--ink-3)" }}>{label}</div>
      <div
        style={{
          fontSize: 12,
          color: "var(--ink)",
          fontFamily: mono ? "var(--mono)" : "var(--sans)",
          fontWeight: mono ? 400 : 500,
          overflow: "hidden",
          textOverflow: "ellipsis",
          whiteSpace: "nowrap",
        }}
      >
        {value}
      </div>
    </div>
  );
}

function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <div
      style={{
        fontSize: 11,
        color: "var(--ink-3)",
        textTransform: "uppercase",
        letterSpacing: "0.08em",
        fontWeight: 600,
        margin: "4px 0 6px",
      }}
    >
      {children}
    </div>
  );
}

function Histogram({ seed }: { seed: string }) {
  const bars = useMemo(() => {
    let s = 0;
    for (let i = 0; i < seed.length; i++) s = (s * 31 + seed.charCodeAt(i)) >>> 0;
    const rng = () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 0xffffffff; };
    const N = 64;
    return Array.from({ length: N }, (_, i) => {
      const t = i / N;
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
        <rect
          key={i}
          x={i * (200 / 64) + 0.4}
          y={48 - v * 44}
          width={200 / 64 - 0.8}
          height={v * 44}
          fill="url(#hg)"
          opacity=".85"
        />
      ))}
    </svg>
  );
}

function MiniMap({ photo }: { photo: Photo }) {
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        backgroundImage:
          "radial-gradient(circle at 30% 70%, #b9d4ff 0 18%, transparent 18%)," +
          "radial-gradient(circle at 75% 50%, #b9d4ff 0 22%, transparent 22%)," +
          "radial-gradient(circle at 55% 30%, #b9d4ff 0 14%, transparent 14%)",
        backgroundColor: "#eef0f2",
      }}
    >
      <svg
        viewBox="0 0 100 60"
        preserveAspectRatio="none"
        style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }}
      >
        <path d="M0 40 Q 20 30 35 38 T 70 32 T 100 30" stroke="#b9d4ff" fill="none" strokeWidth="0.8" />
        <path d="M0 50 Q 30 44 50 48 T 100 44" stroke="#b9d4ff" fill="none" strokeWidth="0.6" />
      </svg>
      <div
        style={{
          position: "absolute",
          left: "62%",
          top: "44%",
          width: 10,
          height: 10,
          borderRadius: 99,
          background: "var(--accent)",
          boxShadow: "0 0 0 4px #1a73ff33, 0 0 0 1px #1a73ff",
          transform: "translate(-50%,-50%)",
        }}
      />
      <div
        style={{
          position: "absolute",
          left: 8,
          bottom: 6,
          fontSize: 10,
          color: "#5a5963",
          fontFamily: "var(--mono)",
        }}
      >
        {photo.gps}
      </div>
    </div>
  );
}

export function InfoPanel({ photo }: InfoPanelProps) {
  return (
    <aside
      style={{
        height: "100%",
        borderLeft: "1px solid var(--hairline)",
        background: "var(--surface-solid)",
        overflowY: "auto",
        padding: "18px 20px 24px",
        boxSizing: "border-box",
      }}
    >
      <div
        style={{
          fontSize: 11,
          color: "var(--ink-3)",
          textTransform: "uppercase",
          letterSpacing: "0.08em",
          fontWeight: 600,
          marginBottom: 10,
        }}
      >
        Information
      </div>

      <h2
        style={{
          fontSize: 18,
          margin: "0 0 4px",
          letterSpacing: "-0.015em",
          lineHeight: 1.2,
          fontWeight: 600,
        }}
      >
        {photo.title}
      </h2>
      <div style={{ fontSize: 12.5, color: "var(--ink-2)", marginBottom: 18 }}>
        {photo.location}
      </div>

      <div
        style={{
          height: 64,
          marginBottom: 18,
          borderRadius: 6,
          padding: "8px 10px",
          background: "var(--hairline)",
          position: "relative",
          overflow: "hidden",
        }}
      >
        <Histogram seed={photo.id} />
      </div>

      <SectionLabel>Camera</SectionLabel>
      <Row label="Camera"  value={photo.camera}   mono={false} />
      <Row label="Lens"    value={photo.lens}     mono={false} />
      <Row label="Focal"   value={photo.focal} />
      <Row label="ƒ"       value={photo.aperture} />
      <Row label="Shutter" value={photo.shutter} />
      <Row label="ISO"     value={String(photo.iso)} />

      <div style={{ height: 14 }} />
      <SectionLabel>File</SectionLabel>
      <Row label="Filename"   value={photo.filename} />
      <Row label="Dimensions" value={`${photo.w} × ${photo.h}`} />
      <Row label="Size"       value={photo.size} />
      <Row label="Captured"   value={photo.date} mono={false} />
      <Row label="Profile"    value={photo.profile} mono={false} />

      <div style={{ height: 14 }} />
      <SectionLabel>Location</SectionLabel>
      <Row label="Coords" value={photo.gps} />
      <div
        style={{
          marginTop: 10,
          height: 110,
          borderRadius: 8,
          overflow: "hidden",
          border: "1px solid var(--hairline)",
          position: "relative",
          background: "var(--bg)",
        }}
      >
        <MiniMap photo={photo} />
      </div>
    </aside>
  );
}
