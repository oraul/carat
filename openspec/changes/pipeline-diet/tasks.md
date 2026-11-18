# Tasks

## 1. Plan

- [ ] 1.1 `tools/run_state.sh` `plan_needed`: an unestimated head item is needed, and a pending change's notes are not counted once a sprint records change merged after it; proved by "plan-needed asks for an estimate of an unestimated head", "plan-needed leaves notes a later sprint plan placed", and "plan-needed keeps a records change's own notes" in `tools/tools_test.sh`

## 2. Scout

- [ ] 2.1 `.claude/workflows/deliver-change.js` `PACK_CURRENT`, `SCOUT_PLAN` (`unread`), `scoutTargets` (`named`), the contributor's prompt, and `.claude/agents/scout.md` step 3; proved by "a pack missing a location is reused with its unread locations", "an area whose locations the brief names starts no scout", "an area the brief does not name is scouted", and the updated currency cases

## 3. Merge and package

- [ ] 3.1 `mergerCap` and `FIXED_CAPS.merger` in `.claude/workflows/deliver-change.js`, `.claude/agents/merger.md` text and `maxTurns`; proved by "the merger's cap is its work and 2 for every wait" and the caps cases
- [ ] 3.2 `tools/run_state.sh reviewed-edits`, the contributor's guard verb in `tools/agent_guard.sh`, and the package step of `.claude/agents/contributor.md`; proved by "reviewed-edits refuses an edit of a reviewed file", "reviewed-edits passes records-only edits", "reviewed-edits refuses without a security review", and "guard: the contributor runs reviewed-edits"
- [ ] 3.3 `tools/docs_lint.sh` `check_paths` skips the change's own queue item; proved by "docs-lint passes a dead path on the change's own queue item" and "docs-lint fails a dead path on another queue item"

## 4. Docs and checks

- [ ] 4.1 `README.md` and `docs/codebase-map.md` (docs only; `make docs-lint` and `make gates`)
- [ ] 4.2 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass
