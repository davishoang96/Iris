import React from "react";

interface ViewerShellProps {
  toolbar: React.ReactNode;
  stage: React.ReactNode;
  filmstrip: React.ReactNode;
  metabar: React.ReactNode;
  infoPanel?: React.ReactNode;
}

export function ViewerShell({ toolbar, stage, filmstrip, metabar, infoPanel }: ViewerShellProps) {
  const hasPanel = !!infoPanel;

  return (
    <div
      style={{
        display: "grid",
        width: "100vw",
        height: "100vh",
        gridTemplateColumns: hasPanel ? "minmax(0,1fr) minmax(0,320px)" : "minmax(0,1fr)",
        gridTemplateRows: "auto 1fr auto auto",
        gridTemplateAreas: hasPanel
          ? `"top top" "stage panel" "strip panel" "bottom panel"`
          : `"top" "stage" "strip" "bottom"`,
        transition: "grid-template-columns .25s ease",
      }}
    >
      <div style={{ gridArea: "top" }}>{toolbar}</div>
      <div style={{ gridArea: "stage" }}>{stage}</div>
      <div style={{ gridArea: "strip" }}>{filmstrip}</div>
      <div style={{ gridArea: "bottom" }}>{metabar}</div>
      {hasPanel && <div style={{ gridArea: "panel" }}>{infoPanel}</div>}
    </div>
  );
}
