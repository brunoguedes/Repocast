import { Resource } from "sst";

/**
 * Typed view of the SST links this backend uses (see sst.config.ts). Kept by
 * hand so the code typechecks before the first `sst dev` generates
 * sst-env.d.ts.
 */
interface Links {
  Table: { name: string };
  Episodes: { name: string };
  Index: { name: string };
  EpisodeFlow: { arn: string };
  Users: { id: string };
  GitHubToken: { value: string };
  ElevenLabsApiKey: { value: string };
  ElevenLabsVoiceId: { value: string };
  BetaEmails: { value: string };
}

export const links = Resource as unknown as Links;
