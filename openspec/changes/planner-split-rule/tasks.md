# Tasks

## 1. Planner

- [ ] 1.1 `.claude/agents/planner.md` step 3: the three-part or three-area split, the size-up after two overruns, the round-limit split in `notes`; wording tightened elsewhere to stay within 8,192 bytes; proved by the `tools/tools_test.sh` case "planner: the size check splits a brief of three or more parts or areas, sizes up after two overruns, and splits what a round-limit stop left" and the docs lint budget.

## 2. CLAUDE.md and README

- [ ] 2.1 CLAUDE.md: the approved lanes wording from the archived `parallel-lanes-b` design, within 30,720 bytes; proved by "claude: the Agents section names the lanes rule" and the existing "claude: the Agents section names the self-check, the review fix, the gate-rules rule, and the merged-name refusal".
- [ ] 2.2 README.md: the planner step's size check.

## 3. Checks

- [ ] 3.1 `make docs-lint`, `make tools-test`, `make gates`, `make spec-validate`.
