import { render } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import { MetaBar } from "./MetaBar";
import { PHOTOS } from "./photos";

const photo = PHOTOS[0];

describe("MetaBar", () => {
  it("shows filename", () => {
    const { getByText } = render(<MetaBar photo={photo} total={20} />);
    expect(getByText(`${photo.id}.RAF`)).toBeInTheDocument();
  });

  it("shows resolution", () => {
    const { getByText } = render(<MetaBar photo={photo} total={20} />);
    expect(getByText(`${photo.w} × ${photo.h}`)).toBeInTheDocument();
  });

  it("shows file size", () => {
    const { getByText } = render(<MetaBar photo={photo} total={20} />);
    expect(getByText(photo.size)).toBeInTheDocument();
  });

  it("shows captured date", () => {
    const { container } = render(<MetaBar photo={photo} total={20} />);
    expect(container.textContent).toContain("Jul 18, 2025");
  });

  it("shows total count", () => {
    const { container } = render(<MetaBar photo={photo} total={20} />);
    expect(container.textContent).toContain("20");
  });
});
