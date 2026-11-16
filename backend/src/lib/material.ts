import type { GitHubClient, TreeEntry } from "./github.js";

/** Caps on how much repo text goes into one model call. */
const MAX_TREE_PATHS = 3000;
const MAX_README_CHARS = 30_000;
const MAX_FILE_CHARS = 12_000;
export const MAX_KEY_FILES = 15;

export function treeListing(files: TreeEntry[]): string {
  const paths = files.map((file) => file.path);
  const shown = paths.slice(0, MAX_TREE_PATHS).join("\n");
  return paths.length > MAX_TREE_PATHS ? `${shown}\n… and ${paths.length - MAX_TREE_PATHS} more files` : shown;
}

export function section(title: string, body: string): string {
  return `## ${title}\n\n${body.trim()}\n`;
}

export function clip(text: string, max: number): string {
  return text.length > max ? `${text.slice(0, max)}\n… (truncated)` : text;
}

export function readmeSection(readme: string | null): string {
  return section("README", readme ? clip(readme, MAX_README_CHARS) : "(This repository has no README.)");
}

/** Fetches `paths` and renders each as its own section, skipping files that fail. */
export async function fileSections(github: GitHubClient, repo: string, commit: string, paths: string[]): Promise<string> {
  const texts = await Promise.all(
    paths.map(async (path) => {
      try {
        return section(path, clip(await github.fileText(repo, path, commit), MAX_FILE_CHARS));
      } catch {
        return "";
      }
    }),
  );
  return texts.filter(Boolean).join("\n");
}
