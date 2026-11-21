# Proposal

## Why

The Facet look has two sources that disagree: the early council notes, which centered float titles and marked the focused float and the active tab with a diamond, and the user's decided design of 2026-11-18 (R1 to R7 and the Facet rules), which puts titles on the left of the top border with a dim count, keys in the bottom border, a sapphire `▎` on the selected row, and the AI's marks for the AI only. Two briefs quoted the early notes, and one shipped a diamond on the active tab that a later change removed. One binding file ends the disagreement. It is outside the roadmap of `docs/architecture.md` section 12: documentation, a user request, run first in the feature lane by the user-approved exception of Sprint 25.

## What Changes

- Add `docs/design.md`: the rules, R1 to R7, the color roles with both palettes' values, contrast targets and open questions, the glyph table with its open clashes, the one-accent rule, the empty and loading rule, the Known drift table (each row a file and line at `6bb8f2a` and its queued item), and the element notes of the decided design.
- Name it in `CLAUDE.md` (Project), `docs/architecture.md` (section 8.2), `README.md`, and `docs/codebase-map.md` (areas 1 and the presenters).
- `tools/docs_lint.sh`: a `check_required` that fails when `docs/design.md` is missing; `tools/tools_test.sh` gets a passing and a failing case, and its clean docs tree holds the file.
- `docs/queue-feature.md`: the user-approved exception line under the Sprint 25 heading.
- `docs/findings/facet-design-doc.md`: the six retrospective notes the plan handed over.
- `CLAUDE.md` and `docs/architecture.md` are at their byte budgets, so a few words of other sentences were shortened to make room; no budget is raised and no rule changes meaning.

Out of scope: any code, theme, or behavior change (each Known drift row is a queued item), `docs/queue-backlog.md`, `docs/metrics-backlog.tsv`, and `tools/rules.sh`.

Assumptions:

- The element notes (start screen, explorer, tab row, gutter, winbar, status bar, finder, key hints) are part of the file as section 8, after the seven parts the brief lists.
- The ascii `+`, the `◇` keyword icon, and the `▣` module icon are named among the glyph clashes because the decided design's defects list names them; `◈` is the AI's, so the ruby and class icons both give it up.
- The palette band row maps to `one-accent` as the plan decided; it is the PmenuSel fill at `carat/adapters/frame_presenter.rb:714`.
- Line numbers in the Known drift table are those of the head at `6bb8f2a`, not the brief's, which did not match the code.

## Capabilities

### New Capabilities

None: documentation and a docs-lint check only (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `docs/design.md`, `CLAUDE.md`, `docs/architecture.md`, `README.md`, `docs/codebase-map.md`, `docs/queue-feature.md`, `docs/findings/facet-design-doc.md`, `tools/docs_lint.sh`, `tools/tools_test.sh`.
- README.md: updated, names the design file and the new docs-lint check.
- docs/architecture.md: updated, section 8.2 names the design file; no layer, port, or roadmap change.
- CLAUDE.md: updated, the Project section names the design file.
- docs/codebase-map.md: updated, area 1 names the check and the presenters' area names the design file; no file under the mapped roots is added.
