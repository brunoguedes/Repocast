import { describe, expect, it } from "vitest";
import cases from "../../shared/fixtures/classification-cases.json" with { type: "json" };
import { classify } from "../src/lib/classify.js";

describe("classify (shared vectors)", () => {
  for (const testCase of cases) {
    it(testCase.name, () => {
      const result = classify(testCase.paths);
      expect(result.classification).toBe(testCase.classification);
      expect(result.manifests).toEqual(testCase.manifests);
      expect(result.entryPoints).toEqual(testCase.entryPoints);
    });
  }
});
