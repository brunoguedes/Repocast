import type { APIGatewayProxyEventV2WithJWTAuthorizer, APIGatewayProxyResultV2 } from "aws-lambda";

export type ApiEvent = APIGatewayProxyEventV2WithJWTAuthorizer;
export type ApiResult = APIGatewayProxyResultV2;

export function json(statusCode: number, body: unknown): ApiResult {
  return { statusCode, headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) };
}

export function problem(statusCode: number, message: string): ApiResult {
  return json(statusCode, { error: message });
}

/** The Cognito user the JWT authorizer verified. */
export function caller(event: ApiEvent): { sub: string; username: string } {
  const claims = event.requestContext.authorizer.jwt.claims;
  return { sub: String(claims.sub), username: String(claims.username ?? claims["cognito:username"] ?? claims.sub) };
}

export function body<T>(event: ApiEvent): Partial<T> {
  try {
    return event.body ? (JSON.parse(event.isBase64Encoded ? Buffer.from(event.body, "base64").toString() : event.body) as T) : {};
  } catch {
    return {};
  }
}

const REPO_PATTERN = /^[A-Za-z0-9-]+\/[A-Za-z0-9._-]+$/;

export function repoFromPath(event: ApiEvent): string | undefined {
  const repo = `${event.pathParameters?.owner}/${event.pathParameters?.name}`;
  return REPO_PATTERN.test(repo) ? repo : undefined;
}

export function isRepoName(value: unknown): value is string {
  return typeof value === "string" && REPO_PATTERN.test(value);
}

export function isCommit(value: unknown): value is string {
  return typeof value === "string" && /^[0-9a-f]{40}$/.test(value);
}
