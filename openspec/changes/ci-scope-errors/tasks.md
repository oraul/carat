# Tasks

## 1. Validated answers

- [ ] 1.1 `tools/ci_scope.sh`: `digits` and `hex` filters; every `gh api` answer (head sha, number, tree sha, both counts, the listed shas) validated at its assignment; the push skip needs all four valid. Proved by `tools/tools_test.sh` "ci_scope: a push whose number query answers an error body runs" and "ci_scope: a push whose every query answers an error body runs", with the existing push and green-head cases unchanged.
- [ ] 1.2 `tools/ci_scope.sh` `answer`: the reason on a single line. Proved by `tools/tools_test.sh` "ci_scope: an error body leaves GITHUB_OUTPUT one run and one reason line".

## 2. Checks

- [ ] 2.1 Run `make tools-test`, `make gates`, and `make spec-validate`.
