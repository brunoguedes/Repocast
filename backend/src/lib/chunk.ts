/** ElevenLabs quality drops on long requests; keep each call under this. */
export const MAX_TTS_CHARS = 1000;

/**
 * Splits spoken text into pieces of at most `maxChars`, breaking between
 * paragraphs first, then sentences, then words — never inside a word.
 */
export function chunkForSpeech(paragraphs: string[], maxChars = MAX_TTS_CHARS): string[] {
  const pieces = paragraphs
    .map((paragraph) => paragraph.trim())
    .filter((paragraph) => paragraph.length > 0)
    .flatMap((paragraph) => splitParagraph(paragraph, maxChars));

  // Pack neighbouring short pieces together so the voice keeps its flow.
  const chunks: string[] = [];
  for (const piece of pieces) {
    const last = chunks.at(-1);
    if (last !== undefined && last.length + 2 + piece.length <= maxChars) {
      chunks[chunks.length - 1] = `${last}\n\n${piece}`;
    } else {
      chunks.push(piece);
    }
  }
  return chunks;
}

function splitParagraph(paragraph: string, maxChars: number): string[] {
  if (paragraph.length <= maxChars) return [paragraph];
  const sentences = paragraph.match(/[^.!?]+(?:[.!?]+["'”’)]*\s*|$)/g) ?? [paragraph];
  return packWords(sentences.map((s) => s.trim()).filter(Boolean), maxChars, " ");
}

function packWords(units: string[], maxChars: number, separator: string): string[] {
  const out: string[] = [];
  let current = "";
  for (const unit of units) {
    if (unit.length > maxChars) {
      if (current) out.push(current);
      current = "";
      // A single sentence longer than the limit: fall back to word boundaries.
      out.push(...packWords(unit.split(/\s+/), maxChars, " "));
      continue;
    }
    const candidate = current ? `${current}${separator}${unit}` : unit;
    if (candidate.length > maxChars) {
      out.push(current);
      current = unit;
    } else {
      current = candidate;
    }
  }
  if (current) out.push(current);
  return out;
}
