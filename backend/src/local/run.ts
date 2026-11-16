/**
 * Runs the tour pipeline on this machine — no deploy, no Cognito, DynamoDB
 * or S3. GitHub and ElevenLabs are called directly, Claude through Bedrock
 * with your local AWS credentials. Output is a narration package per episode
 * under `.local/`, ready to listen to or import into the app.
 *
 *   npm run tour -- brunoguedes/Repocast                 index + scripts + audio
 *   npm run tour -- brunoguedes/Repocast --no-audio      stop after the scripts (no ElevenLabs cost)
 *   npm run tour -- brunoguedes/Repocast --episode architecture --fresh
 *
 * Each stage is cached on disk (index.json, <type>/script.json), like the S3
 * split in the cloud: re-running only redoes what's missing unless --fresh.
 * Env: AWS_PROFILE / AWS_REGION, BEDROCK_REGION, BEDROCK_MODEL_ID,
 * GITHUB_TOKEN (optional), ELEVENLABS_API_KEY + ELEVENLABS_VOICE_ID (audio).
 */
import { existsSync } from "node:fs";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { parseArgs } from "node:util";
import { indexRepo, renderEpisode, wordCount, writeScript } from "../core/tour.js";
import { ElevenLabsClient } from "../lib/elevenlabs.js";
import { GitHubClient } from "../lib/github.js";
import { MODEL_ID } from "../lib/model.js";
import { baseName } from "../lib/package.js";
import { isEpisodeType, type EpisodeType, type Script, type TourIndex } from "../lib/types.js";

const { values, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    episode: { type: "string", default: "all" },
    "no-audio": { type: "boolean", default: false },
    fresh: { type: "boolean", default: false },
    out: { type: "string", default: ".local" },
  },
});

const repoArg = positionals[0];
if (!repoArg || !/^[A-Za-z0-9-]+\/[A-Za-z0-9._-]+$/.test(repoArg)) {
  console.error("Usage: npm run tour -- owner/name [--episode intro|architecture|all] [--no-audio] [--fresh] [--out dir]");
  process.exit(1);
}
if (values.episode !== "all" && !isEpisodeType(values.episode)) {
  console.error(`--episode must be intro, architecture or all (got ${values.episode})`);
  process.exit(1);
}

const log = (message: string) => console.log(`[tour] ${message}`);

async function readJSON<T>(path: string): Promise<T | undefined> {
  return existsSync(path) ? (JSON.parse(await readFile(path, "utf8")) as T) : undefined;
}

async function main() {
  const github = new GitHubClient(process.env.GITHUB_TOKEN || undefined);
  const info = await github.repository(repoArg!);
  if (info.isPrivate) throw new Error("Cloud generation supports public repositories only.");
  const commit = await github.headCommit(info.fullName, info.defaultBranch);
  const root = resolve(values.out!, info.fullName.replace("/", "__"), commit.slice(0, 12));
  await mkdir(root, { recursive: true });
  log(`${info.fullName}@${commit.slice(0, 12)} (${info.defaultBranch}) → ${root}`);
  log(`model ${MODEL_ID} via Bedrock in ${process.env.BEDROCK_REGION ?? process.env.AWS_REGION ?? "the default region"}`);

  // 1. Index
  const indexPath = join(root, "index.json");
  let index = values.fresh ? undefined : await readJSON<TourIndex>(indexPath);
  if (index) {
    log("index: cached");
  } else {
    log("index: reading the repo and asking Claude for the summary…");
    index = await indexRepo(github, info.fullName, commit, info.defaultBranch);
    await writeFile(indexPath, JSON.stringify(index, null, 2));
  }
  log(`  ${index.classification}: ${index.summary}`);
  for (const episode of index.episodes ?? []) log(`  - ${episode.type}: "${episode.title}" (~${episode.estimatedMinutes} min)`);

  const wanted: EpisodeType[] = (index.episodes ?? [])
    .map((episode) => episode.type)
    .filter((type) => values.episode === "all" || type === values.episode);
  if (wanted.length === 0) log(`no ${values.episode} episode planned for this repo`);

  const voice =
    values["no-audio"] || !process.env.ELEVENLABS_API_KEY || !process.env.ELEVENLABS_VOICE_ID
      ? undefined
      : new ElevenLabsClient(process.env.ELEVENLABS_API_KEY, process.env.ELEVENLABS_VOICE_ID);
  if (!voice && !values["no-audio"]) log("audio: skipped — set ELEVENLABS_API_KEY and ELEVENLABS_VOICE_ID to record");

  for (const type of wanted) {
    const dir = join(root, type);
    await mkdir(dir, { recursive: true });

    // 2. Script
    const scriptPath = join(dir, "script.json");
    let script = values.fresh ? undefined : await readJSON<Script>(scriptPath);
    if (script) {
      log(`${type} script: cached`);
    } else {
      log(`${type} script: writing with Claude…`);
      const result = await writeScript(github, index, type);
      script = result.script;
      await writeFile(scriptPath, JSON.stringify(script, null, 2));
      if (result.keyFiles.length) log(`  built from: ${result.keyFiles.join(", ")}`);
    }
    // A readable copy for reviewing the script before paying for audio.
    await writeFile(
      join(dir, "script.md"),
      script.sections.map((s) => `## ${s.title}\n\n${s.paragraphs.join("\n\n")}`).join("\n\n") + "\n",
    );
    log(`  ${script.sections.length} sections, ${wordCount(script)} words (~${Math.round(wordCount(script) / 150)} min) → ${join(dir, "script.md")}`);

    // 3. Audio → narration package
    if (!voice) continue;
    const packageDir = join(dir, baseName(info.fullName, type));
    if (!values.fresh && existsSync(join(packageDir, "manifest.json"))) {
      log(`${type} audio: cached → ${packageDir}`);
      continue;
    }
    await rm(packageDir, { recursive: true, force: true });
    await mkdir(packageDir, { recursive: true });
    log(`${type} audio: recording with ElevenLabs…`);
    const rendered = await renderEpisode(voice, script, { repo: info.fullName, commit, type }, (part, total) =>
      log(`  part ${part + 1} of ${total}`),
    );
    for (const file of rendered.files) await writeFile(join(packageDir, file.name), file.body);
    log(`  ${Math.round(rendered.durationSeconds / 6) / 10} min of audio → ${packageDir}`);
  }
}

main().catch((error) => {
  console.error(`[tour] failed: ${(error as Error).message}`);
  process.exit(1);
});
