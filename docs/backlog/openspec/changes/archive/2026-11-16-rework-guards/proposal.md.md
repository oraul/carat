# Backlog: openspec/changes/archive/2026-11-16-rework-guards/proposal.md

### The archived proposal omits init's merged-run exception
- Location: openspec/changes/archive/2026-11-16-rework-guards/proposal.md:12
- Why: Docs currency: the proposal says init refuses any run state with merged set, while the design and the code resume a merged run the close has not closed.
- Fix: Add that exception to the proposal's sentence.
- Category: pipeline
- Added: 2026-11-17
