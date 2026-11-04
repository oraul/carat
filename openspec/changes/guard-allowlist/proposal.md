# Proposal

## Why

The agent guard refuses commands by matching their text against a list of refused forms, and three changes in a row (`agent-authority`, `workflow-trim`, `guard-hardening`) found a new form that passes it. The periodic review at 8c340cd found more: under the read and contributor profiles `git -c alias.p=push p`, `git send-pack`, `git update-ref`, `git branch -f`, `git checkout -- .`, and `git config` all pass (security Medium (7), `tools/agent_guard.sh:137`), and Bash ANSI-C quoting (`git $'\x70ush'`) passes as an unknown word (Low (7)). Separately, `settled_at` in `tools/gates.sh` lists the changes since a reviewed commit with rename detection on, so a code file moved into `openspec/` after the review reads as settled (security Medium (6), `tools/gates.sh:77`), and the agents' hooks fail open: Claude Code blocks a call only on exit 2, so a guard that is missing, edited, or fails on an error allows every call (Low (6)). `docs/queue.md` item 1 (T3) places them together.

## What Changes

- `tools/agent_guard.sh` becomes an allowlist: a Bash command is split into shell words and simple commands as the shell would, and each simple command must match a form its profile lists (the command, its subcommand or verb, and the options and values it may take); everything else is refused. Constructs the guard cannot read are refused outright for every profile: `$` in any form (variables, command substitution, ANSI-C and locale quoting, arithmetic), backquotes, subshells and groups, here-documents, unquoted glob and brace characters, a leading `~`, a command named by a path, and an assignment before a command other than the few a form lists. `env`, `xargs`, `sh -c`, `eval`, `awk`, and `gh` are refused because no profile lists them.
- The three profiles list what their agents run: `read` (scout, planner, checker, quality and security reviewers, benchmark, reporter, retrospective), `merger`, and `contributor`. A write target (a redirection, or a path argument of a command that writes) is judged by its real path: inside the project, never under `.git/` or the run state's directory, and for `read` only under its DIR, `build/stages/`, or `/dev/null`. A word with a parent step (`..` as a path segment) is refused in every command. The body file is named only as the argument of the body gate; the contributor writes it with the Write tool.
- Each agent's PreToolUse hook runs the guard committed on `origin/main` and refuses the call on any status but 0, so a missing, edited, or failing guard refuses instead of allowing; a change to the guard takes effect when it is merged.
- `.claude/agents/benchmark.md`: the base is measured with the change's script named by the project's absolute path instead of a subshell and a parent step, and the toolchain paths are written absolutely instead of through `$PWD`. `.claude/agents/merger.md`: the hook takes no DIR, since the merger edits no file.
- `tools/gates.sh`: `settled_at` lists the changed paths without rename detection, so a file moved into `openspec/` counts by its old path too.
- `tools/tools_test.sh`: the guard section is rewritten around the allowlist: per profile an allowed command passing and every known bypass form refused, a dry run of each agent's normal commands under its profile, the write-target and body-file cases, and a failing guard refused through the hook line; a gates case for a code file moved into `openspec/`.
- Docs: the map's lines for the guard and `tools/tools_test.sh`; `docs/backlog.md` loses the entries this change fixes, gains what it leaves, and its Queued lines follow the planner's queue.

## Capabilities

### New Capabilities

None. The change alters only the delivery tooling, which no spec under `openspec/specs/` describes; `.openspec.yaml` sets `skip_specs: true`.

### Modified Capabilities

None.

## Impact

Outside the roadmap of `docs/architecture.md` section 12: delivery tooling under goal 1 (security first). No file under `carat/`, `bin/`, `test/`, or `config/` changes, so the editor and its benchmarks are unaffected.

Out of scope: the work-in-progress backup push of `workflow-cost` part (d), which adds its own allowlist entry and case; the contributor's edits of the agent files, whose hook lines a later agent of the same run may load (kept in `docs/backlog.md`); a script or a Makefile recipe the contributor edits and then runs, which the reviews and the merge gate stand behind.

## Assumptions

- An agent's Bash commands start in the project directory, as the harness resets the working directory between calls; `cd` is allowed only to the project or to a worktree under `tmp/.`, and relative paths are judged from the project.
- A command that only mentions a refused form inside quotes, such as a commit message naming `gh pr merge` or a `$`, is refused when the mention is a `$` or a backquote; such text goes into a file through the Write tool and reaches git with `-F`.
- The contributor may still write files outside its profile's commands with the Write and Edit tools anywhere in the project but `.git/` and the run state's directory; a file edit outside the project, which the old guard allowed, is now refused, since a write to a user configuration such as a git configuration file changes what an allowed command runs.
