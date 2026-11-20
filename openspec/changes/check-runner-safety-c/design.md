# Design

## Context

`escape_mark` notes the time, the common configuration, and the run state once the check clone is made; `escaped_paths` lists, once every stage passed, what changed since outside the clone, and any line fails the check. In a lane, `top` is the lane worktree under the main checkout's `tmp/`, `git_dir` the lane's git directory, `common_dir` the main checkout's `.git`. The scan never read the main checkout's work tree (pruned as `tmp/` from the main checkout's side, absent from the lane's side), the common `refs/`, `packed-refs`, `info/`, or the global configuration, while it read the lane's whole git directory, index included, which any `git status` in the lane rewrites when a tracked file's stat changed.

What else writes these during a lane's check, and must leave it passing: another lane's commits, fetches, pushes, and `lane-open` (its branch, the remote-tracking refs, `worktrees/`, `objects/`); and the merger closing another lane, which in the main checkout runs `lane-close` (the worktree removed, its branch kept), `git checkout -q main && git merge -q --ff-only origin/main` (the main checkout's tracked files, index, and branch), and `git branch -D` (`.claude/agents/merger.md`, step 7).

## Decisions

- The delivery clone's `find` becomes `tree_scan DIR [TEST...]`, the same prune list, the tests passed to `find`.
- The main checkout (the work tree of a common directory named `.git` that is not `top`) is checked by what a fast-forward leaves alone, not by time alone:
  - `main_scan`: its paths changed since the mark (`tree_scan ... ! -type d`), less the files it tracks at the scan, which a fast-forward rewrites; an untracked or ignored file a stage writes stays listed. Directories are left out, since a fast-forward adding or removing a file changes its directory's entry.
  - `main_view`: `git status --porcelain --untracked-files=all` (the index against HEAD, the work tree against the index, the untracked files) and the `ls-files -v` entries carrying a flag (assume-unchanged, skip-worktree), which hides a change from the status, read with no optional lock. A fast-forward of a clean checkout leaves it clean; a tracked file written, a staged entry, or a flag set changes it.
  - `main_moved`: its HEAD's commit at the scan is the mark's or its branch's remote-tracking ref, where the fast-forward takes it; anything else (a reset, a commit) fails.
- References are compared, not scanned by time: `refs_view` lists `git for-each-ref` (name and object) less `refs/remotes/`, which a fetch or push of any lane writes and the next fetch restores; less the branches checked out in a linked worktree other than `top` and the main checkout (`lane_branches`) at the mark or at the scan, so a lane's commit, its close with its branch kept, and the merger's deletion pass; and from a lane less the main checkout's branch, which `main_moved` checks. `main`, a tag, a replacement ref, or a new branch written by a stage fails the check as "COMMON/refs: the references changed".
- `$common_dir/info` and `$HOME/.gitconfig` (when `HOME` is set) go through `escape_scan`: nothing in the pipeline writes them during a check.
- The lane's git directory is scanned with `-mindepth 1` and its `index` and `index.lock` pruned, since an index refresh renames `index.lock` over `index`, changing the directory's own entry too. The delivery clone's index is compared instead by `index_view`, `git ls-files --stage -v` with no optional lock (mode, object, stage, path, and the flag tag), so a stat refresh passes and a staged entry or flag a stage writes fails as "INDEX: the staged files changed".
- A deletion in the lane's git directory changes only its directory's entry, which the scan now leaves out; the files that matter there (`HEAD`, the index) are compared by `head_commit` and `index_view`, and a deleted `gitdir` or `commondir` breaks only the lane.

## Risks

- A person writing the main checkout's untracked files, a tag a fetch brings, or `$HOME/.gitconfig` during a lane check fails it, which a rerun clears; the pipeline writes none of them while a check runs (its run states, stage logs, plans, scouts, and lanes are pruned or ignored).
- The remote-tracking refs stay unchecked, and so a stage could forge `origin/main` and fast-forward the main checkout to it: the forged ref lasts until the next fetch, which `run_state.sh push` and `merge-main` run first, and the merger's next `merge --ff-only origin/main` then fails on it rather than passing.
