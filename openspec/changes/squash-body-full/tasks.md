# Tasks

## 1. Merge hook

- [x] 1.1 `merge_tool` in `tools/agent_guard.sh` compares the merge tool's `commit_message` with the archived `pr.md`'s body at the pushed head and the trailer, refusing and naming the first differing line; proved by "guard: the merge tool refuses a shortened squash message", "guard: the merge tool refuses a squash message without the trailer", "guard: the merge tool refuses a merge without a message", and "guard: the merge tool allows the exact squash message" in `tools/tools_test.sh`

## 2. Merger

- [x] 2.1 `.claude/agents/merger.md` steps 5 and 6: read the body file and pass it whole; the docs lint keeps the agent budget

## 3. Docs and checks

- [x] 3.1 README.md pipeline step 9 and `docs/codebase-map.md` (`tools/agent_guard.sh`)
- [x] 3.2 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass

## 4. Review fixes

- [x] 4.1 Test the refusals of a pushed head holding no archived `pr.md` of the change or two, and of a run state not named after a change: "guard: the merge tool refuses a head without the archived pr.md", "guard: the merge tool refuses a head with two archived pr.md", "guard: the merge tool refuses a run state not named after a change"
- [x] 4.2 Compare bytes exactly (security Low): `json_text` decodes the message whole, no fold of text outside ASCII, tabs, carriage returns, or `\b` and `\f`; proved by "guard: the merge tool allows the exact squash message" (two adjacent escaped characters, a surrogate pair, and a `\t` against pr.md's tab), "... with raw text outside ASCII", and the refusals of a question mark, a longer run, a carriage return, a space for a tab, a backspace escape, a raw control byte, and a lone surrogate
- [x] 4.3 Keep `SQUASH_TRAILER` equal to the gates' `TRAILER`: "guard: the squash trailer is the gates' trailer"
- [x] 4.4 The merger reads the body from `pr.md` at the pushed head, the hook's source, in two counted calls (nine for a first green); "guard: merger lists and prints pr.md at the pushed head" and "caps: the merger's first green fits its cap"
