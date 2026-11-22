# Proposal

## Why

An untrusted project `.caratrc` can still chain its allowed bindings into running typed text as a command: it binds insert-mode `<CR>` to `mode.normal` (the `mode.` family is on the project allowlist and only `mode.cmdline` and `palette.open` are kept to normal and visual modes), then a letter such as `;` in normal mode to `mode.cmdline` or `palette.open`, so the next line the user types, believing they are inserting text, opens the command line or the palette and its Enter runs it (sprint-26 review security Lows (5) and (4), sprint-27 note 1). Two tidies ride along in the same files: `Keymap.leader_from` only returns `config.leader` (sprint-26 review quality, note 10), and `Config` pins its settings as `Array[untyped]` while one adapter reads the member directly instead of the typed readers. Outside the roadmap order: backlog security Lows of the configuration files that roadmap item 9 delivered (`docs/architecture.md` section 12).

## What Changes

- In the text-entry modes (`insert`, `replace`, `cmdline`, and the `completion` layer) a project file binds only actions that keep the mode: the `insert.`, `cursor.`, `scroll.`, and `completion.` families and `palette.next` and `palette.previous`. Any other action, `mode.normal` included, is reported as "<action> is not bound in <mode> mode from a project file" and ignored. Since a key the defaults or the user bind to an action the project could not bind is held, insert-mode and cmdline-mode `<Esc>` (`mode.normal`) are now held too: a project file may not unbind or rebind them.
- A project file binds `mode.cmdline` or `palette.open` only to keys that are not typed as text: keys whose every key is a printable character, Tab, Enter, or Backspace are refused as "<keys> is typed as text, so a project file may not bind it to <action>"; `<F4>` or `<C-k>p` stay allowed in normal and visual modes.
- `Keymap.leader_from` is removed; its callers read `Config#leader`.
- `Config`'s settings are read only through `count` and `line_at` (the language gateway's direct `settings.length` read becomes `count`), and the pin's comment says why it stays `Array[untyped]`: Spinel pins arrays only of builtin element types, so the typed reader `line_at` is what types the lines.
- Docs: README's project-file sentence, `docs/architecture.md` section 7's project-file line, `docs/codebase-map.md` (`config.rb`, `keymap.rb`).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `config-files`: ADDED requirements "A project file cannot leave a text-entry mode" and "A project file cannot open a prompt from keys typed as text".

## Out of scope

- The 7 headings split to config-guards-e and config-guards-f (RcLine's byte split, the background option's literals, the doubled collaborators, the generator's header and write step, visual star and hash, the Spinel empty-array appends, the tokenizer); they stay in the backlog, listed by the queue.
- A default or user binding of a prompt to a printable key (`<leader>p palette.open`) stays theirs: the rules are for the project file only, and such a key is not held.
- No `tools/rules.sh` edit; no file of the feature lane.
- Assumption: the text-entry modes are the modes the grammar does not read (`Mode.grammar?` false): insert, replace, cmdline, and the completion layer; `keymap.pick` binds in a pick list's normal mode and is not one.
- Assumption: "a printable key" is a binding every key of which can be produced by typing text (printable characters, Tab, Enter, Backspace), since only such a sequence can fire while the user types text; a sequence holding a control, Alt, or special key cannot.
- Assumption: the "Config pins its settings as untyped" heading is answered by the documented pattern of `docs/spinel-notes.md` (a pinned `Array[untyped]` read through a typed reader), not by a new list class, since `Config` already has the typed reader.

## Impact

- README.md: the project-file sentence of the configuration section names the text-entry rule and the typed-text rule.
- docs/architecture.md: section 7's project-file line says the same.
- docs/codebase-map.md: the `config.rb` and `keymap.rb` lines.
- docs/compatibility.md and docs/actions.md: unchanged, no Neovim command or bound action changes.
- CLAUDE.md: unchanged, no process change.
- Performance: the checks run only on a project file's keymap lines at startup; `lh`, `j`, and `insert` run none of them.
