export const EPISODE_TYPES = ["intro", "architecture"] as const;
export type EpisodeType = (typeof EPISODE_TYPES)[number];

export type Classification = "codebase" | "documents" | "mixed";

export type EpisodeStatus = "pending" | "scripting" | "rendering" | "ready" | "failed";

/** One planned episode in a repo's tour, shown before any audio exists. */
export interface PlannedEpisode {
  type: EpisodeType;
  title: string;
  estimatedMinutes: number;
}

/** The eager, cheap index of one repo at one commit. */
export interface TourIndex {
  repo: string;
  commit: string;
  branch: string;
  status: "indexing" | "ready" | "failed";
  classification?: Classification;
  summary?: string;
  episodes?: PlannedEpisode[];
  manifests?: string[];
  entryPoints?: string[];
  error?: string;
}

/** A script as the model returns it: sections become narration parts. */
export interface Script {
  sections: { title: string; paragraphs: string[] }[];
}

/** Input that flows through the EpisodeFlow state machine. */
export interface EpisodeJob {
  repo: string;
  commit: string;
  type: EpisodeType;
  /** Cognito `sub` of the user whose request started the job. */
  sub: string;
  /** Minutes reserved against that user's quota when the job started. */
  reservedMinutes: number;
}

/** Spoken word budgets per episode, and the minutes they're estimated at. */
export const WORDS_PER_MINUTE = 150;
export const EPISODE_WORD_CAP: Record<EpisodeType, number> = {
  intro: 900,
  architecture: 2000,
};

export function estimatedMinutes(type: EpisodeType): number {
  return Math.ceil(EPISODE_WORD_CAP[type] / WORDS_PER_MINUTE);
}

export function isEpisodeType(value: string | undefined): value is EpisodeType {
  return (EPISODE_TYPES as readonly string[]).includes(value ?? "");
}
