import { useState, useEffect } from "react";
import "./App.css";
import { ThemeProvider } from "./theme";
import { ViewerShell } from "./layout";
import { PHOTOS } from "./photos";
import { Toolbar, type ZoomMode } from "./Toolbar";
import { Stage, type BgTone } from "./Stage";
import { Filmstrip } from "./Filmstrip";
import { MetaBar } from "./MetaBar";
import { InfoPanel } from "./InfoPanel";

function Slideshow({ src, onClose }: { src: string; onClose: () => void }) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  return (
    <div
      onClick={onClose}
      style={{
        position: "fixed", inset: 0, background: "#000",
        display: "flex", alignItems: "center", justifyContent: "center",
        zIndex: 99, cursor: "pointer",
      }}
    >
      <img
        src={src}
        alt=""
        style={{
          maxWidth: "94vw", maxHeight: "94vh",
          objectFit: "contain",
          boxShadow: "0 40px 100px -20px #000",
        }}
      />
      <div
        style={{
          position: "absolute", bottom: 28, left: 0, right: 0,
          textAlign: "center", color: "#aaa",
          fontSize: 12, fontFamily: "var(--mono)",
        }}
      >
        click anywhere or press Esc to exit
      </div>
    </div>
  );
}

function Viewer() {
  const [index, setIndex]         = useState(0);
  const [rotation, setRotation]   = useState(0);
  const [flip, setFlip]           = useState({ h: false, v: false });
  const [zoomMode, setZoomMode]   = useState<ZoomMode>("fit");
  const [zoom, setZoom]           = useState(1);
  const [slideshow, setSlideshow] = useState(false);
  const [infoOpen, setInfoOpen]   = useState(false);
  const [bgTone] = useState<BgTone>("charcoal");

  const photo = PHOTOS[index];

  useEffect(() => {
    setRotation(0);
    setFlip({ h: false, v: false });
    setZoom(1);
  }, [index]);

  const navigate = (delta: number) =>
    setIndex((i) => (i + delta + PHOTOS.length) % PHOTOS.length);

  const nudgeZoom = (delta: number) =>
    setZoom((z) => Math.min(4, Math.max(0.2, +(z + delta).toFixed(2))));

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (slideshow) return;
      switch (e.key) {
        case "ArrowLeft":  navigate(-1); break;
        case "ArrowRight": navigate(+1); break;
        case "+": case "=": nudgeZoom(+0.1); break;
        case "-": nudgeZoom(-0.1); break;
        case "f": case "F": setZoomMode("fit"); setZoom(1); break;
        case "1": setZoomMode("100"); setZoom(1); break;
        case "i": case "I": setInfoOpen((v) => !v); break;
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [slideshow]);

  return (
    <>
      <ViewerShell
        toolbar={
          <Toolbar
            photo={photo}
            index={index}
            total={PHOTOS.length}
            onPrev={() => navigate(-1)}
            onNext={() => navigate(+1)}
            onRotate={(d) => setRotation((r) => r + d)}
            onFlipH={() => setFlip((f) => ({ ...f, h: !f.h }))}
            onFlipV={() => setFlip((f) => ({ ...f, v: !f.v }))}
            zoom={zoom}
            onZoomIn={() => nudgeZoom(+0.1)}
            onZoomOut={() => nudgeZoom(-0.1)}
            zoomMode={zoomMode}
            setZoomMode={(m) => { setZoomMode(m); setZoom(1); }}
            onSlideshow={() => setSlideshow(true)}
            infoOpen={infoOpen}
            onToggleInfo={() => setInfoOpen((v) => !v)}
          />
        }
        stage={
          <Stage
            photo={photo}
            rotation={rotation}
            flip={flip}
            zoom={zoom}
            zoomMode={zoomMode}
            bgTone={bgTone}
          />
        }
        filmstrip={
          <Filmstrip
            photos={PHOTOS}
            index={index}
            onSelect={(i) => setIndex(i)}
          />
        }
        metabar={<MetaBar photo={photo} total={PHOTOS.length} />}
        infoPanel={infoOpen ? <InfoPanel photo={photo} /> : undefined}
      />
      {slideshow && (
        <Slideshow src={photo.full} onClose={() => setSlideshow(false)} />
      )}
    </>
  );
}

export default function App() {
  return (
    <ThemeProvider initial="dark">
      <Viewer />
    </ThemeProvider>
  );
}
