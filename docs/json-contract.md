# codeshape JSON contract

`codeshape --json` (optionally combined with `--since N` or a `path` scope)
emits one JSON object on stdout: either a success envelope or an error
envelope. This document reflects the shipped output of `codeshape/codeshape`
— run `codeshape --json | jq .` against your own repo to see it live.

## Success envelope

```json
{
  "metric": "codeshape",
  "repo": "georgemandis/eng-leader-tools",
  "window_days": 90,
  "generated_at": "2026-07-11T05:29:51Z",
  "data": { ... }
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `metric` | string | Always `"codeshape"`. |
| `repo` | string | `owner/name` parsed from the `origin` remote's GitHub URL if present, otherwise the working tree's directory basename (`basename $(git rev-parse --show-toplevel)`). Empty string if neither is resolvable. |
| `window_days` | number | The churn lookback window used (the `--since` value; default `90`). |
| `generated_at` | string | UTC timestamp, `YYYY-MM-DDTHH:MM:SSZ`. |
| `data` | object | See below. |

## `data` fields

| Field | Type | Notes |
| --- | --- | --- |
| `hotspot_health` | number \| null | Loc-weighted average score of files at or above `CHURN_FLOOR` change count within the window, rounded to 1 decimal. `null` if no file with `loc > 0` meets the churn floor. |
| `average_health` | number \| null | Loc-weighted average score across all scored files with `loc > 0`, rounded to 1 decimal. `null` if there are no such files. |
| `worst` | object \| null | `{ "path": string, "score": number }` for the lowest-scoring file (ties broken by `jq`'s `min_by`, i.e. first match). `null` if no files were scored. |
| `tiers` | object | `{ "green": number, "yellow": number, "red": number }` — counts of scored files in each tier. |
| `coverage` | object | See below. |
| `files` | array | Every scored file, sorted worst-first by score. See below. |

### `coverage`

| Field | Type | Notes |
| --- | --- | --- |
| `scored` | number | Count of files successfully analyzed. |
| `skipped` | number | Count of tracked files that could not be analyzed (no adapter claimed the file, or the file no longer exists on disk). |
| `total` | number | Total tracked files considered (`scored + skipped`, before any `path` scope filtering removes non-matching paths). |
| `skipped_languages` | array of strings | **Accuracy note:** despite the name, this list holds the file **extension** of each skipped file (`"${rel##*.}"` in the shell), not a language name. A file with no extension, or whose "extension" happens to be the whole filename (e.g. `.gitignore`, `LICENSE`, or a file literally named `config.default`), shows up verbatim — e.g. `"gitignore"`, `"LICENSE"`, `"default"`. Treat this field as "file extensions of skipped files," not a language list. |

### `files[]`

Each entry:

| Field | Type | Notes |
| --- | --- | --- |
| `path` | string | Path relative to the repo root (as reported by `git ls-files`). |
| `score` | number | 1.0–10.0, one decimal place. 10.0 is a clean file; the file's score is driven by its single worst-offending function (max CCN, max length, max args, max nesting across all functions in the file) plus a duplication penalty. |
| `loc` | number | Lines of code for the file, from the adapter. |
| `change_count` | number | Commits touching this path in the `--since N` day window (`0` if untouched). |
| `tier` | string | `"green"` if `score >= TIER_GREEN`, `"yellow"` if `score >= TIER_YELLOW`, else `"red"`. |

## Error envelope

On failure, `codeshape --json` emits a single object and exits non-zero:

```json
{ "error": "not inside a git repository (codeshape analyzes the local working tree)", "code": "NOT_FOUND" }
```

| Field | Type | Notes |
| --- | --- | --- |
| `error` | string | Human-readable message. |
| `code` | string | One of the codes below. |

### Codes

| Code | When |
| --- | --- |
| `NOT_FOUND` | Not run inside a git repository. |
| `BAD_ARGS` | `--since` was given a value that isn't a non-negative integer. |
| `DEP_MISSING` | Neither `jq`/`git` (preflight) nor any supported analyzer (`scc`, `lizard`, `radon`, `gocyclo`) is on `PATH`. |

## Non-JSON output modes

`--csv` and `--files` derive from the same `data.files` array documented
above (see `README.md` for example output) and are not covered by this JSON
contract.
