# Proposal

## Why

By the user's decision of 2026-11-21 the code quality review moves into the contributor's own session: after every task of `tasks.md` is done and before the archive, so a finding becomes one more OpenSpec task fixed in the same session instead of a separate reviewer start and a fix round. The delivery's quality reviewer phase, its rework rounds, and its first-pass verdict leave the workflow; the security review stays exactly as it is, and the sprint's combined-diff quality review and the skeptic become the independent quality check. It folds backlog Pool 9's `closing-loop-fold`: the quality rounds that item would trim are removed.

## What Changes

- The contributor's quality step: once every task is done and before the archive, it reviews the whole committed diff with `.claude/agents/quality-reviewer.md`'s instructions, appends each finding as a task under a `Quality review` heading of `tasks.md`, fixes those tasks, and appends any finding it will not fix to `docs/findings/<change>.md` with its reason. `openspec/config.yaml` carries it as `operations.apply.guidance` and `operations.archive.guidance`; rule 10 of the contributor's card (agent file and `CONTRIBUTOR_CARD`) becomes this step.
- The contributor's result gains `quality_review` (`status: done` and the counts `added`, `fixed`, `recorded`); an implement start that finishes the tasks without a well-formed one is refused and restarted once, a second refusal stopping the run, and the archive and package step runs only once a quality review is recorded (`metric.quality_review`), a resume without one first asking one implement start for the step.
- `.claude/workflows/deliver-change.js` starts no quality reviewer in a delivery: no quality phase, review, rework round, first-pass verdict, carried review, or `quality_blocked` figure; the reviews are the security review alone. The pull request text check stays as it is: it is a start of the quality-reviewer agent (`quality-reviewer: pull request text`) after the push, removing it is not required, and it blocked a claim in `tabs-only-dot`.
- The merge gate `passed` (`tools/gates.sh`) requires the check, security, and bench passes, no longer a quality review, which no delivery records any more.
- Docs: CLAUDE.md's Agents phases line, README.md's pipeline steps, `docs/goals.md` (the quality first pass, review-lite, escalation, judgment starts), `docs/contributor-notes.md` (Self-review, Closing), and the quality reviewer's use line (sprint close and the contributor's step).
- Tools-test: a delivery starts no quality-reviewer but the text check, a result without a quality review is refused before the archive, the security reviewer still runs and blocks, and sprint-planning still starts its quality review.

Out of scope: `tools/rules.sh`, every feature-lane file (`docs/queue-feature.md`, `docs/metrics-feature.tsv`), `.claude/workflows/sprint-planning.js` and `periodic-review.js` (unchanged), the run state's phase and review kinds (`quality` stays readable for older runs and the periodic reviews), and `docs/queue-backlog.md`: the Sprint 25 exception line and the removal of `closing-loop-fold` come from the planner's queue, which `plan-apply` copies at the package step.

Roadmap: outside the roadmap of `docs/architecture.md` section 12; a delivery-process change the user decided.

Assumptions: this run itself still runs the workflow loaded at its start, so its own delivery has a quality reviewer phase and main's merge gate requires its pass; the new rules apply from the next delivery. The history's `first_pass` column simply carries no `quality` entry from now on (no verdict is recorded), older rows keep theirs, and the rates read whatever a row holds.

## Capabilities

### New Capabilities

None: pipeline tooling (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

`.claude/workflows/deliver-change.js`, `.claude/agents/contributor.md`, `.claude/agents/quality-reviewer.md`, `openspec/config.yaml`, `tools/gates.sh`, `tools/tools_test.sh`, `CLAUDE.md`, `README.md`, `docs/goals.md`, `docs/contributor-notes.md`.

- CLAUDE.md: changed, the Agents phases line.
- README.md: changed, the pipeline steps.
- docs/architecture.md: unchanged, it describes the editor and names no delivery phase.
