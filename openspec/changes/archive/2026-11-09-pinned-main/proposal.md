# Proposal

## Why

The merge gates and the hooks trust `origin/main`, and four security findings show ways it or the repository git runs in can come from branch code instead of origin. The green line fetches main by whatever `remote.origin.fetch` the delivery clone's configuration holds (Medium (7) and (6) in the `check-isolation` review), so a mapped refspec would turn a branch into `origin/main`. The merge-tool hook runs main's guard only when its text names the merge tool and otherwise lets the merge through unguarded (Low (5) at e368486, Low (4) at b0dd342, Low (3) at c1b3a12). The guard admits any `tmp/.NAME` for `git -C`, `cd`, and `make -C` by its name alone, so a repository branch code planted there runs its own configuration and hooks on a reviewer's command (Medium (6) at b0dd342, Low (6) at 31a93d2).

The `layout-slots` run also reported that the contributor ran a direct `git push` to `refs/backup` outside `tools/run_state.sh`. At b76b722 the guard already refuses every `git push` of the contributor by its verb, so no code path was found that allowed it; this change adds cases that pin the refusal for every push form, the hook included.

This change is outside the roadmap of `docs/architecture.md` section 12: it repairs the delivery pipeline (`docs/queue.md` item 1, `pinned-main`).

## What Changes

- The green line fetches main by its own refspec, `+refs/heads/main:refs/remotes/origin/main`, with `--refmap=` so no configured refspec is read; the guard admits that one fetch form beside the fetch without a refspec.
- The guard refuses every call while `remote.origin.fetch` is set to anything but a clone's default, as the origin gate already does for the gates.
- The merge-tool hook in `.claude/agents/merger.md` refuses when main's guard is missing, empty, or does not name the merge tool, and otherwise always runs it.
- The guard admits `git -C`, `cd`, `git checkout`, and `make -C` in a `tmp/.NAME` only when it is absent or a linked worktree of the project's own repository: a real directory whose `.git` file names a worktree record of the project's common directory that names it back. `git worktree add` and `remove` keep the name rule.
- `tools/tools_test.sh` gains cases for each: the pinned fetch and its refusals, a mapped or doubled fetch refspec, the merge hook with a guard lacking the tool or empty, planted, linked, and foreign repositories at `tmp/.NAME`, and every form of a contributor `git push`, through the contributor's hook too.
- `docs/backlog.md` loses the entries this change fixes and gains the planner's new entries.

## Out of scope

- The rest of the backup problem: a refused backup push is retried and protects nothing (queue item 18 and its backlog entry).
- The Bash hooks of the other agents, which already refuse when main has no guard.
- The Ctrl-W h/j/k/l documentation gap, recorded in the backlog for `breadcrumbs`.

## Assumptions

- "Main fetched by a pinned remote and refspec" is met by the green line's explicit refspec with `--refmap=` and the guard's refusal of a non-default refspec; the origin gate in `tools/gates.sh` already requires the default refspec and compares `origin/main` with `git ls-remote`.
- A `tmp/.NAME` absent when the guard judges a call is admitted, so one call can add a worktree and use it; read and merger profiles create nothing there but by `git worktree add`, and the contributor runs branch code anyway, as the guard's header states.
- The direct backup push could not be reproduced against the code at b76b722; the brief's acceptance is met by cases that show every form refused.
