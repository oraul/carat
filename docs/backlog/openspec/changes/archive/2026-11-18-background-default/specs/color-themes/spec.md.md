# Backlog: openspec/changes/archive/2026-11-18-background-default/specs/color-themes/spec.md

### Background delta spec removes and re-adds the requirement instead of modifying it
- Location: openspec/changes/archive/2026-11-18-background-default/specs/color-themes/spec.md:1 (quality advisory, raised at openspec/changes/background-default/specs/color-themes/spec.md:1)
- Why: one clear way: the delta removes 'The background option chooses who paints the background' and adds a renamed copy repeating three of its four scenarios word for word, where only the default and one scenario changed, so the history reads as a new requirement rather than a changed default.
- Fix: a MODIFIED block under the existing header with the new default, the painted-by-default scenario in place of Transparent by default, and the two named-kept scenarios; the contributor tried a MODIFIED block in a scratch copy and openspec validate refused it for dropping 'Transparent by default' (design.md records it), so a follow-up first checks whether the validator allows a modified requirement to drop a scenario, else closes this finding.
- Category: pipeline
- Added: 2026-11-18
