import React, { useState } from "react";
import type { Photo } from "./photos";
import {
  IconFolder, IconChevron,
  IconRotateLeft, IconRotateRight, IconFlipH, IconFlipV,
  IconCrop, IconStraighten,
  IconZoomOut, IconZoomIn, IconFit, IconOneToOne, IconFill,
  IconSlideshow, IconShare, IconInfo,
} from "./icons";

export type ZoomMode = "fit" | "fill" | "100";

interface ToolbarProps {
  photo: Photo;
  index: number;
  total: number;
  folderLabel?: string;
  onOpenFolder?: () => void;
  onPrev: () => void;
  onNext: () => void;
  onRotate: (deg: number) => void;
  onFlipH: () => void;
  onFlipV: () => void;
  zoom: number;
  onZoomIn: () => void;
  onZoomOut: () => void;
  zoomMode: ZoomMode;
  setZoomMode: (mode: ZoomMode) => void;
  onSlideshow: () => void;
  infoOpen: boolean;
  onToggleInfo: () => void;
}

const btnBase: React.CSSProperties = {
  height: 32, minWidth: 32, padding: "0 8px",
  display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 6,
  background: "transparent", border: 0, borderRadius: 8,
  color: "var(--ink)", cursor: "pointer",
};

function TBButton({
  icon: Icon,
  label,
  title,
  active = false,
  onClick,
}: {
  icon?: React.ComponentType<{ size?: number; style?: React.CSSProperties }>;
  label?: string;
  title: string;
  active?: boolean;
  onClick?: () => void;
}) {
  const [hover, setHover] = useState(false);
  return (
    <button
      title={title}
      onClick={onClick}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        ...btnBase,
        background: active
          ? "var(--hairline-strong)"
          : hover
          ? "var(--hairline)"
          : "transparent",
        transition: "background .12s ease",
      }}
    >
      {Icon && <Icon size={17} />}
      {label && (
        <span style={{ fontSize: 12.5, fontWeight: 500, letterSpacing: "-0.005em" }}>
          {label}
        </span>
      )}
    </button>
  );
}

function Divider() {
  return (
    <div
      style={{
        width: 1, height: 18,
        background: "var(--hairline-strong)",
        margin: "0 6px",
      }}
    />
  );
}

export function Toolbar({
  photo, index, total,
  folderLabel = "Iceland & Faroes",
  onOpenFolder,
  onPrev, onNext,
  onRotate, onFlipH, onFlipV,
  zoom, onZoomIn, onZoomOut, zoomMode, setZoomMode,
  onSlideshow, infoOpen, onToggleInfo,
}: ToolbarProps) {
  return (
    <header
      style={{
        display: "grid",
        gridTemplateColumns: "1fr auto 1fr",
        alignItems: "center",
        padding: "10px 14px",
        borderBottom: "1px solid var(--hairline)",
        background: "var(--surface)",
        backdropFilter: "saturate(180%) blur(20px)",
        WebkitBackdropFilter: "saturate(180%) blur(20px)",
      }}
    >
      {/* Left */}
      <div style={{ display: "flex", alignItems: "center", gap: 10, minWidth: 0 }}>
        <button
          onClick={onOpenFolder}
          title="Open folder"
          style={{
            ...btnBase,
            display: "flex", alignItems: "center", gap: 6,
            color: "var(--ink-2)", fontSize: 12.5, minWidth: 0,
            padding: "0 6px",
            cursor: onOpenFolder ? "pointer" : "default",
          }}
        >
          <IconFolder size={15} />
          <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
            <span style={{ color: "var(--ink)", fontWeight: 500 }}>{folderLabel}</span>
          </span>
        </button>
        <Divider />
        <div style={{ display: "flex", alignItems: "center" }}>
          <TBButton
            icon={(p) => <IconChevron {...p} style={{ transform: "rotate(180deg)" }} />}
            title="Previous"
            onClick={onPrev}
          />
          <TBButton icon={IconChevron} title="Next" onClick={onNext} />
        </div>
        <div
          style={{
            fontSize: 12.5, color: "var(--ink-3)",
            fontVariantNumeric: "tabular-nums",
          }}
        >
          {index + 1}{" "}
          <span style={{ color: "var(--ink-3)", opacity: 0.6 }}>/</span>{" "}
          {total}
        </div>
      </div>

      {/* Center */}
      <div
        style={{
          display: "flex", flexDirection: "column",
          alignItems: "center", gap: 1, minWidth: 0,
        }}
      >
        <div
          style={{
            fontSize: 13, fontWeight: 600,
            letterSpacing: "-0.01em", whiteSpace: "nowrap",
          }}
        >
          {photo.title}
        </div>
        <div
          style={{
            fontSize: 11, color: "var(--ink-3)",
            fontFamily: "var(--mono)", letterSpacing: 0,
          }}
        >
          {photo.filename}
        </div>
      </div>

      {/* Right */}
      <div
        style={{
          display: "flex", alignItems: "center",
          justifyContent: "flex-end", gap: 0,
        }}
      >
        <TBButton icon={IconRotateLeft}  title="Rotate left"       onClick={() => onRotate(-90)} />
        <TBButton icon={IconRotateRight} title="Rotate right"      onClick={() => onRotate(+90)} />
        <TBButton icon={IconFlipH}       title="Flip horizontal"   onClick={onFlipH} />
        <TBButton icon={IconFlipV}       title="Flip vertical"     onClick={onFlipV} />
        <Divider />
        <TBButton icon={IconCrop}       title="Crop" />
        <TBButton icon={IconStraighten} title="Straighten" />
        <Divider />
        <TBButton icon={IconZoomOut} title="Zoom out" onClick={onZoomOut} />
        <div
          style={{
            fontSize: 11.5, color: "var(--ink-2)",
            fontFamily: "var(--mono)", minWidth: 44,
            textAlign: "center", fontVariantNumeric: "tabular-nums",
          }}
        >
          {Math.round(zoom * 100)}%
        </div>
        <TBButton icon={IconZoomIn}  title="Zoom in"      onClick={onZoomIn} />
        <TBButton icon={IconFit}     title="Fit to window (F)" active={zoomMode === "fit"}  onClick={() => setZoomMode("fit")} />
        <TBButton icon={IconOneToOne} title="Actual size (1)"  active={zoomMode === "100"} onClick={() => setZoomMode("100")} />
        <TBButton icon={IconFill}    title="Fill"              active={zoomMode === "fill"} onClick={() => setZoomMode("fill")} />
        <Divider />
        <TBButton icon={IconSlideshow} title="Slideshow"          onClick={onSlideshow} />
        <TBButton icon={IconShare}     title="Share / Export" />
        <TBButton icon={IconInfo}      title="Toggle Info panel (I)" active={infoOpen} onClick={onToggleInfo} />
      </div>
    </header>
  );
}
