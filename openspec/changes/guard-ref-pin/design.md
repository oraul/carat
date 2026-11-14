# Design

## Context

Each agent file's frontmatter holds a `PreToolUse` hook line (the merger two) that reads the guard with `git -C "$CLAUDE_PROJECT_DIR" show origin/main:tools/agent_guard.sh` and runs it with `sh -c`. The hook line is what Claude Code runs; the guard is only trusted as far as the commit the hook reads it from. Branch code shares the user and the repository, so every local ref, `.git/config`, `~/.gitconfig`, and the object store are writable by it. The one source it cannot rewrite is origin's answer for `refs/heads/main`, provided git is not told by writable configuration to ask somewhere else.

## Goals / Non-Goals

**Goals:**

- No hook runs a guard read through a ref, configuration, or address branch code can set.
- The normal path keeps working, the merger's calls after its own merge included, and every failure refuses.

**Non-Goals:**

- Changing what any profile allows, `merge_tool`, the merge gates, or the gates' and run state's reads of `origin/main`.
- Defending against forged object files under `.git/objects` (named for the planner; it needs a design that covers the merge gates' worktree too).

## Decisions

- Main's commit comes from `git ls-remote "$u" refs/heads/main` with `GIT_DIR=/dev/null`, `GIT_CONFIG_GLOBAL=/dev/null`, and `GIT_CONFIG_NOSYSTEM=1`: no repository is discovered, so no local `url.*.insteadOf`, `http.proxy`, `http.sslCAInfo`, credential helper, or `core.sshCommand` applies, and no global or system one either. Alternative rejected: checking `origin/main` against `ls-remote` run in the repository, which the repository's own configuration can redirect to a server answering for a forged main.
- `u` is `remote.origin.url` read with `--local` and pinned configuration, allowed only when it is, `.git` removed, exactly the repository's own address over `https`, `ssh`, or scp-like `git@host:owner/name`, the host and the owner and name written in every hook line; anything else, a leading `-`, a remote helper (`ext::`, `foo::x@host:path`), a `file` address, a local path, or another hosted repository, empties `u` and stops the lookup with `${u:?origin is not hosted}`. `.git/config` is writable by branch code, so a filter by shape alone let it name a fork of its own whose main carries a permissive guard (security review); the hook line is the one place branch code cannot change for the running session. Alternatives rejected: a value from the hook's environment, which nothing trusted supplies, and the run state's repository, which lives under `build/`, writable by branch code. Trade-off accepted: a fork edits the pinned owner and name in its hook lines. Every hook line stays within the agent files' byte budgets, so the case is written with two variables.
- Every git call of the hook runs with `--no-replace-objects`, so a `refs/replace/` ref branch code plants for main's commit cannot substitute a commit carrying another guard; `git` sets `GIT_NO_REPLACE_OBJECTS` for the fetch's subprocesses too.
- The answer must be one line of lowercase hex, otherwise the hook refuses; an empty answer would otherwise make `show ":tools/agent_guard.sh"` read the index, the branch's staged copy.
- When `cat-file -e` finds the commit missing, the hook fetches `refs/heads/main` from `u` with `--refmap=` and `--no-write-fetch-head`, writing no ref, then reads the guard at the commit id it was given: a fetch redirected by local configuration can bring other objects but not a different one under that id. Refusing instead was rejected: after the merger's squash, main is ahead of the local repository and every later call, the fetch included, would be refused.
- Every git call of the hook reads stdin from `/dev/null` where it could talk to a transport (`ls-remote`, `fetch`), so an ssh transport cannot consume the hook's JSON before the guard reads it.
- The resolution is the same text in every hook line, only the profile after `agent_guard` differing; a `tools/tools_test.sh` case compares them so one file cannot drift.
- Tests answer a hosted-looking origin from a local bare repository through `GIT_CONFIG_COUNT` `insteadOf` in the hook's environment: command-line configuration, which `GIT_CONFIG_GLOBAL=/dev/null` does not drop and which branch code cannot set for the harness that runs the hooks.

## Risks / Trade-offs

- [One network round per tool call, about 0.4 s] Accepted for a blocking security fix; the alternative stores (refs, files, caches) are all writable by branch code.
- [Offline or origin unreachable refuses every agent call] Fails closed, as a missing guard did; the run stops instead of running unguarded.
- [A ref on origin ending in `/refs/heads/main` makes the answer two lines] Refused, fails closed; only a push to origin can create one.
- [A forged loose object under the id `ls-remote` names] Out of scope here (Non-Goals); reported as a finding.
- [A fork's hooks refuse every call until it edits the pinned owner and name] Fails closed; the edit is one substitution over `.claude/agents/`.
