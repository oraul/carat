### Security: a check's escape scan leaves the XDG global git configuration and the main checkout's HEAD out

- Location: `tools/run_state.sh`, `escaped_paths` and `refs_view`.
- Why: git also reads `${XDG_CONFIG_HOME:-$HOME/.config}/git/config` as global configuration (a hook path, an alias, a credential helper), and `refs_view` lists `for-each-ref`, which leaves out the common directory's `HEAD`, so a stage writing either by an absolute path still passes the check; the queue item named only `$HOME/.gitconfig` and the references.
- Fix: `escape_scan` the XDG configuration file beside `$HOME/.gitconfig`, and add `git -C "$main_tree" symbolic-ref -q HEAD || git -C "$main_tree" rev-parse HEAD` to the compared views from a lane, each with a failing-stage case in `tools/tools_test.sh`.

### Security: a check leaves the remote-tracking refs unchecked, so a stage can forge origin/main for the next lane

- Location: `tools/run_state.sh`, `refs_view` and `main_moved`.
- Why: `refs_view` leaves out `refs/remotes/`, which every lane's fetch and push rewrite, and `main_moved` accepts the main checkout's HEAD at its branch's remote-tracking ref, so a stage can write `refs/remotes/origin/main` and fast-forward the main checkout to it; the forged ref lasts until the next fetch, and `lane-open` bases a new lane on the local `origin/main` without fetching.
- Fix: have `lane-open` fetch origin before it reads `origin/main`, or compare each remote-tracking ref after the check against `git ls-remote origin`, with a failing-stage case in `tools/tools_test.sh`.

### Security: a check's escape scan leaves the XDG global git configuration and the branch the main checkout's HEAD names out

- Location: `tools/run_state.sh`, `escaped_paths` and `main_moved`.
- Why: git also reads `${XDG_CONFIG_HOME:-$HOME/.config}/git/config` as global configuration (a hook path, an alias, a credential helper), and `main_moved` compares only the commit the main checkout's HEAD names, so a stage writing the XDG file, or switching the main checkout's HEAD to another branch at the same commit, by an absolute path still passes the check; the queue item named only `$HOME/.gitconfig`, the main checkout, and the references.
- Fix: `escape_scan` the XDG configuration file beside `$HOME/.gitconfig`, and compare `git -C "$main_tree" symbolic-ref -q HEAD` beside the commit in `main_moved`, each with a failing-stage case in `tools/tools_test.sh`.

### Security: a lane check's scan skips other lanes' branches and worktrees, so a stage can move or edit a concurrent delivery (security Low (6))
- Location: tools/run_state.sh:1048, refs_view with lane_branches, and tree_scan pruning the main checkout's tmp/
- Why: refs_view skips every branch another lane's worktree has checked out, and tree_scan prunes tmp/, where the other lane worktrees live, so a stage can move another lane's branch to an attacker commit or edit that lane's uncommitted files and the check still passes, planting code in a concurrent delivery; that lane's own committed-diff review only partly mitigates it.
- Fix: record each lane branch's object at escape_mark and accept a change only when it extends that object with commits not reachable from the check clone's HEAD, or better compare each other lane's branch tip against that lane's own run state; scan tmp/.lane-*/ for files whose status-change time is newer than the mark, outside the lanes' own pruned parts (.git, tmp, build links).

### Security: lane_branches trusts any linked worktree present at scan time, so a stage can hide a new or moved branch (security Low (6))
- Location: tools/run_state.sh:1049, lane_branches; tools/run_state.sh:3414, lane_open
- Why: a stage can create its own worktree (git worktree add -b NAME DIR COMMIT, or --force for an existing branch) and leave it, which puts any new or moved local branch on refs_view's skip list, while the admin entry under the common worktrees/ directory is not scanned; lane_open reuses an existing refs/heads/BRANCH as is, so a stage can pre-create a queued change's branch at an attacker commit and the next delivery starts from it, its diff review against origin/main only partly mitigating it.
- Fix: skip only branches checked out at escape_mark (escape_lanes); for a branch first seen at scan time require that its worktree path is tmp/.lane-CHANGE of the main checkout and that build/pipeline/CHANGE.json names that branch, else list it; alternatively have lane_open refuse an existing local branch with no run state or no origin counterpart.

### Security: refs_view leaves refs/remotes/ out, and lane_open bases a new lane on a remote-tracking ref without fetching (security Low (5))
- Location: tools/run_state.sh:1062, refs_view; tools/run_state.sh:3416, lane_open
- Why: lane_open bases a new lane on refs/remotes/origin/BRANCH when that ref exists, without a fetch first, so a stage can write refs/remotes/origin/NEXT-BRANCH at an attacker commit and the next delivery of that branch name tracks and starts from it, extending the recorded origin/main forging finding to the per-branch path.
- Fix: have lane_open run git fetch origin BRANCH before it reads refs/remotes/origin/BRANCH or origin/main, or after the check compare each remote-tracking ref against git ls-remote origin; add a failing-stage case in tools/tools_test.sh.

### Quality: main_moved's ls-remote reaches the network with no prompt guard or time limit (quality advisory)
- Location: tools/run_state.sh:1112, main_moved
- Why: the scan's git ls-remote origin can block on a credential prompt or a stalled connection, holding the check indefinitely.
- Fix: run it with GIT_TERMINAL_PROMPT=0 and a bounded timeout, a failure counting as moved as now, with a tools-test case for an unreachable origin.

### Security: a lane check accepts another lane's branch moved or its worktree files edited (security Low (6), reported three times, still present at package)
- Location: tools/run_state.sh:1048 (refs_view, lane_branches, tree_scan)
- Why: refs_view skips every branch checked out in another lane's worktree (lane_branches), and tree_scan prunes the main checkout's tmp/, where the other lane worktrees live, so a stage can move another lane's branch to an attacker commit, or edit that lane's uncommitted files, and the check still passes, planting code in a concurrent delivery; the other lane's own committed-diff review partly mitigates this.
- Fix: Record each lane branch's object at escape_mark and accept a change only when it extends that object with commits not reachable from the check clone's HEAD, or better compare each other lane's branch tip against that lane's own run state; scan tmp/.lane-*/ for files whose status-change time is newer than the mark, outside the lanes' own pruned parts (.git, tmp, build links).

### Security: a stage-made worktree puts any local branch on the scan's skip list (security Low (6), reported twice, still present at package)
- Location: tools/run_state.sh:1049 (lane_branches), tools/run_state.sh:3414 (lane_open)
- Why: lane_branches trusts every linked worktree that exists when the scan runs, so a stage can add its own (git worktree add -b NAME DIR COMMIT, or --force for an existing branch) and leave it, putting a new or moved local branch on refs_view's skip list; the admin entry under the common worktrees/ directory is not scanned, and lane_open reuses an existing refs/heads/BRANCH as is, so a stage can pre-create a queued change's branch at an attacker commit and the next delivery starts from it; that delivery's own diff review against origin/main partly mitigates this.
- Fix: Skip only the branches checked out at escape_mark (escape_lanes); for a branch first seen at scan time require that its worktree path is tmp/.lane-CHANGE of the main checkout and that build/pipeline/CHANGE.json names that branch, otherwise list it; alternatively have lane_open refuse an existing local branch that has no run state or no origin counterpart.

### Security: a forged remote-tracking ref seeds the next lane of that branch (security Low (5), reported twice, still present at package)
- Location: tools/run_state.sh:1062 (refs_view), tools/run_state.sh:3416 (lane_open)
- Why: refs_view leaves out all of refs/remotes/, and lane_open bases a new lane on refs/remotes/origin/BRANCH when that ref exists without fetching first, so a stage can write refs/remotes/origin/NEXT-BRANCH at an attacker commit and the next delivery of that branch name tracks and starts from it; this extends the recorded origin/main forging finding to the per-branch path.
- Fix: Have lane_open run git fetch origin BRANCH before it reads refs/remotes/origin/BRANCH or origin/main, or after the check compare each remote-tracking ref against git ls-remote origin; add a failing-stage case in tools/tools_test.sh.

### Security: stages run with the real HOME and the scan ignores its executed files (security Medium (6))
- Location: tools/run_state.sh:1131
- Why: apart from $HOME/.gitconfig the escape scan ignores every HOME file later tools execute: ~/.profile and the shell rc files agent Bash calls source, the hooks of ~/.claude/settings.json, and the XDG git configuration (already recorded), so a stage writing one of them by absolute path gets code execution in later agent sessions while the check passes.
- Fix: Run stages with HOME set to a throwaway directory inside the check clone (CLONE_EXEC), or escape_scan the profile and rc files, ~/.claude/, and ${XDG_CONFIG_HOME:-$HOME/.config}/git beside $HOME/.gitconfig, each with a failing-stage case in tools/tools_test.sh.

### Quality: a check between the merger's lane-close and branch deletion fails as the references changed
- Location: tools/run_state.sh:1047 (refs_view)
- Why: the merger's step 7 runs lane-close, then ls-remote, the fast-forward, and git branch -D; a check whose escape_mark falls between lane-close and branch -D sees the closed lane's branch in no worktree at the mark or the scan, so its deletion fails the check, a rare false failure.
- Fix: Leave out of refs_view a branch present at the mark and gone at the scan only when no worktree held it, or have lane-close delete the branch with its worktree, with a test.

### Quality: a tracked path holding a tab, newline, quote, or backslash is reported as untracked
- Location: tools/run_state.sh:1089 (main_scan)
- Why: core.quotePath=false still C-quotes a path holding a tab, newline, double quote, or backslash, so such a tracked file the merger's fast-forward rewrites is not matched by the find output and is reported as an untracked file.
- Fix: Read git ls-files -z and find -print0, or compare through git ls-files --others --ignored --exclude-standard instead.

### Quality: this findings file's first entry is superseded by a later one
- Location: docs/findings/check-runner-safety-c.md:1
- Why: the first entry is superseded by the third (the same XDG gap, and its claim that the main checkout's HEAD is unchecked is stale since main_moved compares the commit), so the backlog receives a near-duplicate.
- Fix: Let groom merge the first entry into the third, dropping the stale HEAD claim.

### Quality: the scan's ls-remote has no prompt guard or time limit
- Location: tools/run_state.sh:1112 (main_moved)
- Why: the scan's git ls-remote reaches the network with no prompt guard or time limit, so a credential prompt or a stalled connection holds the check.
- Fix: Run it with GIT_TERMINAL_PROMPT=0 and a bounded timeout, the failure counting as moved as now.
