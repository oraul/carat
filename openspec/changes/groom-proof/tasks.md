# Tasks

## 1. Groom proofs

- [x] 1.1 `listed` in `groom` (`tools/run_state.sh`, `item_lists`) requires a change of the sprint whose queue item holds the heading; proved by "run_state: groom refuses a listed change outside the sprint", "run_state: groom refuses a listed change whose item lacks the heading", and "run_state: groom removes a merged item's listed headings and no others" in `tools/tools_test.sh`
- [x] 1.2 `fixed` in `groom` (`tools/run_state.sh`, `touches_entry`) requires a commit of the sprint's range changing a file the entry names; proved by "run_state: groom refuses a fixing commit at or before the sprint's base", "run_state: groom refuses a fixing commit touching no file of the entry", "run_state: groom removes a security entry with its fixing commit", and "run_state: groom removes a group of findings with a commit touching a file it names"
- [x] 1.3 The duplicate guard reads a security severity marker; proved by "run_state: groom keeps a disputed security entry", "run_state: groom keeps a security finding inside a group", and "run_state: groom removes a duplicate whose text only mentions security"

## 2. Docs and checks

- [x] 2.1 The `groom` lines of the `tools/run_state.sh` header, README.md pipeline step 11, `docs/codebase-map.md` (`tools/run_state.sh`), and `.claude/agents/planner.md` step 1
- [x] 2.2 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass

## 3. Review fixes

- [x] 3.1 `item_lists` requires the heading bounded in the item (no `#` before it; after it a closing quote, a backtick, a comma, or the end), fixing the bare substring match the quality and security reviews found; proved by "run_state: groom refuses a listed heading that only prefixes a longer quoted one"
- [x] 3.2 `touches_entry` accepts a `.` after a path only when no path character follows it; proved by "run_state: groom refuses a fix whose file the entry's path extends past a dot"
- [x] 3.3 The refusal of every `fixed` line when `sprint_base` names no commit, checked once per run (`base_ok`); proved by "run_state: groom refuses every fixed line when the sprint's base names no commit"
- [x] 3.4 `SECURITY_MARK` also reads the skeptic's `security disputed` and a severity and confidence pair (`High (8)`); proved by "run_state: groom keeps an entry quoting a skeptic's disputed security finding" and "run_state: groom keeps an entry carrying a severity and confidence pair"
- [x] 3.5 `touches_entry` drops `-m`, so a merge commit proves no fix; proved by "run_state: groom refuses a merge commit as a fix, though a side it merged touched the file"
- [x] 3.6 `queue_items` prints the joined item of a change at its merged commit's parent and at the commit, shared by `item_lists` and `exception_item`; the fallback to the merged commit's own queue proved by "run_state: groom removes a listed heading whose item first stands at its merged commit"
- [x] 3.7 `backlog_pick`'s header says why its security ranking stays wider than `SECURITY_MARK`
