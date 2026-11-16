import { readFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

/**
 * Prompts live in shared/prompts so the app and the backend aim at the same
 * episodes. Deployed functions get them via `copyFiles` (see sst.config.ts);
 * tests read them straight from the repo.
 */
function promptsDir(): string {
  if (process.env.LAMBDA_TASK_ROOT) return join(process.env.LAMBDA_TASK_ROOT, "prompts");
  return fileURLToPath(new URL("../../../shared/prompts/", import.meta.url));
}

export type PromptName = "index-summary" | "intro" | "architecture";

export function loadPrompt(name: PromptName, values: Record<string, string | number>): string {
  const template = readFileSync(join(promptsDir(), `${name}.md`), "utf8");
  return template.replace(/\{\{(\w+)\}\}/g, (match, key: string) =>
    key in values ? String(values[key]) : match,
  );
}
