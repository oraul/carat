# Proposal

## Why

Options can be changed only by editing a `.caratrc` file and restarting: `:set` handles `filetype`, `syntax`, the four search options, and `cursorline`, and answers `Not implemented: :set name` for every other option the editor has (`carat/use_cases/ex/set_command_handler.rb`, `PENDING`). The design council of 2026-11-21 (decision 2) put these basics ahead of the remaining Facet waves. Roadmap: item 9, `options-and-config` (`docs/architecture.md` section 12), which keeps `:set` beyond `filetype` and `syntax`.

## What Changes

- `:set` takes every option of `PENDING` but `theme` and `background` (`bg`), by its full and short name, as Neovim 0.10 does: the numbers `tabstop` (`ts`), `shiftwidth` (`sw`), `scroll` (`scr`), `scrolloff` (`so`), `timeoutlen` (`tm`), `undolevels` (`ul`), and `showtabline` (`stal`) as `name=N`, `name+=N`, `name-=N`, `name^=N` (multiply), `name?`, and the bare name; the flags `number` (`nu`), `relativenumber` (`rnu`), `expandtab` (`et`), `autoindent` (`ai`), `list`, `startscreen`, and `reducedmotion` in Vim's boolean forms, as the search options and `cursorline` already take them; the words `listchars` (`lcs`), `winborder`, `icons`, and `breadcrumbs` as `name=value`, `name?`, and the bare name, a blank in the value written `\ ` as in Vim.
- Every value is checked by the configuration line's own rule, through one `Options#problem` that both `Options#apply` and `:set` call, so `:set` never stores a value an `option.*` line would refuse: a value that is not a number is `E521: Number required after =: ts=x`, any other refused value `E474: Invalid argument: ts=0`, and the option keeps its value.
- `name&` resets an option `:set` handles to its shipped default (the value `config/default.caratrc` gives it).
- A bare `:set` lists, under `--- Options ---`, the options that differ from their shipped defaults and the current buffer's `filetype` and `syntax` when set; `:set all` lists every option `:set` handles.
- A change shows at once: the next frame reads the option, `undolevels` reaches the buffer feed every buffer records its undo states through, and the frame's layout key gains the number column so a window draws its new gutter. `startscreen`, read only when the editor starts, answers `Not implemented: :set startscreen live` to every form that would change it; `:set startscreen?` shows it.
- `theme` and `background` keep `Not implemented: :set name`; any other name is `E518`; a `no` or `inv` prefix, a value, or `!` on an option that is not a flag is `E474`; `+=`, `-=`, `^=` on a word option and `&` on `filetype` or `syntax` answer `Not implemented: :set word`.
- Docs: `docs/compatibility.md` (the `:set` rows per kind and the Differences and Options sentences that said `:set` does not handle an option), the README options section, `docs/architecture.md` (the item 9 line), `docs/codebase-map.md`, and the comments of `config/default.caratrc` with its generated mirror.

## Capabilities

### New Capabilities

- `set-command`: `:set` of the global options the editor has: the numbers, the flags, the words, `&`, the listings, and the startup-only option.

### Modified Capabilities

- `syntax-highlighting`: MODIFIED requirement "The filetype and syntax are set with set" (other names than the handled ones are now the `set-command` capability's; `theme` and `background` answer Not implemented).
- `config-files`: REMOVED requirement ":set answers showtabline as not implemented", replaced by the `set-command` capability.

## Out of scope

- Split by the planner: the `hidden` option is `hidden-option`, and `:colorscheme` with `:set theme=`, `:set background=`, and their Tab completion is `colorscheme-command`, both Sprint 26 items.
- Options that are not in `PENDING` (`indentguides`, `indentguides.char`, `keyhints.delay`, `layout.*`, `jumptab`, `gt`, `wrap`, `clipboard`): they keep `E518`, the backlog lane's config-guards-b names them.
- Local options and `:setlocal`, `:set all&`, `+=`, `-=`, and `^=` on a word option (Vim's comma-list forms).
- No `tools/rules.sh` edit; no file of the backlog lane.
- Assumption: `startscreen` and `reducedmotion` are flags in Vim's boolean forms, since their configuration lines take `true` or `false`, though the brief lists them with the words.
- Assumption: a refused value is worded as Neovim words it (`E474: Invalid argument: arg`, `E521: Number required after =: arg`), not with the configuration's range text; the range itself is the configuration line's.
- Assumption: several arguments stop at the first refused one, the ones before it kept, as the handler already does.

## Impact

- README.md: the options section says every option above is set by `:set` too, with its forms.
- docs/architecture.md: the item 9 line of the roadmap says which part of `:set` arrived.
- docs/codebase-map.md: the `set_command_handler.rb`, `options.rb`, and `frame_presenter.rb` lines.
- CLAUDE.md: unchanged, no process change.
- Performance: one more integer in the frame's layout key; `lh`, `j`, and `insert` run no `:set`.
