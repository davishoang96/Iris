import React, { useRef, useEffect } from "react";
import type { Photo } from "./photos";

interface FilmstripProps {
  photos: Photo[];
  index: number;
  onSelect: (i: number) => void;
}

export function Filmstrip({ photos, index, onSelect }: FilmstripProps) {
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = scrollRef.current?.querySelector<HTMLElement>(`[data-idx="${index}"]`);
    if (!el || !scrollRef.current) return;
    const parent = scrollRef.current;
    const er = el.getBoundingClientRect();
    const pr = parent.getBoundingClientRect();
    if (er.left < pr.left + 24 || er.right > pr.right - 24) {
      parent.scrollTo?.({
        left: el.offsetLeft - parent.clientWidth / 2 + el.clientWidth / 2,
        behavior: "smooth",
      });
    }
  }, [index]);

  return (
    <div
      style={{
        borderTop: "1px solid var(--hairline)",
        borderBottom: "1px solid var(--hairline)",
        background: "var(--surface)",
        backdropFilter: "saturate(180%) blur(20px)",
        WebkitBackdropFilter: "saturate(180%) blur(20px)",
        padding: "10px 14px 12px",
      }}
    >
      <div
        ref={scrollRef}
        style={{
          display: "flex",
          gap: 4,
          overflowX: "auto",
          overflowY: "hidden",
          scrollbarWidth: "none",
          msOverflowStyle: "none" as unknown as undefined,
          paddingBottom: 2,
        }}
      >
        {photos.map((p, i) => {
          const selected = i === index;
          return (
            <button
              key={p.id}
              data-idx={i}
              onClick={() => onSelect(i)}
              title={`${p.id} — ${p.title}`}
              style={{
                flex: "0 0 auto",
                width: 64, height: 64,
                padding: 0, border: 0, cursor: "pointer",
                position: "relative",
                borderRadius: 4,
                background: "transparent",
                outline: selected
                  ? "2px solid var(--ink)"
                  : "1px solid var(--hairline-strong)",
                outlineOffset: selected ? 1 : 0,
                transform: selected ? "translateY(-2px)" : "none",
                transition: "transform .15s ease, outline-color .12s ease",
              }}
            >
              <img
                src={p.thumb}
                alt=""
                draggable={false}
                style={{
                  width: "100%", height: "100%",
                  objectFit: "cover", display: "block",
                  borderRadius: 3,
                  opacity: selected ? 1 : 0.85,
                }}
              />
              {p.rating >= 5 && (
                <span
                  style={{
                    position: "absolute", top: 4, right: 4,
                    width: 6, height: 6, borderRadius: 99,
                    background: "#ffcc33",
                    boxShadow: "0 0 0 1px #00000033",
                  }}
                />
              )}
              <span
                style={{
                  position: "absolute", bottom: 3, left: 4,
                  fontFamily: "var(--mono)", fontSize: 9, color: "#fff",
                  textShadow: "0 1px 2px #000a", letterSpacing: 0,
                  opacity: selected ? 1 : 0.7,
                }}
              >
                {String(i + 1).padStart(2, "0")}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
