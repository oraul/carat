# Backlog: test/lint.rb

## The plugin host keeps many-method classes in use_cases

- Where: `carat/use_cases/plugins/`: `PluginHost` (18 public methods besides `call`), `PluginRegistry` (24), `PluginEntries` (5), `PluginEntry` (5), `PluginEvents` (4), `PluginRouter` (4), `PluginSyntax` (3), and `PendingEvent` (1), which the one-call rule of `test/lint.rb` skips by directory since the `use-case-boundaries` change; the request families (`BufferRequests`, `WindowRequests`, `FileRequests`, `UiRequests`) and `PluginLink` keep their request methods by design, as the adapter of `PluginApi::Host`.
- Why it matters: the rule that a use case exposes only `call` holds for the core, but the host's parts are not use cases at all: they are the infrastructure between compiled plugins and the core, and while they sit in `use_cases` the layer reads as if a use case could have two dozen entry points. The `use-case-boundaries` change decided they move out with the whole host and left the move to this plugin-side part, because it reworks the host's construction, the assembly, and five test programs.
- Fix outline: move `carat/use_cases/plugins/` with `concerns/guarded.rb` and `plugins/boundary.rb` to carat/adapters/plugins/ as `Carat::Adapters`, give the core a port in `carat/ports/` for the calls the use cases make into the host (`observe`, `saved`, `resized`, `answer`, `action`, `command?`, `command`, and the tokenizer calls of `HighlightView`), implemented by the host and handed to `SaveFile`, `HandleKey`, `CancelCommandLine`, `ExecuteCommandLine`, `PluginActionHandler`, `PluginCommandHandler`, and `HighlightView` by the assembly, keep the request families' request methods, update the layer ranks and `docs/architecture.md` sections 3, 5, and 9, and drop the `use_cases/plugins/` exemption from the one-call rule.
- Also: docs/architecture.md
- Category: code-quality
- Added: 2026-11-03

## Four float layer methods are exempt from the predicate rule by name

- Where: `BOOL_COMMANDS` in `test/lint.rb` line 212, and `FloatLayer#add`, `#enter`, `#move`, and `#close_top` in `carat/domain/float_layer.rb` at `floating-windows`. Quality advisory of `floating-windows`.
- Why it matters: the table is keyed by bare method name, so `add`, `close`, `enter`, and `move` are now exempt from the predicate rule in every file, while the bool results of those four methods are read only by tests (`OpenFloat` checks `full?` first, `WindowRequests` checks the float's tab first).
- Fix outline: make the four return void, update the tests to check the layer's state instead, and drop their entries, keeping `close` and `close_focused`.
- Also: carat/domain/float_layer.rb
- Category: code-quality
- Added: 2026-11-07

## The holder check counts every assembly reader type as shared

- Where: the `shared` list in `test/lint.rb` line 946 at 4f653d2, which takes the type of every `EditorAssembly` reader. Two quality advisories in `implement-contracts`.
- Why it matters: generics count too (`config_errors` is `Array[String]`), and a namespaced generic such as `Array[Domain::X]` is cut to `X]`, so a holder reader typed `Array[String]` would be demanded a row in `test/adapters_assembly.rb` as if it were a shared object.
- Fix outline: keep only types with a home class under `carat/` (the `homes` the check already builds), or skip types containing a bracket, with a lint case.
- Also: test/adapters_assembly.rb
- Category: code-quality
- Added: 2026-11-07

## The holder check matches a reader with no right boundary

- Where: the `.holder.reader` substring match in `test/lint.rb` line 735 at 4f653d2. Quality advisory in `implement-contracts`.
- Why it matters: a reader counts as checked when the assembly test names a longer reader with the same prefix (`.handle_key.command_line` inside `.handle_key.command_line_x`), so a missing holder row can pass.
- Fix outline: require a non-word character (or the end of the line) after the match, with a lint case for the prefix.
- Category: code-quality
- Added: 2026-11-07

## Two lint checks parse constructor keywords with copied slicing

- Where: `holder_problems` in `test/lint.rb` line 719 and `constructor_problem` at line 365 at 4f653d2, both slicing `stripped[15, ...]` after `def initialize(`. Quality advisory in `implement-contracts`.
- Why it matters: the parser is copied with a bare 15, and both read only one-line constructors, so a fix to one misses the other and a wrapped signature is skipped silently.
- Fix outline: one `keyword_names(stripped)` helper both call, the 15 spelled as the prefix's length.
- Category: code-quality
- Added: 2026-11-07

## The lint rules of implement-contracts-b rescan and reread

- Where: `test/lint.rb` at the `implement-contracts-b` change: line 1120 reads `File.read(MAP)` again right after `map_problems` read it; line 1139 skips `carat/domain/default_config.rb` in the untyped parameter and shared list rules with no stated reason; line 1145 dedupes the shared list names with `pinned_names.index(name) == j` and rescans every owner per match over parallel arrays; line 1150 rescans `pinned_names` and `pinned_owners` for every assigning line and name. Quality advisories of `implement-contracts-b`.
- Why it matters: the scans are quadratic in names per line and harder to read than the rule they enforce, the map is parsed twice per run, and an unexplained skip invites a wrong copy.
- Fix outline: read the map once into a local passed to both checks; comment that `default_config.rb` is generated, or drop the skip if it holds neither shape; after the pin scan build one Hash from name to its owner paths (or a unique name list and `path + name` owner keys) and test membership in it in both the shared and the owned loops.
- Also: carat/domain/default_config.rb
- Category: code-quality
- Added: 2026-11-09

## The reader shadow check skips classes whose name ends in end

- Where: `shadow_problems` in `test/lint.rb` line 1019 at e0bca07, which skips any `class` or `module` line ending in `end`. Quality advisory in `implement-contracts-c`.
- Why it matters: the skip is meant for one-line bodies, but a class named `Backend`, `Append`, or `Legend` also ends in `end` and is silently never checked; no such class exists today.
- Fix outline: skip only a one-line body (the head holds `;`, as in `; end`), and add a `class Backend` case to the reader shadow self-check.
- Category: code-quality
- Added: 2026-11-10

## Two lint def readers parse the same prefixes separately

- Where: `def_name` in `test/lint.rb` line 998 beside `def_named?` at line 661, and `symbol_names` at line 980 beside `symbol_named?` at line 674, at e0bca07. Quality advisory in `implement-contracts-c`.
- Why it matters: `def_name` repeats the `private`, `protected`, `def`, and `self.` prefix parsing of `def_named?`, and `symbol_names` has its own boundary rules, so a fix to one reader can miss the other and the checks drift.
- Fix outline: build `def_named?` on `def_name` (or one shared prefix helper), and `symbol_named?` on `symbol_names`, so each pair shares one parser.
- Category: code-quality
- Added: 2026-11-10

## Backlog entries name queue items that are gone

- Where: `docs/backlog.md:2273` and 33 others (architecture-drift 8, global-tidy 8, search-structure 8, substitute-structure 5, diagnostics-tidy 4, pipeline-hardening 1); 15 under the archived implement-contracts items (`test/lint.rb:1287`). Periodic quality.
- Why it matters: those findings have no live owner.
- Fix outline: requeue each under a live item or drop the reference, and have `tools/docs_lint.sh` check every named owner is queued. Queue item `backlog-compaction`.
- Also: tools/docs_lint.sh
- Category: code-quality
- Added: 2026-11-10

### test/lint.rb helpers return arrays to destructure

- Location: test/lint.rb:255 (`expected_declaration` returns namespaces and base) and :862 (`typed_readers` returns name and type pairs), read back through `Carat::Json.element` at 283, 874, 892, 893, 1290, 1298 to 1300. Sprint-6 review, quality advisory. Queue item `spinel-workarounds`.
- Why: the tests rule asks a helper returning several values to return an object with typed readers.
- Fix outline: small typed records (a declaration with namespaces and base, a reader with name and type) and drop those element reads.
- Category: code-quality
- Added: 2026-11-15

### Lint misreports a typed readerless keyword behind a parenthesized type
- Location: test/lint.rb:941
- Why: a keyword the signature does type, but behind a type holding a parenthesis before `) ->` (the self-test's `^(Integer) -> void` row), is reported as one the signature does not type, sending the reader to fix a signature that is correct.
- Fix: word the message as a keyword lint cannot read from the one-line `#:` signature directly above `def initialize`, and say how to make the signature readable.
- Category: code-quality
- Added: 2026-11-20

### Lint passes a readerless holder whose initialize parameters span lines
- Location: test/lint.rb:932
- Why: a `def initialize` whose parameters span lines yields no keywords, so a readerless holder with such a def and a signature that `signature_keywords` cannot read still passes unchecked; none exists in `READERLESS_DIRS` today, so the check is silently vacuous for that shape.
- Fix: report a readerless holder whose `def initialize(` line does not close its parameter list on that line, with a self-test row.
- Category: code-quality
- Added: 2026-11-20

## Findings of use-case-surface-a after its package step

- quality advisory test/lint.rb:916 simplicity: holder_problems now takes six positional parameters, runs two mutually exclusive branches (readerless by signature, others by # @rbs line) and carries a 12-line comment; fix: split the branches into readerless_keyword_problems and rbs_keyword_problems called from holder_problems
- quality advisory test/lint.rb:999 duplication: ledger_problem and ledger_slots each parse @wiring.record lines with their own marker, and the passed-keyword text check is written twice (holder_problems' slot check and ledger_problem's before/after loop); fix: one ledger_records(holder, assembly) returning slot and object pairs and one passes?(built, keyword, value) helper used by both
- quality advisory test/lint.rb:1435 naming: the local wiring holds the assembly's source text, not the ledger, beside assembly holding its readers; fix: rename it assembly_text
- quality advisory carat/adapters/wiring_ledger.rb:262 speculative generality: record's replace-on-second-record branch serves no caller, since the assembly records each pair once, and the probe self-check in test/adapters_assembly.rb:38 exists only to cover it; fix: drop the branch and the probe row, or have lint refuse a second record of a pair
- quality advisory test/editor_key_hints.rb:27 duplication: empty_session repeats session but for the file's text, as does empty_session in test/editor_palette.rb:33; fix: give session the file text as a parameter, or one builder both helpers call
- quality advisory test/lint.rb:514 rule gap: reader_problems refuses only attr_reader, so a public attr_accessor in a readerless directory, also a reader, passes; fix: match attr_accessor too, with a self-test row
- quality advisory docs/architecture.md:278 docs accuracy: section 8 says the assembly keeps a reader or a WiringLedger record for each shared object, but it keeps a reader for every shared object and the ledger records what each readerless holder was handed; fix: keeping a reader for each, and recording in its WiringLedger what each readerless holder was handed
- Also: carat/adapters/wiring_ledger.rb, test/adapters_assembly.rb, test/editor_key_hints.rb, test/editor_palette.rb, docs/architecture.md
- Category: code-quality
- Added: 2026-11-20

### The lint reads the library in four passes (sprint-24 sweep quality)

- Location: `test/lint.rb:1343`, `:1487`, `:1496`, `:1525`
- Why: each pass globs and reads every library file and repeats the default_config skip.
- Fix: read the library once into a path-to-text table.
- Category: code-quality
- Added: 2026-11-21

### constructor_problem reads only a one-line def initialize( and the text at test/lint.rb:378 (sprint-32 sweep quality, note 79)
- Location: test/lint.rb:378
- Why: constructor_problem reads only a one-line def initialize( and the text before its first ), so a parameter list over several lines, or a positional parameter after a default with parentheses (b: Foo.new(1), c), passes unchecked
- Fix: join the def's lines up to the closing paren at depth zero and split the parameters at top-level commas, with a self-check row for each case
- Category: quality
