import { IconFolder } from "./icons";

interface EmptyStateProps {
  onOpenFolder: () => void;
  loading: boolean;
}

export function EmptyState({ onOpenFolder, loading }: EmptyStateProps) {
  return (
    <div
      style={{
        width: "100vw",
        height: "100vh",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        background: "var(--bg)",
        gap: 20,
      }}
    >
      <IconFolder size={48} style={{ color: "var(--ink-3)", opacity: 0.4 }} />
      <div
        style={{
          fontSize: 16,
          color: "var(--ink-2)",
          fontWeight: 500,
          letterSpacing: "-0.01em",
        }}
      >
        Open a folder to browse your photos
      </div>
      <button
        onClick={onOpenFolder}
        disabled={loading}
        style={{
          height: 36,
          padding: "0 20px",
          borderRadius: 8,
          border: "1px solid var(--hairline-strong)",
          background: "var(--surface)",
          color: "var(--ink)",
          fontSize: 13,
          fontWeight: 500,
          cursor: loading ? "default" : "pointer",
          opacity: loading ? 0.5 : 1,
          fontFamily: "var(--sans)",
        }}
      >
        {loading ? "Loading…" : "Open Folder"}
      </button>
    </div>
  );
}
