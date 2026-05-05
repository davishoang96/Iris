import { render, act } from "@testing-library/react";
import { describe, it, expect, beforeEach } from "vitest";
import { ThemeProvider, useTheme, type Theme } from "./theme";

describe("ThemeProvider", () => {
  beforeEach(() => {
    document.documentElement.removeAttribute("data-theme");
  });

  it("sets data-theme on html element", () => {
    render(<ThemeProvider initial="light"><div /></ThemeProvider>);
    expect(document.documentElement).toHaveAttribute("data-theme", "light");
  });

  it("defaults to light theme", () => {
    render(<ThemeProvider><div /></ThemeProvider>);
    expect(document.documentElement).toHaveAttribute("data-theme", "light");
  });

  it("updates data-theme when theme changes", () => {
    let changeTheme: (t: Theme) => void = () => {};

    function Consumer() {
      const { setTheme } = useTheme();
      changeTheme = setTheme;
      return null;
    }

    render(<ThemeProvider initial="light"><Consumer /></ThemeProvider>);
    expect(document.documentElement).toHaveAttribute("data-theme", "light");

    act(() => changeTheme("dark"));
    expect(document.documentElement).toHaveAttribute("data-theme", "dark");

    act(() => changeTheme("dim"));
    expect(document.documentElement).toHaveAttribute("data-theme", "dim");
  });
});
