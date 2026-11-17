# Design

## Context

See proposal.md, Why. The merger runs the green line in the delivery's worktree `tmp/.lane-<change>`, a linked worktree of the main checkout, so its object store is the main checkout's, which every lane and every command a branch's checks run can write. The line is judged by main's `tools/agent_guard.sh`, which refuses `$`, substitutions, and subshells, so the line cannot make a temporary repository of its own.

## Goals / Non-Goals

Goals: no object branch code planted reaches the merge gates; the hook pins accept the https form of origin only. Non-goals: the other halves of the backlog item (ci-trust-gaps-b and -c).

## Decisions

- Verify the store with `git fsck --no-dangling --no-progress origin/main` after the worktree add, not before it, so an object the add read is still hashed if it was swapped back in between. Alternatives: a fresh bare repository fetched with `transfer.fsckObjects`, as the hook lines do, needs a `mktemp` path the guard cannot admit in the merger's line, and a guard change to admit it would widen the merger's profile far more; `git clone --no-local` into a new directory leaves the guard's worktree checks; hashing only the checked-out files trusts the tree objects, which can be planted too. With a head given, fsck reads no index or reflog, so another lane's work in progress does not fail it, while it still hashes every loose and packed object of every object directory and verifies the commit graph.
- The guard admits fsck to the merger in that exact form only; fsck writes nothing in it.
- fsck turns replace refs off, while a plain worktree add follows them, so a `refs/replace` entry pointing main's gates.sh blob at a valid planted blob would pass fsck and still check out the planted script: every pinned git of the line (PINNED_GIT) runs with `--no-replace-objects`, as the hook lines already do, and the line stops before the add when `git for-each-ref refs/replace` prints anything, a second defence the guard admits as read verbs. Alternative: `GIT_NO_REPLACE_OBJECTS=1`, refused because the guard admits no other assignment before git.
- Pin the https form alone. The ssh and scp transports run the ssh client, whose configuration (a `Host` alias, a `ProxyCommand`) lies outside git's and so outside the hook's pinned environment; https resolves through git's configuration alone, which the hook nulls. The hook line keeps its `case ... in ID)` shape with one id, and `ORIGIN_IDS` holds two (with and without `.git`, since the green line hashes the url unstripped).

## Risks / Trade-offs

- A clone whose origin is ssh must switch to https; recorded in the proposal's assumptions.
- fsck over a cold store of about 17,000 loose objects took 47 s once, 2 s warm; the merge waits minutes on CI, so the cost is accepted. A corrupt object anywhere in the store stops the merge until it is removed, which is the intended fail-closed outcome.
