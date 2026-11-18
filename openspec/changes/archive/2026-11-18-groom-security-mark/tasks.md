# Tasks

## 1. Security judged in one place

- [x] 1.1 `tools/run_state.sh`: widen `SECURITY_MARK` to security and a severity in either order, or a severity and confidence pair, and add `security_entry HEADING`, matching the entry's lines joined; update its comment and the groom header lines. Proved by the `tools/tools_test.sh` cases "groom refuses closing an entry marked only by a Low finding of the periodic security review", "... a gone ...", "... a duplicate ...", "... a merge of it into a plain one", and the kept "groom removes a duplicate whose text only mentions security".
- [x] 1.2 `tools/run_state.sh` `groom`: replace the four repeated checks with one guard before the kinds' proofs (`closed|gone|duplicate` refused, `merged` only into a security entry). Proved by the existing security refusal cases and the cases of 1.1.

## 2. Merged bodies no text redirects

- [x] 2.1 `tools/run_state.sh` `groom`: prefix each `$merges` line (`@` a kept heading, `|` a line to append) and read only the prefix in the rewrite's awk. Proved by the `tools/tools_test.sh` cases "groom keeps a merged body line starting @@kept under its kept heading" and "groom sends no merged line to a heading a body line names".

## 3. Docs

- [x] 3.1 README.md pipeline step 11 and `docs/codebase-map.md` (`tools/run_state.sh`, `groom`): the security entry's wording and `security_entry`. Proved by `make docs-lint` and `make gates`.

## 4. Review fixes

- [x] 4.1 `tools/tools_test.sh`: a groom fixture entry naming security only in its heading and a severity only in its body (`## f periodic security note at tools/q.sh:8`, `- Severity: low`), refused as closed and as a duplicate, proving `security_entry` judges the entry's lines joined.
- [x] 4.2 `tools/tools_test.sh`: groom fixture entries worded "security review finding, rated Medium" and "rated Critical", each refused as closed and as gone, proving the first `SECURITY_MARK` alternative's gap between the word and the severity and the severity `critical`.
- [x] 4.3 `tools/run_state.sh`: the severity and confidence pair alternative of `SECURITY_MARK` takes `critical` too, as `SECURITY_SEVERITY` does, its comment naming "Critical (9)"; proved by the case "groom refuses a gone entry carrying a Critical severity and confidence pair".
- [x] 4.4 `design.md`: the channel decision describes the awk that prefixes the merged body's lines, not a `sed`.
