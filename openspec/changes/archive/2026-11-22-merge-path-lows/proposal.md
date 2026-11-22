# Proposal

## Why

One Medium (6) and four Lows on the guard and merge path, from the periodic review at 186ddfb, the sprint-13 security review, and a `sprint-security` quality advisory:

- Any profile of `tools/agent_guard.sh` may write `.claude/settings.local.json`, `.mcp.json`, or `CLAUDE.local.md` (`write_target`, line 349), which Claude Code reads as settings, servers, and instructions: a write there can turn the hooks off, so the next agent runs unguarded (Medium (6), sweep note 16).
- Every profile runs `date` with any option, so `date -s` can set the clock and skew the `at.*` times the run state records (line 899, sweep note 17).
- The merger's `git read-tree origin/main` is accepted in any worktree `tmp/.NAME`, not only the merge gates' copy (lines 582 to 587).
- The merge gates' green line (`.claude/workflows/deliver-change.js`, line 765) checks the copy with `diff --quiet`, which ignores untracked files, so a file planted in `tmp/.merge-gates` beside main's tree passes it.
- `tools/spec_validate.sh` copies `openspec/` with `cp -R`, which keeps symbolic links, so the preview's archive writes a merged spec through a link a branch commits under `openspec/` to a file outside the preview (security Low (3)).
- The Notes phase of `.claude/workflows/sprint-planning.js` (lines 273 to 281) hands a command built from reviewer text to a general agent with Bash and no guard (sprint-13 security Low (3)).
- The report's not-recorded suffix of the Security line (line 364) has no tools-test case.

## What Changes

- `write_target` refuses, for every profile, a write whose written or real path names `.claude/settings.local.json`, `.mcp.json`, or `CLAUDE.local.md` anywhere in the project, or the `.claude` directory itself; and the guard refuses every call while one of those three files is present untracked at the top of the project (`LOCAL_SETTINGS`).
- `date` is allowed only with its read options (`-u`, `--utc`, `--universal`, `-R`, `--rfc-email`, `-I` and its forms, `--iso-8601`, `--rfc-3339=`, `-d`, `--date=`, `-r`, `--reference=`) and a `+FORMAT` operand; `-s`, `--set`, any prefix of it, and a date operand are refused (`date_form`).
- The merger's `git read-tree` is accepted only with `-C tmp/.merge-gates`.
- The green line adds, after `diff --quiet`, a check that `git ls-files --others` lists nothing in the copy, so an untracked or ignored file there stops it before the merge gates.
- `tools/spec_validate.sh` refuses, before any preview, when `openspec/` holds a symbolic link, naming it.
- The Notes phase runs its command through the quality reviewer in its record mode, whose hook runs the guard's read profile, as the skeptic notes already do. So that no finding is refused there, the guard stores the text word of `sh tools/run_state.sh note CHANGE KIND TEXT` without its word rules (a parent step, the run state's directory), since `run_state.sh` only stores it; the change and kind words keep them. Without this, a security finding naming `build/pipeline` or a parent step, 3 of the 101 recorded so far, would refuse the whole notes command and hold the sprint.
- The report's Security line moves into the helper `securityReport`, which a tools-test case runs for the not-recorded suffix.
- `tools/tools_test.sh` gains a case per fix, each failing before it.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline's guard and workflows, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `tools/agent_guard.sh`, `tools/spec_validate.sh`, `.claude/workflows/deliver-change.js`, `.claude/workflows/sprint-planning.js`, `tools/tools_test.sh`, `docs/codebase-map.md` (the guard and `spec_validate.sh` rows).
- README.md: changed, the green line's untracked-file check, the guard's refusal while a local settings file stands untracked, and the security notes run by the guarded quality reviewer.
- CLAUDE.md: unchanged, it describes neither the guard's forms nor the green line's steps.
- docs/architecture.md: unchanged, it does not describe the delivery guard or the merge gates' green line.
- docs/codebase-map.md: changed, the `tools/agent_guard.sh` and `tools/spec_validate.sh` rows.
- `tools/rules.sh`: not edited.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline defect (T1), the second Sprint 29 backlog item.

Backlog headings this change covers, from its queue entry: "## Security Lows of the periodic review at 186ddfb", "### The Notes phase hands reviewer text to a general agent with Bash (sprint-13 security Low (3))", "### The report's not-recorded suffix and new Sweep line have no test (`sprint-security` quality advisory)".

Re-verified on main at 90b013a: every point above still holds but one, the Sweep line of the last heading, which has tools-test cases on main since #255 ("sprint: the sweep line names unrecorded results", "sprint: the report's sweep line is sweepLine's"), so this change adds none for it. The queue entry's `deliver-change.js:805` is line 765 at 90b013a.

Minor assumptions: the untracked-file refusal checks the three files at the top of the main checkout, where Claude Code reads them; a user who keeps a `.claude/settings.local.json` there moves its rules to the user settings, since its presence refuses every agent call. A copy into the project root is already refused as a write outside the project, so a directory holding one of those files cannot be copied there; the start check covers a file that arrives from outside an agent.

## Out of scope

- `tools/rules.sh`, the feature lane's files, and any other form of the guard.
