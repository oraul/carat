# Backlog: openspec/changes/archive/2026-11-19-quality-first-pass/tasks.md

### Task 1.2 names a test that does not exist
- Location: openspec/changes/archive/2026-11-19-quality-first-pass/tasks.md:6
- Why: task 1.2 names a test, a blocking quality finding on unchanged lines is noted as a first-pass miss, that tools/tools_test.sh does not contain.
- Fix: name the existing tests (a first-pass miss is noted only for a new marked finding; the quality handler notes first-pass misses only when the prior list is the last review's).
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-19
