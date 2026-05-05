import { render } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import { Stage } from "./Stage";
import { PHOTOS } from "./photos";

const photo = PHOTOS[0];

const defaults = {
  photo,
  rotation: 0,
  flip: { h: false, v: false },
  zoom: 1,
  zoomMode: "fit" as const,
  bgTone: "charcoal" as const,
};

describe("Stage", () => {
  it("renders img with photo.full src", () => {
    const { container } = render(<Stage {...defaults} />);
    const img = container.querySelector("img");
    expect(img).toBeInTheDocument();
    expect(img?.src).toBe(photo.full);
  });

  it("renders resolution overlay", () => {
    const { getByText } = render(<Stage {...defaults} />);
    expect(getByText(`${photo.w} × ${photo.h}`)).toBeInTheDocument();
  });
});
