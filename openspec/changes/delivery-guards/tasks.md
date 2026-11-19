# Tasks

## 1. Findings gate

- [x] 1.1 Add the `findings` gate to `tools/gates.sh` in `static`, `pre-push`, and `merge`, with its usage text and the Makefile description
- [x] 1.2 Add tools-test cases: an appended entry passes, a removed, renamed, or dropped-file heading fails, a `sprint-N-records` change passes

## 2. Pull request text review

- [x] 2.1 Add `prTextTask`, `prTextBlocks`, and `prTextReview` to the workflow and run it after the package step, with a `prtext` call cap
- [x] 2.2 Add a tools-test case: a pr.md claiming out-of-scope work is blocked

## 3. Records and docs

- [x] 3.1 Append the dropped `LineNrFifth` finding and the #223 body finding with `>>`
- [x] 3.2 Update README.md

## 4. Review fixes

- [x] 4.1 Compare only the base's headings and the headings the branch's non-merge commits added, so a merged main that groomed an entry passes; add a tools-test case
- [x] 4.2 Add the `push --pr-text` kind (one a run, a recorded push other than HEAD, counted by the pushes gate, allowed by the agent guard) and name it in the rewrite task; add tools-test cases
- [x] 4.3 Replace the findings temporary file with a shell variable, match the records exemption exactly (`sprint-[0-9]+-records`), rewrap the merge usage line
- [x] 4.4 Measure the text review under `prtext`, move its round decision into `prTextStep` with a js case, add `prtext` to the quality reviewer's maxTurns pair
- [x] 4.5 Align the design and proposal text, add the README sentence on the text review
