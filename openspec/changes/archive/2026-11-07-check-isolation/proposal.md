# Proposal

## Why

Four reviews in a row found one cause: the delivery pipeline trusts local git state and run states that branch code, run by the checks in the delivery clone, can write. Make recipes and test programs the checker runs on the branch can rewrite `refs/remotes/origin/main` or `.git/config`, so the merge gates' worktree of `origin/main`, and the hooks reading main's guard, can come from the branch (Medium (6) at e20c83c, Low (4) at 5722559). The same code can write `review.security pass HEAD` into `build/pipeline/CHANGE.json`, which a resumed run accepts, skipping the security review (Medium (5) at 803fe6e, Medium (6) at eb63fb4). And the merge tool has no hook: the merge gates run only because the merger's instructions say so (Medium (6) at 5722559).

The stopped `merge-gate-integrity` delivery closed those paths one at a time and its last review found a fourth (Medium (8) at e368486): the green line's fetch reads `remote.origin.fetch` from a `.git/config` a check stage can write. This change carries its six unpushed commits and removes the cause instead: the check stages run in a throwaway clone.

This change is outside the roadmap of `docs/architecture.md` section 12: it repairs the delivery pipeline (`docs/queue.md` item 1, `check-isolation`).

## What Changes

- `tools/run_state.sh check` runs every stage, and the `make -s stages` that lists them, in a throwaway clone of HEAD made by a fetch into a new repository outside the delivery clone: its own `.git`, refs, configuration with no remote, sample hooks only, and no `build/pipeline`, with `origin/main` copied as a ref. The runner removes it on every exit. The compile outputs and the metrics a later stage or the benchmark reads are carried between checks in `build/stages/CHANGE/carry` and `build/metrics/current.tsv`, never in `build/pipeline`.
- A new `origin` gate of `tools/gates.sh`, first in the `pre-push` and `merge` groups, refuses a repository configuration that sets a key which runs a command or redirects origin (`core.fsmonitor`, `core.hooksPath`, `url.*.insteadOf`, `include.*`, `remote.origin.uploadpack`, and the rest of one list), and, for an `origin/` base, a fetch refspec other than the default, an origin that is a local repository, and an `origin/main` other than origin's `main` as `git ls-remote` reports it.
- `tools/agent_guard.sh` refuses every call of every profile while the repository configuration sets a key of the same list, so no git command an agent runs starts a branch-written command.
- The workflow skips a review, the benchmark, or the check only on a pass this start recorded, never one read from the run state, and builds the merge gates' records from this start's results alone; a resume past the push runs them again at the pushed head.
- The merge gates record `gated`, the head they passed at, through the new `tools/run_state.sh gated` command, cleared at their start and by every push; the merger's hook now also matches the GitHub merge tool, and main's guard refuses a merge whose expected head is not both `pushed` and `gated`, that is not a squash, or while `origin/main` differs from origin's `main`.
- The merger's green line fetches origin before it adds the merge-gates worktree.

## Capabilities

### New Capabilities

None: the change alters the delivery tooling, not the editor's behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

`tools/run_state.sh check`, `tools/gates.sh`, `tools/rules.sh`, `tools/agent_guard.sh`, `tools/run_state.sh`, `tools/tools_test.sh`, `.claude/workflows/deliver-change.js`, `.claude/agents/merger.md`, `.claude/agents/contributor.md`, `README.md`, `docs/codebase-map.md` area 1, and `docs/backlog.md`.

## Out of scope

- The backup refusal and the backup's own gates: `backup-records` (queue item 18) as the planner placed it.
- The merge-gates worktree removal, the stages gate's reader, and the scratch files: `merge-gate-tidy`.
- The gates' fetch of main by a remote and refspec pinned in the run state before branch code runs, and the merge-tool hook reading its guard from that main and refusing when it cannot: queue item 2, `pinned-main`, split from this change by the planner.
- Branch code that writes the delivery clone by an absolute path, the shared toolchain under `tmp/`, and the benchmark's `make` in the delivery clone: the clone separates what a stage writes relative to its directory, not what a process of the same user can reach; recorded in `docs/backlog.md`.

## Assumptions

- Only the repository's own configuration is read (`git config --local`); the user's global configuration, which the session sets up, is not the branch's to write within this threat model, and is left to the clone design.
- This change's own merge runs main's older guard and gates; the merge-tool hook line therefore defers to main's guard only when main's guard judges the merge tool, a clause the backlog entry removes once main holds it.
- The clone shares the toolchain by symbolic links to `tmp/.toolchain` and `tmp/.spinel`, which a check cannot rebuild in reasonable time.
- A pull request merged on GitHub is never re-merged by a resume, so a resume past the push that reruns the reviews costs at most one review round.
