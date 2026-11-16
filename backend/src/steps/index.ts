import { indexRepo } from "../core/tour.js";
import { putHead, putIndex } from "../lib/db.js";
import { GitHubClient } from "../lib/github.js";
import { links } from "../lib/resources.js";
import type { TourIndex } from "../lib/types.js";

export interface IndexEvent {
  repo: string;
  commit: string;
  branch: string;
}

/**
 * Eager, cheap index on add, so the app can list the tour's episodes (titles,
 * estimated minutes) before any audio exists. Invoked asynchronously by
 * POST /repos.
 */
export async function handler(event: IndexEvent): Promise<void> {
  try {
    const github = new GitHubClient(links.GitHubToken.value || undefined);
    await putIndex(await indexRepo(github, event.repo, event.commit, event.branch));
    await putHead(event.repo, event.commit, event.branch);
  } catch (error) {
    console.error("Index failed", event, error);
    const failed: TourIndex = { ...event, status: "failed", error: (error as Error).message };
    await putIndex(failed);
  }
}
