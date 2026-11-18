# Proposal

## Why

`sh tools/run_state.sh check` runs the checker's stages `CHECK_JOBS` at a time in the order `STAGE_AFTER` gives, and `STAGE_AFTER` has no pair for gates. The gates stage runs `sh tools/gates.sh static`, whose `snapshots` gate runs the changed snapshots' tests on `build/test/run_all` and fails when the runner is missing, so a branch that changes a `test/*.expected` fails gates at once whenever gates starts before test-build has compiled the runner, killing test-build and the other running stages (gutter-signcolumn's check at 118500e1d053: gates failed after 1 s, test-build and diagnose were killed after 28 s). The brief is `brief.md`; outside the roadmap of `docs/architecture.md` section 12, a blocking pipeline defect.

This restates the findings entry gutter-signcolumn appended about it (`docs/findings/gutter-signcolumn.md`, on that unpushed branch; not read here): the check starts gates before test-build compiled `build/test/run_all`, so gates' snapshots gate fails on a missing runner for any change that edits a snapshot; the fix is a `gates:test-build` pair in `STAGE_AFTER`. Once gutter-signcolumn merges, the sprint groom can list that entry as fixed by check-stage-order.

## What Changes

- `STAGE_AFTER` in `tools/run_state.sh` gains `gates:test-build`: the gates stage starts only once test-build passed (or was skipped, carried, scoped, or compiled), as test-run already does. The other stages that read test-build's outputs already wait for it: test-run (`test-run:test-build`) runs the runner, and metrics (`metrics:test-build`) reads its timing report; diagnose reads the source `test/runner/run_all.rb`, not the runner, so it stays free.
- The comment above `STAGE_AFTER` says why gates waits.
- `tools/tools_test.sh`: a parallel check with gates queued before test-build passes and starts gates only after test-build ended.

Out of scope: `tools/rules.sh` is not edited; the stage lists (`CHECK_STAGES`, `FAST_STAGES`) and CI, which runs no gates stage, are unchanged; the skip rules of `check_stages` are unchanged. No file of the feature lane is touched.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the delivery pipeline is described by no spec under `openspec/specs/` (`skip_specs: true`).

## Impact

- `tools/run_state.sh` (`STAGE_AFTER` and its comment), `tools/tools_test.sh` (one ordering case).
- README.md: unchanged, it names no stage order.
- docs/architecture.md: unchanged, section 10 names no stage order.
- CLAUDE.md: unchanged, it says only that the checker's stages run before every push; the order is the script's.
- docs/codebase-map.md: unchanged, it names `STAGE_AFTER` without its pairs and no file is added or removed.
- Assumption: the check is longer by up to test-build's remaining time for a change whose gates stage would otherwise have run beside test-build: gates is the last of `FAST_STAGES`, but with `CHECK_JOBS` at 3 it can start as soon as the fast free stages ahead of it end, as the defect shows (gates started while test-build still ran), so the pair delays it until test-build ends.
