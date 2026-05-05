import { render } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import { ViewerShell } from "./layout";

describe("ViewerShell", () => {
  it("renders grid container", () => {
    const { container } = render(
      <ViewerShell
        toolbar={<div data-testid="toolbar" />}
        stage={<div data-testid="stage" />}
        filmstrip={<div data-testid="filmstrip" />}
        metabar={<div data-testid="metabar" />}
      />
    );
    expect(container.querySelector("[data-testid='toolbar']")).toBeInTheDocument();
    expect(container.querySelector("[data-testid='stage']")).toBeInTheDocument();
    expect(container.querySelector("[data-testid='filmstrip']")).toBeInTheDocument();
    expect(container.querySelector("[data-testid='metabar']")).toBeInTheDocument();
  });

  it("renders info panel slot when provided", () => {
    const { container } = render(
      <ViewerShell
        toolbar={<div />}
        stage={<div />}
        filmstrip={<div />}
        metabar={<div />}
        infoPanel={<div data-testid="info" />}
      />
    );
    expect(container.querySelector("[data-testid='info']")).toBeInTheDocument();
  });

  it("omits info panel slot when not provided", () => {
    const { container } = render(
      <ViewerShell
        toolbar={<div />}
        stage={<div />}
        filmstrip={<div />}
        metabar={<div />}
      />
    );
    expect(container.querySelector("[data-testid='info']")).not.toBeInTheDocument();
  });
});
