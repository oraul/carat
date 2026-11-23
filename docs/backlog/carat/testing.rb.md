# Backlog: carat/testing.rb

## The test rig's fail shadows Kernel#fail

- Where: the private `fail` of `carat/testing.rb` line 74 and `assert_raises` line 38 at 847851d. Periodic quality. Queue item: backlog items.
- Why it matters: `assert_raises` rescues only `StandardError`, so `assert_raises(NotImplementedError)`, the error every port method raises, ends the test program instead of passing.
- Fix outline: rename the helper `record_failure` and rescue `StandardError` and `ScriptError`, with a rig case.
- Category: editor
- Added: 2026-11-09

## Carat::Testing takes a positional constructor with no stated exemption

- Where: `Testing#initialize(name)` in `carat/testing.rb` line 13; `test/lint.rb` line 1000 applies the keyword rule only to layer files, at 3895e21. Periodic quality. Queue item `docs-index`.
- Why it matters: CLAUDE.md names `Carat::Testing` among the classes whose constructors take required keywords, so files outside a layer, plugins included, escape the rule unstated.
- Fix outline: state the exemption beside the keyword rule in CLAUDE.md, or move to `initialize(name:)` across the tests.
- Also: test/lint.rb, CLAUDE.md
- Category: editor
- Added: 2026-11-09

## The docs still name spin test as the snapshot judge

- Where: the harness comment in `carat/testing.rb` line 4 and `docs/architecture.md` lines 396 and 421 at 2f54bb5. Periodic quality at 2f54bb5. Queued in `docs-index`.
- Why it matters: the hard rules forbid running `spin test`; `tools/run_tests.sh` compares the snapshots, so the docs point at the wrong tool.
- Fix outline: name `tools/run_tests.sh` and `make test` in the three places.
- Also: docs/architecture.md, tools/run_tests.sh
- Category: editor
- Added: 2026-11-10

### Rename the private element reader list in carat/testing.rb:83

- Location: carat/testing.rb:83 (quality advisory, naming).
- Why: the private element reader `list` reads as a collection constructor and shares its name with `FilePort#list`, which `DiskFiles` and `MemoryFiles` implement, the shared-name shape `docs/spinel-notes.md` warns can leave calls unresolved.
- Fix: rename it after what it returns, for example `array_cell`, beside `cell`.
- Also: docs/spinel-notes.md
- Category: editor
- Added: 2026-11-14

### Testing#cases accepts a row whose input is no array literal

- Location: carat/testing.rb:66 (sprint-4 review, quality).
- Why: such a row compiles with the wrong typing and no warning.
- Fix: test/lint.rb flags a `t.cases` row whose second element is not an array literal.
- Also: test/lint.rb
- Category: editor
- Added: 2026-11-14

### Testing's comment names spin test as the snapshot runner

- Location: carat/testing.rb:4, docs/architecture.md:425 (sprint-8 sweep, quality); queued in `architecture-docs`.
- Why: both say spin test diffs the output against the snapshot, while tools/run_tests.sh compares it and spin test is never run.
- Fix: name tools/run_tests.sh in both places.
- Also: docs/architecture.md, tools/run_tests.sh
- Category: editor
- Added: 2026-11-16

### Doc comments and map entries drift (sprint-18 sweep quality)
- Location: `carat/testing.rb:4`; `bin/carat-gen-config.rb:32`; `carat/domain/range.rb:4`; `carat/adapters/editor_assembly.rb:190`; `docs/codebase-map.md:128`, `:478`, `:543`, `:474`; `tools/docs_lint.sh:22`, `docs/codebase-map.md:55`; `tools/gates.sh:39`.
- Why it matters: testing.rb credits spin with the diff; the generated header says `spin run`; range.rb names only charwise ranges; a broken comment and a repeated loop in EditorAssembly; the map omits Messages E16, E444, E477, E490, REPORT, StatusSlots `set_lsp`, Paths `absolute`, and still names FramePresenter `diagnostic_group`; docs_lint says 0 to 2 backlog items where the sprint holds 3; the gates usage names CHECK_STAGES where FAST_STAGES is read first.
- Fix outline: correct each text, `make gen-config` after the header fix.
- Also: bin/carat-gen-config.rb, carat/domain/range.rb, carat/adapters/editor_assembly.rb, docs/codebase-map.md, tools/docs_lint.sh, tools/gates.sh
- Category: editor
- Added: 2026-11-18

### assert_true passes any truthy value (sprint-18 sweep quality)
- Location: `carat/testing.rb:31`.
- Why it matters: a predicate returning a non-bool passes while the failure text says expected true.
- Fix outline: compare `value == true`, or rename to `assert_truthy`.
- Category: editor
- Added: 2026-11-18

### Testing.new takes a positional name (sprint-24 sweep quality)

- Location: `carat/testing.rb:13`, `:4`, `test/lint.rb:1354`
- Why: CLAUDE.md lists Carat::Testing among keyword-constructor classes, lint skips it, and its comment says spin diffs the output where `tools/run_tests.sh` does.
- Fix: take `name:` or document the exemption, and correct the comment.
- Also: test/lint.rb, CLAUDE.md, tools/run_tests.sh
- Category: editor
- Added: 2026-11-21

### assert_true passes any truthy value at carat/testing.rb:30 (sprint-28 sweep quality, note 40)

- Location: carat/testing.rb:30
- Why: a predicate returning 0, "", or an object passes its test.
- Fix: pass only on value == true and rerun the snapshots.
- Category: editor
- Added: 2026-11-22

### the header says spin diffs the output against the at carat/testing.rb:4 (sprint-30 sweep quality, note 71)

- Location: carat/testing.rb:4
- Why: the header says spin diffs the output against the snapshot, but tools/run_tests.sh compares it and spin test is forbidden by CLAUDE.md
- Fix: name tools/run_tests.sh
- Also: tools/run_tests.sh, CLAUDE.md
- Category: editor
- Added: 2026-11-23

### assert_true passes any truthy value, so a non-nil string at carat/testing.rb:30 (sprint-30 sweep quality, note 72)

- Location: carat/testing.rb:30
- Why: assert_true passes any truthy value, so a non-nil string or 0 passes as true while the failure text says expected true
- Fix: compare value == true, or rename it to assert_truthy if truthiness is meant
- Category: editor
- Added: 2026-11-23
