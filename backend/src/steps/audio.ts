import { chunkForSpeech } from "../lib/chunk.js";
import { addMinutes, putEpisode, setEpisodeStatus } from "../lib/db.js";
import { concatAudio, ElevenLabsClient } from "../lib/elevenlabs.js";
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
import { monthKey, roundMinutes } from "../lib/quota.js";
import { links } from "../lib/resources.js";
import { episodePrefix, getText, putObject, scriptKey } from "../lib/storage.js";
import type { EpisodeJob, Script } from "../lib/types.js";

/**
 * Step 2 of EpisodeFlow: voices each script section as one part, then writes
 * the narration package (parts, transcripts, playlist, manifest) to S3 and
 * settles the requester's quota against the real duration.
 */
export async function handler(job: EpisodeJob): Promise<EpisodeJob> {
  await setEpisodeStatus(job.repo, job.commit, job.type, "rendering");
  const script = JSON.parse(await getText(scriptKey(job.repo, job.commit, job.type))) as Script;
  const voice = new ElevenLabsClient(links.ElevenLabsApiKey.value, links.ElevenLabsVoiceId.value);

  const base = baseName(job.repo, job.type);
  const prefix = episodePrefix(job.repo, job.commit, job.type);
  const parts: PackagePart[] = [];
  for (const [index, scriptSection] of script.sections.entries()) {
    const audio = concatAudio(await voice.speakAll(chunkForSpeech(scriptSection.paragraphs)));
    const part: PackagePart = {
      file: partFileName(base, index),
      title: scriptSection.title,
      transcript: transcriptFileName(base, index),
      durationSeconds: Math.round(cbrDurationSeconds(audio.length) * 10) / 10,
    };
    await putObject(prefix + part.file, audio, "audio/mpeg");
    await putObject(prefix + part.transcript, scriptSection.paragraphs.join("\n\n"), "text/plain; charset=utf-8");
    parts.push(part);
  }

  const durationSeconds = parts.reduce((sum, part) => sum + part.durationSeconds, 0);
  const quotaMinutes = roundMinutes(durationSeconds);
  const manifest: NarrationManifest = {
    schemaVersion: 1,
    repo: job.repo,
    commit: job.commit,
    episodeType: job.type,
    module: null,
    executor: "cloud",
    voice: "ElevenLabs",
    quotaMinutes,
    generatedAt: new Date().toISOString(),
    parts,
  };
  const playlist = `${base}.m3u8`;
  await putObject(prefix + playlist, writePlaylist(playlistTitle(job.repo, job.type), base, parts), "application/vnd.apple.mpegurl");
  await putObject(prefix + "manifest.json", JSON.stringify(manifest, null, 2), "application/json");

  // The request reserved an estimate; charge the real duration instead.
  await addMinutes(job.sub, monthKey(), quotaMinutes - job.reservedMinutes);
  await putEpisode(job.repo, job.commit, job.type, {
    status: "ready",
    prefix,
    files: [playlist, "manifest.json", ...parts.flatMap((part) => [part.file, part.transcript])],
    durationSeconds,
  });
  return job;
}
