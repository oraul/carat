# Backlog: .claude/settings.json

## The contributor can edit the agent files of its own run

- Where: the agent files under `.claude/agents/`, whose hook lines name each agent's guard profile and which the contributor's file tools may write. What remains of the periodic security Low (6) at 8c340cd after `guard-allowlist` made every hook run `origin/main`'s guard and refuse on any failure.
- Why it matters: if the harness reads an agent file from the working tree when the workflow starts that agent, an edit on the branch (a hook line removed, a profile widened) applies to the later agents of the same run before any review.
- Fix outline: have the workflow compare `.claude/agents/` and `.claude/settings.json` with `origin/main` before it starts each agent and stop on a difference the brief does not name, or refuse the contributor's edits of them unless a record only the workflow writes names them; add a `tools/tools_test.sh` case. Queued in the backlog-items change of `docs/queue.md` (review triggers).
- Also: tools/tools_test.sh
- Category: security
- Added: 2026-11-04
