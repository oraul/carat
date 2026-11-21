# Backlog: tools/analysis_budget.sh

### tools/analysis_budget.sh:202: the rounds comparison runs inside an if, so a (sprint-22 sweep quality)

- Location: `tools/analysis_budget.sh:202`
- Why: the rounds comparison runs inside an if, so a rounds value that is not a number makes test error, which reads as false and passes the budget (fails open)
- Fix: refuse a rounds value that is not digits before comparing, with a tools-test case
- Category: pipeline
- Added: 2026-11-20
