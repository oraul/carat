## 1. Contributor quality step

- [x] 1.1 Add `operations.apply.guidance` and `operations.archive.guidance` for the quality step to `openspec/config.yaml`; checked by `openspec validate` and `make spec-validate`
- [x] 1.2 Make card rule 10 and the implement steps of `.claude/agents/contributor.md` the quality step, with `CONTRIBUTOR_CARD` in `.claude/workflows/deliver-change.js` word for word; proven by the tools-test card comparison
- [x] 1.3 Add the `quality_review` result field, its refusal in `contributor()`, `metric.quality_review`, and `qualityStep()` before the archive and package step (`.claude/workflows/deliver-change.js`); proven by tools-test cases for a refused result, a restart, a stop, and the step before package

## 2. Quality phase removed

- [x] 2.1 Remove the quality reviewer start, its scope, split, advisories, rounds, carry, and records from `.claude/workflows/deliver-change.js`, the reviews being the security review alone; proven by tools-test cases that a delivery starts no quality-reviewer but the text check and that the security reviewer still runs and blocks
- [x] 2.2 Require check, security, and bench in the `passed` gate of `tools/gates.sh`; proven by the tools-test gate case
- [x] 2.3 Update the tools-test cases of the removed helpers and caps (`tools/tools_test.sh`), and prove sprint-planning still starts its quality review

## 3. Docs

- [x] 3.1 Update CLAUDE.md's Agents phases line, README.md's pipeline steps, `docs/goals.md`, `docs/contributor-notes.md`, and the quality reviewer's use line; checked by `make docs-lint` and `make gates`

## 4. Quality review

- [x] 4.1 Remove the `at` reader of `.claude/workflows/deliver-change.js` that only the removed quality seed called, and the tools-test stubs of it and of `addAdvisories`; proven by the closing loop's restart cases, which run `seed` without them
- [x] 4.2 Name `metric.quality_review` in the run state header of `tools/run_state.sh`, `quality_blocked` kept for older runs; documentation only
- [x] 4.3 Recorded in `docs/findings/review-in-openspec.md`: the steps 5 to 7 of `.claude/agents/quality-reviewer.md` still describe a delivery review no workflow starts; rewording them needs a decision on the pull request text check's recording, beyond this change
- [x] 4.4 Recorded in `docs/findings/review-in-openspec.md`: the advisory-only round that settles on records-only fixes can no longer arise, since only security findings are offered and a security offer never settles; removing it is new code beyond this change
- [x] 4.5 Recorded in `docs/findings/review-in-openspec.md`: a run resumed across this change no longer hands its earlier `quality-advisory` notes to the package step
- [x] 4.6 Refuse a done result for each of its problems, a head and a quality review, in `contributor()` of `.claude/workflows/deliver-change.js` (`resultProblems`): each noted under its own kind, the one restart carrying every reason and the quality step when the review is missing, each kind restarted once and its second refusal stopping the run naming the kinds refused twice; proven by the tools-test cases of a result refused for both together and of a quality review refused after a refused head
- [x] 4.7 Drop the quality review from the merge's recorded passes in README.md's gates paragraph
- [x] 4.8 Say in `docs/goals.md` that the contributor tier trials' keep rules judge without the quality first pass, which no delivery records since this change
- [x] 4.9 Make `awaiting` of `.claude/workflows/deliver-change.js` an array and drop the kind parameter of `inPlaceCheck`, `confirmInPlace`, and `continueReview`, each only given security; proven by the in-place and closing loop tools-test cases
- [x] 4.10 Word card rule 10 as done before packaging, where the package step archives (`.claude/agents/contributor.md` and `CONTRIBUTOR_CARD`), and have implement step 5 return `quality_review`; proven by the tools-test card comparison
- [x] 4.11 Name the quality step's refusal and restart, the step before the package, and the security-only reviews in the `tools/tools_test.sh` entry of `docs/codebase-map.md`
- [x] 4.12 Word each refusal note of `contributor()` in `.claude/workflows/deliver-change.js` by its own kind: `; refused twice, stopped` only for a repeated kind, `; stopped` for a new kind when the run stops, `; restarted` otherwise; proven by the tools-test case of a repeated head refusal beside a first quality refusal
