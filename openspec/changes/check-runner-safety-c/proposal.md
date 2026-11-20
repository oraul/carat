# Proposal

## Why

The check's escape scan (`escaped_paths`, `tools/run_state.sh:1035` at c7c9f84) fails a check whose stage wrote outside its clone by an absolute path, but in a lane it reads only the lane worktree, the lane's git directory, the common directory's hooks, `config.worktree`, and configuration, and the shared toolchain. A stage can still write the main checkout's files, the common git directory's references (a branch, a tag, a replacement ref) or its `info/` (excludes, attributes, grafts), or the user's global git configuration, `$HOME/.gitconfig`, and the check passes. The other half is a false failure: the scan of the lane's whole git directory (`:1039`) lists the lane's index when any `git status` refreshes it during the check, so a check fails though no stage wrote anything.

This is a pipeline defect (security Medium) outside the roadmap of `docs/architecture.md` section 12, run first in Sprint 22's backlog lane by the user-approved exception line under its heading.

## What Changes

- `tools/run_state.sh`, `escaped_paths`, `tree_scan` (new): the delivery clone's `find` becomes `tree_scan`, the same parts left out (its `.git`, `tmp/` with the lanes, and the run states, stage logs, plans, and compile cache).
- `tools/run_state.sh`, `main_scan`, `main_view`, `main_moved` (new): from a lane the main checkout (the common directory's work tree) is checked: its untracked files changed during the check (`tree_scan`, directories and tracked files left out), its status against its HEAD and its flagged index entries, and its HEAD, which may move only to its branch's remote-tracking ref, so the merger's close of another lane (`git checkout main && git merge --ff-only origin/main`) leaves the check passing.
- `tools/run_state.sh`, `refs_view`, `lane_branches` (new): the common directory's references are compared by their listing (name and object), less the remote-tracking refs, which a fetch or push of any lane rewrites and the next fetch restores, the branches checked out in another linked worktree at the mark or at the scan, which their lanes commit to and the merger deletes, and from a lane the main checkout's branch (`main_moved`).
- `tools/run_state.sh`, `escaped_paths`: the common directory's `info/` and `$HOME/.gitconfig` are scanned like the hooks.
- `tools/run_state.sh`, `escaped_paths`, `index_view` (new): the lane's git directory is scanned without its `index` (and `index.lock`) and without its own entry, and the delivery clone's index is compared by its staged entries (`git ls-files --stage -v`), so a stat refresh passes and a staged change fails.
- `tools/run_state.sh`, `escape_mark`: notes the main checkout, its branch, HEAD, and state, the lanes' branches, the references, and the staged entries beside the configuration.
- `tools/tools_test.sh`: a lane check fails for a stage writing a tracked or an untracked file of the main checkout, staging into its index or the lane's, moving its HEAD, writing the common `info/`, a common reference, or `$HOME/.gitconfig`; it passes with a lane index refresh, another lane's commit, a lane's worktree removed with its branch kept, and the main checkout's branch fast-forwarded to its remote-tracking ref during it.

## Capabilities

### New Capabilities

None: the change alters the delivery tooling (`skip_specs: true`).

### Modified Capabilities

None.

## Out of scope

- No `tools/rules.sh` edit; no file of the feature lane.
- The XDG global configuration (`~/.config/git/config`), and the main checkout's `HEAD` switched to another branch at the same commit (`main_moved` compares the commit only): not in the queue item, recorded in `docs/findings/check-runner-safety-c.md`. The common `objects/`, which every lane writes, stay unscanned, and so do the remote-tracking refs (Design, Risks).
- A stage that deletes a file of the lane's git directory leaves no entry with a new status-change time once its directory's own entry is left out; such a deletion breaks only the lane itself.

## Impact

- README.md: the checker paragraph names what the scan covers, now the main checkout, the common references, `info/`, and staged files, and the global git configuration, and what concurrent work leaves it passing.
- docs/codebase-map.md: area 1's `tools/run_state.sh` entry names `tree_scan`, `main_scan`, `main_view`, `main_moved`, `refs_view`, `lane_branches`, and `index_view`.
- CLAUDE.md: unchanged, it does not describe the check's scan, and no command, agent, or rule changes.
- docs/architecture.md: unchanged, no layer, port, or module is touched.
