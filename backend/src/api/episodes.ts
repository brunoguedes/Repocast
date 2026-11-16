import { SFNClient, StartExecutionCommand } from "@aws-sdk/client-sfn";
import { addMinutes, claimEpisode, getEpisode, getIndex } from "../lib/db.js";
import type { NarrationManifest } from "../lib/package.js";
import { MONTHLY_QUOTA_MINUTES, monthKey } from "../lib/quota.js";
import { links } from "../lib/resources.js";
import { getText, signedUrl } from "../lib/storage.js";
import { isEpisodeType, type EpisodeJob } from "../lib/types.js";
import { body, caller, isCommit, json, problem, repoFromPath, type ApiEvent, type ApiResult } from "./http.js";

const sfn = new SFNClient({});

/**
 * POST /repos/{owner}/{name}/episodes/{type} {commit}: lazy generation. Episodes
 * are cached per repo, commit and type and shared by every listener, so only
 * the first request reserves quota and starts EpisodeFlow.
 */
export async function start(event: ApiEvent): Promise<ApiResult> {
  const repo = repoFromPath(event);
  const type = event.pathParameters?.type;
  const { commit } = body<{ commit: string }>(event);
  if (!repo || !isEpisodeType(type) || !isCommit(commit)) return problem(400, "Bad episode request.");

  const index = await getIndex(repo, commit);
  const planned = index?.episodes?.find((episode) => episode.type === type);
  if (index?.status !== "ready" || !planned) return problem(409, "This episode isn't in the repository's tour.");

  const existing = await getEpisode(repo, commit, type);
  if (existing && existing.status !== "failed") return json(202, { status: existing.status });

  const { sub } = caller(event);
  const month = monthKey();
  if (!(await addMinutes(sub, month, planned.estimatedMinutes, MONTHLY_QUOTA_MINUTES))) {
    return problem(429, "You've used this month's cloud generation minutes.");
  }
  if (!(await claimEpisode(repo, commit, type))) {
    // Someone else started it between our read and claim.
    await addMinutes(sub, month, -planned.estimatedMinutes);
    return json(202, { status: (await getEpisode(repo, commit, type))?.status ?? "pending" });
  }

  const job: EpisodeJob = { repo, commit, type, sub, reservedMinutes: planned.estimatedMinutes };
  await sfn.send(
    new StartExecutionCommand({
      stateMachineArn: links.EpisodeFlow.arn,
      name: `${repo.replace(/[^A-Za-z0-9-]/g, "-")}-${type}-${commit.slice(0, 12)}-${Date.now()}`.slice(0, 80),
      input: JSON.stringify(job),
    }),
  );
  return json(202, { status: "pending" });
}

/**
 * GET /repos/{owner}/{name}/episodes/{type}?commit=: status, and once ready the
 * manifest plus a short-lived signed URL per package file for the app to
 * download into its narrations store.
 */
export async function status(event: ApiEvent): Promise<ApiResult> {
  const repo = repoFromPath(event);
  const type = event.pathParameters?.type;
  const commit = event.queryStringParameters?.commit;
  if (!repo || !isEpisodeType(type) || !isCommit(commit)) return problem(400, "Bad episode request.");

  const record = await getEpisode(repo, commit, type);
  if (!record) return problem(404, "This episode hasn't been requested.");
  if (record.status !== "ready" || !record.prefix || !record.files) {
    return json(200, { status: record.status, error: record.error });
  }
  const prefix = record.prefix;
  const manifest = JSON.parse(await getText(prefix + "manifest.json")) as NarrationManifest;
  const files = await Promise.all(
    record.files.map(async (name) => ({ name, url: await signedUrl(prefix + name) })),
  );
  return json(200, { status: "ready", manifest, files });
}
