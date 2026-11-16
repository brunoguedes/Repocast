/**
 * Minimal GitHub REST client for public repos. A read-only token (the
 * GitHubToken secret) lifts the 60 requests/hour anonymous limit that Lambda's
 * shared IPs would otherwise hit.
 */
export class GitHubError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}

export interface RepoInfo {
  fullName: string;
  defaultBranch: string;
  isPrivate: boolean;
  description: string | null;
}

export interface TreeEntry {
  path: string;
  size: number;
}

export class GitHubClient {
  constructor(
    private readonly token: string | undefined,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  async repository(fullName: string): Promise<RepoInfo> {
    const json = await this.getJSON<{
      full_name: string;
      default_branch: string;
      private: boolean;
      description: string | null;
    }>(`/repos/${fullName}`);
    return {
      fullName: json.full_name,
      defaultBranch: json.default_branch,
      isPrivate: json.private,
      description: json.description,
    };
  }

  async headCommit(fullName: string, branch: string): Promise<string> {
    const json = await this.getJSON<{ sha: string }>(
      `/repos/${fullName}/commits/${encodeURIComponent(branch)}`,
    );
    return json.sha;
  }

  /** Every file (blob) in the tree at `sha`. `truncated` is set by GitHub for huge repos. */
  async tree(fullName: string, sha: string): Promise<{ files: TreeEntry[]; truncated: boolean }> {
    const json = await this.getJSON<{
      tree: { path: string; type: string; size?: number }[];
      truncated: boolean;
    }>(`/repos/${fullName}/git/trees/${sha}?recursive=1`);
    return {
      files: json.tree
        .filter((entry) => entry.type === "blob")
        .map((entry) => ({ path: entry.path, size: entry.size ?? 0 })),
      truncated: json.truncated,
    };
  }

  /** The README's text at `ref`, or null when the repo has none. */
  async readme(fullName: string, ref: string): Promise<string | null> {
    try {
      return await this.getText(`/repos/${fullName}/readme?ref=${ref}`);
    } catch (error) {
      if (error instanceof GitHubError && error.status === 404) return null;
      throw error;
    }
  }

  async fileText(fullName: string, path: string, ref: string): Promise<string> {
    const encoded = path.split("/").map(encodeURIComponent).join("/");
    return this.getText(`/repos/${fullName}/contents/${encoded}?ref=${ref}`);
  }

  private async request(path: string, accept: string): Promise<Response> {
    const headers: Record<string, string> = {
      Accept: accept,
      "X-GitHub-Api-Version": "2022-11-28",
      "User-Agent": "Repocast",
    };
    if (this.token) headers.Authorization = `Bearer ${this.token}`;
    const response = await this.fetchImpl(`https://api.github.com${path}`, { headers });
    if (!response.ok) {
      const body = await response.text().catch(() => "");
      throw new GitHubError(response.status, `GitHub ${response.status} for ${path}: ${body.slice(0, 200)}`);
    }
    return response;
  }

  private async getJSON<T>(path: string): Promise<T> {
    return (await (await this.request(path, "application/vnd.github+json")).json()) as T;
  }

  private async getText(path: string): Promise<string> {
    return (await this.request(path, "application/vnd.github.raw+json")).text();
  }
}
