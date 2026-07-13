import { z } from "zod";

export const TOOL = {
  name: "codeshape_health",
  description:
    "Score the current health of a local codebase — a CodeScene-style 1–10 " +
    "deduction score per file, rolled up to Hotspot Health, Average Health, " +
    "and the worst file. Analyzes the working tree; needs an analyzer (scc/lizard) installed.",
};

export function buildArgs(params: Record<string, unknown>): string[] {
  const args: string[] = [];
  if (params.since !== undefined && params.since !== null) {
    args.push("--since", String(params.since));
  }
  if (params.files === true) args.push("--files");
  return args;
}

export function schemaFor(): Record<string, z.ZodTypeAny> {
  return {
    directory: z.string().optional()
      .describe("Path to the local git repository to analyze (defaults to the server cwd)"),
    since: z.number().optional().describe("Churn lookback window in days (default: 90)"),
    files: z.boolean().optional().describe("Return per-file scores instead of the KPI summary"),
  };
}
