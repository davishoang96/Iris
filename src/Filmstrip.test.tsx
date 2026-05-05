import { render, fireEvent } from "@testing-library/react";
import { describe, it, expect, vi } from "vitest";
import { Filmstrip } from "./Filmstrip";
import { PHOTOS } from "./photos";

describe("Filmstrip", () => {
  it("renders a button for each photo", () => {
    const { container } = render(
      <Filmstrip photos={PHOTOS} index={0} onSelect={vi.fn()} />
    );
    expect(container.querySelectorAll("button")).toHaveLength(PHOTOS.length);
  });

  it("renders thumbs with correct src", () => {
    const { container } = render(
      <Filmstrip photos={PHOTOS} index={0} onSelect={vi.fn()} />
    );
    const imgs = container.querySelectorAll("img");
    expect(imgs[0]).toHaveAttribute("src", PHOTOS[0].thumb);
    expect(imgs[1]).toHaveAttribute("src", PHOTOS[1].thumb);
  });

  it("calls onSelect with index when thumb clicked", () => {
    const onSelect = vi.fn();
    const { container } = render(
      <Filmstrip photos={PHOTOS} index={0} onSelect={onSelect} />
    );
    const buttons = container.querySelectorAll("button");
    fireEvent.click(buttons[3]);
    expect(onSelect).toHaveBeenCalledWith(3);
  });

  it("applies selected lift to active thumb", () => {
    const { container } = render(
      <Filmstrip photos={PHOTOS} index={2} onSelect={vi.fn()} />
    );
    const buttons = container.querySelectorAll("button");
    expect((buttons[2] as HTMLElement).style.transform).toContain("translateY(-2px)");
    expect((buttons[0] as HTMLElement).style.transform).not.toContain("translateY(-2px)");
  });

  it("shows sequence numbers", () => {
    const { container } = render(
      <Filmstrip photos={PHOTOS} index={0} onSelect={vi.fn()} />
    );
    expect(container.textContent).toContain("01");
    expect(container.textContent).toContain("02");
  });
});
