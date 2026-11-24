# Design

## Context

The first pass over the run_state.sh backlog closed headings by grep and by comment; an independent check found fixes without a failing case and entries that need an operating-system sandbox. The work list gives each heading a verdict. This change keeps to the check runner and escape scan theme and records the rest.

## Goals / Non-Goals

**Goals:**
- Every fixed heading has a case that fails at the base and passes at the head; every earlier fix is proved by a behavior case failing at the commit before it, or recorded not fixed.
- Every heading of the work list is named once in the findings file.

**Non-Goals:**
- An operating-system sandbox for stages, and any edit of `tools/rules.sh`.
- The groom, plan, push, and lane headings, queued to `run-state-backlog-c`, `-d`, `-e`.

## Decisions

- Lock: `state_lock` makes the directory `FILE.lock` with `mkdir` (one process wins) and writes its pid to `FILE.lock/pid`. A lock whose owner is gone, or that held no pid for a minute, is taken over by renaming the directory to a name of the taker, checking the owner again, and making the lock again with `mkdir` when the moved one proves live. `state_unlock` removes the lock only while its pid file names this process, and `state_rewrite` renames its file in only while it still holds the lock, so a writer that lost its lock to a third writer in the rename gap writes nothing and removes nothing (a failed write, the next call retries). Alternative: a lock file with noclobber, whose takeover had no step that tells a stale lock from one just retaken.
- Process groups: the job subshell starts the stage under `setsid`, so the stage's pid is its group, and kills the group with SIGKILL after reaping the stage (and with SIGTERM when the runner stops it). A stage that calls `setsid` itself leaves the group; that residual needs a sandbox and is recorded.
- Lost runner: only a group whose leader pid no live process holds is signalled, since the kernel keeps a pid from reuse while a member of its group lives, so a signalled group is the dead runner's.
- Ref guard: a branch counts as a lane opened since the mark only when it was absent from the references at the mark and its worktree lies at a `tmp/.lane-NAME` path, where lane-open makes them; a worktree a stage makes elsewhere hides no branch. A stage can still make one at such a path, which only a sandbox closes. A lane opened and closed inside one check stays a known false alarm (recorded for the heading naming it).
- Removal: only files under the main checkout's `build/`, regular or links, and never one `LANE_WRITTEN` names; the check is void either way. Removing outside `build/` could delete a user's file.
- Records of what was not fixed carry their reason; a heading needing a sandbox is recorded so.
