# Backlog: docs/examples.md

## The action handler wiring omits the description

- Where: the action handler wiring list of `docs/examples.md` (line 27 at `leader-layout`) does not say that `register` now takes a short description, at most 32 characters, checked by `test/use_cases_actions.rb`. Quality advisory of `leader-layout`.
- Why it matters: an author wiring a handler by hand learns of the description only from a failing test.
- Fix outline: add the description to the wiring sentence for the by-hand path.
- Also: test/use_cases_actions.rb
- Category: design
- Added: 2026-11-05

### Split the golden table-test sentence in docs/examples.md:55

- Location: docs/examples.md:55 (quality advisory, docs clarity).
- Why: the inserted clause about `t.cases` when every input is an array literal, so the block indexes a typed array, turns the golden table-test sentence into a run-on list.
- Fix: move `cases` into its own sentence after the one describing `t.table`.
- Category: design
- Added: 2026-11-14

### docs/examples.md:31 golden ex-command paragraph omits the palette description (quality, docs currency)

- Where: docs/examples.md:31 and its wiring list at docs/examples.md:33.
- Why: task 2.3 of architecture-tidy is done, but the golden ex-command paragraph and its wiring still describe register(table) without the palette description the registration now carries, nor the generator's TODO placeholder that must be replaced by hand.
- Fix: say SyntaxCommandHandler registers itself with its description in self.register(table), and add the description to the wiring list as a by-hand step.
- Category: design
- Added: 2026-11-15

### The examples' action kinds omit :search

- Location: docs/examples.md:25. Sprint-6 sweep, quality advisory. Queue item `tools-docs-tidy`.
- Why: SearchHandler registers the search kind and CommandGrammar reads it.
- Fix outline: add it to the list with what it reads.
- Category: design
- Added: 2026-11-15
