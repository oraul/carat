# Proposal

## Why

Three patterns a machine can see keep reaching the quality review as blockers because `make lint` passes them: a Vim message literal spelled in a second file (E492 in `execute_ex.rb` and `plugin_router.rb`, periodic df4654c), a `def` replacing an `attr_reader` of its own class (the private `hover` in the gateway, blocker at 13de267), and a key binding hard-coded in Ruby (`PICK_BINDINGS` in `show_definition.rb`, which passed three quality reviews and cost the `definitions` run its third of four rounds). Quality first pass is 19 of 53 recorded runs.

This change is outside the roadmap of `docs/architecture.md` section 12: it repairs the delivery pipeline (`docs/queue.md` item 1, `implement-contracts-c`, the backlog entries "Lint does not catch a message literal in a second file or a def shadowing a reader" and "A key binding hard-coded in Ruby passes make lint").

## What Changes

- `make lint` refuses a Vim message literal (a string beginning `E<number>:`) whose fixed text, up to its first interpolation, is spelled in more than one file under `carat/`, `bin/`, and `carat.rb`. The eight repeats on `main` beside E492 are recorded in `KNOWN_REPEATED_MESSAGES` with their owner, queue item `messages-tidy`, and lint also refuses a recorded entry that no longer repeats, so the list only shrinks.
- E492 moves to `Domain::Messages.not_an_editor_command`, called by `ExecuteEx` and `PluginRouter`; the message is unchanged.
- `make lint` refuses a `def` that replaces a reader of its own class body: an `attr_reader` or `attr_accessor` name, or a `Struct` or `Data` member of the class line.
- `make lint` refuses a string literal outside `carat/plugins/` and the generated `carat/domain/default_config.rb` that begins `keymap.<mode> `, for every mode `config/default.caratrc` binds keys in, since a binding lives in the configuration or in a plugin's manifest.
- Each rule has its self-check case in `test/lint.rb`; the planner's records for this run go into `docs/backlog.md` (the periodic review at 186ddfb, the owners of the 8d8832f blockers) and its queue is shortened to the docs-lint budget.

## Out of scope

- The other parts of the planner's item: the docs gate taking a self-written `unchanged` line as proof and the two gate advisories moved to queue item `content-gate-gaps`.
- Removing the eight recorded message repeats (queue item `messages-tidy`).
- A binding spelled without the `keymap.` prefix, such as a key and an action in two literals; the rule catches the configuration-line form that reached the review.
- The 7 periodic blockers and the backlog compaction, which the planner queued as `periodic-blockers-a`, `periodic-blockers-b`, and `backlog-compaction`.

## Impact

- `test/lint.rb` and `test/lint.rb.expected`: three rules and their cases.
- `carat/domain/messages.rb`, `carat/use_cases/ex/execute_ex.rb`, `carat/use_cases/plugins/plugin_router.rb`: E492 in one place.
- `docs/codebase-map.md`: the lint line and the `Messages` method list. `docs/backlog.md`: the two closed entries removed, the new entries recorded.
- README.md: unchanged, the lint target and its usage keep their shape and no command changes.
- docs/architecture.md: unchanged, no spec changes and section 10's test machinery keeps its shape.
- CLAUDE.md: the key binding convention names the lint check.

## Assumptions

- "A message literal" is read as a Vim message (`E<number>: text`), the form both recorded findings had; other repeated strings are left to review.
- Recording the existing repeats with an owner, as `UNTYPED_SHARED` does for `Buffer#styles`, is preferred to rewriting eight messages across twenty files in a tooling change; a stale entry fails, so the exemption cannot outlive its cause.
- The reader rule works per class body, so a `def message` of one class beside a `message` member of another class in the same file is not a shadow.
