# Backlog: carat/adapters/editor_assembly.rb

## The completion close use case is shared through a local

- Where: `close_completion` in `carat/adapters/editor_assembly.rb` line 336 at b0dd342, shared by `ShowCompletion` (338), `AcceptCompletion` (344), and `CompletionHandler` (413). Periodic quality, blocking. Queued in `completion-tidy`. Raised again at ce6abdb (periodic quality), with `open_popup` (`editor_assembly.rb:429`, beside `close_completion` at 398) shared the same way: assembly readers for both, asserted per holder in `test/adapters_assembly.rb`.
- Why it matters: CLAUDE.md asks everything shared to be kept in an assembly reader so the assembly test checks every holder; only `show_completion.close_completion` is checked.
- Fix outline: keep it in a reader and assert that the other two holders hold that one object.
- Also: test/adapters_assembly.rb, CLAUDE.md
- Category: editor
- Added: 2026-11-07

## EditorAssembly names the gateway without requiring it

- Where: `carat/adapters/editor_assembly.rb` line 327 at 3895e21, resolving only through the order of `carat.rb` lines 314 and 322. Periodic quality advisory. Queue item 39 (require orders).
- Why it matters: every other collaborator is required in the file; a reorder of `carat.rb` breaks it.
- Fix outline: add `require_relative "json_rpc_language_gateway"` with the other adapter requires.
- Also: carat.rb
- Category: editor
- Added: 2026-11-09

### The assembly grows with every feature (architecture-review M5)

Location: `carat/adapters/editor_assembly.rb` (582 lines), whose `initialize` builds every record and use case. Why: it is the one wiring place by design, but one long constructor makes a feature's wiring hard to find and review. Fix outline: group construction into a private method per feature (language services, discovery, plugins), keeping the readers and the one-instance rule `test/adapters_assembly.rb` checks.
- Also: test/adapters_assembly.rb
- Category: editor
- Added: 2026-11-15

### EditorAssembly names the loaded config value

- Location: carat/adapters/editor_assembly.rb:325 (sweep, quality).
- Why: the loaded Domain::Config is named value across about 175 lines.
- Fix outline: rename it loaded_config.
- Category: editor
- Added: 2026-11-17

### Ragged wiring comment around HandleKey in EditorAssembly
- Location: carat/adapters/editor_assembly.rb:191
- Why: the edited comment reads 'registered afterwards, after HandleKey, which :normal receives, the core ex commands before the', a broken wrap with stacked clauses that leaves a short ragged line, reported by two review passes, merged here.
- Fix: rewrap the paragraph and say HandleKey is built before the ex handlers because :normal receives it.
- Category: editor
- Added: 2026-11-18

### carat/adapters/editor_assembly.rb:406: the wiring ledger repeats what lint already checks: each (sprint-22 review quality)

- Location: `carat/adapters/editor_assembly.rb:406`
- Why: the wiring ledger repeats what lint already checks: each @wiring.record names the same assembly instance variable the construction passes, and lint (test/lint.rb holder_problems, ledger_records) checks the record against the construction and the holder's @slot = slot, so held(holder, slot).equal?(a.slot) in test/adapters_assembly.rb compares the assembly's own ivar with its own reader and cannot fail at run time, while adding about 40 record lines and a ledger built on every production start (duplication, speculative generality)
- Fix: either drop WiringLedger and have lint check that the construction passes the assembly's shared ivar for each shared keyword, or keep holder readers as before
- Also: test/lint.rb, test/adapters_assembly.rb
- Category: editor
- Added: 2026-11-20

### The LSP command handlers take services positionally (sprint-24 sweep quality)

- Location: `carat/adapters/editor_assembly.rb:502`
- Why: LspStartCommandHandler.register and LspRestartCommandHandler.register take `@services` positionally while every other register call takes keywords.
- Fix: a `services:` keyword in both.
- Category: editor
- Added: 2026-11-21

### Domain::Options.shipped parses the embedded defaults a second time at at carat/adapters/editor_assembly.rb:509 (sprint-26 sweep quality, note 10)

- Location: carat/adapters/editor_assembly.rb:509
- Why: Domain::Options.shipped parses the embedded defaults a second time at startup, built inline rather than kept in a reader, and lines 515-516 hand services to LspStartCommandHandler and LspRestartCommandHandler positionally where every other register takes keywords
- Fix: build the shipped options once into a reader, and take services: as a keyword
- Category: editor
- Added: 2026-11-22

### Two editors ending together share one temporary state file name
- Location: `carat/adapters/editor_assembly.rb`, `save_recent_files` (the `recent_files.tmp` beside the state file)
- Why: the private write removes a leftover temporary file and then creates it exclusively, so two editors ending at the same moment can remove each other's file or fail the create, and one list is lost; the list is a convenience and every failure is skipped, so nothing breaks, but the later list may not be the one kept.
- Fix: name the temporary file by the process id, or take an advisory lock on the state directory around the write.
none
- Category: editor
- Added: 2026-11-23

### make_state_directories skips a state directory that exists (exist?) without at carat/adapters/editor_assembly.rb:723 (sprint-30 sweep quality, note 20)

- Location: carat/adapters/editor_assembly.rb:723
- Why: possible security point, not examined: make_state_directories skips a state directory that exists (exist?) without checking it is not a symbolic link; for the security reviewer
- Fix: judge the point named in Why against the code; fix it with a test or record why it holds
- Category: editor
- Added: 2026-11-23
