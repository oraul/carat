# Proposal

## Why

Every agent's PreToolUse hook runs `git show origin/main:tools/agent_guard.sh` and pipes the call into that text. `origin/main` is a local ref: branch code run by `make` (a profile's `make dev-build` or `metrics`, the contributor's `make`, a check clone reaching the project through its `tmp/.toolchain` link) can move it with `git update-ref` to a local commit whose guard is `exit 0`, and every agent's guard falls with it, the merge tool's hook included. Only `merge_tool` inside the guard compares `origin/main` with `ls-remote`, and by then the substituted guard is the one running. This is the security Medium (8) of the sprint-4 sweep at 41cf724, undisputed and blocking, sprint 5's head; it is outside the roadmap of `docs/architecture.md` section 12: it is delivery tooling.

## What Changes

- Every hook line under `.claude/agents/` resolves main from origin itself instead of reading the local ref: it takes `remote.origin.url` from the repository's own configuration, refuses one that is not a hosted repository (`https`, `ssh`, or `user@host:path`, no local path, `file:`, remote helper, or option), asks that address for `refs/heads/main` with `git ls-remote` run outside the repository (`GIT_DIR=/dev/null`) and with no global or system configuration, so no `insteadOf`, proxy, or certificate setting branch code can write redirects it, and reads `tools/agent_guard.sh` at the commit it answered. When that commit is not in the repository yet (main moved, as after the merger's merge), the hook fetches main from the same address without writing any ref, and the commit's id, which the fetch cannot forge, still names the guard. A failed lookup, a malformed answer, or a missing guard refuses the call.
- The merger's merge-tool hook keeps its check that main's guard names the merge tool, on the guard read the same way.
- `tools/tools_test.sh`: the hook cases run against a hosted-looking origin answered by a local bare repository (a command-line `insteadOf` in the hook's environment, which branch code cannot set); a case moves `origin/main` locally to a commit with a permissive guard and every agent's hook still refuses, the normal path passes, and cases refuse a local origin and ignore a repository `insteadOf`, fetch a main the repository lacks, and keep every hook line's resolution identical.
- `tools/agent_guard.sh` header, `docs/codebase-map.md` (its bullet), and `README.md` (the guard sentence) say where the guard is read from.

Out of scope: the guard's allowlists and `merge_tool`; the merge gates' green line and `originCheck`; reads of `origin/main` by `tools/gates.sh` and `tools/run_state.sh`; the planner's queue decisions in the brief (applied by the package step from `build/plan/`); `docs/backlog.md`, which the package step only appends to.

Assumptions:

- Every hook call now costs one `git ls-remote` (about 0.4 s here) and needs origin reachable; offline, every agent call is refused, which fails closed as a missing guard already did.
- A branch named so that its ref ends in `/refs/heads/main` makes `ls-remote` answer two lines, which the hook refuses rather than choose between; that fails closed too.
- Rewriting an object file under `.git/objects` is a separate route (git does not re-hash an object it reads); it also reaches the merge gates' worktree of `origin/main`, so it is named as a finding for the planner rather than fixed here.

## Capabilities

### New Capabilities

None: the change is delivery tooling and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `.claude/agents/*.md` (the hook lines), `tools/agent_guard.sh` (header comment), `tools/tools_test.sh`, `docs/codebase-map.md`, `README.md`.
- CLAUDE.md: unchanged, it says only that each agent's hook runs `tools/agent_guard.sh`, which stays true; no command, target, agent, workflow, or gate is added or removed.
- README.md: changed, its guard sentence names origin's main as `ls-remote` reports it.
- docs/architecture.md: unchanged, no section describes the agents' hooks.
