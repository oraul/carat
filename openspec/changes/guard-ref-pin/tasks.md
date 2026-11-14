# Tasks

## 1. Hooks read main's guard at origin's answer

- [x] 1.1 `.claude/agents/*.md`: every hook line resolves main with a config-free `git ls-remote` of the validated `remote.origin.url`, fetches the commit without writing a ref when it is missing, and runs `tools/agent_guard.sh` at that commit; the merger's merge-tool line keeps its merge-tool check. Proved by `tools/tools_test.sh` "guard: the $a hook refuses with origin's main's guard when origin/main was moved locally" and "guard: the $a hook allows a git read".
- [x] 1.2 `tools/tools_test.sh`: the hook cases run against a hosted-looking origin answered by a local bare repository; cases "guard: every hook line resolves main the same way", "guard: a hook refuses a local origin", "guard: a hook ignores a repository insteadOf", "guard: a hook fetches a main the repository lacks", "guard: a hook refuses when origin cannot be reached", and the merge-hook cases with main pushed to the origin.

## 2. Docs

- [x] 2.1 `tools/agent_guard.sh` header comment, the `agent_guard.sh` bullet of `docs/codebase-map.md`, and the guard sentence of `README.md`: the guard is read at origin's main as `ls-remote` reports it. Proved by `make docs-lint` and `make gates`.

## 3. Checks

- [x] 3.1 Run `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate`.
