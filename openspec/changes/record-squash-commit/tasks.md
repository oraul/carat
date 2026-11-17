# Tasks

## 1. Run state

- [x] 1.1 Resolve the word `merged` in `phase CHANGE merge|retro|report merged [REPORTED]` to the squash commit, noting a disagreeing REPORTED (`squash_of_change`, `tools/run_state.sh`, its header); proved by "run_state: phase merged records the merge at the squash commit, not the reported head", "run_state: phase merged notes the reported head beside the squash commit", "run_state: phase merged refuses a recorded merged that is not the squash commit", and "run_state: phase merged refuses a change with no pull request or merged commit" in `tools/tools_test.sh`

## 2. Guard

- [x] 2.1 Accept `phase CHANGE NAME merged` (NAME merge, retro, report) and `phase CHANGE merge merged COMMIT` in the close profile (`tools/agent_guard.sh`); proved by "guard: close records a phase at the merged commit" and "guard: close refuses a phase at another word" in `tools/tools_test.sh`

## 3. Workflow

- [x] 3.1 Record the merge, retro, and report phases with the word `merged`, the merger's sha only as REPORTED (`.claude/workflows/deliver-change.js`: the merge phase, `queue`, `CLOSABLE`, `closeLines`, the close prompt); proved by "workflow: a merger reporting the pushed head records the squash commit as phase.merge, phase.retro, and phase.report" in `tools/tools_test.sh`
- [x] 3.2 Run every close record line whatever an earlier one did and report the refused ones (`recordLine`, the `CLOSE` schema's `refused`, the refused-line note); proved by "workflow: a close record line with one refused phase still records the rest and every metric field" and "workflow: the refused close lines are noted by their text" in `tools/tools_test.sh`

## 4. Agents and docs

- [x] 4.1 Name where the merged commit comes from in `.claude/agents/merger.md` and `.claude/agents/retrospective.md`, and the record line's new shape (docs only; the guard and agent cases in `tools/tools_test.sh` stay green)
- [x] 4.2 Update the run state paragraph of README.md and the `tools/run_state.sh` entry of `docs/codebase-map.md` (docs only; `make docs-lint`)
- [x] 4.3 `make gates`, `make spec-validate`, `make docs-lint`, and `make tools-test` pass
