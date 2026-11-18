# Design

## Context

The merger squash-merges with the GitHub merge tool, whose message is the agent's own argument; `merger.md` asks for the body file's text and the trailer, but nothing holds it to that. The tool's hook runs main's `tools/agent_guard.sh` (`merge_tool`), which already finds the one run state recording the expected head as pushed and gated.

## Decisions

- Where: the pre-merge hook rather than a post-merge check, since a squash commit on main cannot be undone without rewriting main, and a refusal lets the merger retry with the right text in the same start. The guard is run from main as one string, so the comparison is inline in `merge_tool`, sourcing nothing.
- Source: `pr.md` read from the pushed head with git (`openspec/changes/archive/DATE-CHANGE/pr.md`, CHANGE the run state's file name), the committed text the pull request was opened from, not the body file, which a later edit could leave differing. Exactly one such file is required.
- Comparison: the message as `field` returns it (escaped line breaks marked) against pr.md's lines after the first two, one blank line, and the trailer; trailing blank lines dropped on both sides; a tab is a space and a run of bytes outside ASCII one `?` on both, since `field` reads a JSON tab escape as a space and a `\u` escape of a character outside ASCII as `?`. The first differing line is named with both texts, cut to 80 characters.
- Merger: one Read of the body file before the merge; the first green grows from seven calls to eight, inside the fixed cap of 10.

## Risks

- A refusal costs the merger a retry call; a merger that cannot produce the text returns not merged, and the run stops rather than merging a short body.
