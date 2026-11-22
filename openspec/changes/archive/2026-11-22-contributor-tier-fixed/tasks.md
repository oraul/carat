# Tasks

## 1. Workflow

- [x] 1.1 Give every contributor start its `agent/high` profile and note an escalation in a critical run too in `deliver-change.js`; proved by "routing: a normal, critical, large-estimate, and escalated contributor start each carries the high effort, agent/high, and no model", "routing: escalate runs once and notes once, the contributor keeping agent/high", "routing: a critical run records its rule, and its escalation is noted and recorded, the profile unchanged", and the self-check case that leaves the contributor at agent/high
- [x] 1.2 Move `CALIBRATION.close` to `agent/high` and add the retrospective agent file's `model:` line; proved by "routing: the close start runs at agent/high with the high effort and no model, the security start unchanged" and "calibration: the close start runs on the retrospective's agent file's tier at high effort, the tier of the contributor's file"

## 2. Docs

- [x] 2.1 Update `docs/goals.md` (Critical changes, Escalation, Calibration with the dated entry and keep rule) and `README.md`; checked by `make docs-lint` and `make gates`
- [x] 2.2 Run `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate`

## 3. Quality review

- [x] 3.1 Reviewed the committed diff by the quality reviewer's rules: stale comments of `calibrate` and `escalate`, the README and goals prose, and the old routing cases were all updated in the change; no finding left, none recorded
