# Design

## Context

`make spec-validate` (`tools/spec_validate.sh`) runs in the contributor's and the checker's sessions, which hold the push credentials of the repository; `npx -y PACKAGE@latest` resolves the tag on the registry at every call and runs the package's code there. The contributor also runs OpenSpec directly, through `npx`, as CLAUDE.md says; its guard (`tools/agent_guard.sh`, `judge`, the `npx` form) is what limits which package it may fetch.

In CI the `Scope` step decides whether the toolchain, builds, and tests run (`run`), whether the tools test runs (`tools`), and whether anything compiles (`compile`); the job `spin` reports a pass either way, and it is the required check. On a pull request the checkout is the merge commit `refs/pull/N/merge` with `fetch-depth: 2`, whose first parent is the base branch's head.

## Decisions

- One exact version, `2.1.1`, the version `@latest` names at d7f5de8, so `make spec-validate` validates exactly as before. An npm version once published cannot be replaced, so the pinned name always fetches the same code. A version bump is an edit of four places in one change, which a tools-test case keeps equal: `OPENSPEC_PACKAGE` in the Makefile, the default `openspec` command of `tools/spec_validate.sh`, the guard's `npx` case, and CLAUDE.md's OpenSpec line, which agents run as written. The guard cannot read the Makefile at hook time, and `spec_validate.sh` runs without `make` in the tools test, so the literals stay, checked equal rather than shared; the guard's header comment and its npx refusal name `OPENSPEC_PACKAGE` instead of a fifth literal, which a tools-test case checks; `tools/rules.sh`, the one file all three tools source, is out of reach of this change (main's merge gate reads it).
- The guard refuses `npx` of the bare `@fission-ai/openspec` too: npx runs whatever version its cache holds or the registry names for it, as unpinned as `@latest`. The bare `openspec` command stays allowed: it is an installation the user made, nothing npx fetches.
- The `Scope` step writes `git show HEAD^1:tools/ci_scope.sh` and `HEAD^1:tools/rules.sh` to `$RUNNER_TEMP/base-tools/` and runs `sh "$RUNNER_TEMP/base-tools/ci_scope.sh"` from the checkout: the script sources `rules.sh` from its own directory and reads the merge commit through git in the current directory, so the base's rules judge the pull request's files. `HEAD^1` is already in the checkout (`fetch-depth: 2`), so no other checkout or token is needed. A pull request that changes `tools/ci_scope.sh` or `tools/rules.sh` is judged by the base's copy, which counts both as code and runs the checks, where the tools test exercises the new copy.
- The workflow file itself still comes from the pull request (GitHub runs a `pull_request` workflow from the merge commit), so a pull request editing `ci.yml` can still change the step; that edit is a visible change to a workflow file in the reviewed diff, where a changed scope script or documentation rule judging itself was not.

## Testing

- `spec_validate.sh` with `OPENSPEC_CMD` unset runs a stub `npx` first on `PATH` that logs its arguments; the log names `@fission-ai/openspec@2.1.1`. Before the fix it names `@latest`.
- The four pins are read from the Makefile, the script, the guard, and CLAUDE.md and compared.
- The guard refuses `npx -y @fission-ai/openspec@latest`, `npx @fission-ai/openspec`, and another version, and accepts the pinned one (the two existing contributor cases now use it).
- The `Scope` step's `run:` block is read from `ci.yml` and run in a temporary repository whose first parent holds the real `ci_scope.sh` and `rules.sh` and whose head replaces `ci_scope.sh` with a script answering `run=false`; the answer is `run=true`. Before the fix the step runs the head's script and answers `run=false`.

## Risks

- A new OpenSpec release is no longer picked up until the pin is bumped; that is the point of the pin.
- A pull request whose base lacks `tools/ci_scope.sh` would fail the step; every base since the script was added has it.
