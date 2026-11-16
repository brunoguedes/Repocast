export interface SpeechRequest {
  text: string;
  previousText?: string;
  nextText?: string;
}

/**
 * ElevenLabs' standard text-to-speech endpoint is synchronous: one request,
 * one MP3 back. `previous_text` / `next_text` keep prosody continuous across
 * chunk boundaries.
 */
export class ElevenLabsClient {
  static readonly outputFormat = "mp3_44100_128";

  constructor(
    private readonly apiKey: string,
    private readonly voiceId: string,
    private readonly modelId = "eleven_multilingual_v2",
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  async speak(request: SpeechRequest, attempt = 0): Promise<Uint8Array> {
    const url = `https://api.elevenlabs.io/v1/text-to-speech/${this.voiceId}?output_format=${ElevenLabsClient.outputFormat}`;
    const response = await this.fetchImpl(url, {
      method: "POST",
      headers: { "xi-api-key": this.apiKey, "Content-Type": "application/json", Accept: "audio/mpeg" },
      body: JSON.stringify({
        text: request.text,
        model_id: this.modelId,
        previous_text: request.previousText,
        next_text: request.nextText,
      }),
    });
    if ((response.status === 429 || response.status >= 500) && attempt < 4) {
      await new Promise((resolve) => setTimeout(resolve, 1000 * 2 ** attempt));
      return this.speak(request, attempt + 1);
    }
    if (!response.ok) {
      const body = await response.text().catch(() => "");
      throw new Error(`ElevenLabs ${response.status}: ${body.slice(0, 200)}`);
    }
    return new Uint8Array(await response.arrayBuffer());
  }

  /** Speaks every chunk with at most `concurrency` requests in flight, keeping order. */
  async speakAll(chunks: string[], concurrency = 2): Promise<Uint8Array[]> {
    const results: Uint8Array[] = new Array(chunks.length);
    let next = 0;
    const worker = async () => {
      while (next < chunks.length) {
        const index = next++;
        results[index] = await this.speak({
          text: chunks[index]!,
          previousText: chunks[index - 1],
          nextText: chunks[index + 1],
        });
      }
    };
    await Promise.all(Array.from({ length: Math.min(concurrency, chunks.length) }, worker));
    return results;
  }
}

/** Concatenates same-encoding MP3 frames into one playable file. */
export function concatAudio(pieces: Uint8Array[]): Uint8Array {
  const out = new Uint8Array(pieces.reduce((sum, piece) => sum + piece.length, 0));
  let offset = 0;
  for (const piece of pieces) {
    out.set(piece, offset);
    offset += piece.length;
  }
  return out;
}
