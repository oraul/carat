## 1. Contributor quality step

- [ ] 1.1 Add `operations.apply.guidance` and `operations.archive.guidance` for the quality step to `openspec/config.yaml`; checked by `openspec validate` and `make spec-validate`
- [ ] 1.2 Make card rule 10 and the implement steps of `.claude/agents/contributor.md` the quality step, with `CONTRIBUTOR_CARD` in `.claude/workflows/deliver-change.js` word for word; proven by the tools-test card comparison
- [ ] 1.3 Add the `quality_review` result field, its refusal in `contributor()`, `metric.quality_review`, and `qualityStep()` before the archive and package step (`.claude/workflows/deliver-change.js`); proven by tools-test cases for a refused result, a restart, a stop, and the step before package

## 2. Quality phase removed

- [ ] 2.1 Remove the quality reviewer start, its scope, split, advisories, rounds, carry, and records from `.claude/workflows/deliver-change.js`, the reviews being the security review alone; proven by tools-test cases that a delivery starts no quality-reviewer but the text check and that the security reviewer still runs and blocks
- [ ] 2.2 Require check, security, and bench in the `passed` gate of `tools/gates.sh`; proven by the tools-test gate case
- [ ] 2.3 Update the tools-test cases of the removed helpers and caps (`tools/tools_test.sh`), and prove sprint-planning still starts its quality review

## 3. Docs

- [ ] 3.1 Update CLAUDE.md's Agents phases line, README.md's pipeline steps, `docs/goals.md`, `docs/contributor-notes.md`, and the quality reviewer's use line; checked by `make docs-lint` and `make gates`
