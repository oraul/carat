# Design

## Context

Each agent's PreToolUse hook line reads `remote.origin.url` from the repository's own configuration, checks it against a `case` pattern holding the repository's address in pieces, fetches `refs/heads/main` from it into a new temporary bare repository with no global or system configuration and hashed objects, and runs `tools/agent_guard.sh` from `FETCH_HEAD`. The pattern is the only identity check on origin; everything after it reads nothing branch code can write. The hook line is self-contained because any script it read from the working tree is branch code's to substitute, and `contributor.md` and `planner.md` sit 60 bytes under their budgets.

## Goals / Non-Goals

**Goals:**
- No tracked file but the Makefile `toolchain` target holds the repository's address, host, or owner and name, whole or in pieces.
- The hook accepts exactly the addresses #126's pattern accepted and refuses everything else with the same message, so every route stays closed and every existing case passes.

**Non-Goals:**
- The merge gates' `originCheck` and the merge gates' worktree (the latter goes to the backlog).
- Any change to the URL rule or `tools/scan_text.sh`.

## Decisions

- Pin by digest: `case $(printf %s "${u%.git}"|"$@" hash-object --stdin) in D1|D2|D3);;*)echo origin is not hosted>&2;exit 2;esac`, where D1, D2, D3 are the blob ids of the `https`, `ssh` with `git@`, and `git@host:path` forms without `.git`. Exact string equality with three fixed digests accepts precisely the old pattern's set (each form with `.git` optional) with no parsing to get wrong. `"$@"` is the config-free git of the line, so no `insteadOf`, filter, or global setting enters; `hash-object --stdin` applies no attributes. A repository whose configuration changes its object format hashes differently and refuses, failing closed.
- Alternatives rejected: one digest of a canonical form (shorter, but the canonicalization must refuse a local path such as `git@host/owner:name`, which git reads as a path, and admits forms the old pattern refused); a pinned root commit (any fork carries it, so a foreign origin with a permissive guard would pass, weaker than #126); a pin file, environment variable, or script outside the line (branch code can write each, or the line would read the working tree); a truncated digest (weaker).
- Bytes: the digest list is 86 bytes longer than the pattern. The line drops `p=$CLAUDE_PROJECT_DIR;` for `"$CLAUDE_PROJECT_DIR"` in its one use (4 bytes) and writes `-c transfer.fsckObjects`, a bare key git reads as true (5 bytes); the contributor's and the planner's prose lose the remaining bytes by rewording, no instruction dropped, no budget raised.
- Tests: `hook()` and the merge-hook case replace the three pinned digests in the line under test with the digests of a fixture address on `host.invalid`, whose forms a command-line `insteadOf` in the hook's environment answers from the local bare repository, as before; a case checks that the replacement happened in every line, so the real pin is never silently in use, and the existing route cases run unchanged against it.

## Risks / Trade-offs

- A wrong digest refuses every agent call: the three digests were computed from the repository's own origin in this clone and the real hook line was run against the project once before committing.
- Renaming or moving the repository needs the three digests recomputed (`printf %s FORM | git hash-object --stdin`), as #126's pattern needed an edit; the guard header says so.
