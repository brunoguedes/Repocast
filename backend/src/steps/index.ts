import { classify } from "../lib/classify.js";
import { putHead, putIndex } from "../lib/db.js";
import { GitHubClient } from "../lib/github.js";
import { fileSections, readmeSection, section, treeListing } from "../lib/material.js";
import { generate, IndexSummarySchema } from "../lib/model.js";
import { loadPrompt } from "../lib/prompts.js";
import { links } from "../lib/resources.js";
import { estimatedMinutes, type PlannedEpisode, type TourIndex } from "../lib/types.js";

export interface IndexEvent {
  repo: string;
  commit: string;
  branch: string;
}

/**
 * Eager, cheap index on add: file tree, README, manifests, classification and
 * a one-paragraph summary, so the app can list the tour's episodes (titles,
 * estimated minutes) before any audio exists. Invoked asynchronously by
 * POST /repos.
 */
export async function handler(event: IndexEvent): Promise<void> {
  const base: TourIndex = { repo: event.repo, commit: event.commit, branch: event.branch, status: "indexing" };
  try {
    const github = new GitHubClient(links.GitHubToken.value || undefined);
    const [{ files }, readme] = await Promise.all([
      github.tree(event.repo, event.commit),
      github.readme(event.repo, event.commit),
    ]);
    const { classification, manifests, entryPoints } = classify(files.map((file) => file.path));

    const material = [
      readmeSection(readme),
      section("File tree", treeListing(files)),
      await fileSections(github, event.repo, event.commit, manifests.slice(0, 5)),
    ].join("\n");
    const summary = await generate({
      instructions: loadPrompt("index-summary", { repo: event.repo, classification }),
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

    await putIndex({ ...base, status: "ready", classification, summary: summary.summary, episodes, manifests, entryPoints });
    await putHead(event.repo, event.commit, event.branch);
  } catch (error) {
    console.error("Index failed", event, error);
    await putIndex({ ...base, status: "failed", error: (error as Error).message });
  }
}
