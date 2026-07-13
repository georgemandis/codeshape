import { spawn } from "node:child_process";

export function runCodeshape(args: string[], cwd?: string): Promise<unknown> {
  return new Promise((resolve, reject) => {
    const bin = process.env.CODESHAPE_BIN || "codeshape";
    const child = spawn(bin, [...args, "--json"], { cwd });
    let out = "", err = "";
    child.stdout.on("data", (d) => (out += d));
    child.stderr.on("data", (d) => (err += d));
    child.on("error", reject);
    child.on("close", () => {
      try {
        const parsed = JSON.parse(out);
        if (parsed && parsed.code) reject(new Error(`[${parsed.code}] ${parsed.error}`));
        else resolve(parsed);
      } catch {
        reject(new Error(err || "codeshape produced no parseable JSON"));
      }
    });
  });
}
