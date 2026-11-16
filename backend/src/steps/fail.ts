import { addMinutes, setEpisodeStatus } from "../lib/db.js";
import { monthKey } from "../lib/quota.js";
import type { EpisodeJob } from "../lib/types.js";

/** EpisodeFlow's catch: marks the episode failed and refunds the reservation. */
export async function handler(event: { job: EpisodeJob; error?: { Error?: string; Cause?: string } }): Promise<void> {
  const { job, error } = event;
  console.error("Episode failed", job, error);
  await setEpisodeStatus(job.repo, job.commit, job.type, "failed", error?.Error ?? "Generation failed");
  if (job.reservedMinutes > 0) await addMinutes(job.sub, monthKey(), -job.reservedMinutes);
}
