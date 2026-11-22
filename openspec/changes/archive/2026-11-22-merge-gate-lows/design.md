# Design

## Context

The merger's green line (`mergeLines` in `.claude/workflows/deliver-change.js`) runs in the delivery's worktree: it records CI green, checks origin, fetches main by its own refspec, stops when a `refs/replace` entry stands, adds a detached worktree of `origin/main` at `tmp/.merge-gates`, runs `git fsck --no-dangling --no-progress origin/main`, and then runs that copy's `tools/gates.sh merge`. Every git of the line is `PINNED_GIT` (no global or system configuration, no hook, `--no-replace-objects`). The store is shared with branch code the checks ran, which can plant loose objects; `tools/agent_guard.sh` admits the line command by command.

Three gaps: the refs/replace stop is `for-each-ref refs/replace | wc -l | grep -q -x -E ' *0'`, whose status is grep's, so a failing for-each-ref passes it; fsck reads the object store, not the copy, so an object planted before the add (whose text the add writes) and swapped back to the true object before the fsck passes it, and so does a copy file rewritten after the add; the comment claims the fsck stops a planted object outright.

## Goals / Non-Goals

Goals: the refs/replace stop fails closed on its own command's failure; main's merge gates run only from a copy whose every tracked file hashed, after the fsck, to the blob main's tree names; the comment and the docs say what each step stops.

Non-goals: the open-pr fork heading, closed by `7cbcf29` (#268) and re-verified (proposal); a same-user process racing the line in the instant after the content check (Risks); `tools/open_pr.sh wait`.

## Decisions

- The refs/replace stop prints a line that only a finished listing prints: `for-each-ref --sort=-refname refs/replace refs/remotes/origin/main | cut -f2 | tr -d '\n' | grep -q -x -F refs/remotes/origin/main`. origin/main exists after the fetch; any `refs/replace/` name sorts after `refs/remotes/` in ascending order, so descending puts every replace entry before origin/main, and the joined output equals origin/main's name only when for-each-ref listed it and nothing else. A failing for-each-ref prints nothing and the grep fails. Alternatives: `set -o pipefail`, which the POSIX `sh` the tests and the merger's line may run under does not have everywhere; a temporary file of the listing, which the merger's guard admits only under its own directory and which adds a write.
- The copy is checked by content, not stat: `git -C tmp/.merge-gates read-tree origin/main && git -C tmp/.merge-gates diff --quiet`. The add's index holds main's blob ids with the stat data of the files it wrote, so a plain `git diff` trusts a file the add wrote from a planted object; `read-tree` without `-m` or `-u` replaces the index with main's tree and no stat data, so `diff` rehashes every tracked file and reports one whose bytes are not its blob (exit 1), a missing one, or its own failure (exit 128). The check runs after the fsck, so the tree it reads was verified a moment before, and right before the gates, so the window for a rewrite shrinks from the fsck's whole run to the gap between two commands. It covers every tracked file, `tools/rules.sh`, `tools/run_state.sh`, and the Makefile the gates read beside `gates.sh` included. Alternative: pipe `git cat-file blob origin/main:tools/gates.sh` into `sh`; rejected, since `gates.sh` sources `rules.sh` and runs `run_state.sh` beside itself, so the whole directory would need the same treatment.
- `tools/agent_guard.sh` admits `git read-tree origin/main` to the merger alone and only with `-C` a worktree `tmp/.NAME`, as it admits `checkout` there: it writes that worktree's index and nothing else. `diff` is a read verb already admitted.
- The tests run the green line's tail as the workflow builds it over real temporary repositories, with a `git` wrapper first on the PATH for the two races (it swaps the planted object back, or rewrites the copy's `gates.sh`, when the fsck runs) and for the failing for-each-ref (it exits 128 for `for-each-ref`). Each fails with the old line: the planted text runs, or the line passes the refs/replace stop and runs main's gates.

## Risks / Trade-offs

- The merger runs as the same user as the branch code the checks ran. A process that outlives the checks and rewrites the copy in the instant between `diff` and the shell's read of `gates.sh`, or swaps a tree object back and forth around the fsck and the read-tree, still wins; the line narrows those windows to single command boundaries, and CI, the reviews, and branch protection stand behind it. Closing it needs a different user or a sandbox for the checks, outside a shell line.
- Untracked files in the copy are not checked: the gates read only tracked paths beside `gates.sh`, and `git worktree add` into a path the line removed first writes no other file.
- `git diff` reads the repository's configuration, which branch code can write: the keys that would steer it (`core.fsmonitor`, `diff.external`, a textconv) are in the guard's `RISKY_CONFIG`, under which it refuses every call, and a key written between the hook and the line is the exposure every git of the line already had; `--quiet` prints no diff, so no external diff or textconv runs.
- The check hashes every tracked file of main once per merge, well under a second at the repository's size.
