# codeshape — session handoff

Pick-up notes for resuming work in a fresh session. Last updated 2026-07-30.

## What this is

`codeshape` is a standalone, local-first bash CLI (+ Bun/TypeScript MCP server)
that scores the current health of a codebase — a CodeScene-inspired **deduction
score** (start at 10, subtract weighted penalties for complexity / function
length / arg count / nesting / duplication, clamp to [1,10]) computed over
**pluggable analyzer adapters** (`scc`/`lizard`/…), weighted by **self-derived
git churn**, rolled up to three project KPIs (Hotspot Health, Average Health,
Worst Performer). It's the third measurement axis alongside two sibling tools:

| Tool | View | Question |
|---|---|---|
| engleader.tools | manager / GitHub API | How is the team shipping? |
| engsight | IC / git-hook events | How am I working? |
| **codeshape** | **the artifact itself** | **What shape is the code in?** |

## Current status — DONE and shipped

- **Repo:** https://github.com/georgemandis/codeshape (public)
- **Local:** `/Users/georgemandis/Projects/engleader.tools/codeshape` (sibling to
  `engleader-tools-scripts`), branch `main`, working tree clean, fully pushed.
- **13 commits.** Built via TDD across 8 tasks (subagent-driven development):
  scaffold+envelope helpers, config+loader, scorer, scc adapter, lizard adapter,
  churn+aggregator+CLI, test runner+docs, MCP server — plus a reconciliation
  fix and a chore commit (license/badge/CI).
- **Tests green:** bash suite (adapters/cli/common/config/scorer) + MCP
  (`bun test`). Run everything with `bash test/run.sh` and `cd mcp && bun test`.
  Analyzers must be on PATH: `export PATH="$HOME/.local/bin:$PATH"` — `scc`
  (brew) and `lizard` (pip, at ~/.local/bin) are installed on this machine.
- **CI:** `.github/workflows/code-health.yml` ran and PASSED on the last push
  (gates the build at a 6.0 average-health floor; also updates the badge gist).
- **Live self-score:** ~9.2 average health (it's clean code).

## The ONE open action

**Set the `GIST_TOKEN` repo secret** so the live README badge auto-updates.
It is currently NOT set — the workflow's badge step skips cleanly without it
(CI stays green), so the badge is frozen at its last value (~9.2).

To enable:
1. Create a classic PAT with ONLY the `gist` scope: https://github.com/settings/tokens
2. `gh secret set GIST_TOKEN --repo georgemandis/codeshape`  (paste the token)

Badge gist: `d0fe45659b9ea460cd4e74b3629e10e7` (file `cs_badge.json`), rendered
via a shields.io endpoint in the README.

## Open follow-ups (all optional, none blocking)

1. **GIST_TOKEN** — above. The only thing preventing the badge from being fully live.
2. **Badge metric choice** — badge + CI gate both use `average_health`. Switching
   to `hotspot_health` (frequently-changed files — arguably the more honest
   "getting worse" signal) is a one-line change in the README endpoint's source
   data + the workflow. Left on average for now.
3. **Known Minor (cosmetic):** the human KPI summary prints `10` where the JSON
   emits `10.0`. Purely display; JSON contract is correct. Fix opportunistically.
4. **First-CI-run watch:** the workflow installs `scc` via `go install
   github.com/boyter/scc/v3@latest` and `lizard` via `pipx`. It passed once; if
   scc's install path drifts, that install step is the likeliest thing to tweak.

## Design docs (kept OUT of the public repo history)

The design spec and implementation plan were deliberately scrubbed from this
repo's git history (they're internal process artifacts). They still live in the
**engleader.tools** repo on `main` as a historical breadcrumb:
- `~/Projects/engleader.tools/engleader-tools-scripts/docs/superpowers/specs/2026-07-08-codeshape-design.md`
- `~/Projects/engleader.tools/engleader-tools-scripts/docs/superpowers/plans/2026-07-11-codeshape.md`

(The SDD progress ledger + per-task reports from the build live under that repo's
git-ignored `.superpowers/sdd/` scratch dir — reference only, not needed to resume.)

## Layout

```
codeshape            # the CLI executable (bash)
config.default       # default thresholds/weights/tiers (overridable via .codeshaperc)
lib/                 # _common.sh (envelopes), config.sh, scorer.sh, adapters.sh
mcp/                 # tools.ts + tools.test.ts, runner.ts, index.ts, package.json
test/                # *.test.sh + run.sh
docs/json-contract.md
README.md            # usage, CI example, config table, badges
LICENSE              # MIT (George Mandis, 2026)
```

## Sibling context

- engleader.tools: `~/Projects/engleader.tools/engleader-tools-scripts`
- engsight: `~/Projects/recurse/2026/engsight`
- codeshape shares their conventions (JSON `{error,code}` envelopes, MCP ToolDef
  shape) but has ZERO runtime coupling — it derives its own churn from `git log`.
