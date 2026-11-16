import { describe, expect, it, vi } from "vitest";
import { concatAudio, ElevenLabsClient } from "../src/lib/elevenlabs.js";
import { GitHubClient, GitHubError } from "../src/lib/github.js";

describe("GitHubClient", () => {
  it("lists only blobs from the recursive tree and sends the token", async () => {
    const fetchImpl = vi.fn(async () =>
      Response.json({
        truncated: false,
        tree: [
          { path: "src", type: "tree" },
          { path: "src/main.ts", type: "blob", size: 10 },
        ],
      }),
    );
    const github = new GitHubClient("t0ken", fetchImpl as unknown as typeof fetch);
    const tree = await github.tree("o/r", "abc");
    expect(tree.files).toEqual([{ path: "src/main.ts", size: 10 }]);
    const [url, init] = fetchImpl.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toBe("https://api.github.com/repos/o/r/git/trees/abc?recursive=1");
    expect((init.headers as Record<string, string>).Authorization).toBe("Bearer t0ken");
  });

  it("returns null for a missing README and throws GitHubError otherwise", async () => {
    const notFound = new GitHubClient(undefined, (async () => new Response("", { status: 404 })) as typeof fetch);
    expect(await notFound.readme("o/r", "main")).toBeNull();
    const broken = new GitHubClient(undefined, (async () => new Response("", { status: 500 })) as typeof fetch);
    await expect(broken.repository("o/r")).rejects.toBeInstanceOf(GitHubError);
  });
});

describe("ElevenLabsClient", () => {
  it("speaks chunks in order with neighbouring context, retrying 429s", async () => {
    let calls = 0;
    const bodies: { text: string; previous_text?: string; next_text?: string }[] = [];
    const fetchImpl = vi.fn(async (_url: string, init: RequestInit) => {
      calls += 1;
      if (calls === 1) return new Response("", { status: 429 });
      const body = JSON.parse(String(init.body));
      bodies.push(body);
      return new Response(new TextEncoder().encode(body.text));
    });
    vi.useFakeTimers({ shouldAdvanceTime: true, advanceTimeDelta: 500 });
    const client = new ElevenLabsClient("key", "voice", undefined, fetchImpl as unknown as typeof fetch);
    const audio = await client.speakAll(["a", "b", "c"], 2);
    vi.useRealTimers();
    expect(audio.map((bytes) => new TextDecoder().decode(bytes))).toEqual(["a", "b", "c"]);
    expect(bodies.find((body) => body.text === "b")).toMatchObject({ previous_text: "a", next_text: "c" });
    expect(new TextDecoder().decode(concatAudio(audio))).toBe("abc");
  });
});
