# Design

## Context

The contributor reads `CLAUDE.md` (41,066 bytes), the touched sections of `docs/architecture.md` (91,890 bytes), the code map, and then searches the tree for a file like the one it is about to write and for every place such a file is wired into: `carat.rb`, `EditorAssembly`, `test/runner/run_all.rb`, the map, `docs/actions.md`, `docs/compatibility.md`, `config/plugins.caratrc`. The Spinel pitfalls are stated in up to three places each: `private_constant` and destructured arrays in all three of `CLAUDE.md`, `docs/architecture.md`, and `docs/backlog.md`; untyped widening, `IO.popen`, the block forms of records, the keyword `super` rule, and Ractor in two. No check holds a document's size or catches a dead path in prose; `tools/gates.sh` scans only a branch's added lines for URLs, emails, and model names.

## Goals / Non-Goals

**Goals:**

- One page that answers "what do I copy, and what else do I touch" for each common kind, pointing at files the checks already keep correct.
- Generators that leave the tree compiling, passing lint, and passing the doc-derived tests, so the author only fills the behavior in.
- One home for the Spinel pitfalls, referenced from the binding documents.
- A stage that keeps the documents within budget and free of forbidden content and dead paths.
- Smaller `CLAUDE.md`, `docs/architecture.md`, and contributor instructions with no rule lost.

**Non-Goals:**

- New editor behavior, new sample code in the library, or a change to any rule's meaning.
- A compile of the generators' output in `make check` (see Risks).

## Decisions

### Golden examples are existing files

Each kind names one or two files already in the tree: `JoinLines` and `SplitWindow` (use cases without and with collaborators), `TabHandler` (action handler), `SyntaxCommandHandler` (ex handler), `Position` and `Cursor` (a `Data` and a `Struct` record), `ClockPort`, `MonotonicClock`, and `ManualClock` (port, driver, double), the `hello` fixture plugin, and `test/domain_ex_grammar.rb` and `test/editor_insert.rb` (table-driven tests at the domain and editor level). They are compiled, linted, and tested on every run, so they cannot rot; `docs/examples.md` adds what a file cannot show: the checklist of other files per kind and the generator. Alternative considered: a directory of sample files compiled only into the test runner. It would duplicate the real shapes, put sample classes in the library's namespaces, and for handlers would have to be registered in the production tables to be tested by the doc-derived checks.

### Generators are one shell script with anchored insertions

`tools/new.sh KIND NAME [ARG]` holds the five templates as quoted here-documents with `@CLASS@`-style tokens replaced by `sed`, and inserts lines with `awk` at fixed anchors: before the `plugin_command_handler` and `plugin_action_handler` requires and the `PluginCommandHandler` and `PluginActionHandler` registrations (the plugin entries stay last, as the precedence rules need), before the `unknown` row of the ex table in `docs/compatibility.md`, after the last row of the `Implemented` table of `docs/actions.md`, among the runner's `require_relative` and `when` lines in sorted order, after the last bullet of an area's Files list or at the end of its Tests line in the map. A missing anchor, an existing file, an invalid name, or an action already documented stops the script before it writes anything. The Makefile targets pass `NAME`, `AREA`, `DIR`, `SPEC`, and `ACTION`; `make new-plugin` runs `make gen-config` afterwards so the registry is current. What each generator writes:

- `new-use-case NAME= [DIR=] AREA=`: `carat/use_cases/[DIR/]NAME.rb` with `call(state, command)` returning `Outcome.none`, its require in `carat.rb`, its map bullet.
- `new-action NAME= ACTION= [AREA=5]`: `carat/use_cases/actions/NAME_handler.rb` with `self.register(table)`, its requires in `carat.rb` and `EditorAssembly`, its registration, its `docs/actions.md` row, its map bullet.
- `new-ex-command NAME= SPEC= [AREA=12]`: `carat/use_cases/ex/NAME_command_handler.rb` answering `Not implemented: :name`, its requires, its registration, its `docs/compatibility.md` row, its map bullet.
- `new-test NAME= AREA=`: `test/NAME.rb` with a two-row table, its `.expected` snapshot with exactly the output it prints, its runner lines, its map entry.
- `new-plugin NAME= [AREA=15]`: `carat/plugins/NAME/plugin.rb` with a manifest of one action and one binding, its `config/plugins.caratrc` line, its `docs/actions.md` Plugins row, its map bullet.

Alternative considered: templates as separate files under `tools/templates/`. They would need their own map entries and could be mistaken for source by `spin`, which reads every visible directory; one script keeps the shape and the wiring together.

### docs-lint is a shell stage sharing the gates' patterns

`tools/docs_lint.sh` checks the documents a contributor reads: `CLAUDE.md`, `README.md`, `docs/*.md`, `.claude/agents/*.md`, `.claude/commands/*.md` (not the generated `opsx/`), and `.github/pull_request_template.md`. Budgets are bytes from `wc -c`. Content uses the same `scan` as the content gate, moved with its patterns into `tools/rules.sh`, so a pattern is defined once. A hard-wrapped line is a non-blank line that follows a non-blank line without being a bullet, heading, rule, or comment, checked in the pull request template and in the example body of `CLAUDE.md`. A dead path is a backticked span that starts with a tracked root (`carat/`, `bin/`, `test/`, `bench/`, `tools/`, `docs/`, `config/`, `openspec/`, `.claude/`, `.github/`), holds no placeholder (`<`, `*`, `NAME`, `CHANGE`, `...`), and names nothing on disk. It runs right after `doctor`, since it needs no build and fails fast. CI runs it too; on a Markdown-only pull request CI skips its checks by design, and the checker's run before the push covers it.

### Slimming moves detail, never a rule

Spinel mechanics leave `CLAUDE.md` Coding conventions and `docs/architecture.md` sections 2.1 and 10 for `docs/spinel-notes.md`; the per-kind wiring (key bindings, ex commands, plugins, tests) leaves `CLAUDE.md` for `docs/examples.md`; the Commands section becomes one line per target with `make help` holding the full text. Each moved block leaves a one-line pointer that states the rule and where its detail is binding. The contributor's Context step points at the examples and notes before any search.

Sizes, before and after (bytes, `wc -c`):

| File | Before | After |
| --- | --- | --- |
| `CLAUDE.md` | 41,066 | 30,584 |
| `docs/architecture.md` | 91,890 | 87,261 |
| `.claude/agents/contributor.md` | 6,716 | 6,712 |

## Risks / Trade-offs

- [Generated code could stop compiling when a convention changes] → the generators are covered by `make tools-test` for their files and insertions, and this change compiles, lints, and tests the output of all five by hand; an automated compile of the output is left in `docs/backlog.md` because it would add a full analysis of the library to every check.
- [Anchored insertion breaks when an anchor line is renamed] → the script refuses with the anchor's name instead of writing a partial change, and `make tools-test` runs every generator against the current files.
- [A budget blocks a change that must add a rule] → the budget is a number in `tools/docs_lint.sh`; raising it is a visible, reviewed line, which is the point.

`CLAUDE.md` lost 26 percent and is the one document every agent reads in full. `docs/architecture.md` lost 5 percent: its sections 2.1 and 10 point to the notes, and the rest is design no other document holds, so its budget is set at the new size rounded up to the next KiB (88,064 bytes) to hold it there. The contributor's instructions stayed the same size while gaining the pointers to the examples, the generators, and the notes; the saving for the contributor is in what it no longer has to look up. The new guides, `docs/spinel-notes.md` (about 10 KB) and `docs/examples.md` (about 7 KB), replace reading three documents for the pitfalls and searching the tree for a file to copy.
