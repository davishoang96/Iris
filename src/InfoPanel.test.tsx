import { render } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import { InfoPanel } from "./InfoPanel";
import { PHOTOS } from "./photos";

const photo = PHOTOS[0];

describe("InfoPanel", () => {
  it("renders title and location", () => {
    const { getByText } = render(<InfoPanel photo={photo} />);
    expect(getByText(photo.title)).toBeInTheDocument();
    expect(getByText(photo.location)).toBeInTheDocument();
  });

  it("renders camera section", () => {
    const { getByText } = render(<InfoPanel photo={photo} />);
    expect(getByText(photo.camera)).toBeInTheDocument();
    expect(getByText(photo.lens)).toBeInTheDocument();
    expect(getByText(photo.focal)).toBeInTheDocument();
    expect(getByText(photo.aperture)).toBeInTheDocument();
    expect(getByText(photo.shutter)).toBeInTheDocument();
    expect(getByText(String(photo.iso))).toBeInTheDocument();
  });

  it("renders file section", () => {
    const { getByText } = render(<InfoPanel photo={photo} />);
    expect(getByText(`${photo.id}.RAF`)).toBeInTheDocument();
    expect(getByText(`${photo.w} × ${photo.h}`)).toBeInTheDocument();
    expect(getByText(photo.size)).toBeInTheDocument();
    expect(getByText(photo.profile)).toBeInTheDocument();
  });

  it("renders GPS coords", () => {
    const { getAllByText } = render(<InfoPanel photo={photo} />);
    expect(getAllByText(photo.gps).length).toBeGreaterThanOrEqual(1);
  });

  it("renders histogram SVG", () => {
    const { container } = render(<InfoPanel photo={photo} />);
    expect(container.querySelector("svg")).toBeInTheDocument();
  });
});
