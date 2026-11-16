import { InvokeCommand, LambdaClient } from "@aws-sdk/client-lambda";
import { claimIndex, getEpisode, getHead, getIndex } from "../lib/db.js";
import { GitHubClient, GitHubError } from "../lib/github.js";
import { links } from "../lib/resources.js";
import type { IndexEvent } from "../steps/index.js";
import { body, isCommit, isRepoName, json, problem, repoFromPath, type ApiEvent, type ApiResult } from "./http.js";

const lambda = new LambdaClient({});

/**
 * POST /repos {fullName}: resolves the default branch's HEAD and starts the
 * index for that commit unless it's already indexed or indexing. Public repos
 * only in this slice — no GitHub token ever leaves the device.
 */
export async function add(event: ApiEvent): Promise<ApiResult> {
  const { fullName } = body<{ fullName: string }>(event);
  if (!isRepoName(fullName)) return problem(400, "fullName must be owner/name.");

  const github = new GitHubClient(links.GitHubToken.value || undefined);
  let repo;
  let commit;
  try {
    repo = await github.repository(fullName);
    if (repo.isPrivate) return problem(422, "Cloud generation supports public repositories only.");
    commit = await github.headCommit(repo.fullName, repo.defaultBranch);
  } catch (error) {
    if (error instanceof GitHubError && error.status === 404) return problem(404, "Repository not found, or it isn't public.");
    throw error;
  }

  const job: IndexEvent = { repo: repo.fullName, commit, branch: repo.defaultBranch };
  if (await claimIndex({ ...job, status: "indexing" })) {
    await lambda.send(
      new InvokeCommand({ FunctionName: links.Index.name, InvocationType: "Event", Payload: JSON.stringify(job) }),
    );
  }
  const index = await getIndex(job.repo, commit);
  return json(202, { repo: job.repo, commit, status: index?.status ?? "indexing" });
}

/** GET /repos/{owner}/{name}/tour?commit=: the index plus each episode's status. */
export async function tour(event: ApiEvent): Promise<ApiResult> {
  const repo = repoFromPath(event);
  if (!repo) return problem(400, "Bad repository.");
  const commit = isCommit(event.queryStringParameters?.commit)
    ? event.queryStringParameters.commit
    : (await getHead(repo))?.commit;
  if (!commit) return problem(404, "This repository hasn't been added yet.");

  const index = await getIndex(repo, commit);
  if (!index) return problem(404, "This commit hasn't been indexed.");
  const episodes = await Promise.all(
    (index.episodes ?? []).map(async (episode) => ({
      ...episode,
      status: (await getEpisode(repo, commit, episode.type))?.status ?? "none",
    })),
  );
  return json(200, {
    repo,
    commit,
    status: index.status,
    classification: index.classification,
    summary: index.summary,
    episodes,
    error: index.error,
  });
}
