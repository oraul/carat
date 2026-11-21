# Backlog: docs/contributor-notes.md

### Waiting timeout stated twice in the contributor notes
- Location: docs/contributor-notes.md:49 and .claude/agents/contributor.md:63
- Why: the Waiting section repeats the Bash timeout 600000 that package step 5 still states, and step 5 does not point to the section, so the 540 s reason is read only by chance.
- Fix: keep the timeout in one place, either step 5 pointing to docs/contributor-notes.md, Waiting, or the section dropped.
- Also: .claude/agents/contributor.md
- Category: pipeline
- Added: 2026-11-19

### Unclear antecedent in the merge-main notes
- Location: docs/contributor-notes.md:11
- Why: the section opens "On its conflicts", whose antecedent (merge-main) is only in contributor.md, so the notes read alone leave "its" unclear.
- Fix: write "On the conflicts of merge-main".
- Category: pipeline
- Added: 2026-11-19
