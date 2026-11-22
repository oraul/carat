# Backlog: .github/workflows/main.yml

### The compile cache key is written three times across the CI workflows

- Location: .github/workflows/main.yml:52
- Why: the key expression is written twice in main.yml (probe and restore) and again in ci.yml, so a drift silently makes the probe never hit (every push compiles) or pull requests miss main's units (quality advisory, ci-time-tidy-b).
- Fix: compute the key once in a step output used by both steps, and add a tools_test case that the key text in ci.yml equals main.yml's.
- Category: pipeline
- Added: 2026-11-16

### The check steps of main.yml are copied from ci.yml

- Location: .github/workflows/main.yml:95
- Why: the check steps (doctor, no-cruby, docs-lint, tools, config-current, test) are copied from ci.yml, so a check added to one workflow is easily missed in the other (quality advisory, ci-time-tidy-b).
- Fix: a tools_test case that every check step name of main.yml exists in ci.yml with the same run line, or a composite action both jobs use.
- Category: pipeline
- Added: 2026-11-16

### The main workflow's compile probe ignores the measurement tool

- Location: .github/workflows/main.yml:47
- Why: the probe keys only on Ruby sources, so an equal-tree push that changes only tools/metrics.sh or the Makefile's budgets skips main's measurement and pull requests keep comparing with one made by the old tool; the design names build flags only (quality advisory, ci-time-tidy-b).
- Fix: add hashFiles of Makefile and tools/metrics.sh to the compile cache key in both workflows, or probe the measurement entry separately.
- Also: tools/metrics.sh, Makefile
- Category: pipeline
- Added: 2026-11-16

### A redundant ref test in the main workflow's Keep and Save steps

- Location: .github/workflows/main.yml:151
- Why: the Keep and Save steps test github.ref == 'refs/heads/main' beside github.event_name == 'push', which the main-only push trigger already implies (quality advisory, ci-time-tidy-b).
- Fix: drop the ref test.
- Category: pipeline
- Added: 2026-11-16

### The main workflow skips the release build on a build-input-only equal-tree merge

- Location: .github/workflows/main.yml:47, tools/ci_scope.sh:45, .github/workflows/main.yml:155 (sprint-8 review, quality blocking, and security Low (5)); queued as `ci-workflow-tidy`.
- Why: the compile gate reads a lookup-only probe keyed on the .rb sources only, so an equal-tree squash merge that changes only the Makefile, tools/metrics.sh, bench/, spin.toml, or config/ skips the release build, its smoke test, and main's measurement; pull requests never build the release binary, so a broken `make build` merges unbuilt, where every push to main built it before sprint 8.
- Fix: in the equal-tree branch still list the squash commit's paths and compile when one is a build input; a tools-test case for a Makefile-only equal-tree push with cached units.
- Also: tools/ci_scope.sh, Makefile, tools/metrics.sh, spin.toml
- Category: security
- Added: 2026-11-16

### The compile-cache key is written three times at .github/workflows/main.yml:52 (sprint-28 sweep quality, note 53)

- Location: .github/workflows/main.yml:52, :91; .github/workflows/ci.yml:101
- Why: the probe means something only while it equals the restore key.
- Fix: compute the key once per job and reuse it.
- Also: .github/workflows/ci.yml
- Category: pipeline
- Added: 2026-11-22
