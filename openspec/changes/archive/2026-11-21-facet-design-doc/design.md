# Design

## Context

The decided look lives only in a session note outside the repository; briefs quoted an older note. `docs/design.md` is the repository's copy, binding, read by every UI change.

## Decisions

- One file, eight sections: the brief's seven parts in its order, then the element notes, so a change reads the rules first and an element's note when it touches one.
- Known drift names code at the head (`6bb8f2a`); a row leaves the table in the change that closes it, so the table never claims more than the code holds.
- `docs-lint` checks only that the file exists (`REQUIRED`), the same level of check as the other documents it guards; the drift table's accuracy is a review matter, since a line number goes stale with any edit.
- Budgets: `CLAUDE.md` and `docs/architecture.md` had under 15 bytes free, so wording elsewhere in each was shortened by the added bytes; the budget lines are untouched.

## Risks

A Known drift line number goes stale when the file changes; each row also names the thing (the fill, the title, the mark), so the row stays findable.
