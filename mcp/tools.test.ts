import { test, expect } from "bun:test";
import { TOOL, buildArgs, schemaFor } from "./tools.ts";

test("tool name is codeshape_health", () => {
  expect(TOOL.name).toBe("codeshape_health");
});

test("buildArgs omits directory (it becomes cwd) and orders --since / --files", () => {
  expect(buildArgs({})).toEqual([]);
  expect(buildArgs({ directory: "/repo" })).toEqual([]);
  expect(buildArgs({ directory: "/repo", since: 180 })).toEqual(["--since", "180"]);
  expect(buildArgs({ since: 90, files: true })).toEqual(["--since", "90", "--files"]);
});

test("schemaFor exposes directory/since/files, not repo", () => {
  const shape = schemaFor();
  expect(shape.directory).toBeDefined();
  expect(shape.since).toBeDefined();
  expect(shape.files).toBeDefined();
  expect((shape as Record<string, unknown>).repo).toBeUndefined();
});
