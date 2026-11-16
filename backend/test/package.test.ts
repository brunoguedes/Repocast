import { readFileSync } from "node:fs";
import { Ajv2020 } from "ajv/dist/2020.js";
import addFormats from "ajv-formats";
import { describe, expect, it } from "vitest";
import schema from "../../shared/narration-manifest.schema.json" with { type: "json" };
import {
  baseName,
  cbrDurationSeconds,
  partFileName,
  playlistTitle,
  transcriptFileName,
  writePlaylist,
  type NarrationManifest,
} from "../src/lib/package.js";

describe("narration package", () => {
  const base = baseName("brunoguedes/Repocast", "architecture");
  const parts = [0, 1].map((index) => ({
    file: partFileName(base, index),
    title: `Section ${index + 1}`,
    transcript: transcriptFileName(base, index),
    durationSeconds: 61.4,
  }));

  it("names files the way NarrationImporter expects", () => {
    expect(base).toBe("Repocast_architecture");
    expect(parts[1]!.file).toBe("Repocast_architecture_part2.mp3");
    expect(parts[1]!.transcript).toBe("Repocast_architecture_part2.txt");
    expect(playlistTitle("brunoguedes/Repocast", "intro")).toBe("Repocast — Intro");
  });

  it("writes a playlist in the fixture's shape", () => {
    const playlist = writePlaylist("Repocast — Architecture", base, parts);
    expect(playlist).toBe(
      [
        "#EXTM3U",
        "#PLAYLIST:Repocast — Architecture",
        "#EXTINF:61,Section 1",
        "#EXT-TRANSCRIPT:Repocast_architecture_part1.txt",
        "Repocast_architecture_part1.mp3",
        "#EXTINF:61,Section 2",
        "#EXT-TRANSCRIPT:Repocast_architecture_part2.txt",
        "Repocast_architecture_part2.mp3",
        "",
      ].join("\n"),
    );
    // Same directives as the app's Studio-export fixture.
    const fixture = readFileSync(new URL("../../ios/Tests/Fixtures/proposal_v2/proposal_v2.m3u8", import.meta.url), "utf8");
    const directives = (text: string) => new Set(text.split("\n").map((line) => line.split(":")[0] ?? "").filter((d) => d.startsWith("#")));
    expect(directives(playlist)).toEqual(directives(fixture));
  });

  it("builds a manifest that validates against the shared schema", () => {
    const manifest: NarrationManifest = {
      schemaVersion: 1,
      repo: "brunoguedes/Repocast",
      commit: "5220ca1d0f3a5c2b6c8e9f0a1b2c3d4e5f607182",
      episodeType: "architecture",
      module: null,
      executor: "cloud",
      voice: "ElevenLabs",
      quotaMinutes: 2,
      generatedAt: new Date().toISOString(),
      parts,
    };
    const ajv = new Ajv2020({ strict: false });
    addFormats.default(ajv);
    const validate = ajv.compile(schema);
    expect(validate(manifest), JSON.stringify(validate.errors)).toBe(true);
    expect(validate({ ...manifest, executor: "server" })).toBe(false);
  });

  it("derives CBR durations from byte length", () => {
    expect(cbrDurationSeconds(16_000 * 90)).toBe(90);
  });
});
