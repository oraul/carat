# Design

## Context

`escape_mark` notes the time, the common configuration, and the run state once the check clone is made; `escaped_paths` lists, once every stage passed, what changed since outside the clone, and any line fails the check. In a lane, `top` is the lane worktree under the main checkout's `tmp/`, `git_dir` the lane's git directory, `common_dir` the main checkout's `.git`. The scan never reads the main checkout's work tree (pruned as `tmp/` from the main checkout's side, absent from the lane's side), the common `refs/`, `packed-refs`, `info/`, or the global configuration, while it reads the lane's whole git directory, index included, which any `git status` in the lane rewrites when a tracked file's stat changed.

## Decisions

- The delivery clone's `find` becomes `tree_scan DIR`, the same prune list, run over `top` and, when the common directory is a `.git` whose work tree is not `top` (a lane), over that work tree, the main checkout. The lane itself sits under the main checkout's `tmp/`, which is pruned, so the two scans do not overlap.
- References are compared, not scanned by time: concurrent lanes write the common `refs/` and `packed-refs` all the time (their commits, fetches, pushes, `pack-refs`). `refs_view` lists `git for-each-ref` (name and object) less `refs/remotes/`, which a fetch or push of any lane writes and the push's fetch restores, and less the branches checked out in a linked worktree other than `top` and the main checkout, which their own lanes commit to; the main checkout's branch and `top`'s own stay compared, so `main`, a tag, a replacement ref, or a new branch written by a stage fails the check as "COMMON/refs: the references changed".
- `$common_dir/info` and `$HOME/.gitconfig` (when `HOME` is set) go through `escape_scan`: nothing in the pipeline writes them during a check.
- The lane's git directory is scanned with `-mindepth 1` and its `index` and `index.lock` pruned, since an index refresh renames `index.lock` over `index`, changing the directory's own entry too. What an index holds is then compared instead: `index_view DIR` is `git ls-files --stage -v` with no optional lock (mode, object, stage, path, and the assume-unchanged tag), for `top` and, in a lane, the main checkout, so a stat refresh passes and a staged entry or flag a stage writes fails as "INDEX: the staged files changed". The main checkout's index is compared too, as part of the main checkout, though its file was never scanned.
- A deletion in the lane's git directory changes only its directory's entry, which the scan now leaves out; the files that matter there (`HEAD`, the index) are compared by `head_commit` and `index_view`, and a deleted `gitdir` or `commondir` breaks only the lane.

## Risks

- The main session or a person writing the main checkout's work tree, a tag a fetch brings, or `$HOME/.gitconfig` during a lane check fails it, which a rerun clears; the pipeline itself writes none of them while a check runs (its run states, stage logs, plans, scouts, and lanes are pruned).
- The remote-tracking refs stay unchecked: a forged one lasts until the next fetch, which `run_state.sh push` and `merge-main` run first.
