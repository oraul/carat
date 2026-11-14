# Proposal

## Why

Main's CI run 246 at b05069d failed in its scope step: `tools/ci_scope.sh` stored a GitHub 5xx error body (multi-line JSON, `{"message": "Server Error"}`) from an unchecked `gh api` answer in `$number`, and `answer` wrote it into the reason line of `GITHUB_OUTPUT`, whose format a line break breaks. The script's header promises that anything it cannot establish, a failed API call included, runs the checks; an answer that is not the value asked for broke that promise. This change is the queue's T0 item `ci-scope-errors` (a red main); it is outside the roadmap of `docs/architecture.md` section 12: it is CI tooling.

## What Changes

- Every `gh api` answer in `tools/ci_scope.sh` is validated before use: a pull request number must be digits only, a commit or tree sha lowercase hex only, a count digits only. Any other answer, an error body included, is treated as unknown, which runs the checks: the push skip needs a valid head sha, pull request number, tree sha, and a count above zero.
- `answer` writes the reason on a single line whatever it is given (line breaks become spaces), so `GITHUB_OUTPUT` always holds exactly one `run=` and one `reason=` line.
- `tools/tools_test.sh` gains cases with a stubbed `gh` that prints the error body and fails: on a push whose number query fails, and on a push where every query fails, each asserting `run=true` and a well-formed `GITHUB_OUTPUT`.

Out of scope: any other change to what `ci_scope.sh` skips or runs; `.github/workflows/ci.yml`; the planner's placements named in the brief (the planner's queue, applied at the package step); `docs/backlog.md`, which the package step only appends to.

Assumptions:

- A valid answer from the query that failed in run 246 means the push skip still applies as before; only an answer that is not a number, sha, or count changes the outcome, to running the checks.
- The single-line reason in `answer` is defense in depth: after validation no gh answer reaches the reason with a line break, and git quotes a path with a line break in `--name-only` output, so no test drives it through the script's interface; the tools-test cases check the file's format.

## Capabilities

### New Capabilities

None: the change is CI tooling and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `tools/ci_scope.sh`, `tools/tools_test.sh`.
- CLAUDE.md: unchanged, no command, agent, workflow, or gate changes.
- README.md: unchanged, no user-visible change.
- docs/architecture.md: unchanged, section 10 does not describe the scope step's answers.
- docs/codebase-map.md: unchanged, no file is added, moved, or removed.
