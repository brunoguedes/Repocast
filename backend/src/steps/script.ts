import { writeScript } from "../core/tour.js";
import { getIndex, setEpisodeStatus } from "../lib/db.js";
import { GitHubClient } from "../lib/github.js";
import { links } from "../lib/resources.js";
import { putObject, scriptKey } from "../lib/storage.js";
import type { EpisodeJob } from "../lib/types.js";

/**
 * Step 1 of EpisodeFlow. The script goes to S3 so an audio failure retries
 * without paying for the model calls again.
 */
export async function handler(job: EpisodeJob): Promise<EpisodeJob> {
  await setEpisodeStatus(job.repo, job.commit, job.type, "scripting");
  const index = await getIndex(job.repo, job.commit);
  if (index?.status !== "ready") throw new Error(`No ready index for ${job.repo}@${job.commit}`);

  const github = new GitHubClient(links.GitHubToken.value || undefined);
  const { script } = await writeScript(github, index, job.type);
  await putObject(scriptKey(job.repo, job.commit, job.type), JSON.stringify(script), "application/json");
  return job;
}
