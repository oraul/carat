# Backlog: .claude/agents/security-reviewer.md

## The Skill tool has no hook

- Where: the tools of `.claude/agents/security-reviewer.md` (line 4), the other reviewers, and the contributor, whose hooks match only Bash, Edit, and Write. Periodic security Low (4) at 598cf1b.
- Why it matters: an agent led astray can load any listed skill, including one that changes the configuration or runs in a subagent outside its guard.
- Fix outline: a Skill matcher whose check admits only the skills each agent needs, with a `tools/tools_test.sh` case. Queued in `guard-lows`.
- Also: tools/tools_test.sh
- Category: security
- Added: 2026-11-04

### Security reviewer prompt lacks the fixed_in_place instruction
- Location: .claude/agents/security-reviewer.md:1
- Why: the SECURITY schema gains fixed_in_place and quality-reviewer.md describes it, but security-reviewer.md says nothing, so the security side relies on the prompt alone.
- Fix: add the same one-sentence fixed_in_place instruction to security-reviewer.md.
- Category: pipeline
- Added: 2026-11-18
