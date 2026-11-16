import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { links } from "./resources.js";
import type { EpisodeStatus, EpisodeType, TourIndex } from "./types.js";

/**
 * Single-table layout:
 *   REPO#owner/name  HEAD                  latest indexed commit pointer
 *   REPO#owner/name  COMMIT#<sha>          TourIndex at that commit
 *   REPO#owner/name  EPISODE#<sha>#<type>  EpisodeRecord (shared by every listener)
 *   USER#<sub>       QUOTA#<yyyy-mm>       minutes used that month
 */
export const doc = DynamoDBDocumentClient.from(new DynamoDBClient({}), {
  marshallOptions: { removeUndefinedValues: true },
});

const repoKey = (repo: string) => `REPO#${repo}`;
const table = () => links.Table.name;

export interface EpisodeRecord {
  status: EpisodeStatus;
  error?: string;
  /** S3 prefix holding the package once ready. */
  prefix?: string;
  files?: string[];
  durationSeconds?: number;
  updatedAt: string;
}

export async function getHead(repo: string): Promise<{ commit: string; branch: string } | undefined> {
  const { Item } = await doc.send(new GetCommand({ TableName: table(), Key: { pk: repoKey(repo), sk: "HEAD" } }));
  return Item as { commit: string; branch: string } | undefined;
}

export async function putHead(repo: string, commit: string, branch: string): Promise<void> {
  await doc.send(
    new PutCommand({
      TableName: table(),
      Item: { pk: repoKey(repo), sk: "HEAD", commit, branch, updatedAt: new Date().toISOString() },
    }),
  );
}

export async function getIndex(repo: string, commit: string): Promise<TourIndex | undefined> {
  const { Item } = await doc.send(
    new GetCommand({ TableName: table(), Key: { pk: repoKey(repo), sk: `COMMIT#${commit}` } }),
  );
  return Item as TourIndex | undefined;
}

export async function putIndex(index: TourIndex): Promise<void> {
  await doc.send(
    new PutCommand({
      TableName: table(),
      Item: { pk: repoKey(index.repo), sk: `COMMIT#${index.commit}`, ...index, updatedAt: new Date().toISOString() },
    }),
  );
}

/** Creates the index row only if it doesn't exist yet. Returns false when it already did. */
export async function claimIndex(index: TourIndex): Promise<boolean> {
  try {
    await doc.send(
      new PutCommand({
        TableName: table(),
        Item: { pk: repoKey(index.repo), sk: `COMMIT#${index.commit}`, ...index, updatedAt: new Date().toISOString() },
        ConditionExpression: "attribute_not_exists(pk) OR #status = :failed",
        ExpressionAttributeNames: { "#status": "status" },
        ExpressionAttributeValues: { ":failed": "failed" },
      }),
    );
    return true;
  } catch (error) {
    if ((error as Error).name === "ConditionalCheckFailedException") return false;
    throw error;
  }
}

const episodeKey = (repo: string, commit: string, type: EpisodeType) => ({
  pk: repoKey(repo),
  sk: `EPISODE#${commit}#${type}`,
});

export async function getEpisode(repo: string, commit: string, type: EpisodeType): Promise<EpisodeRecord | undefined> {
  const { Item } = await doc.send(new GetCommand({ TableName: table(), Key: episodeKey(repo, commit, type) }));
  return Item as EpisodeRecord | undefined;
}

export async function putEpisode(repo: string, commit: string, type: EpisodeType, record: Omit<EpisodeRecord, "updatedAt">) {
  await doc.send(
    new PutCommand({
      TableName: table(),
      Item: { ...episodeKey(repo, commit, type), ...record, updatedAt: new Date().toISOString() },
    }),
  );
}

/**
 * Marks an episode `pending` unless it's already ready or in flight, so two
 * listeners tapping Generate at once start one job. Returns false when the
 * claim lost.
 */
export async function claimEpisode(repo: string, commit: string, type: EpisodeType): Promise<boolean> {
  try {
    await doc.send(
      new PutCommand({
        TableName: table(),
        Item: { ...episodeKey(repo, commit, type), status: "pending", updatedAt: new Date().toISOString() },
        ConditionExpression: "attribute_not_exists(pk) OR #status = :failed",
        ExpressionAttributeNames: { "#status": "status" },
        ExpressionAttributeValues: { ":failed": "failed" },
      }),
    );
    return true;
  } catch (error) {
    if ((error as Error).name === "ConditionalCheckFailedException") return false;
    throw error;
  }
}

export async function setEpisodeStatus(repo: string, commit: string, type: EpisodeType, status: EpisodeStatus, error?: string) {
  await doc.send(
    new UpdateCommand({
      TableName: table(),
      Key: episodeKey(repo, commit, type),
      UpdateExpression: "SET #status = :status, updatedAt = :now" + (error ? ", #error = :error" : " REMOVE #error"),
      ExpressionAttributeNames: { "#status": "status", "#error": "error" },
      ExpressionAttributeValues: {
        ":status": status,
        ":now": new Date().toISOString(),
        ...(error ? { ":error": error } : {}),
      },
    }),
  );
}

const quotaKey = (sub: string, month: string) => ({ pk: `USER#${sub}`, sk: `QUOTA#${month}` });

export async function getMinutesUsed(sub: string, month: string): Promise<number> {
  const { Item } = await doc.send(new GetCommand({ TableName: table(), Key: quotaKey(sub, month) }));
  return (Item?.minutes as number | undefined) ?? 0;
}

/**
 * Adds `minutes` (negative to refund) to the user's month. With `cap`, the
 * write only succeeds if the total stays within it; returns false otherwise.
 */
export async function addMinutes(sub: string, month: string, minutes: number, cap?: number): Promise<boolean> {
  try {
    await doc.send(
      new UpdateCommand({
        TableName: table(),
        Key: quotaKey(sub, month),
        UpdateExpression: "ADD minutes :m",
        ...(cap === undefined
          ? { ExpressionAttributeValues: { ":m": minutes } }
          : {
              ConditionExpression: "attribute_not_exists(minutes) OR minutes <= :limit",
              ExpressionAttributeValues: { ":m": minutes, ":limit": cap - minutes },
            }),
      }),
    );
    return true;
  } catch (error) {
    if ((error as Error).name === "ConditionalCheckFailedException") return false;
    throw error;
  }
}
