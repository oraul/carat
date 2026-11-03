# Tasks

## 1. Run state and gates

- [x] 1.1 Add `tools/run_state.sh` (`init`, `set`, `get`, `show`, `phase`, `review`, `stage`, `check`, `push`, `status`); verify with `make tools-test`.
- [x] 1.2 Add `tools/gates.sh` (`trailer`, `content`, `snapshots`, `docs`, `security`, `pushes`, `pr-body`, and the groups `static`, `pre-push`, `merge`); verify with `make tools-test`.
- [x] 1.3 Add `tools/tools_test.sh` covering `tools/ci_scope.sh`, the run state, and every gate's pass and refusal; verify with `make tools-test`.

## 2. Stage list and CI

- [x] 2.1 Add `CHECK_STAGES`, `stages`, `config-current`, `gates`, and `tools-test` to the Makefile, make `check` run the list, check `bin/carat.rb`'s analysis budget in `dev-build`, and remove the URL from `spinel-rev`; verify with `make stages`, `make dev-build`, and `make spinel-rev`.
- [x] 2.2 Mirror the list in `.github/workflows/ci.yml` (config-current, tools-test) with the recorded differences; verify by reading it against `CHECK_STAGES` and by CI on the pull request.

## 3. Agents, workflow, and commands

- [x] 3.1 Add the seven agents under `.claude/agents/`; verify each against its phase and that none sets `model:`.
- [x] 3.2 Add `.claude/workflows/deliver-change.js`; verify that it parses with `node --check` and reads against the phases.
- [x] 3.3 Add `.claude/commands/deliver.md` and `status.md`; verify `sh tools/run_state.sh status`.
- [x] 3.4 Reshape `.claude/agents/contributor.md` around the phases with the conflicts resolved; verify by reading it against `CLAUDE.md`.

## 4. Docs

- [x] 4.1 Update `CLAUDE.md` (security first, Git workflow, Pull requests, Agents, Commands) within its current size; verify with `wc -c`.
- [x] 4.2 Update `docs/codebase-map.md` areas 1 and 18 and the delivered changes within its current size; verify with `make lint` and `wc -c`.
- [x] 4.3 Add the README section on how carat is built with AI; verify by reading it against what this change ships.

## Workflow follow-up

- Run `make check` on the committed tree through `tools/run_state.sh check`, the new gates on the branch, and the security review on the committed diff.
- Push once, open the pull request with the gates' output, strip any footer, wait for CI, and squash-merge.
