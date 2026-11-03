# Proposal

## Why

Every contributor run starts cold and reads `CLAUDE.md` (84 KB, dominated by its Status paragraph and its Layout section) and `docs/architecture.md` (92 KB) in full before it can find the files a change touches. Over the last 15 contributor runs, 1,231 of 2,130 tool calls (58 percent) were reads and searches of the codebase, rising from 17 per run at #12 to between 111 and 169 per run at #18 to #23. The user approved a change to the agent setup and its documentation ("one contributor for many scouts", cheap read-only scouts, a code map, a slim `CLAUDE.md`, and the contributor's instructions improved), split into two changes; this is the first, `agents-and-map`.

## What Changes

- Add `docs/codebase-map.md`: one section per area of the codebase (build and CI, toolchain, configuration, grammar and keymap, motions and text objects, operators and registers, edit path and transactions, undo and repeat, visual modes, windows and tabs, ex commands and files, rendering, syntax highlighting, plugin host and API, explorer plugin, ports and drivers, tests and benchmarks). Each section gives what the area does in one line, the flow through its entry points, its files with their key methods by name, its tests, its archived designs, the rules that apply, and its benchmark scenarios where they exist. A closing section lists the delivered changes in order, the record the Status paragraph of `CLAUDE.md` used to hold.
- Add a coverage rule to `test/lint.rb`: every file under `carat/`, `bin/`, `test/`, `bench/`, and `tools/`, and `carat.rb`, appears in the map (a test's `.expected` snapshot through its test), and every file path the map names exists. `tools/ci_scope.sh` counts `docs/codebase-map.md` as a document a test reads.
- Slim `CLAUDE.md` from 84 KB to about 30 KB without losing a rule: Status shrinks to the done roadmap items, the next item, and pointers; Layout shrinks to the top-level folders and a pointer to the map; the conventions that were written twice are merged and the ones `docs/architecture.md` states in full point there. Every moved paragraph is listed in `design.md` with where it went.
- Add `.claude/agents/scout.md`: a read-only agent on the cheapest model tier with Read, Grep, Glob, and read-only shell, which follows the map for one area and writes a context pack of facts to `tmp/scout/<area>-<short commit>-<UTC timestamp>.md`, naming the commit it read, with the reuse and pruning rules for packs.
- Improve `.claude/agents/contributor.md` from the experience of the last runs: checks only through `make`, a resume path, detached check stages with progress files, the security review after committing, targeted tests while iterating, measured performance targets, re-verified findings, splits proposed during Propose, one push, the link footer stripped through the GitHub tool, scout packs and the map read first, other branches left alone, and a fixed report shape.
- Name both agents and the grouping rule in the Agents section of `CLAUDE.md`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a documentation, agent, and lint change with no change to the editor's behavior; `skip_specs` is set.

## Impact

- New: `docs/codebase-map.md`, `.claude/agents/scout.md`.
- Changed: `CLAUDE.md`, `.claude/agents/contributor.md`, `test/lint.rb` (its snapshot stays the empty report), `tools/ci_scope.sh`, `README.md` where it points at the layout.
- No file under `carat/`, `bin/`, or `bench/` changes; the editor binary is unchanged.

This change is outside the roadmap of `docs/architecture.md` section 12: it is a tooling change to the agent workflow that the user approved before more features.

Out of scope: slimming `docs/architecture.md` and the workflow that starts scouts before a contributor, which belong to the second change of the split; any change to the OpenSpec skills or commands under `.claude/`, which are generated.

Assumptions recorded instead of asked:

- The scout's frontmatter sets its `model` field to the cheapest tier. This is a tool setting the agent loader reads, not a model name or identifier in prose; the hard rule against model names in pushed files is read as covering prose, identifiers, and attribution. The pull request's Notes say so, so the user can decide.
- Scout packs live under `tmp/scout/`, which `.gitignore` already ignores through `tmp/`; packs are Markdown, which `spin` does not read as source, so the directory need not be hidden.
- The Status paragraph's history moves to the map's closing section, one line per delivered change, since `docs/architecture.md` section 12 already records each roadmap item's delivery and the archived changes hold the detail.
