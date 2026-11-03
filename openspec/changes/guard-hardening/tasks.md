# Tasks

## 1. Agent guard

- [x] 1.1 `tools/agent_guard.sh`: remove quotes and backslashes from a Bash command's text before every rule. Tested by the `tools/tools_test.sh` cases "guard: read refuses a quoted git push", "guard: read refuses a quoted git", "guard: read refuses an escaped git", "guard: read refuses a split git verb", "guard: read refuses a quoted gh", "guard: contributor refuses a quoted push", "guard: read refuses a quoted run state record", "guard: read refuses a quoted run state path", and "guard: read allows a quoted git read".
- [x] 1.2 `tools/agent_guard.sh`: the contributor and merger profiles refuse a link, move, or copy onto the body file and a command naming a body file that is a link; a file edit is judged by its real path too, and a body file that is a link is refused. Tested by the cases "guard: contributor refuses a link at the body file", "guard: merger refuses a move onto the body file", "guard: merger refuses a write to a linked body file", "guard: contributor refuses a path through a dangling link", "guard: contributor refuses a command on a linked body file", "guard: contributor refuses a write to a linked body file", "guard: contributor refuses a linked directory into the run state", "guard: read refuses a link out of its directory", and "guard: contributor writes the body file in a real tree".
- [x] 1.3 `tools/gates.sh`: `gate_pr_body` refuses a body file that is a link. Tested by the case "gates: pr-body refuses a linked body file".

## 2. Review areas

- [x] 2.1 `tools/run_state.sh`: `REVIEW_AREAS` gains `entry point` and `tooling and CI` and the generator in config loading. Tested by the cases "run_state: review-due names the entry point", "run_state: review-due names a tool", "run_state: review-due names an agent", "run_state: review-due names the CI workflow".
- [x] 2.2 `tools/run_state.sh`: `review_due` leaves out `config/default.caratrc` and its mirror when only key bindings, comments, and blank lines changed there. Tested by the cases "run_state: review-due skips a keymap-only change", "run_state: review-due names a changed option", "run_state: review-due names the mirror changed alone", "run_state: review-due names a loader", and "run_state: review-due names the generator".

## 3. Workflow advisories

- [x] 3.1 `.claude/workflows/deliver-change.js`: merge the advisories of every quality review without duplicates, seed them from every `quality-advisory` note, hand the package step the findings and the CI fix's push those that arrived after it. Checked by `node --check`.
- [x] 3.2 `.claude/agents/contributor.md`: push mode puts the findings it is given into `docs/backlog.md` and commits before the push. Checked by `make docs-lint` (agent budget).

## 4. Small fixes

- [x] 4.1 `tools/ci_wait.sh`: one refusal message, a failing `sleep` exits 1. Tested by the case "ci_wait: fails when the sleep fails" and the existing refusal cases.
- [x] 4.2 `Makefile`: the `tools-test` help names every tool `tools/tools_test.sh` tests; `tools/tools_test.sh` header rewrapped. Checked by `make help`.

## 5. Docs and records

- [x] 5.1 The review areas in `README.md`, `docs/goals.md`, `.claude/commands/review.md`, and `.claude/workflows/periodic-review.js`; area 1 of `docs/codebase-map.md` for the guard, the run state, `ci_wait.sh`, and the gates. Checked by `make docs-lint` and `make gates`.
- [x] 5.2 `docs/backlog.md`: remove the three entries this change fixes; add the entries of `build/plan/backlog.md` this change leaves (the `/status` and killed-run phase loss, the merger's foreground sleep). Checked by `make docs-lint`.
- [x] 5.3 Run `make tools-test`, `make lint`, `make docs-lint`, and `make gates`.
