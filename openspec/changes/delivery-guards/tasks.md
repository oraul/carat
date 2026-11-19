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
