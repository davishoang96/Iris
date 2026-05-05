import type { Photo } from "./photos";
import { IconStar } from "./icons";

interface MetaBarProps {
  photo: Photo;
  total: number;
}

function Cell({ label, value, mono = false }: { label: string; value: string; mono?: boolean }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 1, minWidth: 0 }}>
      <div
        style={{
          fontSize: 10, color: "var(--ink-3)",
          textTransform: "uppercase", letterSpacing: "0.06em", fontWeight: 500,
        }}
      >
        {label}
      </div>
      <div
        style={{
          fontSize: 12, color: "var(--ink)", fontWeight: 500,
          fontFamily: mono ? "var(--mono)" : "var(--sans)",
          overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
        }}
      >
        {value}
      </div>
    </div>
  );
}

export function MetaBar({ photo, total }: MetaBarProps) {
  return (
    <footer
      style={{
        display: "grid",
        gridTemplateColumns: "minmax(160px,1.2fr) minmax(120px,1fr) minmax(100px,1fr) minmax(160px,1.4fr) auto",
        alignItems: "center",
        gap: 28,
        padding: "10px 18px",
        background: "var(--surface)",
        backdropFilter: "saturate(180%) blur(20px)",
        WebkitBackdropFilter: "saturate(180%) blur(20px)",
        borderTop: "1px solid var(--hairline)",
      }}
    >
      <Cell label="File"       value={photo.filename} mono />
      <Cell label="Resolution" value={`${photo.w} × ${photo.h}`} mono />
      <Cell label="Size"       value={photo.size} mono />
      <Cell label="Captured"   value={photo.date} />
      <div style={{ display: "flex", alignItems: "center", gap: 12, justifyContent: "flex-end" }}>
        <div style={{ display: "inline-flex", color: "var(--ink-2)" }}>
          {[1, 2, 3, 4, 5].map((n) => (
            <span
              key={n}
              style={{
                color: n <= photo.rating ? "#e8a900" : "var(--ink-3)",
                opacity: n <= photo.rating ? 1 : 0.35,
              }}
            >
              <IconStar size={13} filled={n <= photo.rating} />
            </span>
          ))}
        </div>
        <div style={{ width: 1, height: 16, background: "var(--hairline-strong)" }} />
        <div
          style={{
            fontSize: 11.5, color: "var(--ink-3)",
            fontFamily: "var(--mono)",
          }}
        >
          1 of {total} selected
        </div>
      </div>
    </footer>
  );
}
