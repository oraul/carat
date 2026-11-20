# Tasks

## 1. Same-repository open

- [x] 1.1 `tools/open_pr.sh open`: list with `isCrossRepository`, keep same-repository numbers, view and edit by number, read the created number; tests in `tools/tools_test.sh` ("open_pr: open opens its own pull request beside a fork's on the branch's name", "open_pr: open edits its own pull request by number beside a fork's", the existing open cases on the new stand-in)

## 2. Environment rule

- [x] 2.1 `tools/open_pr.sh rule` and its step in `.github/workflows/open-pr.yml` with `actions: read`; tests in `tools/tools_test.sh` ("open_pr: rule ..." cases, "repository: open-pr checks the environment rule with its own token before the read")

## 3. Pinned checkout

- [x] 3.1 `.github/workflows/open-pr.yml` pins `actions/checkout` by sha; test "repository: open-pr pins every action by a full commit sha"

## 4. Merger head repository

- [x] 4.1 `.claude/agents/merger.md` step 1 and `open_pr.sh wait`'s comment and usage; test "repository: the merger merges only a pull request of this repository and branch"

## 5. Docs

- [x] 5.1 README.md step 9, `docs/codebase-map.md` area 1, CLAUDE.md's `open_pr.sh` Commands line

## 6. Review fixes

- [x] 6.1 `.claude/agents/merger.md` step 1 names the head commit, head repository, head branch, and title, and requires the head repository and head branch to be the input's; test "repository: the merger merges only a pull request of this repository and branch" matches both phrases
- [x] 6.2 `tools/open_pr.sh open` reads the list once: one awk refuses a malformed line and prints the same-repository numbers, the count taken from its output; tests "open_pr: a list line without a number and repository flag is refused", "open_pr: a malformed list line after a same-repository one is refused"
- [x] 6.3 CLAUDE.md's `open_pr.sh` Commands line keeps its wording and only adds `rule`
