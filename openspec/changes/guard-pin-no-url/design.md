# Design

## Context

Each agent's PreToolUse hook line reads `remote.origin.url` from the repository's own configuration, checks it against a `case` pattern holding the repository's address in pieces, fetches `refs/heads/main` from it into a new temporary bare repository with no global or system configuration and hashed objects, and runs `tools/agent_guard.sh` from `FETCH_HEAD`. The pattern is the only identity check on origin; everything after it reads nothing branch code can write. The merge gates' green line (`originCheck`, #74) checks origin's url, as git resolves it, against a pattern naming the hosted service's host and the run state's repository before its fetch of main. The hook line is self-contained because any script it read from the working tree is branch code's to substitute, and `contributor.md` and `planner.md` sit 60 bytes under their budgets.

## Goals / Non-Goals

**Goals:**
- No tracked file but the Makefile `toolchain` target holds the repository's address, host, or owner and name, whole or in pieces.
- The hook accepts exactly the addresses #126's pattern accepted and refuses everything else with the same message, so every route stays closed and every existing case passes.

**Non-Goals:**
- The merge gates' worktree of `origin/main` and planted objects in it (the backlog entry).
- Any change to the URL rule or `tools/scan_text.sh`.

## Decisions

- Pin by digest: `case $(printf %s "${u%.git}"|"$@" hash-object --stdin) in D1|D2|D3);;*)echo origin is not hosted>&2;exit 2;esac`, where D1, D2, D3 are the blob ids of the `https`, `ssh` with `git@`, and `git@host:path` forms without `.git`. Exact string equality with three fixed digests accepts precisely the old pattern's set (each form with `.git` optional) with no parsing to get wrong. `"$@"` is the config-free git of the line, so no `insteadOf`, filter, or global setting enters; `hash-object --stdin` applies no attributes. A repository whose configuration changes its object format hashes differently and refuses, failing closed.
- Alternatives rejected: one digest of a canonical form (shorter, but the canonicalization must refuse a local path such as `git@host/owner:name`, which git reads as a path, and admits forms the old pattern refused); a pinned root commit (any fork carries it, so a foreign origin with a permissive guard would pass, weaker than #126); a pin file, environment variable, or script outside the line (branch code can write each, or the line would read the working tree); a truncated digest (weaker).
- Bytes: the digest list is 86 bytes longer than the pattern. The line drops `p=$CLAUDE_PROJECT_DIR;` for `"$CLAUDE_PROJECT_DIR"` in its one use (4 bytes) and writes `-c transfer.fsckObjects`, a bare key git reads as true (5 bytes); the contributor's and the planner's prose lose the remaining bytes by rewording, no instruction dropped, no budget raised.
- Green line: `ORIGIN_IDS` holds six blob ids, the hook lines' three forms without `.git`, then the same three with `.git`, and `originCheck()` is `PINNED_GIT remote get-url origin | tr -d '\n' | PINNED_GIT hash-object --stdin | grep -q -x -E 'ID1|...|ID6'`. Six ids rather than stripping `.git` keep the line to commands the guard already reads, with no `sed` allowance; `remote get-url` still resolves a repository `insteadOf` (which the guard's RISKY_CONFIG refuses anyway), so an `insteadOf` to a local origin hashes to a path and fails. Dropping the run state's repository removes the one input branch code could write. The old pattern's optional user before the host and trailing slash are refused, as the user accepted.
- Guard: `git_form` gains `hash-object` for the merger alone, accepting exactly `--stdin`; `-w` would write an object into the project's store, `--path` applies attributes and filters, `--literally` and `-t` forge objects, so every other word is refused.
- Tests: `hook()` and the merge-hook case replace the three pinned digests in the line under test with the digests of a fixture address on `host.invalid`, whose forms a command-line `insteadOf` in the hook's environment answers from the local bare repository, as before; a case checks that the replacement happened in every line, so the real pin is never silently in use, and the existing route cases run unchanged against it.

## Risks / Trade-offs

- Bootstrap: the merger's hook runs origin's main's guard, which refuses `git hash-object` until this change is on main, so this change's own green line is refused at its merge unless the guard allowance lands first or the merge is done otherwise.
- The `.git` half of `ORIGIN_IDS` cannot be checked against the hook lines in a test without the address; the test checks the first half equals the hook lines' ids and that all six are distinct, and the real check was run once against this clone's origin, accepting its form and the form with `.git`.

- A wrong digest refuses every agent call: the three digests were computed from the repository's own origin in this clone and the real hook line was run against the project once before committing.
- Renaming or moving the repository needs the three digests and `ORIGIN_IDS` recomputed (`printf %s FORM | git hash-object --stdin`), as #126's pattern needed an edit; the guard header says so.
