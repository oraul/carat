# Design

## Context

Each agent file's frontmatter holds a `PreToolUse` hook line (the merger two) that reads the guard with `git -C "$CLAUDE_PROJECT_DIR" show origin/main:tools/agent_guard.sh` and runs it with `sh -c`. The hook line is what Claude Code runs; the guard is only trusted as far as the commit the hook reads it from. Branch code shares the user and the repository, so every local ref, `.git/config`, `~/.gitconfig`, and the object store are writable by it. The one source it cannot rewrite is origin's answer for `refs/heads/main`, provided git is not told by writable configuration to ask somewhere else.

## Goals / Non-Goals

**Goals:**

- No hook runs a guard read through a ref, configuration, or address branch code can set.
- The normal path keeps working, the merger's calls after its own merge included, and every failure refuses.

**Non-Goals:**

- Changing what any profile allows, `merge_tool`, the merge gates, or the gates' and run state's reads of `origin/main`.
- Defending the merge gates' worktree of `origin/main` against forged object files under `.git/objects` (named for the planner); the hooks no longer read the project's objects at all.

## Decisions

- The hook reads the guard from a fetch of origin's `refs/heads/main` into a new temporary bare repository (`mktemp -d`, `git init --bare`, every git call there with `GIT_DIR` set to it), with `GIT_CONFIG_GLOBAL=/dev/null` and `GIT_CONFIG_NOSYSTEM=1`, so the only configuration is the fresh repository's own: no local, global, or system `url.*.insteadOf`, `http.proxy`, `http.sslCAInfo`, credential helper, or `core.sshCommand` applies. The guard is `FETCH_HEAD:tools/agent_guard.sh` in that repository, which is removed before the guard runs, whatever the outcome. Branch code can write the project's `.git` (the threat this change addresses), and git hashes an object only when it arrives, never when it reads it: the first read, `git show "$m:tools/agent_guard.sh"` in the project after `ls-remote`, followed the verified commit's tree to a blob a planted loose object answered for, and a planted commit under `$m` plus a repository `insteadOf` redirected its fetch (security review, both reproduced). A fresh repository has no objects and no alternates, so `index-pack` hashes every object of the fetch, `transfer.fsckObjects=true` checks them too, and nothing local can answer for an id. Alternative rejected: hashing the commit, the two trees, and the blob from the project's store with `git hash-object` before the read; it keeps the call local, but needs one more step per object and a reread of each object after it is checked, which a writer racing the hook can swap, and the hook lines no longer fit the agent files' budgets.
- The fetch is `--depth=1`: the guard needs main's tree, not its history; about 1 s per call against about 0.3 s for the `ls-remote` it replaces, with no local fetch when main moved, as after the merger's squash.
- `u` is `remote.origin.url` read with `--local` and pinned configuration, allowed only when it is, `.git` removed, exactly the repository's own address over `https`, `ssh`, or scp-like `git@host:owner/name`, the host and the owner and name written in every hook line; anything else, a leading `-`, a remote helper (`ext::`, `foo::x@host:path`), a `file` address, a local path, or another hosted repository, prints `origin is not hosted` and exits 2. `.git/config` is writable by branch code, so a filter by shape alone let it name a fork of its own whose main carries a permissive guard (security review); the hook line is the one place branch code cannot change for the running session. Alternatives rejected: a value from the hook's environment, which nothing trusted supplies, and the run state's repository, which lives under `build/`, writable by branch code. Trade-off accepted: a fork edits the pinned owner and name in its hook lines. Every hook line stays within the agent files' byte budgets, so the case is written with two variables.
- Every git call of the hook runs with `--no-replace-objects` and `core.hooksPath=/dev/null`; the fresh repository has no replace refs or hooks, so these only keep the project read of `remote.origin.url` from running anything.
- The fetch reads stdin from `/dev/null`, so an ssh transport cannot consume the hook's JSON before the guard reads it.
- Every failure exits 2, the status Claude Code reads as a refusal, never another nonzero status, which it would treat as a hook error and let the call run.
- The resolution is the same text in every hook line, only the profile after `agent_guard` differing; a `tools/tools_test.sh` case compares them so one file cannot drift.
- Tests answer a hosted-looking origin from a local bare repository through `GIT_CONFIG_COUNT` `insteadOf` in the hook's environment: command-line configuration, which `GIT_CONFIG_GLOBAL=/dev/null` does not drop and which branch code cannot set for the harness that runs the hooks.

## Risks / Trade-offs

- [One shallow fetch of main per tool call, about 1 s] Accepted for a blocking security fix; every store that could cache it (refs, objects, files under the same user) is writable by branch code.
- [Offline or origin unreachable refuses every agent call] Fails closed, as a missing guard did; the run stops instead of running unguarded.
- [Branch code writing the temporary repository during the hook's fetch] It is created with mode 0700 under the harness's `TMPDIR` and lives for one call; the same user can still write it, as it can write the hook's process, which no hook line defends against.
- [A fork's hooks refuse every call until it edits the pinned owner and name] Fails closed; the edit is one substitution over `.claude/agents/`.
