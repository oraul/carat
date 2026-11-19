# Proposal

## Why

The squash commits 5c94cc0 (#234) and 4e06a10 (#236) on main hold only one paragraph as their body, while each pull request's body, set from the archived `pr.md` by the open-pr workflow, holds all four sections (read back over the REST API: #234 and #236 both start `## Summary` and go on to `## Changes`). The body is lost in the merge call itself: the merger's transcript of #236 shows `mcp__github__merge_pull_request` called with `expectedHeadSha` and a `commit_message` the merger wrote as a summary, which GitHub took as given. The merger built the message by hand from `git ls-tree` and `git show ... | tail -n +3` output (step 5 of `.claude/agents/merger.md`) and wrote its own text instead of copying it.

The merge tool's guard (`squash_message` in `tools/agent_guard.sh`) would refuse such a message, yet the call went through. The guard also reads the expected head from a key `sha`, while the tool's parameter is `expectedHeadSha` (all three merge calls of #234, #235, and #236 pass it), so the guard as written would refuse every real merge before its message check: no hook refusal was raised for any of them, so the guard did not judge these calls at all. CLAUDE.md requires the pull request description, its four sections and dividers kept, as the squash body.

This is a pipeline defect outside the roadmap of `docs/architecture.md` section 12, delivered as a T1 pipeline defect in the backlog lane.

## What Changes

- `tools/open_pr.sh message CHANGE SHA`: prints the squash message, the body of the change's one archived `pr.md` at SHA (the archive's own entries, as the guard picks them) with its trailing blank lines dropped, one blank line, and the co-author trailer, byte for byte; refuses a name that is not a change name, a SHA that is not 40 digits, a SHA holding no one archived `pr.md` of the change, and a `pr.md` with no body. The merger passes its output as the commit message, so no text is composed by the agent.
- `.claude/agents/merger.md` step 5: one call of `sh tools/open_pr.sh message <change> <sha>` replaces the `git ls-tree` and `git show | tail -n +3` calls; its output is passed exactly as `commit_message`, never retyped, shortened, or summarized, with the pushed head as `expectedHeadSha`; the first green costs eight calls instead of nine.
- `tools/agent_guard.sh`: `merge_tool` reads the expected head from `expectedHeadSha`, the merge tool's parameter, and refuses a call without it; the merger profile may run `sh tools/open_pr.sh message CHANGE SHA` (a change name and a full sha), the contributor still only `write` and `wait`.
- `tools/tools_test.sh`: a case building the message from a four-section `pr.md`, all four `## ` headings, the three dividers, and the trailer last kept; the message's refusals; the guard admitting the message `message` builds and refusing a head passed as `sha`; the merger's `message` form allowed and the contributor's refused.

## Capabilities

### New Capabilities

None: the change alters the delivery tooling (`skip_specs: true`).

### Modified Capabilities

None.

## Out of scope

- The post-merge check that reads main's new commit body and records a defect note when a `## ` heading is missing: split out by the plan as the backlog item merge-body-check.
- Why the agents' frontmatter hooks did not judge the merge call is outside the repository (the harness that starts the workflow's agents); it is recorded in `docs/findings/merge-body-sections.md`.
- No `tools/rules.sh` edit.

## Impact

- CLAUDE.md: the Commands line of `tools/open_pr.sh` names `message`, the merger's.
- docs/codebase-map.md: area 1's `tools/open_pr.sh` entry names `message`.
- README.md: unchanged, it does not describe the merge call or the commands of `tools/open_pr.sh`.
- docs/architecture.md: unchanged, no layer, port, or roadmap item is touched.
