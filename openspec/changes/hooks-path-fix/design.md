# Design

## Context

`make hooks` (#100) set `core.hooksPath` to the absolute `.githooks` of the main worktree. Git runs every hook in that directory, and a checkout writes that directory, so a branch that commits an executable `post-checkout` runs it during the checkout that brings it in; the gate and the guard, which look before and after commands, see it only once it has run. The scout pack `tmp/scout/build-and-ci-bd86828-20261110T231149Z.md` lists the code: the `hooks` target, `gate_origin`, the guard's copy, the hooks, `pr_scan.sh`, and `scan.yml`.

## Goals / Non-Goals

Goals: no hook a checkout can write ever runs; the commit-time scan keeps working in the main worktree and every linked worktree; the hooks and the pull request scan run a scanner the change under test cannot edit. Non-goals: the workflow definition a pull request edits, and recording reviews.

## Decisions

### The hooks are copied into the common hooks directory, and no core.hooksPath is allowed

`make hooks` writes `commit-msg`, `pre-commit`, `scan_text.sh`, and `rules.sh` into `$(git rev-parse --path-format=absolute --git-common-dir)/hooks`, from the blobs at `HEAD`, and unsets `core.hooksPath`. Git never checks out a path under the git directory, and every linked worktree runs the common directory's hooks, so the one directory serves all worktrees and no checkout reaches it. A dedicated directory named by an absolute `core.hooksPath` was the alternative; it keeps a value to compare and an exemption to get right, while git's default directory needs neither, so `core.hooksPath` returns to the plain `RISKY_CONFIG` refusal, which covers a work-tree path, a relative one, and any other. The gate and the guard allow in the hooks directory the samples and the names of `INSTALLED_HOOKS_RE`; anything else, a `post-checkout` above all, is refused as before. Contents are not compared: a later main that changes the hooks would refuse every clone until `make hooks` reran.

### The hooks run the scanner beside them

Each hook runs `sh "$here/scan_text.sh"` with `here` the directory of `$0`, the installed copy, so a commit in a worktree whose `tools/scan_text.sh` differs still scans with the installed one. A status other than 0 or 1 (a missing or broken scanner) refuses the commit with its own message rather than passing silently.

### The pull request scan runs the base's scanner

`scan.yml` checks out the head to `head` with full history and the base commit to `base`, both with `persist-credentials: false`, and runs `sh ../base/tools/pr_scan.sh` from `head`: the script resolves the scanner beside itself, so the base's `scan_text.sh` and `rules.sh` read the head's title, body, messages, and added lines. The workflow file itself still comes from the head under `pull_request`; `pull_request_target` would fix that only by exposing the base's token to the head's text, so it stays out.

## Risks / Trade-offs

- A clone where the #100 target ran keeps `core.hooksPath` until `make hooks` runs again; the gate and the guard refuse it meanwhile, naming `make hooks`, which is the safe direction.
- A branch that changes the hooks or the scanner installs nothing until `make hooks` reruns on a commit that holds the change.
