# Tasks

## 1. Security judged in one place

- [ ] 1.1 `tools/run_state.sh`: widen `SECURITY_MARK` to security and a severity in either order, or a severity and confidence pair, and add `security_entry HEADING`, matching the entry's lines joined; update its comment and the groom header lines. Proved by the `tools/tools_test.sh` cases "groom refuses closing an entry marked only by a Low finding of the periodic security review", "... a gone ...", "... a duplicate ...", "... a merge of it into a plain one", and the kept "groom removes a duplicate whose text only mentions security".
- [ ] 1.2 `tools/run_state.sh` `groom`: replace the four repeated checks with one guard before the kinds' proofs (`closed|gone|duplicate` refused, `merged` only into a security entry). Proved by the existing security refusal cases and the cases of 1.1.

## 2. Merged bodies no text redirects

- [ ] 2.1 `tools/run_state.sh` `groom`: prefix each `$merges` line (`@` a kept heading, `|` a line to append) and read only the prefix in the rewrite's awk. Proved by the `tools/tools_test.sh` cases "groom keeps a merged body line starting @@kept under its kept heading" and "groom sends no merged line to a heading a body line names".

## 3. Docs

- [ ] 3.1 README.md pipeline step 11 and `docs/codebase-map.md` (`tools/run_state.sh`, `groom`): the security entry's wording and `security_entry`. Proved by `make docs-lint` and `make gates`.
