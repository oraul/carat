# Tasks

## 1. Hooks pin origin by digest

- [x] 1.1 `.claude/agents/*.md`: every hook line accepts `remote.origin.url` only when the blob id of its `.git`-stripped text is one of the three pinned digests, drops the one-use `p` variable, and writes `-c transfer.fsckObjects`; no line names the address, host, or owner and name. Proved by `tools/tools_test.sh` "guard: every hook line resolves main the same way", "guard: the $a hook allows a git read", and "guard: the $a hook refuses an origin other than the pinned one".
- [x] 1.2 `tools/tools_test.sh`: the fixture origin is an address on `host.invalid` whose digests replace the pinned ones in the line under test ("guard: every hook line carries the three pinned digests", "guard: no hook line names an address, host, or path"); new cases "guard: a hook accepts the ssh form of origin", "guard: a hook accepts the scp form of origin", and "guard: a hook refuses origin with a trailing slash"; every existing route case (moved `origin/main`, replace ref, planted object, local, `file:`, remote helper, foreign origin, `insteadOf`) still passes.
- [x] 1.3 `.claude/agents/contributor.md` and `.claude/agents/planner.md`: prose reworded to their budgets, no instruction dropped. Proved by `make docs-lint`.

## 2. Docs and records

- [x] 2.1 `tools/agent_guard.sh` header comment, the `agent_guard.sh` bullet of `docs/codebase-map.md`, and the guard sentence of `README.md`: the hook line pins origin by the blob ids of its three forms and how to recompute them. Proved by `make docs-lint` and `make gates`.
- [x] 2.2 `docs/backlog.md`: append with `>>` the security entry for a planted or overwritten object reaching the merge gates' worktree of `origin/main`. Proved by `git diff` showing only appended lines.

## 3. Checks

- [x] 3.1 Run `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate`, and check that no tracked file outside the Makefile holds the address.

## 4. The merge gates' green line pins origin by digest

- [x] 4.1 `.claude/workflows/deliver-change.js`: `ORIGIN_IDS` holds the six blob ids (the hook lines' three forms, then each with `.git`) and `originCheck()`, with no argument, accepts origin's resolved url only when its blob id is one of them; the line names no host. Proved by `tools/tools_test.sh` "workflow: the origin check passes the hosted repository", "workflow: the origin check passes the ssh form" (and https, ssh .git, scp, scp .git), "workflow: the origin check fails a trailing slash", "workflow: the origin check fails a user before the host", "workflow: the origin check fails another repository", and "workflow: originCheck's ids are the hook lines' ids, with and without .git".
- [x] 4.2 `tools/agent_guard.sh`: `git hash-object --stdin` for the merger profile only, every other option refused; header lists it. Proved by "guard: merger hashes stdin", "guard: merger refuses a hash that writes the object", "guard: merger refuses a hash through a path's filters", "guard: read refuses git hash-object", and "guard: merger runs the green line".
- [x] 4.3 `tools/tools_test.sh`: the green-line cases use the `host.invalid` fixture's six ids ("workflow: the origin check under test holds the fixture's ids"); no tracked file but the Makefile toolchain target names the hosted service's host. Proved by `make tools-test` and a search of the tracked files.
