# Tasks

## 1. Run state writes

- [x] 1.1 `tools/run_state.sh`: `write_key` refuses a key outside `[a-z0-9][a-z0-9_.-]*` and a key or value holding a control character; `valid` refuses a control character; `escape` only escapes `\` and `"`; `init` refuses a control character in the change, branch, and remote; `stage` checks its key first. Tested by the `tools/tools_test.sh` cases "run_state: set refuses a forged review line in its key", "... a forged phase line in its value", "... a carriage return", "... a key that is not a run state key", "metric refuses a forged line in its name", "... in its value", "note refuses a forged line in its kind", "... in its text", "review refuses a forged line in its summary", "stage refuses a forged line in its name", "init refuses a forged line in its branch", "... a control character in the change name", "no forged line reached the file", and "a refused init writes no state".

## 2. Merged values

- [x] 2.1 `tools/run_state.sh`: `merged_commit`; `set` refuses a `merged` or `pushed` value that is not hexadecimal; `pending_list`, `newest_pending`, `history_row`, `estimate_of`, and `review_due` read `merged` through it and pass it to git after `--end-of-options`. Tested by the cases "set refuses an option-shaped merged value", "... pushed value", "budget passes git only a commit hash as the merged value", "pending skips an option-shaped merged value" (so `bench`'s `newest_pending` never reads it), "review-due refuses an option-shaped merged value", and "history never passes the merged value to git as an option".

## 3. Trusted records

- [x] 3.1 `tools/run_state.sh trusted`: the state without the `phase.*`, `review.*`, and `merged` records git does not support, with an `untrusted` key naming them. Tested by the cases "trusted keeps a record at an ancestor of HEAD", "trusted keeps a review at an ancestor of HEAD", "trusted keeps a record at a commit of main", "trusted keeps the merged commit on main", "trusted leaves out a record at a commit off the branch", "trusted names what it left out" (a missing commit, a value that is not hexadecimal, a second line of a key, and a key with an escape), "trusted prints one flat object", "trusted leaves the file as it was", and "trusted without the base still trusts the ancestors of HEAD".
- [x] 3.2 `.claude/workflows/deliver-change.js`: the resume returns `trusted`'s output as `state_json` and notes `untrusted`; checked by `node --check` and by parsing this change's own `trusted` output with `JSON.parse` (no dry run of the workflow can run inside its own delivery).

## 4. Merge gates

- [x] 4.1 `tools/gates.sh`: `gate_passed` in the `merge` group; `gate_records` refuses an empty `RECORDS`; `settled_at` checks its commit. Tested by the cases "gates: passed refuses a merge given no records", "... without a recorded push", "... when HEAD is not the pushed head", "... a blocked review", "... a record before a code change", "passed passes the four records at the pushed head", "passed passes after the planning records", "records refuses when no records are given", and "merge refuses a merge given no records".

## 5. Docs and bookkeeping

- [x] 5.1 `docs/codebase-map.md` area 1, `README.md`, the header comments of both scripts; `docs/backlog.md`: remove "The records gate passes a merge given no records" and "The run state's merged value reaches git log unchecked", add the three entries of `build/plan/backlog.md`, and replace the stale line references of the REVIEW_AREAS, agent guard, and file operations entries with names. Checked by `make docs-lint`, `make tools-test`, and `make gates`.
