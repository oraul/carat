# Design

## Context

The merger squash-merges with the GitHub merge tool, whose message is the agent's own argument; `merger.md` asks for the body file's text and the trailer, but nothing holds it to that. The tool's hook runs main's `tools/agent_guard.sh` (`merge_tool`), which already finds the one run state recording the expected head as pushed and gated.

## Decisions

- Where: the pre-merge hook rather than a post-merge check, since a squash commit on main cannot be undone without rewriting main, and a refusal lets the merger retry with the right text in the same start. The guard is run from main as one string, so the comparison is inline in `merge_tool`, sourcing nothing.
- Source: `pr.md` read from the pushed head with git (`openspec/changes/archive/DATE-CHANGE/pr.md`, CHANGE the run state's file name), the committed text the pull request was opened from, not the body file, which a later edit could leave differing. Exactly one such file is required.
- Comparison: `json_text` decodes the message's JSON string whole (`\uXXXX` and surrogate pairs as UTF-8, `\b`, `\f`, `\n`, `\r`, `\t` as their bytes), refusing a raw control byte, a NUL, a lone surrogate, or a bad escape; its lines are compared byte for byte with pr.md's lines after the first two, one blank line, and the trailer, trailing blank lines dropped on both sides. No folding: an earlier draft read a tab as a space and a run outside ASCII as one `?`, which let a message pr.md does not hold pass (the security review). Only the display of the first differing line, cut to 80 characters, shows a control or non-ASCII byte as `?`.
- Merger: it reads the body from the hook's own source, pr.md at the pushed head (`git ls-tree` for the path, `git show SHA:PATH | tail -n +3`, two calls), not the body file, so a body file a later edit left differing cannot make the merger pass a text the hook refuses; the first green grows from seven calls to nine, inside the fixed cap of 10.
- `SQUASH_TRAILER` repeats `TRAILER` of `tools/gates.sh`, since the guard runs from main as one string sourcing nothing; a tools-test case keeps the two equal.

## Risks

- A refusal costs the merger a retry call; a merger that cannot produce the text returns not merged, and the run stops rather than merging a short body.
