import { describe, expect, it } from "vitest";
import { loadPrompt } from "../src/lib/prompts.js";
import { enforceCap, wordCount } from "../src/core/tour.js";

const words = (n: number) => Array.from({ length: n }, () => "word").join(" ");

describe("script word cap", () => {
  const script = {
    sections: [
      { title: "One", paragraphs: [words(600)] },
      { title: "Two", paragraphs: [words(600), words(300)] },
      { title: "Three", paragraphs: [words(600)] },
    ],
  };

  it("counts spoken words across sections", () => {
    expect(wordCount(script)).toBe(2100);
  });

  it("drops whole trailing sections to fit", () => {
    expect(enforceCap(script, 2000).sections.map((s) => s.title)).toEqual(["One", "Two"]);
    expect(enforceCap(script, 2100).sections).toHaveLength(3);
  });

  it("always keeps the first section", () => {
    expect(enforceCap(script, 10).sections.map((s) => s.title)).toEqual(["One"]);
  });
});

describe("shared prompts", () => {
  it("fill every placeholder", () => {
    for (const name of ["index-summary", "intro", "architecture"] as const) {
      const text = loadPrompt(name, { repo: "o/r", classification: "codebase", maxWords: 2000, summary: "S" });
      expect(text).not.toMatch(/\{\{\w+\}\}/);
    }
  });
});
