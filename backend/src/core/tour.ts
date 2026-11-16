import { chunkForSpeech } from "../lib/chunk.js";
import { classify } from "../lib/classify.js";
import { concatAudio, type ElevenLabsClient } from "../lib/elevenlabs.js";
import type { GitHubClient } from "../lib/github.js";
import { fileSections, MAX_KEY_FILES, readmeSection, section, treeListing } from "../lib/material.js";
import { FileSelectionSchema, generate, IndexSummarySchema, ScriptSchema } from "../lib/model.js";
import {
  baseName,
  cbrDurationSeconds,
  partFileName,
  playlistTitle,
  transcriptFileName,
  writePlaylist,
  type NarrationManifest,
  type PackagePart,
} from "../lib/package.js";
import { loadPrompt } from "../lib/prompts.js";
import { roundMinutes } from "../lib/quota.js";
import {
  EPISODE_WORD_CAP,
  estimatedMinutes,
  type EpisodeType,
  type PlannedEpisode,
  type Script,
  type TourIndex,
} from "../lib/types.js";

/**
 * The tour pipeline with no AWS in it: GitHub in, Claude on Bedrock and
 * ElevenLabs in the middle, narration-package files out. The Lambda steps
 * wrap these with DynamoDB and S3; `src/local/run.ts` wraps them with the
 * file system.
 */

/** Index: tree, README and manifests → classification, summary, episode plan. */
export async function indexRepo(github: GitHubClient, repo: string, commit: string, branch: string): Promise<TourIndex> {
  const [{ files }, readme] = await Promise.all([github.tree(repo, commit), github.readme(repo, commit)]);
  const { classification, manifests, entryPoints } = classify(files.map((file) => file.path));

  const material = [
    readmeSection(readme),
    section("File tree", treeListing(files)),
    await fileSections(github, repo, commit, manifests.slice(0, 5)),
  ].join("\n");
  const summary = await generate({
    instructions: loadPrompt("index-summary", { repo, classification }),
    material,
    schema: IndexSummarySchema,
    effort: "low",
    maxTokens: 4000,
  });

  // Documents-only repos have no architecture to tell in this slice.
  const episodes: PlannedEpisode[] = [
    { type: "intro", title: summary.introTitle, estimatedMinutes: estimatedMinutes("intro") },
  ];
  if (classification !== "documents") {
    episodes.push({
      type: "architecture",
      title: summary.architectureTitle,
      estimatedMinutes: estimatedMinutes("architecture"),
    });
  }
  return { repo, commit, branch, status: "ready", classification, summary: summary.summary, episodes, manifests, entryPoints };
}

export function wordCount(script: Script): number {
  return script.sections
    .flatMap((s) => s.paragraphs)
    .join(" ")
    .split(/\s+/)
    .filter(Boolean).length;
}

/**
 * Keeps the script within the hard word cap by dropping whole trailing
 * sections, never cutting mid-thought. Always keeps the first section.
 */
export function enforceCap(script: Script, cap: number): Script {
  const sections = [...script.sections];
  while (sections.length > 1 && wordCount({ sections }) > cap) sections.pop();
  return { sections };
}

export interface ScriptResult {
  script: Script;
  /** Files the architecture episode was built from (empty for the intro). */
  keyFiles: string[];
}

/** Script: one model call per episode (plus a file pick for architecture), under the word cap. */
export async function writeScript(github: GitHubClient, index: TourIndex, type: EpisodeType): Promise<ScriptResult> {
  const { repo, commit } = index;
  const [{ files }, readme] = await Promise.all([github.tree(repo, commit), github.readme(repo, commit)]);
  const manifests = await fileSections(github, repo, commit, (index.manifests ?? []).slice(0, 5));
  const maxWords = EPISODE_WORD_CAP[type];

  let material: string;
  let keyFiles: string[] = [];
  if (type === "intro") {
    material = [readmeSection(readme), manifests].join("\n");
  } else {
    // Let the model pick the files that explain the architecture: entry
    // points, routing, the data layer, wiring and configuration.
    const tree = section("File tree", treeListing(files));
    const selection = await generate({
      instructions:
        `Pick at most ${MAX_KEY_FILES} files from the repository ${repo} that best explain how it is architected: ` +
        `entry points, routing or navigation, the data and persistence layer, dependency wiring, and core services. ` +
        `Likely entry points: ${(index.entryPoints ?? []).slice(0, 20).join(", ") || "none detected"}. ` +
        `Return paths exactly as they appear in the file tree.`,
      material: [readmeSection(readme), manifests, tree].join("\n"),
      schema: FileSelectionSchema,
      effort: "low",
      maxTokens: 4000,
    });
    const known = new Set(files.map((file) => file.path));
    keyFiles = selection.files.filter((path) => known.has(path)).slice(0, MAX_KEY_FILES);
    material = [readmeSection(readme), manifests, tree, await fileSections(github, repo, commit, keyFiles)].join("\n");
  }

  const instructions = loadPrompt(type, { repo, maxWords, summary: index.summary ?? "" });
  let script: Script = await generate({ instructions, material, schema: ScriptSchema });
  if (wordCount(script) > maxWords) {
    script = await generate({
      instructions,
      material,
      schema: ScriptSchema,
      followUp: {
        previous: JSON.stringify(script),
        request: `That script is ${wordCount(script)} words. Rewrite it to at most ${maxWords} words, keeping the same sections where you can.`,
      },
    });
  }
  return { script: enforceCap(script, maxWords), keyFiles };
}

export interface PackageFile {
  name: string;
  body: string | Uint8Array;
  contentType: string;
}

export interface RenderedEpisode {
  files: PackageFile[];
  manifest: NarrationManifest;
  durationSeconds: number;
}

/** Audio: each section voiced as one part, then the playlist and manifest. */
export async function renderEpisode(
  voice: ElevenLabsClient,
  script: Script,
  episode: { repo: string; commit: string; type: EpisodeType },
  onPart?: (index: number, total: number) => void,
): Promise<RenderedEpisode> {
  const base = baseName(episode.repo, episode.type);
  const files: PackageFile[] = [];
  const parts: PackagePart[] = [];
  for (const [index, scriptSection] of script.sections.entries()) {
    onPart?.(index, script.sections.length);
    const audio = concatAudio(await voice.speakAll(chunkForSpeech(scriptSection.paragraphs)));
    const part: PackagePart = {
      file: partFileName(base, index),
      title: scriptSection.title,
      transcript: transcriptFileName(base, index),
      durationSeconds: Math.round(cbrDurationSeconds(audio.length) * 10) / 10,
    };
    files.push({ name: part.file, body: audio, contentType: "audio/mpeg" });
    files.push({ name: part.transcript, body: scriptSection.paragraphs.join("\n\n"), contentType: "text/plain; charset=utf-8" });
    parts.push(part);
  }

  const durationSeconds = parts.reduce((sum, part) => sum + part.durationSeconds, 0);
  const manifest: NarrationManifest = {
    schemaVersion: 1,
    repo: episode.repo,
    commit: episode.commit,
    episodeType: episode.type,
    module: null,
    executor: "cloud",
    voice: "ElevenLabs",
    quotaMinutes: roundMinutes(durationSeconds),
    generatedAt: new Date().toISOString(),
    parts,
  };
  files.push({
    name: `${base}.m3u8`,
    body: writePlaylist(playlistTitle(episode.repo, episode.type), base, parts),
    contentType: "application/vnd.apple.mpegurl",
  });
  files.push({ name: "manifest.json", body: JSON.stringify(manifest, null, 2), contentType: "application/json" });
  return { files, manifest, durationSeconds };
}
