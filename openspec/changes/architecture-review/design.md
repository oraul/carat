# Design

## Context

See proposal.md, Why. The review reads `docs/architecture.md` and `docs/codebase-map.md` against the code at main (a9812b5): each class, file, command, and number the documents name is checked with `grep` and `find` over `carat/`, `bin/`, `config/`, `test/`, `bench/`, and the Makefile, never over `docs/backlog.md`. `test/lint.rb` already proves the map's file coverage, its method lists, and the port table of section 6, so the review spends its effort on what no check covers: prose claims, the layer diagram, lists of names, sizes, versions, and the shape of the code.

## Goals / Non-Goals

**Goals:**

- A report a planner can queue from: every open finding with a location, why it matters, and a fix outline, small enough to become one queue item each.
- Documents that no longer state as present what the code does not have.

**Non-Goals:**

- Completeness of the architecture: it names the core pieces and leaves the rest to the map, so an omission is a finding only where a reader would miss a mechanism (floats).

## Decisions

- Planned pieces are marked in place, `(planned)` with the roadmap item where there is one, instead of being deleted. The architecture is the target and the roadmap builds toward it; deleting the target would lose decisions already made, and leaving it unmarked misleads. Alternative: a separate "not yet built" section, which would split each description from its plan.
- The plugin API's version history stays only in `docs/plugins.md`, the plugin author's guide; section 9.4 names the current version and points there. Two copies had already diverged (9.4 said 2.0, the code and the guide 2.6).
- Findings this change corrects are listed in the report and not appended to the backlog, since nothing is left to do; every other finding is appended once, in the backlog's entry shape (a heading, location, why, fix outline), written without reading the file.
- Dead code is found by a heuristic: every method defined under `carat/` and `bin/` whose name appears nowhere else in `carat/`, `bin/`, `test/`, or `bench/`. Plugin-facing API members with no caller are reported separately, since a third-party plugin may call them.

## Risks / Trade-offs

- [A finding duplicates a sprint-4 sweep entry the review could not read] → the planner's sprint mode removes duplicates (`backlog-dups`), as the brief says.
- [The dead-code heuristic misses a method called only through a dynamic name, or reports one used by a name shared with another method] → Spinel forbids computed `send`, so the first cannot happen; each reported method was checked by hand.
- [A correction changes a budgeted document's size] → `make docs-lint` checks the budgets; the corrections replace text rather than add sections.
