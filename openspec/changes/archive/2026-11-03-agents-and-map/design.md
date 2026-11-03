# Design

## Context

A contributor run reads `CLAUDE.md` and `docs/architecture.md` in full before it can find anything, because the only index of the code was the Layout section of `CLAUDE.md`, one 31 KB bullet list in layer order, and the only record of what is done was the Status paragraph, 12 KB of history. Over the last 15 runs 58 percent of tool calls were reads and searches. The user approved "one contributor for many scouts": cheap read-only agents gather the facts of each area first, and the contributor starts from those facts and an index organized by area. This change delivers the index, its check, the scout, the slimmer `CLAUDE.md`, and the contributor's instructions; slimming `docs/architecture.md` is the second change.

## Goals / Non-Goals

Goals:

- An index by area that a scout can follow and a contributor can read one section of.
- A check that keeps the index complete as files come and go.
- `CLAUDE.md` at about a third of its size with every rule kept.
- A scout agent that produces facts, not conclusions, at the lowest cost.
- The contributor's instructions brought up to what the last runs learned.

Non-Goals:

- Slimming `docs/architecture.md`, and the workflow that starts scouts automatically.
- Any change to the editor, its tests' behavior, or the OpenSpec files under `.claude/`.

## Decisions

### The map is organized by area, not by layer

A change touches one feature across layers (the edit path is `Buffer` in the domain, the dispatcher in the use cases, and the plugin host's events), so the map has one section per area, 18 in all: build and CI, toolchain, configuration, composition and state, grammar and keymap, motions and text objects, operators and registers, edit path with insert mode, undo and repeat, visual modes, windows and tabs, ex commands with the command line and files, rendering, syntax highlighting, plugin host and API, explorer plugin, ports and drivers, tests and benchmarks. The request named about 15; composition and state, and the toolchain beside build and CI, were split out because the composition root and the records have no single feature home, and the ruby plugin went to syntax highlighting with its engine. Each section has What, Flow, Files (key methods by name, no line numbers, which go stale), Tests, Designs (archived change and section names), Rules, and Bench where scenarios exist. Every file is in exactly one area, so a scout's area is unambiguous.

### The coverage rule lives in the lint test

`test/lint.rb` already reads every source file and runs in `make test`, `make lint`, and CI, so the rule costs no new target. It takes the code spans of the map (text between backtick pairs) and requires every file under `carat/`, `bin/`, `test/`, `bench/`, and `tools/`, and `carat.rb`, to be one of them; a `.rb.expected` snapshot is covered by its test. In reverse, every span that reads as a lowercase file path under those roots must exist, so a removed file cannot linger in the map; spans with placeholders (`test/NAME.rb`) or a trailing slash are not paths. The rule has a self-check over a small sample like the other rules, and a second one that the file walk reaches subdirectories and skips directories. `tools/ci_scope.sh` now counts the map as a document a test reads, so a map-only change still runs the checks. The snapshot of `test/lint.rb` gains the two self-check lines.

### What moved out of `CLAUDE.md`, and where

Size: 84,391 bytes before, 39,371 after. The verbatim sections (Hard rules, Git workflow, Branch naming, Commit messages, Pull requests, Pull request description, OpenSpec) are unchanged but for two example lists put on one line each and one duplicate line removed.

- Project, Status paragraph (12 KB): replaced by three sentences (done roadmap items, the next item, pointers). Its history went to the closing section of `docs/codebase-map.md`, Delivered changes, one line per pull request with what each left for later (the buffer list commands, `plugin-finder`, the marks, the time arguments of `:earlier` and `:later`, the syntax items, the plugin-side change); `docs/architecture.md` section 12 already records each roadmap item's delivery.
- Project, Architecture bullet: "Read it before planning any change" became "read the sections of it the change touches", as the request asks the contributor to do; a new Code map bullet says what the map is and that the lint test checks it.
- Layout (31 KB): every per-file bullet moved into the file's area of the map, merged with the method names; the section keeps one bullet per top-level folder and the ignored directories. The stale mention of `config/plugins.json` for the registry was corrected to `config/plugins.caratrc` on the way.
- Agents: rewritten to name the contributor, the scout, and the grouping rule.
- Stack: Language and Toolchain shortened; the reasons stay in `docs/architecture.md` sections 2 and 13, and the hidden `tmp/` directories moved to the Layout's ignored line.
- Commands: each target kept with its rule; the explanations of the test runner, the analysis budget, and `spinel-doctor`'s legs point to `docs/architecture.md` section 10, and `make bench`'s measurements to the map.
- Coding conventions: the two inline RBS bullets merged into one, and the two concern bullets merged into one; the use case bullet keeps its lint rules and points to `docs/architecture.md` section 5 for the split rules, which that section states with the same examples; the record bullet keeps the record list, the subclass form, the keyword `initialize`, and the lint checks, and points to section 2.1 for what Spinel supports; the test value and test file bullets point to section 10 for the measurements; the concern and plugin bullets point to sections 5.4 and 9.

### Every rule, and where it is now

Checked by reading the old file bullet by bullet against the new one and the sections it points to:

- Hard rules (contributor-only changes, no session URL, no URL but the Spinel clone address, no email but the trailer, the exact trailer, no other trailer, no model names, no secrets, Ruby 4 through Spinel only, tests and snapshots and benchmarks only through `make`): unchanged in `CLAUDE.md`.
- Git workflow, branch naming, commit messages, pull requests, the pull request description contract, OpenSpec: unchanged in `CLAUDE.md` (the duplicate "Do not create a pull request unless explicitly asked" kept once, in Git workflow).
- The contributor delivers every change; the main session hands work over: `CLAUDE.md` Hard rules and Agents.
- Keep Commands, Stack, Layout, and now the map accurate; keep this file, the map, and the README in sync: `CLAUDE.md` Project and Coding conventions.
- Each command's behavior and its rules (never `spin test` directly, review snapshot diffs, `make check` before every push, bump `SPINEL_REF` in its own pull request with the regenerated header, `make clean` never touches `tmp/`): `CLAUDE.md` Commands.
- Naming rules, `BOOL_COMMANDS`, suffixes and prefixes, verb-phrase use cases and noun drivers: `CLAUDE.md` Coding conventions, unchanged.
- One public `call` per use case and the three lint rules: `CLAUDE.md`; operation, variant, handler, shared logic, and shared constant rules: `docs/architecture.md` section 5 (and the short form in `CLAUDE.md`).
- Keyword constructors, defaults only for stateless collaborators, wiring only in `EditorAssembly`, the shared-instance test and its readers: `CLAUDE.md`.
- Concerns: `CLAUDE.md` (readers comment, module function fallback, list classes) and `docs/architecture.md` section 5.4 (the behavior-only rules, `# @rbs skip`).
- Tests alongside changes, typed test values, test modules and the runner line, helpers returning objects: `CLAUDE.md`, with the measurements in `docs/architecture.md` section 10.
- Backlog entries for unfixed findings; Spinel rules and the layer rule; no RuboCop: `CLAUDE.md`.
- Inline RBS everywhere, no sidecars, signatures trusted, required parameters, overridden methods' `# @rbs` lines, `make types`: `CLAUDE.md`, with section 2.1.
- Record kinds, the record list, subclass form only, keyword `initialize`, keyword construction and its lint checks, plain behavior classes: `CLAUDE.md`, with section 2.1. `Struct` members through readers and writers, pinned members, the empty array literal, `super()` for partial members: `CLAUDE.md`.
- `Array[T]` and `Hash[K, V]` pins, `Symbol` not pinned, `Data` pins need a statement, empty hash literals, constant hash keys, `Hash` keys `String` or `Symbol` only, the line array through the writer: `CLAUDE.md`.
- Bindings never hard-coded, `make gen-config`, plugin bindings below the configuration's, every action with a handler and a line in `docs/actions.md`, the kinds, ex handler order, a new motion's five maps, visual operators, action names: `CLAUDE.md`, unchanged.
- Plugins: the require and naming rules, ids, strings, copies, the guarded path, a new request's three parts and version bump, a new plugin's list, registry, configuration lines, manifest, and actions, icons by name: `CLAUDE.md`, with section 9.
- Buffer text only through the primitives, never mutating a line string, the derived modified flag, who opens transactions: `CLAUDE.md`, unchanged.
- Every Neovim command in `docs/compatibility.md` with a table-driven test; ask before hard-to-reverse changes: `CLAUDE.md`, unchanged.

### The scout

The `model` setting in the frontmatter puts the scout on the cheapest tier; its tools are Read, Grep, Glob, and the shell, the shell for read-only git and listing commands and for the one heredoc that writes the pack, since a scout with a Write tool could write anywhere. A pack is facts with a path and line on every entry, the commit it was read at, the files it read (so reuse is one `git diff --quiet` over them), quotes of the designs and rules, and Gaps for what was not found. The scout prunes packs whose commit left `main` and reuses a pack still current. Packs go to `tmp/scout/`, already ignored through `tmp/`; they are Markdown, which `spin` does not read, so the directory need not be hidden. Agents cannot start agents here, so the main session or a workflow starts the scouts; the contributor reads the packs first and stops naming the missing area when it lacks context.

### The contributor

The file keeps the mandate, the stop conditions, and the phases, and adds what the last runs learned, without repeating `CLAUDE.md`: a Context step (packs, then the map, then only the touched sections); a resume path from the branch, `tasks.md`, and the progress file; targeted tests while iterating and one full `make check` on the committed tree, run as detached stages with logs and a progress file under `build/stages/<change>/`, so a restart repeats only the interrupted stage; the security review after committing, done inline when it asks for sub-tasks; measured performance targets (`make bench` on one core, interleaved runs, medians, stop on a miss); findings re-verified against `main`; a split proposed during Propose with the grouping rule; one push; the footer removed through the GitHub tool, since a REST `PATCH` re-appends it; other branches never touched; and a fixed report shape.

## Risks / Trade-offs

- The map can drift in what it says about a file even while the lint rule passes, since the rule checks presence, not descriptions. Method names without line numbers drift slowly, and every change that touches an area is asked to update it.
- `CLAUDE.md` lands at 39 KB, above the 35 KB of the target range: the sections the request keeps unchanged (hard rules to OpenSpec, 13 KB) and the coding conventions (14 KB), whose rules are not all stated elsewhere, set the floor without dropping a rule.
- The scout's `model` frontmatter setting names a model tier in a committed file. It is the setting the agent loader reads, not prose, an identifier of a specific model version, or attribution; the pull request says so for the user to decide.

## Migration Plan

None. The next contributor run reads the slim `CLAUDE.md` and the map; scouts are optional until the second change adds the workflow that starts them.
