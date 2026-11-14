# Tasks

## 1. Hooks read main's guard at origin's answer

- [x] 1.1 `.claude/agents/*.md`: every hook line resolves main with a config-free `git ls-remote` of the validated `remote.origin.url`, fetches the commit without writing a ref when it is missing, and runs `tools/agent_guard.sh` at that commit; the merger's merge-tool line keeps its merge-tool check. Proved by `tools/tools_test.sh` "guard: the $a hook refuses with origin's main's guard when origin/main was moved locally" and "guard: the $a hook allows a git read".
- [x] 1.2 `tools/tools_test.sh`: the hook cases run against a hosted-looking origin answered by a local bare repository; cases "guard: every hook line resolves main the same way", "guard: a hook refuses a local origin", "guard: a hook ignores a repository insteadOf", "guard: a hook fetches a main the repository lacks", "guard: a hook refuses when origin cannot be reached", and the merge-hook cases with main pushed to the origin. The security and quality fixes add "guard: the $a hook refuses an origin other than the pinned one", "guard: the $a hook refuses with main's guard past a replace ref", and "guard: a hook refuses a remote helper origin with an at sign and a colon".
- [x] 1.3 `.claude/agents/*.md`: every hook line fetches main from the pinned address with `--depth=1` into a new temporary bare repository with no global or system configuration and `transfer.fsckObjects=true`, reads the guard at its `FETCH_HEAD`, and removes it, never reading the project's objects (security review: a planted loose object under the guard blob's id, or a planted commit with a repository `insteadOf`, ran a permissive guard). Proved by `tools/tools_test.sh` "guard: the $a hook refuses with main's guard past a planted object with a mismatched hash", "guard: the hook leaves no temporary repository", "guard: the hook's fetch writes neither an object nor a ref in the repository", and "guard: a hook ignores a repository insteadOf".

## 2. Docs

- [x] 2.1 `tools/agent_guard.sh` header comment, the `agent_guard.sh` bullet of `docs/codebase-map.md`, and the guard sentence of `README.md`: the guard is fetched from origin's main into a temporary repository. Proved by `make docs-lint` and `make gates`.

## 3. Checks

- [x] 3.1 Run `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate`.
