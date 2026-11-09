# Design

## Context

The merger's green line fetches origin, adds a worktree of `origin/main` at `tmp/.merge-gates`, and runs that copy's merge gates; the merge-tool hook and every Bash hook read `tools/agent_guard.sh` from `origin/main`. `check-isolation` moved the check stages into a throwaway clone, but the green line's fetch still read the configured refspec, the merge-tool hook skipped a guard without the tool's name, and the guard's worktree rule was a name pattern. The scout pack `build-and-ci-b76b722` lists the code paths.

## Goals / Non-Goals

Goals: `origin/main` is origin's main whatever the delivery clone's configuration says; the merge tool never runs without main's guard judging it; git and make run only in the project's own repository or its linked worktrees; every contributor push form but the run state's is refused, with a case.

Non-goals: the backup retry (queue item 18), the other agents' Bash hooks, and the delivery clone's trust in the contributor's own scripts, which the reviews and branch protection cover.

## Decisions

### The pinned fetch

The green line runs `fetch -q --refmap= origin +refs/heads/main:refs/remotes/origin/main`. With a refspec on the command line git reads `remote.origin.fetch` only for opportunistic tracking updates, and `--refmap=` turns those off, so the configured value has no effect on the fetch. The guard admits that exact form (with or without `-q`) and still refuses any other refspec. The alternative, checking the configured refspec before a plain fetch, depends on a value branch code can write between the check and the fetch.

### The configured refspec

The guard refuses every call while `remote.origin.fetch` is set to anything but `+refs/heads/*:refs/remotes/origin/*`, beside its risky-key and hooks checks, since a mapped refspec makes any agent's plain `git fetch` forge the `origin/main` whose guard the hooks read. An unset refspec forges nothing and is admitted. The origin gate in `tools/gates.sh` already requires the default.

### The merge-tool hook

The hook reads main's guard and exits 2 when the read fails, the text does not name `mcp__github__merge_pull_request`, or the guard refuses; otherwise it runs the guard unconditionally. The bootstrap fallthrough, which let the merge run while main's guard predated the tool, is gone: every guard on main has named the tool since `check-isolation`.

### Worktrees of the project

`worktree_name` keeps the name rule (`tmp/.NAME`, not the toolchain directories) for `git worktree add` and `remove`, where git itself refuses to add over a repository and removes only a worktree it lists. `worktree`, used for `git -C`, `cd`, `checkout`, `make -C`, and the measurement roots, also requires an existing path to be a real directory, not a link, whose `.git` is a regular file naming `COMMON/worktrees/ID` of the project's common directory, whose `gitdir` names that `.git` file back and whose `commondir` is `../..`. The guard reads these files rather than running git in the candidate, so a planted repository's configuration never runs during the judgment. A linked worktree shares the project's configuration and hooks, which the global checks already judge; `extensions.worktreeConfig` is a risky key, so no per-worktree configuration applies.

An absent path is admitted, since the guard judges a whole command line before it runs and the benchmark's `git worktree add ... || git -C ... checkout` and the green line's remove-then-add name one path in both states.

### Contributor pushes

The contributor's `git push` is refused by its verb (`only_profiles merger`) whatever global options, `-C`, `-c`, or assignments come first. The new cases cover the exact backup push `tools/run_state.sh backup` runs, a plain backup ref push, `-C .`, `-c core.hooksPath=/dev/null`, an assignment with `--no-pager`, and a branch deletion, each refused, plus the same backup push through the contributor's hook line reading main's guard.

## Risks / Trade-offs

- A worktree created by a git that writes a relative `gitdir` (`worktree.useRelativePaths`) would be refused until re-added; the delivery clones use the default absolute paths.
- Between the guard's judgment of an absent path and the command, something else would have to create a repository there; the check stages run in a throwaway clone, so no branch code runs in the delivery clone at that time.
