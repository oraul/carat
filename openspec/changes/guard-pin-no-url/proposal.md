# Proposal

## Why

#126 (`guard-ref-pin`) pins origin in every hook line under `.claude/agents/` by spelling the repository's hosted address in pieces (the scheme as `https:[/][/]`, the host with a bracketed dot, the owner and name in a variable), and `tools/tools_test.sh` sets its fixture origin to the same address in pieces, so `tools/scan_text.sh` does not catch either. `CLAUDE.md` allows a URL only in the Makefile `toolchain` target, so both break the hard rule. The user decided to fix the rule break now, ahead of `untyped-gateway` at sprint 5's head; it is outside the roadmap of `docs/architecture.md` section 12: it is delivery tooling.

## What Changes

- Every hook line pins origin by digest instead of by address: it hashes `remote.origin.url`, `.git` stripped, with `git hash-object --stdin` (no global or system configuration, as before) and accepts only the three blob ids of the repository's own address in its three hosted forms (`https`, `ssh` with `git@`, and `git@host:path`), the same set #126's pattern accepted, so a local path, `file:`, a remote helper, an option, or any other hosted repository is refused with the same message, `origin is not hosted`. The line names neither the address, nor its host, nor its owner and name; the fetch, the temporary repository, the hashed objects, and the guard read at `FETCH_HEAD` are unchanged, so every route #126 closed (a moved local `origin/main`, a replace ref, a planted object, a changed `remote.origin.url` or `insteadOf`, a foreign origin) stays closed.
- To keep `contributor.md` and `planner.md` within their `docs_lint.sh` budgets, the hook line drops its one-use `p` variable and writes `transfer.fsckObjects` as the bare boolean key (true), and a few bytes of each file's prose are reworded without dropping an instruction; no budget is raised.
- `tools/tools_test.sh`: the hook cases run against a fixture origin on a reserved `.invalid` host whose digests replace the pinned ones in the line under test, so the file no longer holds the repository's address; new cases accept the fixture's three forms and refuse a near miss (a trailing slash, another owner), and every existing case for the routes above still passes.
- `tools/agent_guard.sh` header and the `agent_guard.sh` bullet of `docs/codebase-map.md` say how the pin is written and how to recompute it.
- `docs/backlog.md`: one security entry appended with `>>` (never read): a planted or overwritten object under `.git/objects` can still substitute content in the merge gates' worktree of `origin/main`.

Out of scope: the URL rule and `tools/scan_text.sh` (unchanged by the brief); the guard's allowlists and `merge_tool`; the merge gates' green line `originCheck` in `.claude/workflows/deliver-change.js` and its cases in `tools/tools_test.sh`, which name the hosted service's host (not the repository's address) and predate #126 (#74); the planner's queue placement (applied by the package step from `build/plan/`).

Assumptions:

- A git blob id (SHA-1 here) of the exact address string is a pin, not the address in pieces: it cannot be read back into the address, and matching it needs a second preimage, which no known attack on SHA-1 gives.
- A fork or a clone whose origin is another repository refuses every agent call, as it did with #126's pattern; the header says how to recompute the three digests.

## Capabilities

### New Capabilities

None: the change is delivery tooling and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `.claude/agents/*.md` (the hook lines; a few bytes of the contributor's and the planner's prose), `tools/agent_guard.sh` (header comment), `tools/tools_test.sh`, `docs/codebase-map.md`, `docs/backlog.md` (appended).
- CLAUDE.md: unchanged, it says only that each agent's hook runs `tools/agent_guard.sh`, which stays true; no command, target, agent, workflow, or gate is added or removed.
- README.md: unchanged, its guard sentence says the guard is fetched from origin's main into a temporary repository, which stays true.
- docs/architecture.md: unchanged, no section describes the agents' hooks.
