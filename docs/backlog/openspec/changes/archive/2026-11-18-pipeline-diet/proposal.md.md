# Backlog: openspec/changes/archive/2026-11-18-pipeline-diet/proposal.md

### The proposal and the contributor disagree on when reviewed-edits runs (pipeline-diet quality)
- Location: openspec/changes/archive/2026-11-18-pipeline-diet/proposal.md:13 (was openspec/changes/pipeline-diet/proposal.md:13), .claude/agents/contributor.md:49
- Why: docs drift: the proposal says the package step runs reviewed-edits before each commit, while .claude/agents/contributor.md:49 runs it once in step 4 before the push, after the records commits.
- Fix: state one rule in both (before each commit, or once before the push with a restoring commit).
- Also: .claude/agents/contributor.md
- Category: pipeline
- Added: 2026-11-18
