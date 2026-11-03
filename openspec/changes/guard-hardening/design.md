# Design

## Context

The scout pack `tmp/scout/build-and-ci-00eaa53-20261103T231702Z.md` (Commit: 00eaa53, `origin/main`, the branch's base) holds the facts used here, re-checked against `main`: the guard's matches read the command text with its quotes (`tools/agent_guard.sh` lines 73 to 89 and 126 to 132); a file edit is judged by the path string only (113 to 124); `REVIEW_AREAS` is at `tools/run_state.sh` 124 to 130 and `review_due` matches paths only (637 to 650); the workflow replaces `qualityAdvisory` on each quality review (`deliver-change.js` 332) and hands it to the package step only (449). Two of the brief's line numbers moved: the config loading pattern is at `run_state.sh:126`, not 114, and the duplicate refusal of `ci_wait.sh` is at its lines 17 and 21, not 146 (line 146 is in `tools_test.sh`). The `CLAUDE.md` part of the `tools-test` advisory no longer holds: its Commands section names `make tools-test` without a tool list, so only the `Makefile` help needs the fix.

## Decisions

### Quotes and backslashes removed before matching

The shell removes quotes and backslash escapes before it runs a word, so `git 'push'`, `"git" push`, `g\it push`, and `pu''sh` all run `git push`. The guard deletes every `'`, `"`, and `\` from a Bash command's text once, right after reading it, and every later rule (git, gh, run state, overrides, the run state's directory, the body file rewrites) reads the result. Deleting is conservative: it can join two words into one only where the shell would too, and it never removes a space, so the merger's branch deletion rule still sees a second ref. `sh -c 'git push'` and `eval "git push"` reduce to text that names `git push` and are refused with no rule of their own. A file tool's path is not rewritten, since a quote in a path is a literal character. `RUN_STATE` drops its optional quotes, which are gone.

### Links and the body file

The contributor and the merger may name `build/pipeline/CHANGE.body.md`. Before the body-file rewrite, both profiles refuse a command that names a body file with `ln`, `mv`, `cp`, `install`, or `link`, and a command naming a body file that already is a link (`-L` under `CLAUDE_PROJECT_DIR`, else the working directory). For a file tool the guard computes a real path: a final link followed (at most eight hops, else refused), then the nearest existing directory resolved with `pwd -P` and the rest appended; a dangling link on the way is refused. A path with a parent step (`..`) is refused for every profile before it is resolved, and so is a link target whose parent step follows a missing directory: the write resolves such a step lexically, past a linked directory before it, while the guard could not. The run-state-directory rule then reads both the path and the real path (each with the body-file rewrite for those two profiles), a read or merger agent's file must lie under the real path of its DIR as well as under DIR as written, and a body file that is a link is refused outright. `readlink` without options is used, available on Linux and macOS. `gate_pr_body` in `tools/gates.sh` refuses a body file that is a link, so the merge never reads the run state as the body.

### Review areas

Two lines are added: `entry point=^bin/carat[.]rb$` (the composition root constructs every driver) and `tooling and CI=^(tools/|\.claude/|\.github/workflows/)` (the gates, the guard, the agents, the workflows, and CI decide what is checked). The config loading area gains `bin/carat-gen-config[.]rb$`, the generator of the mirror, so the keymap exception below can trust the mirror to follow the file. `review_due` reads the changed lines of `config/default.caratrc` (`git diff -U0`); when every added or removed line is a `keymap.*` line, a comment, or blank, the file and `carat/domain/default_config.rb` are dropped from the paths before the areas are matched. The mirror changed without the file still matches; the `config-current` stage keeps the mirror equal to the generator's output. Every other area is unchanged.

### Advisories of every round

`qualityAdvisory` becomes the run's list: each quality review appends the advisories not already in it, in order. `seed()` rebuilds it on a resume from every `quality-advisory COMMIT TEXT` note, whatever its commit, without duplicates, independently of the last review's record, since an earlier round's review record is overwritten by the next. The package step receives the security lines and the advisories as before and the workflow remembers what it handed over; the push of a CI fix receives the findings that arrived since, which the contributor's push mode puts into `docs/backlog.md` and commits before `tools/run_state.sh push`. A backlog-only commit keeps the stages and reviews settled. On a resume after the push, everything seeded counts as handed over, so a restart cannot hand an entry twice; an advisory of a CI-fix round before such a restart stays in its note for the planner.

### Small fixes

`tools/ci_wait.sh` keeps one refusal message in a function and exits 1 with `ci_wait: sleep failed` when `sleep` fails, tested with a failing `sleep` first on the `PATH`. The `tools-test` help line lists the tools `tools/tools_test.sh` covers. The header of `tools/tools_test.sh` is rewrapped at its width.

## Non-goals

A command hidden behind a variable, a glob, `$'...'`, or a script file; the time between the guard's check and the command (a link made by another process in between); the `/status` phase display and the killed-run phase loss; the merger's reliance on a foreground sleep. The last two are recorded in `docs/backlog.md`.

## Risks

Removing quotes makes the guard refuse text that only mentions a refused command inside quotes, such as a commit message naming `gh pr`; the guard's header already sends such text through the Write tool and a message file. The `tooling and CI` area makes the periodic review due after most workflow changes, which is the finding's intent.
