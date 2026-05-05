import { render } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import {
  IconRotateLeft, IconRotateRight, IconFlipH, IconFlipV,
  IconCrop, IconStraighten, IconFit, IconOneToOne, IconFill,
  IconZoomOut, IconZoomIn, IconShare, IconInfo, IconSlideshow,
  IconChevron, IconFolder, IconStar, IconSearch,
} from "./icons";

describe("icons", () => {
  it("renders SVG with correct viewBox", () => {
    const { container } = render(<IconRotateLeft />);
    const svg = container.querySelector("svg");
    expect(svg).toBeInTheDocument();
    expect(svg).toHaveAttribute("viewBox", "0 0 20 20");
  });

  it("accepts size prop", () => {
    const { container } = render(<IconZoomIn size={24} />);
    const svg = container.querySelector("svg");
    expect(svg).toHaveAttribute("width", "24");
    expect(svg).toHaveAttribute("height", "24");
  });

  it("defaults to size 18", () => {
    const { container } = render(<IconInfo />);
    const svg = container.querySelector("svg");
    expect(svg).toHaveAttribute("width", "18");
  });

  it("renders all 18 icons without throwing", () => {
    const icons = [
      IconRotateLeft, IconRotateRight, IconFlipH, IconFlipV,
      IconCrop, IconStraighten, IconFit, IconOneToOne, IconFill,
      IconZoomOut, IconZoomIn, IconShare, IconInfo, IconSlideshow,
      IconChevron, IconFolder, IconStar, IconSearch,
    ];
    for (const Icon of icons) {
      const { container } = render(<Icon />);
      expect(container.querySelector("svg")).toBeInTheDocument();
    }
  });

  it("IconStar renders filled path when filled=true", () => {
    const { container: filled } = render(<IconStar filled />);
    const { container: empty } = render(<IconStar />);
    const filledPath = filled.querySelector("path");
    const emptyPath = empty.querySelector("path");
    expect(filledPath?.getAttribute("fill")).toBe("currentColor");
    expect(emptyPath?.getAttribute("fill")).toBe("none");
  });

  it("IconChevron accepts style prop for rotation", () => {
    const { container } = render(<IconChevron style={{ transform: "rotate(180deg)" }} />);
    const svg = container.querySelector("svg");
    expect(svg).toHaveStyle({ transform: "rotate(180deg)" });
  });
});
