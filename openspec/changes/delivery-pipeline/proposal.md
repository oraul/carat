# Proposal

## Why

The contributor agent carries the whole delivery loop in its instructions, and every rule it must keep (the single trailer, no URL or email or model name, one push, the footer strip, the security review, snapshots through `make`, the map and docs kept current) is held only in its memory. Five ad hoc progress formats under `build/stages/` show that each run reinvented its bookkeeping, `make check` and CI disagree on their stages without a recorded reason, the analysis budget of `bin/carat.rb` is checked by neither, and the security review has no gate at all. The user asked for a deterministic development pipeline "where you won't forget", started by a command, with the security review as the most important step, code quality checked, and fewer tokens spent. This is the first of three planned changes; `authoring-kit` and `planner-and-metrics` follow.

## What Changes

- Add `.claude/workflows/deliver-change.js`, a workflow with fixed phases, each one agent call with a schema-checked result: scouts per map area (reusing current packs), the contributor (propose and apply, committing early), the checker, the quality reviewer, the security reviewer (never skipped; a High or Medium finding at confidence 8 or above goes back to the contributor and the checker and reviewers run again), the benchmark agent, the contributor again to archive, push once, and open the pull request, the CI watcher, the merger, and the reporter. It reads the run state on start and resumes from it.
- Add seven narrow agents under `.claude/agents/`: `checker`, `quality-reviewer`, `security-reviewer`, `benchmark`, `ci-watcher`, `merger`, `reporter`, each with only the tools it needs and no `model:` setting.
- Add `tools/run_state.sh`, the one writer of the run state `build/pipeline/<change>.json` (phases done, commit, stage results, reviews, pushes, pull request, CI) and of stage logs under `build/stages/<change>/`, replacing the five ad hoc formats; it runs the canonical stage list, resuming at the first stage not passed at the current commit, and pushes only when the gates pass.
- Add `tools/gates.sh` and `make gates`: the single trailer on every branch commit; no URL, email (but the trailer), model name, or session id in the diff, commit messages, or pull request body; one push plus one per CI fix; no footer in the pull request body and the template's shape; the security review recorded at the reviewed commit; changed snapshots matching the runner; the code map, `CLAUDE.md`, and the README updated when files, targets, or the process change.
- Make one canonical stage list, `CHECK_STAGES` in the Makefile, that `make check` and the checker run and CI mirrors with recorded reasons for each difference: `make dev-build` now checks the analysis budget of `bin/carat.rb` from its own report, `make config-current` diffs the plugin registry as well as the config mirror (in CI too), and `make tools-test` tests `tools/ci_scope.sh`, the run state, and the gates.
- Add the slash commands `/deliver` and `/status` under `.claude/commands/`.
- Reshape `.claude/agents/contributor.md` around the phases: it implements and packages; the other agents own checks, quality, security, benchmarks, CI, and merge. Resolve its conflicts: one push plus one per CI fix, the gates instead of a checklist `CLAUDE.md` lacks, and a run of the contributor or `/deliver` counts as being asked for the pull request and the merge.
- Put security first in the hard rules of `CLAUDE.md`, and update its Agents and Commands sections, the code map, and the README (a section on how carat is built with AI) within their current size.
- Remove the URL from the `spinel-rev` target: a branch or tag name resolves through the toolchain checkout's remote.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a tooling, agent, and documentation change with no change to the editor's behavior; `skip_specs` is set.

## Impact

- New: `.claude/workflows/deliver-change.js`, seven files under `.claude/agents/`, `.claude/commands/deliver.md` and `status.md`, `tools/run_state.sh`, `tools/gates.sh`, `tools/tools_test.sh`.
- Changed: `Makefile` (`CHECK_STAGES`, `stages`, `config-current`, `gates`, `tools-test`, `dev-build`, `check`, `spinel-rev`), `.github/workflows/ci.yml`, `.claude/agents/contributor.md`, `CLAUDE.md`, `docs/codebase-map.md`, `README.md`.
- No file under `carat/`, `bin/`, `test/`, or `bench/` changes; the editor binary is unchanged.

This change is outside the roadmap of `docs/architecture.md` section 12: it is a tooling change to the delivery process that the user asked for before more features.

Out of scope: golden examples, generators, Spinel notes, and the docs size gate (`authoring-kit`); the planner, goals, the queue, the metrics history, the retrospective, and periodic reviews (`planner-and-metrics`); any change to the generated OpenSpec commands and skills; the scout's existing `model:` setting, which stays as it is.

Assumptions recorded instead of asked:

- This change cannot be delivered through the workflow it creates, so it is delivered the current way, with the new gates run once on its own branch before the push and their output in the pull request.
- The run state is one flat JSON object with string values, one key per line, so a POSIX shell script can write it without a JSON tool and an agent can read it with `cat`.
- CI cannot run the gates: a pull request's checkout is a merge commit with two levels of history and no run state. The checker runs them before the push and the merger before the merge.
- `/status` reads the queue `docs/queue.md` and the metrics `docs/metrics.tsv` when they exist; `planner-and-metrics` creates them.
