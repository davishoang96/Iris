import React, { useRef, useState, useEffect } from "react";
import type { Photo } from "./photos";
import type { ZoomMode } from "./Toolbar";

export type BgTone = "charcoal" | "black" | "paper" | "checker";

interface StageProps {
  photo: Photo;
  rotation: number;
  flip: { h: boolean; v: boolean };
  zoom: number;
  zoomMode: ZoomMode;
  bgTone: BgTone;
}

export function Stage({ photo, rotation, flip, zoom, zoomMode, bgTone }: StageProps) {
  const wrapRef = useRef<HTMLDivElement>(null);
  const [box, setBox] = useState({ w: 0, h: 0 });

  useEffect(() => {
    const el = wrapRef.current;
    if (!el) return;
    const ro = new ResizeObserver(() => {
      const r = el.getBoundingClientRect();
      setBox({ w: r.width, h: r.height });
    });
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  const rotated = (rotation / 90) % 2 !== 0;
  const aspect = rotated ? photo.h / photo.w : photo.w / photo.h;

  let fitW = box.w, fitH = box.w / aspect;
  if (fitH > box.h) { fitH = box.h; fitW = box.h * aspect; }

  let fillW = box.w, fillH = box.w / aspect;
  if (fillH < box.h) { fillH = box.h; fillW = box.h * aspect; }

  let baseW: number, baseH: number;
  if (zoomMode === "fill") {
    baseW = fillW; baseH = fillH;
  } else if (zoomMode === "100") {
    baseW = Math.min(rotated ? photo.h : photo.w, 2000);
    baseH = baseW / aspect;
  } else {
    baseW = fitW; baseH = fitH;
  }

  const finalW = baseW * zoom;
  const finalH = baseH * zoom;

  const bgFill =
    bgTone === "black" ? "#050507"
    : bgTone === "paper" ? "var(--bg)"
    : "var(--canvas)";

  const checkerProps: React.CSSProperties =
    bgTone === "checker"
      ? {
          backgroundImage:
            "linear-gradient(45deg,#2a2a2e 25%,transparent 25%)," +
            "linear-gradient(-45deg,#2a2a2e 25%,transparent 25%)," +
            "linear-gradient(45deg,transparent 75%,#2a2a2e 75%)," +
            "linear-gradient(-45deg,transparent 75%,#2a2a2e 75%)",
          backgroundSize: "20px 20px",
          backgroundPosition: "0 0,0 10px,10px -10px,-10px 0",
        }
      : {};

  return (
    <div
      ref={wrapRef}
      style={{
        position: "relative",
        overflow: "hidden",
        height: "100%",
        width: "100%",
        background: bgFill,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        ...checkerProps,
      }}
    >
      <div
        style={{
          width: finalW || undefined,
          height: finalH || undefined,
          transition: "width .2s ease, height .2s ease",
          position: "relative",
          boxShadow: "0 30px 80px -30px #00000088, 0 2px 0 #ffffff04 inset",
        }}
      >
        <img
          src={photo.full}
          alt=""
          draggable={false}
          style={{
            width: "100%",
            height: "100%",
            display: "block",
            objectFit: "cover",
            transform: `rotate(${rotation}deg) scale(${flip.h ? -1 : 1},${flip.v ? -1 : 1})`,
            transformOrigin: "center",
            transition: "transform .35s cubic-bezier(.2,.8,.2,1)",
            userSelect: "none",
          }}
        />
      </div>

      <div
        style={{
          position: "absolute", top: 12, right: 12,
          padding: "4px 8px", borderRadius: 6,
          background: "#0008", color: "#f1f0ec",
          fontFamily: "var(--mono)", fontSize: 11,
          opacity: 0.55,
        }}
      >
        {photo.w} × {photo.h}
      </div>
    </div>
  );
}
