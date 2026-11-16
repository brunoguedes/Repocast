import { renderEpisode } from "../core/tour.js";
import { addMinutes, putEpisode, setEpisodeStatus } from "../lib/db.js";
import { ElevenLabsClient } from "../lib/elevenlabs.js";
import { monthKey } from "../lib/quota.js";
import { links } from "../lib/resources.js";
import { episodePrefix, getText, putObject, scriptKey } from "../lib/storage.js";
import type { EpisodeJob, Script } from "../lib/types.js";

/**
 * Step 2 of EpisodeFlow: writes the narration package to S3 and settles the
 * requester's quota against the real duration.
 */
export async function handler(job: EpisodeJob): Promise<EpisodeJob> {
  await setEpisodeStatus(job.repo, job.commit, job.type, "rendering");
  const script = JSON.parse(await getText(scriptKey(job.repo, job.commit, job.type))) as Script;
  const voice = new ElevenLabsClient(links.ElevenLabsApiKey.value, links.ElevenLabsVoiceId.value);

  const { files, manifest, durationSeconds } = await renderEpisode(voice, script, job);
  const prefix = episodePrefix(job.repo, job.commit, job.type);
  for (const file of files) await putObject(prefix + file.name, file.body, file.contentType);

  // The request reserved an estimate; charge the real duration instead.
  await addMinutes(job.sub, monthKey(), manifest.quotaMinutes - job.reservedMinutes);
  await putEpisode(job.repo, job.commit, job.type, {
    status: "ready",
    prefix,
    files: files.map((file) => file.name),
    durationSeconds,
  });
  return job;
}
