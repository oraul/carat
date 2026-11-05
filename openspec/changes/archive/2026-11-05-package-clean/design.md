# Design

## Context

The scout pack `tmp/scout/build-and-ci-5ac9674-20261105T111422Z.md` holds the line references at 5ac9674; they hold. `.claude/settings.json` has only `env` and `permissions.deny`. The contributor opens the pull request with `mcp__github__create_pull_request` from the body file and then, in package step 5, re-reads it and removes the footer with `mcp__github__update_pull_request`. Strict validation runs in implement step 2 as `openspec validate "<change>" --strict` and in package step 1 as `openspec validate --all --strict` after `openspec archive`; `make spec-validate` runs the second form only and nothing calls it. One correction to the brief: implement does validate strictly already, but only the delta, which is why it passed in `theme-tokens`.

## Decisions

### The footer is Claude Code's attribution, turned off in the project settings

The settings reference names three keys under `attribution`: `commit` (the text added to commits, trailers included; unset is a `Co-Authored-By` line naming the model in use), `pr` (the text added to pull request descriptions; unset is a "Generated with Claude Code" line with a link), and `sessionUrl` (default true: the claude.ai session link, a `Claude-Session` trailer on commits and a link in pull request descriptions, from cloud and Remote Control sessions). The reference also says Claude Code tells Claude that a CLAUDE.md rule on attribution takes precedence over these lines, which is why the contributor removed them; the link reaching the pull request at creation and coming back on a REST `PATCH` (`.claude/agents/contributor.md` step 5) fits a session-level attribution, not the GitHub tool.

The project file sets:

- `commit`: exactly `Co-Authored-By: Claude <noreply@anthropic.com>`, the one trailer `CLAUDE.md` allows, so the default trailer naming a model never appears.
- `pr`: the empty string, no attribution line.
- `sessionUrl`: false, no session link in either.

Rejected: `"attribution": false`, which hides everything in one value but makes a Claude Code older than the release that accepts it skip the whole project settings file, the `OPENSPEC_TELEMETRY` and `permissions.deny` entries with it.

### A gate keeps the setting

`gate_attribution` in `tools/gates.sh` reads `.claude/settings.json` at the top of the work tree and refuses it unless it holds an `attribution` object and the three lines `"commit": "TRAILER"`, `"pr": ""`, and `"sessionUrl": false`, matched as fixed strings (the file is small and hand-written; there is no JSON tool in the stack's shell). It joins the `static` group, which `make gates` and the `gates` stage of `make check` run, so a change that drops the setting fails its check before it is pushed. It stays out of `pre-push` and `merge`: the stages gate already requires the `gates` stage at the checked commit, and the temporary repositories of the push and merge tests have no settings file.

### make spec-validate previews the archive

`tools/spec_validate.sh`, behind `make spec-validate`, runs `openspec validate --all --strict --no-interactive` in the tree, then for each directory of `openspec/changes/` but `archive`: copies `openspec/` to `build/spec-preview/openspec`, runs `openspec archive NAME -y` there (with `--skip-specs` when the change's `.openspec.yaml` sets `skip_specs: true`), and validates the copy strictly. A failure names the change and keeps the preview for reading; the real tree is never written. `OPENSPEC_CMD` overrides the command, which the tools test sets to a stub, so the script is tested without the network. Archiving with `-y` proceeds past incomplete tasks, so the preview works in the middle of implement.

The contributor runs `make spec-validate` at implement step 2 (after proposing, beside the change's own validation) and before it finishes implement and fix, so a spec the archive would reject is fixed before the checker and the reviewers see it, and package's archive edits no spec. Package step 1 runs it after the archive in place of `openspec validate --all --strict`, which it includes, so the agent file stays within its 8 KiB budget.

Rejected: a requirement-length check of our own over the delta files. It would cover the one rule seen so far and drift from OpenSpec's validator; the preview applies whatever the archive and the strict validation apply.

### Package step 5 checks instead of editing

Step 5 becomes: re-read the pull request; with the settings in place it shows the body file's text, and nothing is edited. If a line the contributor did not write is there, the contributor removes it with the GitHub MCP update tool as before and says so in its report, so a session that did not read the settings is visible in the run's notes rather than hidden.

## Risks

- The session running the pipeline may have read its settings before this branch changed them; then this change's own pull request still gets a footer. The fallback keeps the hard rule's damage to the one edit it has today, and the report names it; the next run starts with the settings on `main`.
- The preview needs `npx` and the network, as `openspec` already does in implement; it runs in the contributor only.
