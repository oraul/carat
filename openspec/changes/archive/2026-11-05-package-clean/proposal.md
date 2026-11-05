# Proposal

## Why

Two defects of the package step, item 1 of `docs/queue.md`. First, every pull request since #32 was created with a footer holding a Claude session link, which the contributor removed in a second edit, so the link stays in the pull request's edit history against the hard rule that no session URL appears in GitHub activity (PR 57 and 58 the latest). Second, the implement step validates the change with `openspec validate <change> --strict`, which checks the delta only: a spec that only the archive's merge makes invalid first fails `openspec validate --all --strict` at the package step, after the reviews, so `theme-tokens`' package split three reviewed `color-themes` requirements over the 500-character limit and took 28 calls against 16 to 23 in the nine runs before.

The Claude Code settings reference confirms the brief's candidate: `attribution.commit` sets the trailer Claude Code adds to commits, `attribution.pr` the attribution text it adds to pull request descriptions (an empty string hides it), and `attribution.sessionUrl` (default true) whether it appends the session link, as a `Claude-Session` trailer on commits and as a link in pull request descriptions, when it commits or opens a pull request from a cloud or Remote Control session, which is how this pipeline runs. The project's `.claude/settings.json` is read by those sessions. OpenSpec's own validator (its latest release) confirms the second cause: the change validation checks the length of an ADDED requirement but leaves a MODIFIED one alone, while the main spec check after the archive fails both; a trial with a MODIFIED `start-screen` requirement of about 720 characters passed `validate <change> --strict` and failed `validate --all --strict` after the archive.

This is outside the editor roadmap of `docs/architecture.md` section 12: it changes the delivery pipeline's settings, scripts, and agent only.

## What Changes

- `.claude/settings.json` gains `attribution` with `commit` exactly the trailer of `CLAUDE.md`, `pr` empty, and `sessionUrl` false, so a pull request is created with the body file's text only and a commit gets the one allowed trailer.
- A new `attribution` gate of `tools/gates.sh`, in the `static` group that `make gates` and the `gates` stage run, refuses a `.claude/settings.json` without those three values.
- `make spec-validate` runs the new `tools/spec_validate.sh`: strict validation of every change and spec as before, then each active change archived in a copy of `openspec/` under `build/spec-preview/` and the copy validated strictly, so what the package step's archive would fail on fails at implement.
- `.claude/agents/contributor.md`: implement and fix run `make spec-validate` before they finish; package step 5 becomes a check that the pull request shows the body file's text as created, an edit only when it does not, reported.
- The plan's bookkeeping: the five entries of `build/plan/backlog.md` go into `docs/backlog.md`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change touches the delivery pipeline's settings, scripts, and agent file, and no editor behavior, so it sets `skip_specs: true`.

## Impact

- `.claude/settings.json`, `tools/gates.sh`, `tools/spec_validate.sh` (new), `Makefile` (`spec-validate`), `tools/tools_test.sh`.
- `.claude/agents/contributor.md`.
- `CLAUDE.md`, `README.md`, `docs/codebase-map.md` area 1, `docs/backlog.md`; `docs/queue.md` and `docs/metrics.tsv` at the package step.

## Out of scope

- Rewriting the edit history of the merged pull requests 32 to 58: GitHub keeps a description's earlier versions, which only the repository's owner can delete; that is outside the repository and irreversible, so it is left to the user.
- A gate that reads the created pull request: the pipeline's agents reach GitHub only through the MCP tools, so the contributor's re-read stays the check, and the next five pull requests are the acceptance.
- Making `spec-validate` a stage of `make check`: it needs `npx` and the network, which CI and the checker's stages do not assume.

## Assumptions

- The settings take effect for the sessions the workflow starts from this branch's working tree; the change's own pull request is the proof the brief asks for. If it still gets a footer, the session in use did not read the new keys, the contributor removes the footer as before, and the report says so, so the next run, started with the settings on `main`, is the test.
- The `sessionUrl` key is set beside empty `pr` rather than `attribution: false`, which needs a newer Claude Code and would make an older one skip the whole settings file.
- The archive preview runs for every active change, normally only the one being delivered; it leaves the real `openspec/` untouched.
