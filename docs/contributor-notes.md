# Contributor notes

Prose the contributor reads when a step needs it, moved out of `.claude/agents/contributor.md` to keep that file within its docs-lint budget. The rules card at the top of the agent file is the short form.

## Context

Read in order until you know what the change touches: the scout packs, trusting their lines (open a covered file only to edit it); the map sections of the touched areas (`docs/codebase-map.md`); the files, tests, and designs they name; the touched sections of `docs/architecture.md`. A file added, moved, or removed is placed in its map area.

## Conflicts with main

On a conflict with `main`, run `merge-main` and say so. On its conflicts merge `origin/main` by hand (the trailer of `CLAUDE.md`): keep both sides of appended files, regenerate generated ones with `make`, and stop and name a conflict where both sides changed the same logic. The fix stays in the push start; the checks and reviews rerun.

## Propose

Propose with the `openspec-propose` skill (a change with no behavior change sets `skip_specs: true`), minor assumptions in the proposal. A change past one reviewable pull request is split, its first part delivered. Fix every finding of `openspec validate "<change>" --strict --no-interactive` and `make spec-validate`.

## Iterating

Run only targeted checks through `make`: `make test-one T=test/NAME.rb`, `diagnose-one T=path`, `lint`, `docs-lint`. Only `make snapshots` rewrites a snapshot, and its diff is read.

## Body

Write the body with the Write tool by CLAUDE.md's Pull request description section: its Testing names only checks and reviews that ran, with results, the security review first. Check it with `sh tools/gates.sh pr-body` on that file before `open_pr.sh write`.

## Findings

Append each finding to `docs/findings/<change>.md` with `>>`, as a `### title` heading and three lines: `- Location:`, `- Why:`, `- Fix:`.

## Edge-case checklist

The self-check of the implement mode and of the fix mode walks these points, each from findings the quality review blocked a first pass on. A behavior the change touches that one of them concerns gets a test, or the reason it cannot arise is stated in the test or the proposal.

- Empty range: a count, range, or selection of zero lines or characters, and a start past the end.
- CRLF: a line ending in a carriage return survives an edit, a motion, and a write.
- UTF-16 and multi-byte: a column, a width, or a language server position over a multi-byte or surrogate-pair character is counted in the unit its consumer expects.
- Trailing blanks: a line ending in spaces or tabs, and a blank line at the end of a range.
- Last line: the cursor or the range on the final line, with and without a final newline.
- Empty buffer: one empty line, and no line at all, where a port can return one.
- A test per behavior change: every added or altered branch has a test, a raise or error branch included, and a test expectation the change made stale is updated.
- An existing helper searched first: grep `carat/` for one before writing a new one.
- Comments, docs, and spec text match the code: a comment, a doc row, or a spec scenario the change made untrue is corrected in the same change.

## Self-review

After the self-check, read the committed diff once as the quality reviewer would, with the instructions of `.claude/agents/quality-reviewer.md`: a bug, an untested behavior change, and a mismatch between code and text block. Fix what blocks in place; record the rest in the findings file.
