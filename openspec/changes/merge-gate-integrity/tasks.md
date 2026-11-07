# Tasks

## 1. The origin gate and the guard's configuration check

- [x] 1.1 `tools/rules.sh` and `tools/gates.sh`: `RISKY_CONFIG` and the `origin` gate, first in `pre-push` and `merge`. Tested by the "gates: origin" cases (a risky key, a fetch refspec, a local origin, a rewritten ref, a clean local base).
- [x] 1.2 `tools/agent_guard.sh`: refuse every call while the configuration sets a risky key; the copy of the list equal to `rules.sh`'s. Tested by "guard: a risky configuration key refuses every call" and "guard: the guard's risky keys are the gates'".

## 2. Records this start made

- [x] 2.1 `.claude/workflows/deliver-change.js`: `ran`, `passedAt`, `mergeRecords`, the skip helpers on `ran`, the merge records from `ran`, `verify()` before the merger on a resume past the push. Tested by the "workflow: a forged record" cases.

## 3. The merge-tool hook

- [x] 3.1 `tools/run_state.sh`: `gated CHANGE clear|pass`, `set` refusing `gated`, `push` writing `gated none`. Tested by the "run_state: gated" cases.
- [x] 3.2 `tools/gates.sh`: the merge group clears and records `gated`. Tested by "gates: merge records the head it passed at".
- [x] 3.3 `tools/agent_guard.sh` and `.claude/agents/merger.md`: the merge tool's check and its hook matcher; the green line fetches first. Tested by the "guard: merge tool" cases and "guard: merger runs the green line".

## 4. Docs and bookkeeping

- [x] 4.1 `README.md`, `docs/codebase-map.md` area 1, `.claude/agents/contributor.md` (fetch before the push), and `docs/backlog.md` (the three entries removed, the residual risks added).

## 5. Review fixes

- [x] 5.1 `tools/gates.sh` and `tools/agent_guard.sh`: refuse a hook other than a sample in the hooks directory, and run their git with `GIT_CONFIG_GLOBAL=/dev/null` and `GIT_CONFIG_NOSYSTEM=1`. Tested by "gates: origin refuses a hook in the hooks directory", "guard: a planted hook refuses every call", and "gates: origin ignores a global insteadOf".
- [x] 5.2 `.claude/workflows/deliver-change.js` and `tools/agent_guard.sh`: the green line's fetch and worktree add run with no global or system configuration and no hook (`PINNED_GIT`), which the guard admits before git only with those exact values. Tested by "guard: merger runs the green line", the three "guard: merger refuses" assignment cases, and "workflow: the green line fetches and adds the copy".
- [x] 5.3 `.claude/workflows/deliver-change.js`: the resume check runs again only when this start holds no check or review record of a kind (`ranAll`), and without fix rounds (`verify(false)`), so the package step's records-only commits do not rerun the reviews. Tested by "workflow: a resume past the push checks and reviews again unless this start ran them".
- [x] 5.4 `tools/tools_test.sh`: "run_state: push clears a gated marker recorded before it".
