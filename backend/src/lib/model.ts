import { AnthropicBedrockMantle } from "@anthropic-ai/bedrock-sdk";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";
import { z } from "zod";

/** Claude on Amazon Bedrock. Override with the BEDROCK_MODEL_ID env var. */
export const MODEL_ID = process.env.BEDROCK_MODEL_ID ?? "anthropic.claude-opus-5";

let client: AnthropicBedrockMantle | undefined;
function bedrock(): AnthropicBedrockMantle {
  client ??= new AnthropicBedrockMantle({ awsRegion: process.env.BEDROCK_REGION ?? process.env.AWS_REGION });
  return client;
}

export interface StructuredRequest<Schema extends z.ZodType> {
  instructions: string;
  material: string;
  schema: Schema;
  effort?: "low" | "medium" | "high";
  maxTokens?: number;
  /** Extra turn appended after the first answer, e.g. "too long — shorten it". */
  followUp?: { previous: string; request: string };
}

/**
 * One structured call: the shared prompt as instructions, the repo material
 * after `---` (the same layout the app uses on device), JSON validated
 * against `schema`.
 */
export async function generate<Schema extends z.ZodType>(request: StructuredRequest<Schema>): Promise<z.infer<Schema>> {
  const messages: { role: "user" | "assistant"; content: string }[] = [
    { role: "user", content: `${request.instructions}\n\n---\n\n${request.material}` },
  ];
  if (request.followUp) {
    messages.push({ role: "assistant", content: request.followUp.previous });
    messages.push({ role: "user", content: request.followUp.request });
  }
  const response = await bedrock().messages.parse({
    model: MODEL_ID,
    max_tokens: request.maxTokens ?? 16000,
    thinking: { type: "adaptive" },
    output_config: { effort: request.effort ?? "high", format: zodOutputFormat(request.schema) },
    messages,
  });
  if (response.stop_reason === "refusal") throw new Error("The model declined to write this episode.");
  if (response.stop_reason === "max_tokens") throw new Error("The model ran out of output tokens.");
  if (response.parsed_output == null) throw new Error("The model returned no structured output.");
  return response.parsed_output as z.infer<Schema>;
}

export const ScriptSchema = z.object({
  sections: z
    .array(
      z.object({
        title: z.string(),
        paragraphs: z.array(z.string()).min(1),
      }),
    )
    .min(1),
});

export const IndexSummarySchema = z.object({
  summary: z.string(),
  introTitle: z.string(),
  architectureTitle: z.string(),
});

export const FileSelectionSchema = z.object({
  files: z.array(z.string()),
});
