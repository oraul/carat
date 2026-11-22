# Design

## Context

`tools/agent_guard.sh` is the PreToolUse hook every agent runs from origin's main. `write_target` judges every write by its written and real path; `judge` matches each simple command to a form; `git_form` holds the merger's `read-tree` for the green line of `.claude/workflows/deliver-change.js`, which resets the merge gates' copy `tmp/.merge-gates` to main's tree and checks it with `diff --quiet` before running the copy's gates. `tools/spec_validate.sh` archives each active change in a copy of `openspec/`. `.claude/workflows/sprint-planning.js` records the sprint review's security findings in its Notes phase.

## Goals / Non-Goals

**Goals:**

- No agent writes the local settings Claude Code reads, and no agent call runs while one of them stands untracked.
- `date` reads the clock and never sets it; `read-tree` writes only the merge gates' index.
- The merge gates run only when the copy holds exactly main's tracked files.
- The spec preview never writes through a link.
- Reviewer text runs only under a guarded agent.

**Non-Goals:**

- Any change to `tools/rules.sh` or the merge gates themselves.

## Decisions

- One regex, `LOCAL_SETTINGS`, matches the three names at any depth, a `./` segment or a doubled slash included, and the `.claude` directory itself (a `mv` onto it or into it); `write_target` checks it on the written path, made relative, and on the real one, so a link to the file or a linked `.claude` does not hide it. Refusing anywhere in the project, worktrees included, costs nothing, since no agent needs those files. Alternative: only the top of the main checkout, which a link or a worktree session would evade.
- The start check lists the three files at the top of `CLAUDE_PROJECT_DIR`, the main checkout, and refuses when one exists (a link included) and `git ls-files --error-unmatch` does not know it: a tracked one is in a reviewed diff. It runs beside the hooks-directory check, before any tool is judged.
- `date_form` allows a fixed list of read options, `-d`, `-r` with their values, and a `+FORMAT` operand; everything else, `-s`, `--set`, a GNU prefix such as `--se`, a cluster, and the `MMDDhhmm` operand, is refused. An allowlist, since GNU takes any unambiguous prefix of a long option.
- `read-tree` compares the `-C` path, made relative, with `tmp/.merge-gates`, after the worktree check; a lane's green line runs after a `cd` into its worktree, so the relative form is the one it writes.
- The green line's added step is `git -C tmp/.merge-gates ls-files --others | wc -c | grep -q -x -E ' *0'`: `--others` without `--exclude-standard` lists ignored files too, and every word is a form the merger's profile already runs, with no `$` or `!` the guard refuses.
- `spec_validate.sh` runs `find openspec -type l` once before the strict validation and exits 1 naming the links, so neither validation nor preview runs over them. Alternative: `cp -RL`, which would follow a link to a large or special file.
- The Notes phase passes `agentType: 'quality-reviewer'` and `Mode: record.`, the record mode the skeptic notes use; the read profile runs `sh tools/run_state.sh note CHANGE security TEXT`.
- `securityReport(r, blocking, disputed, missedBoth, noted)` returns the whole Security line, so the `js` helper of the tools test runs it.

## Risks / Trade-offs

- A user's own untracked `.claude/settings.local.json` in the main checkout refuses every agent call; the refusal names the file and asks to remove it. That is the queue entry's fix outline.
