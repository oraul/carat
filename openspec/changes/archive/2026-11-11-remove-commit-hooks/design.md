# Design

## Context

#100 added tracked commit hooks under `.githooks` and a `make hooks` target that pointed `core.hooksPath` at them, with exemptions in the origin gate and the agent guard for that one value. A tracked hooks directory is written by every checkout, so any branch could add a hook git would then run. Three install schemes in hooks-path-fix (PR #101) each opened a new hole, and the user chose removal.

## Goals / Non-Goals

Goals: no hook a checkout can write ever runs; the gates and the guard refuse any `core.hooksPath` again; the pull request scan cannot be weakened by the pull request it scans. Non-goals: another commit-time scan, the replace-refs finding, and the PR #101 bookkeeping.

## Decisions

- Remove, not harden. The commit-time scan was a convenience: the content gate scans every branch commit before the backup, the push, and the merge, and the pull request scan reads the live text, so removing the hooks loses only the earliest feedback. Any hook scheme reads files a checkout writes.
- `core.hooksPath` is a plain `RISKY_CONFIG` key again, with no exemption, in the origin gate and the guard; the planted-hook check keeps the common git directory's hooks folder, which is where git looks once no `core.hooksPath` is set (also for a linked worktree). The content gate's added-hook refusal goes with `HOOKS_PATH`, since a tracked `.githooks` file is inert when no setting names it.
- The scan workflow checks out the base commit (`ref: base.sha`, `path: base`, `persist-credentials: false`) and the pull request (`path: head`, full history, no credentials), and runs `sh ../base/tools/pr_scan.sh` with `working-directory: head`. `pr_scan.sh` already resolves `scan_text.sh` beside itself and `scan_text.sh` sources `rules.sh` beside itself, so all three are the base's while git reads the head's repository. A pull request that edits the scanner is read by the base's until it merges.
- The test of `make toolchain` runs the real target in a clone with `SPINEL_SRC` an empty repository whose origin is a local stand-in with no-op `deps`, `all`, and `install` targets, so it needs no network and no compiler.

## Risks / Trade-offs

- A forbidden line is caught at the backup or the push instead of the commit; the commits are local until then and the branch is squash-merged, so a fix commit suffices.
- The first pull request after this lands is scanned by the base's scanner, which is the same scanner; a change to the scanner's rules takes effect on the pull requests opened after it merges.
