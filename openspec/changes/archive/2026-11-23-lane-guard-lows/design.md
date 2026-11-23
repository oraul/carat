# Design

## Context

`lane_open` links the main checkout's toolchain, cache, and run state directories into a lane worktree checked out from a branch the delivery does not trust. `merge_main` ran plain git, which reads the invoking user's global configuration and hooks. `set` refused only the keys other commands own. `wait` had only `git ls-remote` to tell pull requests apart, which shows no head repository.

## Decisions

- The lane checks run on every `lane-open`, a resume included, since the branch may have moved since. They run before any `mkdir` or `ln`, so a refusal writes nothing through a committed link. The worktree stays for the contributor to inspect; `lane-close` removes it.
- Tracked is checked with `git ls-files` at the link path; a link as the parent directory with `-L` on the checked-out tree, which is what a committed symlink becomes.
- `merge_main` reuses `pinned_git`, the pinned git of the check clone (no global or system configuration, `core.hooksPath` the null device). Read-only calls (`diff`, `rev-parse`, `merge-base`) stay plain git.
- `set` refuses `note.*` like the other keys only their command writes. The late-finding tests forged notes by `set`; they write the file as branch code could.
- `wait` uses `gh pr view --json isCrossRepository,headRefName`, compared with the run state's branch, rather than parsing the repository name: the cross-repository flag is gh's own. An unreadable answer is not recorded; it keeps waiting and ends in a refusal naming the cause.

## Risks

- A contributor session without gh can no longer record the number: the refusal says why. The merger reads the head repository again, so the check only moves the refusal earlier.
