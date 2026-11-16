import { describe, expect, it } from "vitest";
import { chunkForSpeech, MAX_TTS_CHARS } from "../src/lib/chunk.js";

const sentence = (n: number) => `This is sentence number ${n}, which talks about the architecture at some length.`;

describe("chunkForSpeech", () => {
  it("keeps short paragraphs together", () => {
    expect(chunkForSpeech(["One.", "Two."])).toEqual(["One.\n\nTwo."]);
  });

  it("never exceeds the limit and never splits a word", () => {
    const paragraphs = [Array.from({ length: 40 }, (_, i) => sentence(i)).join(" "), sentence(99)];
    const chunks = chunkForSpeech(paragraphs);
    expect(chunks.length).toBeGreaterThan(1);
    for (const chunk of chunks) expect(chunk.length).toBeLessThanOrEqual(MAX_TTS_CHARS);
    const words = (text: string) => text.split(/\s+/).filter(Boolean);
    expect(chunks.flatMap(words)).toEqual(paragraphs.flatMap(words));
  });

  it("falls back to word boundaries for a sentence longer than the limit", () => {
    const run = Array.from({ length: 400 }, () => "word").join(" ");
    const chunks = chunkForSpeech([run], 100);
    for (const chunk of chunks) expect(chunk.length).toBeLessThanOrEqual(100);
    expect(chunks.join(" ").split(" ")).toHaveLength(400);
  });

  it("drops empty paragraphs", () => {
    expect(chunkForSpeech(["  ", "Hello."])).toEqual(["Hello."]);
  });
});
