# codeshape

![shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnubash&logoColor=white)
![code health](https://img.shields.io/badge/code%20health-9.6-brightgreen)

`codeshape` is a standalone, local-first bash CLI that scores the current
health of a codebase. Inspired by CodeScene's "hotspot" idea, it combines a
per-file complexity score (cyclomatic complexity, function length, argument
count, nesting depth, and duplication, via `scc`/`lizard`/`radon`/`gocyclo`)
with git churn (commits per file in a lookback window) to highlight the files
that are both messy *and* frequently changed — the parts of the codebase most
worth paying down first. It runs entirely against your local working tree (no
network calls, no external services) and emits either a human-readable KPI
summary, a per-file listing, CSV, or a JSON envelope for CI/dashboard
integration.

## Requirements

- `git`
- `jq`
- At least one of: `scc`, `lizard`, `radon`, `gocyclo`

## Usage

```
codeshape [path] [--since N] [--files] [--json|--csv]
  path       subdirectory to scope the scan to (default: repo root)
  --since N  churn lookback window in days (default: 90)
  --files    list per-file scores (worst first) instead of the KPI summary
  --json     machine-readable envelope
  --csv      per-file CSV
```

### `codeshape` (default KPI summary)

```
$ codeshape
Code Health — 60 of 64 files scored
──────────────────────────────────────────
  Hotspot Health : 7.2
  Average Health : 6.4
  Worst          : 1.0  src/mcp-install.sh
  Green/Yellow/Red: 50 / 4 / 6
  Skipped        : 4 files (gitignore, LICENSE, default)
```

### `codeshape --files` (worst-first per-file listing)

```
$ codeshape --files
1.0  R  src/mcp-install.sh
1.0  R  docs/superpowers/plans/2026-07-11-codeshape.md
4.0  R  src/todo-debt.sh
4.2  R  README.md
4.7  R  docs/superpowers/specs/2026-06-16-mcp-server-design.md
...
10.0  G  codeshape/lib/scorer.sh
```

Each line is `SCORE  TIER-INITIAL  path` (`G`reen / `Y`ellow / `R`ed).

### `codeshape --since 180 --json` (JSON envelope, wider churn window)

```
$ codeshape --since 180 --json
{
  "metric": "codeshape",
  "repo": "georgemandis/eng-leader-tools",
  "window_days": 180,
  "generated_at": "2026-07-11T05:29:51Z",
  "data": { "hotspot_health": 7.2, "average_health": 6.4, "worst": {...},
            "tiers": {...}, "coverage": {...}, "files": [...] }
}
```

See [`docs/json-contract.md`](docs/json-contract.md) for the full field
reference, including the error envelope.

## Continuous integration

`codeshape --json` is designed to be gated in CI. Because every failure path
emits a JSON `{error, code}` envelope on stdout, you can parse the result and
fail the build when the codebase's average health slips below a floor.

```yaml
# .github/workflows/code-health.yml
name: code-health
on: [push, pull_request]

jobs:
  codeshape:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0          # codeshape needs history for churn
      - name: Install analyzers
        run: |
          go install github.com/boyter/scc/v3@latest
          pipx install lizard
      - name: Run codeshape
        run: |
          score=$(./codeshape --json | jq -r '.data.average_health // 0')
          echo "Average health: $score"
          awk -v s="$score" 'BEGIN { exit (s < 6.0) }' \
            || { echo "::error::Average health $score is below the 6.0 floor"; exit 1; }
```

Adjust the `6.0` floor to taste, or gate on `.data.hotspot_health` (the
frequently-changed files) or `.data.worst.score` (the single worst file)
instead — see the [JSON contract](docs/json-contract.md) for all fields.

## Configuration

`codeshape` reads a `.codeshaperc` file (shell-sourced `KEY=value` pairs) from
the repo root if present, layered over the built-in defaults in
`config.default`. Any subset of keys may be overridden.

| Key | Default | Meaning |
| --- | --- | --- |
| `T_CCN` | `10` | Cyclomatic complexity threshold — penalized only above this. |
| `T_LEN` | `60` | Function length (lines) threshold. |
| `T_ARGS` | `4` | Function argument count threshold. |
| `T_NEST` | `3` | Nesting depth threshold. |
| `W_CCN` | `0.30` | Points deducted per unit of CCN over `T_CCN`. |
| `W_LEN` | `0.03` | Points deducted per line over `T_LEN`. |
| `W_ARGS` | `0.50` | Points deducted per arg over `T_ARGS`. |
| `W_NEST` | `1.00` | Points deducted per nesting level over `T_NEST`. |
| `W_DUP` | `5.00` | Points deducted per ratio-point of duplication. |
| `TIER_GREEN` | `8` | Minimum score to be classified `green`. |
| `TIER_YELLOW` | `5` | Minimum score to be classified `yellow` (below this is `red`). |
| `CHURN_FLOOR` | `3` | Minimum change count (commits in the `--since` window) for a file to count toward Hotspot Health. |

A file scores 10.0 unless a function inside it exceeds a threshold or the
file has duplicated content; scores are clamped to a 1.0 floor.
