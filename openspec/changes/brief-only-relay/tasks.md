# Tasks

## 1. The brief in every start

- [x] 1.1 Keep only the known arguments in `input` (`ARG_KEYS`, `startInput` in `.claude/workflows/deliver-change.js`), proven by "workflow: a start's prompt holds only the brief or the resume brief" in `tools/tools_test.sh`
- [x] 1.2 Build every contributor start from `contributorTask` with the brief, proven by "workflow: the brief, a hold for the user included, reaches every contributor start" in `tools/tools_test.sh`
- [x] 1.3 Name only the queue plan-needed read in the resume brief (`resumeBrief`), proven by "workflow: the resume brief names only the queue plan-needed read" in `tools/tools_test.sh`

## 2. The exception marker

- [x] 2.1 Honor a `The user-approved exception` line under a sprint heading and fix the usage header (`tools/docs_lint.sh`), proven by "docs_lint: a marked sprint of 4 pipeline items passes" and "docs_lint: an unmarked sprint of 4 pipeline items fails" in `tools/tools_test.sh`

## 3. Docs and close

- [x] 3.1 Update CLAUDE.md's Agents section (the brief in every contributor start, the sprint marker) and area 1 of `docs/codebase-map.md`
- [ ] 3.2 Run `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate`
