# Proposal

## Why

CLAUDE.md (Pull requests) makes the pull request description the body of the squash commit on main, and `.claude/agents/merger.md` step 5 tells the merger to pass the body file's text and the trailer as the merge message. Yet since #199 most squash commits carry a one-sentence body and the trailer (`git log -1 --format=%b` gives 3 lines for 1a05518 and 84ed58b against 35 for 2af0b3a and 34 for adf6dc2), so the history on main loses each change's Summary, Changes, Testing, and Notes. No code builds the message: `mergeLines` in `.claude/workflows/deliver-change.js` and the merger prompt carry none, so it is the merger's own tool-call argument, which it sometimes shortens, and nothing checks it: the merge hook (`merge_tool` in `tools/agent_guard.sh`) reads only the merge method and the expected head, and step 6 checks only the subject and the trailer. The brief is `brief.md`; outside the roadmap of `docs/architecture.md` section 12, a pipeline defect.

## What Changes

- The merge hook (`merge_tool`, main's `tools/agent_guard.sh`) refuses a squash whose `commit_message` is not exactly the body of the archived change's `pr.md` at the pushed head (every line after the title and its blank line), one blank line, and the trailer as the last line; the refusal names the first line that differs, the message's and pr.md's, or a missing message. Trailing blank lines are ignored on both sides.
- The merger (`.claude/agents/merger.md` step 5) reads the body file, which `pr.md` holds byte for byte, with the Read tool and passes it whole, never shortened or summarized; step 6 confirms the body too.
- `tools/tools_test.sh`: the merge tool cases pass a message and the fixture commits an archived `pr.md`; new cases refuse a missing, a shortened, and a trailer-less message, naming the difference, and pass the exact one.

Out of scope: `tools/rules.sh` is not edited; `.claude/workflows/deliver-change.js` needs no change (it builds no message); no file of the feature lane is touched; the package step adds no queue line. Main's hook judges this change's own merge, so its squash body may still be short: the next delivery's squash commit is the acceptance check.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the delivery pipeline is described by no spec under `openspec/specs/` (`skip_specs: true`).

## Impact

- `tools/agent_guard.sh`, `.claude/agents/merger.md`, `tools/tools_test.sh`.
- README.md: changed, the merge hook sentence of pipeline step 9.
- docs/codebase-map.md: changed, the `merge_tool` description of `tools/agent_guard.sh`; no file is added, moved, or removed.
- CLAUDE.md: unchanged, its Pull requests section already makes the description the squash commit's body, which the hook now enforces, and it stands at its byte budget.
- docs/architecture.md: unchanged, it does not describe the merge hook.
