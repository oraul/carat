# Tasks

## 1. The guard and the gate

- [x] 1.1 Take only a `CHANGE_NAME` in the guard's `lane-close` and `merge-main` forms (`tools/agent_guard.sh`); proved by the four guard cases in `tools/tools_test.sh`
- [x] 1.2 Compare groom's sprint row byte for byte, read the history rows from HEAD (`sprint-row COMMIT committed`), and refuse an edited earlier history row (`tools/gates.sh`, `tools/run_state.sh`); proved by the groom row cases in `tools/tools_test.sh`
- [x] 1.3 Drop an exact repeat of a `quality` note (`tools/run_state.sh`); proved by the quality note cases in `tools/tools_test.sh`
- [x] 1.4 Confirm the Security line suffix and the Sweep line are tested by 8b8e44e (#307); recorded in `docs/findings/sprint-guard-lows.md`

## 2. Docs

- [x] 2.1 Update the `sprint-row` words of `docs/codebase-map.md`

## Quality review

- [x] 3.1 `sprint-row COMMIT other` (a second word other than `committed`) had no test: added the usage case in `tools/tools_test.sh`
- [x] 3.2 The headings whose fix the delivery cannot derive, the moved RISKY_CONFIG heading, and the untracked marker are recorded in `docs/findings/sprint-guard-lows.md`, recorded
