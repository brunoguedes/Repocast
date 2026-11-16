import rules from "../../../shared/classification.json" with { type: "json" };
import type { Classification } from "./types.js";

export interface ClassificationResult {
  classification: Classification;
  manifests: string[];
  entryPoints: string[];
}

const codeExtensions = new Set(rules.codeExtensions);
const docExtensions = new Set(rules.docExtensions);
const ignored = new Set(rules.ignoredDirectories);

function baseName(path: string): string {
  return path.slice(path.lastIndexOf("/") + 1);
}

function extension(name: string): string {
  const dot = name.lastIndexOf(".");
  return dot > 0 ? name.slice(dot + 1).toLowerCase() : "";
}

function isIgnored(path: string): boolean {
  return path.split("/").slice(0, -1).some((folder) => ignored.has(folder));
}

function isManifest(path: string): boolean {
  if (path.split("/").length - 1 > rules.manifestMaxDepth) return false;
  const name = baseName(path);
  return rules.manifests.some((pattern) =>
    pattern.startsWith("*") ? name.endsWith(pattern.slice(1)) : name === pattern,
  );
}

function isEntryPoint(path: string): boolean {
  const name = baseName(path);
  if (rules.entryPointSuffixes.some((suffix) => name.endsWith(suffix))) return true;
  const ext = extension(name);
  if (!codeExtensions.has(ext)) return false;
  const stem = name.slice(0, name.length - ext.length - 1).toLowerCase();
  return rules.entryPointStems.includes(stem);
}

/**
 * Classifies a repo from its file paths by the rule in
 * shared/classification.json. Mirrors the app's `RepoClassifier`; both run
 * shared/fixtures/classification-cases.json.
 */
export function classify(paths: string[]): ClassificationResult {
  const kept = paths.filter((path) => !isIgnored(path));
  let code = 0;
  let docs = 0;
  for (const path of kept) {
    const ext = extension(baseName(path));
    if (codeExtensions.has(ext)) code += 1;
    else if (docExtensions.has(ext)) docs += 1;
  }
  const counted = code + docs;
  const manifests = kept.filter(isManifest);
  const entryPoints = kept.filter(isEntryPoint);

  let classification: Classification = "mixed";
  if (manifests.length > 0 && counted > 0 && code / counted >= rules.codebaseMinCodeRatio) {
    classification = "codebase";
  } else if (manifests.length === 0 && counted > 0 && docs / counted >= rules.documentsMinDocRatio) {
    classification = "documents";
  }
  return { classification, manifests, entryPoints };
}
