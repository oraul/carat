# Backlog: openspec/changes/archive/2026-11-15-spinel-untyped-bump-b/proposal.md

## Header claimed regenerated in the archived spinel-untyped-bump-b (openspec/changes/archive/2026-11-15-spinel-untyped-bump-b/proposal.md:11)

- Location: openspec/changes/archive/2026-11-15-spinel-untyped-bump-b/proposal.md:11, also its :29 Impact, design.md:7, and tasks.md:6.
- Why: quality advisory, docs currency: they say the vendored header tools/spinel/spinel_rt_responds_generated.h is regenerated and changed, but commit 7d6e154 leaves it byte for byte the 6af548c9 one and the diff has no header change.
- Fix outline: say the header was regenerated at 93d7883b and came out unchanged, and drop it from Impact (in the next note that cites the pin, since the archive records the change as it was).
- Also: tools/spinel/spinel_rt_responds_generated.h
- Category: pipeline
- Added: 2026-11-15
