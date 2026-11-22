# Proposal

## Why

Switching files with unsaved work means writing first: `:e` and the buffer commands refuse a modified buffer with `E37` as Neovim does with `hidden` off, while closing a window already keeps a modified buffer hidden. The design council of 2026-11-21 (decision 2) put these basics ahead of the remaining Facet waves and the user approved a global `hidden` option, on by default, as Neovim 0.10 has it. This is part 2 of the set-options brief, split by the planner after `:set` for the existing options merged (#287). Roadmap: item 9, `options-and-config` (`docs/architecture.md` section 12).

## What Changes

- A global option `hidden` (`hid`), a flag, on in `Options.new` and in `config/default.caratrc` (`option.hidden true`, mirrored by `make gen-config`), read from the `option.hidden` line and set by `:set` in Vim's boolean forms (`hid`, `nohid`, `invhid`, `hid!`, `hid?`, `hid&`).
- On, `:e` of another file and `:b N`, `:bn`, `:bp`, `:bN`, `:bfirst`, `:blast` leave a modified file buffer hidden with its changes instead of refusing it with `E37`; off keeps today's refusals, the bang still overriding them.
- `:e` or `:e <current path>` reloads the current buffer in place and drops its changes, so a modified buffer still refuses it with `E37` whatever the option says, as Vim does.
- `:q` on the last window and `:qa` still name a modified hidden buffer with `E37` and `E162`; no code changes there, a test proves it with the option on.
- `SwitchBuffer` is also what Ctrl-^, `gt`, `gT`, `]b`, `[b`, `[B`, and `]B` run, so they follow the option too: the same rule for every way of showing another buffer in the window, as Neovim's `hidden` has it.
- Docs: the `hidden off` Differences sentence and the rows of `:e`, `:b`, `:bn`, `:bfirst`, Ctrl-^, `gt`, and the `:set` flag row in `docs/compatibility.md`, its Options sentence, the README options section, `docs/architecture.md` (the option lists), `docs/codebase-map.md`, and the comments of `config/default.caratrc` with its generated mirror.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `buffer-list`: ADDED requirement "The hidden option decides whether a switch leaves a modified buffer"; MODIFIED "Refusals of the buffer switch" and "Moving to the first and the last buffer".
- `command-line-mode`: MODIFIED the `:e` requirement (a modified buffer is left hidden under `hidden`; the reload stays refused).
- `jump-list`: MODIFIED "Ctrl-^ shows the alternate buffer".
- `buffer-tabs`: MODIFIED "gt and gT move between the buffer tabs".
- `set-command`: MODIFIED "Flag options take Vim's boolean forms" (`hidden` joins the flags).

## Out of scope

- Ctrl-O and Ctrl-I across files (`walk_jumps.rb`) and the jump to a definition or other target in another file (`visit_target.rb`) keep refusing a modified buffer with `E37`: the brief names `:e` and the six buffer commands only, the planner asked the user and the brief did not add them. Recorded in `docs/findings/hidden-option.md`.
- `:bd`, `:q`, `:qa`, and the explorer's file opening keep their rules.
- No local options, `:setlocal`, or `bufhidden`.
- No `tools/rules.sh` edit; no file of the backlog lane.
- Assumption: the default is on in `Options.new` too (as `ignorecase` mirrors the shipped value), so a harness without a configuration behaves as the editor does; tests of the refusals set `:set nohidden` first.
- Assumption: the refusal of a modified scratch buffer is untouched (a scratch buffer was never refused).

## Impact

- README.md: the options section names `hidden` among the options and says what it decides.
- docs/architecture.md: the `Options` and `option.<name>` lists name `hidden`.
- docs/codebase-map.md: the `options.rb` line and the tests' lines that carry the new cases.
- CLAUDE.md: unchanged, no process change.
- Performance: `lh`, `j`, and `insert` read an option only on a buffer switch, not on a key's path.
