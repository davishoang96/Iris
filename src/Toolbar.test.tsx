import { render, fireEvent } from "@testing-library/react";
import { describe, it, expect, vi } from "vitest";
import { Toolbar } from "./Toolbar";
import { PHOTOS } from "./photos";

const photo = PHOTOS[0];

const defaults = {
  photo,
  index: 0,
  total: 20,
  onPrev: vi.fn(),
  onNext: vi.fn(),
  onRotate: vi.fn(),
  onFlipH: vi.fn(),
  onFlipV: vi.fn(),
  zoom: 1,
  onZoomIn: vi.fn(),
  onZoomOut: vi.fn(),
  zoomMode: "fit" as const,
  setZoomMode: vi.fn(),
  onSlideshow: vi.fn(),
  infoOpen: false,
  onToggleInfo: vi.fn(),
};

describe("Toolbar", () => {
  it("shows photo title", () => {
    const { getByText } = render(<Toolbar {...defaults} />);
    expect(getByText(photo.title)).toBeInTheDocument();
  });

  it("shows filename", () => {
    const { getByText } = render(<Toolbar {...defaults} />);
    expect(getByText(`${photo.id}.RAF`)).toBeInTheDocument();
  });

  it("shows counter as index+1 and total", () => {
    const { container } = render(<Toolbar {...defaults} index={2} total={20} />);
    expect(container.textContent).toContain("3");
    expect(container.textContent).toContain("20");
  });

  it("shows zoom percentage", () => {
    const { getByText } = render(<Toolbar {...defaults} zoom={1.5} />);
    expect(getByText("150%")).toBeInTheDocument();
  });

  it("calls onPrev when prev button clicked", () => {
    const onPrev = vi.fn();
    const { getByTitle } = render(<Toolbar {...defaults} onPrev={onPrev} />);
    fireEvent.click(getByTitle(/previous/i));
    expect(onPrev).toHaveBeenCalledOnce();
  });

  it("calls onNext when next button clicked", () => {
    const onNext = vi.fn();
    const { getByTitle } = render(<Toolbar {...defaults} onNext={onNext} />);
    fireEvent.click(getByTitle(/next/i));
    expect(onNext).toHaveBeenCalledOnce();
  });

  it("calls onToggleInfo when info button clicked", () => {
    const onToggleInfo = vi.fn();
    const { getByTitle } = render(<Toolbar {...defaults} onToggleInfo={onToggleInfo} />);
    fireEvent.click(getByTitle(/info/i));
    expect(onToggleInfo).toHaveBeenCalledOnce();
  });
});
