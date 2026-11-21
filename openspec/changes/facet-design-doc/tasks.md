# Tasks

## 1. The design file

- [x] 1.1 Write `docs/design.md` with the rules, R1 to R7, the color roles, the glyph table, the one-accent rule, the empty and loading rule, the Known drift table, and the element notes. Checked by `make docs-lint` (paths exist, no forbidden text) and by every Known drift row naming a file and line and a queued item.
- [x] 1.2 Name it in `CLAUDE.md`, `docs/architecture.md` section 8.2, `README.md`, and `docs/codebase-map.md`, within the byte budgets. Checked by `make docs-lint` (budgets).

## 2. The check

- [x] 2.1 Add `check_required` to `tools/docs_lint.sh` for `docs/design.md`, with a passing and a failing case in `tools/tools_test.sh` ("docs_lint: passes with docs/design.md present", "docs_lint: refuses a tree without docs/design.md"). Checked by `make tools-test`.

## 3. Queue and records

- [x] 3.1 Add the user-approved exception line under the Sprint 25 heading of `docs/queue-feature.md`. Checked by `make docs-lint` (queue).
- [x] 3.2 Append the plan's six notes to `docs/findings/facet-design-doc.md`.

## 4. Checks

- [x] 4.1 Run `make spec-validate`, `make gates`, `make docs-lint`, and `make tools-test`, all pass.

## 5. Review fixes

- [x] 5.1 Add the git signs' `icons.rb:93`, `:94` row to Known drift (`glyph-audit`).
- [x] 5.2 Mark the `▎` git sign row and the selection row as the open clash of section 4, so no glyph holds two decided meanings.
- [x] 5.3 State one count order per surface: the status bar's counts `✖ ▲ ◇`, the sign cell `✖ ▲ ◆ ◇`.
- [x] 5.4 Name `one-accent` and `glyph-audit` as planned items in section 7, since the queue does not hold them yet.
- [x] 5.5 Split the glyph-pair row of Known drift into one row per pair with its two `icons.rb` lines.
