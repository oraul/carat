# Tasks

## 1. Merge hook

- [x] 1.1 `merge_tool` in `tools/agent_guard.sh` compares the merge tool's `commit_message` with the archived `pr.md`'s body at the pushed head and the trailer, refusing and naming the first differing line; proved by "guard: the merge tool refuses a shortened squash message", "guard: the merge tool refuses a squash message without the trailer", "guard: the merge tool refuses a merge without a message", and "guard: the merge tool allows the exact squash message" in `tools/tools_test.sh`

## 2. Merger

- [x] 2.1 `.claude/agents/merger.md` steps 5 and 6: read the body file and pass it whole; the docs lint keeps the agent budget

## 3. Docs and checks

- [x] 3.1 README.md pipeline step 9 and `docs/codebase-map.md` (`tools/agent_guard.sh`)
- [x] 3.2 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass
