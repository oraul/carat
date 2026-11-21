# Backlog: openspec/changes/archive/2026-11-15-spinel-warnings/proposal.md

### openspec/changes/archive/2026-11-15-spinel-warnings/proposal.md:1 the change mixed fixes with a build change

- Where: openspec/changes/archive/2026-11-15-spinel-warnings/proposal.md:1 (proposal.md of spinel-warnings before its archive).
- Why: the branch mixes fixes (the test/lint.rb require, the tab_request and utf8 warnings) with a build change (every target fails on a warning), needing both fix and build types in one squash commit (quality advisory, one logical change per pull request).
- Fix: name the fixes as the enabling part of the build change in the pull request text, or split the lint and warning fixes out next time.
- Also: test/lint.rb
- Category: pipeline
- Added: 2026-11-15
