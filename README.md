# codeshape

A standalone bash CLI that scores code health by analyzing repository metrics like complexity, test coverage, and common anti-patterns. It produces JSON output for integration with CI/CD pipelines and engineering dashboards.

## Requirements

- git
- jq
- At least one of: scc, lizard, radon, gocyclo
