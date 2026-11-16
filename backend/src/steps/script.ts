import { getIndex, setEpisodeStatus } from "../lib/db.js";
import { GitHubClient } from "../lib/github.js";
import { fileSections, MAX_KEY_FILES, readmeSection, section, treeListing } from "../lib/material.js";
import { FileSelectionSchema, generate, ScriptSchema } from "../lib/model.js";
import { loadPrompt } from "../lib/prompts.js";
import { links } from "../lib/resources.js";
import { putObject, scriptKey } from "../lib/storage.js";
import { EPISODE_WORD_CAP, type EpisodeJob, type Script } from "../lib/types.js";

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

/**
 * Step 1 of EpisodeFlow: one model call per episode, written to S3 so an
 * audio failure retries without paying for the script again.
 */
export async function handler(job: EpisodeJob): Promise<EpisodeJob> {
  await setEpisodeStatus(job.repo, job.commit, job.type, "scripting");
  const index = await getIndex(job.repo, job.commit);
  if (index?.status !== "ready") throw new Error(`No ready index for ${job.repo}@${job.commit}`);

  const github = new GitHubClient(links.GitHubToken.value || undefined);
  const [{ files }, readme] = await Promise.all([github.tree(job.repo, job.commit), github.readme(job.repo, job.commit)]);
  const manifests = await fileSections(github, job.repo, job.commit, (index.manifests ?? []).slice(0, 5));
  const maxWords = EPISODE_WORD_CAP[job.type];

  let material: string;
  if (job.type === "intro") {
    material = [readmeSection(readme), manifests].join("\n");
  } else {
    // Let the model pick the files that explain the architecture: entry
    // points, routing, the data layer, wiring and configuration.
    const tree = section("File tree", treeListing(files));
    const selection = await generate({
      instructions:
        `Pick at most ${MAX_KEY_FILES} files from the repository ${job.repo} that best explain how it is architected: ` +
        `entry points, routing or navigation, the data and persistence layer, dependency wiring, and core services. ` +
        `Likely entry points: ${(index.entryPoints ?? []).slice(0, 20).join(", ") || "none detected"}. ` +
        `Return paths exactly as they appear in the file tree.`,
      material: [readmeSection(readme), manifests, tree].join("\n"),
      schema: FileSelectionSchema,
      effort: "low",
      maxTokens: 4000,
    });
    const known = new Set(files.map((file) => file.path));
    const keyFiles = selection.files.filter((path) => known.has(path)).slice(0, MAX_KEY_FILES);
    material = [readmeSection(readme), manifests, tree, await fileSections(github, job.repo, job.commit, keyFiles)].join("\n");
  }

  const instructions = loadPrompt(job.type, { repo: job.repo, maxWords, summary: index.summary ?? "" });
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
  script = enforceCap(script, maxWords);

  await putObject(scriptKey(job.repo, job.commit, job.type), JSON.stringify(script), "application/json");
  return job;
}
