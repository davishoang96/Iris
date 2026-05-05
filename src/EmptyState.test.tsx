import { render, fireEvent } from "@testing-library/react";
import { describe, it, expect, vi } from "vitest";
import { EmptyState } from "./EmptyState";

describe("EmptyState", () => {
  it("renders prompt text", () => {
    const { getByText } = render(<EmptyState onOpenFolder={vi.fn()} loading={false} />);
    expect(getByText(/open a folder/i)).toBeInTheDocument();
  });

  it("renders Open Folder button", () => {
    const { getByRole } = render(<EmptyState onOpenFolder={vi.fn()} loading={false} />);
    expect(getByRole("button", { name: /open folder/i })).toBeInTheDocument();
  });

  it("calls onOpenFolder when button clicked", () => {
    const onOpenFolder = vi.fn();
    const { getByRole } = render(<EmptyState onOpenFolder={onOpenFolder} loading={false} />);
    fireEvent.click(getByRole("button", { name: /open folder/i }));
    expect(onOpenFolder).toHaveBeenCalledOnce();
  });

  it("shows loading state when loading=true", () => {
    const { getByRole } = render(<EmptyState onOpenFolder={vi.fn()} loading={true} />);
    expect(getByRole("button")).toBeDisabled();
  });
});
