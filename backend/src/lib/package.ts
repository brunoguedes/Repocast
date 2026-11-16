import type { EpisodeType } from "./types.js";

/**
 * Narration package layout — the contract `NarrationImporter` in the app
 * already accepts (see shared/narration-manifest.schema.json and the root
 * CLAUDE.md). Never emit a stitched `<base>.mp3`: it would hide the parts.
 */
export interface PackagePart {
  file: string;
  title: string;
  transcript: string;
  durationSeconds: number;
}

export interface NarrationManifest {
  schemaVersion: 1;
  repo: string;
  commit: string;
  episodeType: EpisodeType;
  module: string | null;
  executor: "cloud" | "device";
  voice: string | null;
  quotaMinutes: number;
  generatedAt: string;
  parts: PackagePart[];
}

const EPISODE_LABEL: Record<EpisodeType, string> = {
  intro: "Intro",
  architecture: "Architecture",
};

/** `Repocast_architecture` — file-system safe, unique per repo and episode. */
export function baseName(repo: string, type: EpisodeType): string {
  const name = repo.split("/")[1] ?? repo;
  return `${name.replace(/[^A-Za-z0-9._-]/g, "_")}_${type}`;
}

export function playlistTitle(repo: string, type: EpisodeType): string {
  return `${repo.split("/")[1] ?? repo} — ${EPISODE_LABEL[type]}`;
}

export function partFileName(base: string, index: number, ext = "mp3"): string {
  return `${base}_part${index + 1}.${ext}`;
}

export function transcriptFileName(base: string, index: number): string {
  return `${base}_part${index + 1}.txt`;
}

/** `<base>.m3u8` with titles, durations and the `#EXT-TRANSCRIPT` extension. */
export function writePlaylist(title: string, base: string, parts: PackagePart[]): string {
  const lines = ["#EXTM3U", `#PLAYLIST:${title}`];
  parts.forEach((part, index) => {
    lines.push(`#EXTINF:${Math.round(part.durationSeconds)},${part.title}`);
    lines.push(`#EXT-TRANSCRIPT:${transcriptFileName(base, index)}`);
    lines.push(part.file);
  });
  return `${lines.join("\n")}\n`;
}

/**
 * Duration of a constant-bitrate MP3. ElevenLabs' `mp3_44100_128` output is
 * CBR at 128 kbps, i.e. 16,000 bytes per second.
 */
export function cbrDurationSeconds(byteLength: number, kbps = 128): number {
  return byteLength / ((kbps * 1000) / 8);
}
