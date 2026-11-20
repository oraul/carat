# Proposal

## Why

Two security findings of Sprint 22's backlog item `pr-trust-lows` (queue line at d7f5de8):

- OpenSpec runs unpinned beside the push credentials (sprint-2 sweep security Medium (4)): `tools/spec_validate.sh:17` runs `npx -y @fission-ai/openspec@latest`, so every `make spec-validate` of the contributor and the checker fetches and runs whatever version the registry names latest at that moment, in a session that holds the repository's push credentials. `Makefile:135` (`OPENSPEC`, used by `spec-list` and `spec-update`) and the contributor's guard (`tools/agent_guard.sh:901`, which accepts `@latest` and the bare package name) leave the same opening.
- CI runs the branch's own scope script (security Low (6)): the `Scope` step of `.github/workflows/ci.yml` runs `sh tools/ci_scope.sh` from the pull request's merge commit, with `GH_TOKEN`, so a change to `tools/ci_scope.sh` or to the documentation rules it sources from `tools/rules.sh` decides by its own logic whether the checks that would test it run at all.

This is a pipeline defect outside the roadmap of `docs/architecture.md` section 12.

## What Changes

- OpenSpec is pinned to one exact version, 2.1.1 (the version `@latest` resolves to at d7f5de8, so validation does not change): `OPENSPEC_PACKAGE` in the Makefile (used by `OPENSPEC`), the default command of `tools/spec_validate.sh`, and the contributor's `npx` allowlist in `tools/agent_guard.sh`, which now refuses `@latest`, the bare package name, and any other version. CLAUDE.md's OpenSpec line names the pinned package.
- The `Scope` step of `ci.yml` reads `tools/ci_scope.sh` and `tools/rules.sh` from the merge commit's first parent, the base the pull request merges into, into the runner's temporary directory and runs that copy over the merge commit's checkout.
- `tools/tools_test.sh`: `spec_validate.sh` with no `OPENSPEC_CMD` runs the pinned package, the same one the Makefile and the guard name; the guard refuses `npx` of `@latest`, of the bare name, and of another version; the `Scope` step's commands, run in a repository whose head replaces the scope script with one that skips everything, answer with the base's script.

## Capabilities

### New Capabilities

None: the change alters the delivery tooling and CI (`skip_specs: true`).

### Modified Capabilities

None.

## Out of scope

- The other eight headings of the queue line (`open_pr.sh:118` and `open-pr.yml:39` with fork branch names, `gates.sh:112`, the review continuations of `sprint-planning.js` and `deliver-change.js`, the periodic review's Lows): queued by the planner as separate items, not copied to this change's findings file.
- No `tools/rules.sh` edit; no file of the feature lane.
- `.github/workflows/main.yml` keeps running `tools/ci_scope.sh` from its checkout: it runs only on a push to `main`, whose code is the base itself.
- The generated OpenSpec skills and commands under `.claude/` are not refreshed (`make spec-update`): they record the version that generated them and are refreshed in their own change.

## Impact

- CLAUDE.md: the OpenSpec line names `@fission-ai/openspec@2.1.1`, the only form the guard lets the contributor run, and the Makefile's `OPENSPEC_PACKAGE` as where it is pinned.
- README.md: the OpenSpec commands row says they run the pinned version.
- docs/architecture.md: section 10's CI paragraph says the scope is the base's script.
- docs/codebase-map.md: area 1's `tools/ci_scope.sh`, `tools/spec_validate.sh`, and `ci.yml` entries.
