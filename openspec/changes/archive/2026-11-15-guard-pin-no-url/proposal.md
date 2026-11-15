# Proposal

## Why

#126 (`guard-ref-pin`) pins origin in every hook line under `.claude/agents/` by spelling the repository's hosted address in pieces (the scheme as `https:[/][/]`, the host with a bracketed dot, the owner and name in a variable), and `tools/tools_test.sh` sets its fixture origin to the same address in pieces, so `tools/scan_text.sh` does not catch either; the merge gates' green line (`originCheck` in `.claude/workflows/deliver-change.js`, from #74) and its two test copies name the hosted service's host. `CLAUDE.md` allows a URL only in the Makefile `toolchain` target, so all of them break the hard rule. The user decided to fix the rule break now, ahead of `untyped-gateway` at sprint 5's head; it is outside the roadmap of `docs/architecture.md` section 12: it is delivery tooling.

## What Changes

- Every hook line pins origin by digest instead of by address: it hashes `remote.origin.url`, `.git` stripped, with `git hash-object --stdin` (no global or system configuration, as before) and accepts only the three blob ids of the repository's own address in its three hosted forms (`https`, `ssh` with `git@`, and `git@host:path`), the same set #126's pattern accepted, so a local path, `file:`, a remote helper, an option, or any other hosted repository is refused with the same message, `origin is not hosted`. The line names neither the address, nor its host, nor its owner and name; the fetch, the temporary repository, the hashed objects, and the guard read at `FETCH_HEAD` are unchanged, so every route #126 closed (a moved local `origin/main`, a replace ref, a planted object, a changed `remote.origin.url` or `insteadOf`, a foreign origin) stays closed.
- The merge gates' green line pins origin the same way: `originCheck` takes no argument and accepts origin's url, as git resolves it with its lines joined, only when `git hash-object --stdin` of it is one of six blob ids in `ORIGIN_IDS`, the three the hook lines pin and the same three forms with `.git`; the line names no host, and the run state's repository no longer enters it. An origin with a user before the host or a trailing slash, which the old pattern accepted, is refused (accepted by the user).
- `tools/agent_guard.sh` `git_form` admits `git hash-object --stdin` for the merger profile alone, with no other option (`-w`, `--path`, `--literally`, `-t`, and the rest refused), so the merger can run the green line; no `sed` allowance is added.
- To keep `contributor.md` and `planner.md` within their `docs_lint.sh` budgets, the hook line drops its one-use `p` variable and writes `transfer.fsckObjects` as the bare boolean key (true), and a few bytes of each file's prose are reworded without dropping an instruction; no budget is raised.
- `tools/tools_test.sh`: the hook cases run against a fixture origin on a reserved `.invalid` host whose digests replace the pinned ones in the line under test, so the file no longer holds the repository's address; new cases accept the fixture's three forms and refuse a near miss (a trailing slash, another owner), and every existing case for the routes above still passes.
- `tools/tools_test.sh`: the green-line guard case and the workflow's origin check cases run against a fixture origin on `host.invalid` whose six ids replace the pinned ones; new cases accept each form with and without `.git` and refuse a trailing slash and a user before the host; cases allow `git hash-object --stdin` for the merger and refuse `-w`, `--path`, and the read profile; the case for a run state's repository of another form is replaced by one checking that `ORIGIN_IDS` begins with the hook lines' three ids and holds six distinct ids.
- `tools/agent_guard.sh` header and the `agent_guard.sh` bullet of `docs/codebase-map.md` say how the pin is written and how to recompute it; the guard sentence of `README.md` says the hook line pins origin by digest.
- `docs/backlog.md`: one security entry appended with `>>` (never read): a planted or overwritten object under `.git/objects` can still substitute content in the merge gates' worktree of `origin/main`.

Out of scope: the URL rule and `tools/scan_text.sh` (unchanged by the brief); the guard's allowlists beyond `git hash-object --stdin` for the merger, and `merge_tool`; the planner's queue placement (applied by the package step from `build/plan/`).

Assumptions:

- A git blob id (SHA-1 here) of the exact address string is a pin, not the address in pieces: it cannot be read back into the address, and matching it needs a second preimage, which no known attack on SHA-1 gives.
- The three `.git` ids of `ORIGIN_IDS` cannot be checked against the hook lines without the address; they were computed from this clone's origin and the real green-line check was run against it once.
- The merger's hook runs the guard of origin's main, which admits `git hash-object` only once this change merges, so this change's own green line may be refused at its merge (see the design's risks).
- A fork or a clone whose origin is another repository refuses every agent call, as it did with #126's pattern; the header says how to recompute the three digests.

## Capabilities

### New Capabilities

None: the change is delivery tooling and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `.claude/agents/*.md` (the hook lines; a few bytes of the contributor's and the planner's prose), `.claude/workflows/deliver-change.js` (`ORIGIN_IDS`, `originCheck`), `tools/agent_guard.sh` (header comment, the merger's `git hash-object --stdin`), `tools/tools_test.sh`, `docs/codebase-map.md`, `README.md` (the guard sentence), `docs/backlog.md` (appended).
- CLAUDE.md: unchanged, it says only that each agent's hook runs `tools/agent_guard.sh`, which stays true; no command, target, agent, workflow, or gate is added or removed.
- README.md: changed, its guard sentence says the hook line pins origin by digest, naming no address.
- docs/architecture.md: unchanged, no section describes the agents' hooks.
