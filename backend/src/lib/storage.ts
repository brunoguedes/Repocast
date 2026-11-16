import { GetObjectCommand, PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { links } from "./resources.js";
import type { EpisodeType } from "./types.js";

const s3 = new S3Client({});

export const scriptKey = (repo: string, commit: string, type: EpisodeType) => `scripts/${repo}/${commit}/${type}.json`;
export const episodePrefix = (repo: string, commit: string, type: EpisodeType) => `episodes/${repo}/${commit}/${type}/`;

export async function putObject(key: string, body: string | Uint8Array, contentType: string): Promise<void> {
  await s3.send(new PutObjectCommand({ Bucket: links.Episodes.name, Key: key, Body: body, ContentType: contentType }));
}

export async function getText(key: string): Promise<string> {
  const { Body } = await s3.send(new GetObjectCommand({ Bucket: links.Episodes.name, Key: key }));
  if (!Body) throw new Error(`Empty object ${key}`);
  return Body.transformToString();
}

/** Short-lived download link for one package file. */
export async function signedUrl(key: string, expiresIn = 900): Promise<string> {
  return getSignedUrl(s3, new GetObjectCommand({ Bucket: links.Episodes.name, Key: key }), { expiresIn });
}
