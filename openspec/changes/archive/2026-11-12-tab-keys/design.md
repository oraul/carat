# Design

## Context

`gt` and `gT` are bound to `tab.next` and `tab.previous` (`config/default.caratrc:180`, `:181`), which `TabHandler` sends to `SwitchTab` with the typed count; `SwitchTab` moves through `TabList#next_tab` and `#previous_tab`. The top row lists the listed file buffers (`BufferList#tab_row?`, `TabBar`), which only `:bn`, `:bp`, and `<leader>bn`, `<leader>bp` (`BufferHandler`, `SwitchBuffer`) step through. `TabCommandHandler#call` (`carat/use_cases/ex/tab_command_handler.rb:33`) never reads `command.args` for `:tabc`, `:tabo`, `:tabn`, `:tabp`, `:tabfir`, or `:tabl`. The key decoder keeps only the first CSI parameter, so Ctrl-PageDown reads as PageDown, and key notation has no `<C-PageDown>`. `TabList` keeps no last accessed tab page.

## Goals / Non-Goals

Goals: the acceptance of queue item `tab-keys`: `gt`, `gT`, `{count}gt` over the buffer tabs; `<C-PageDown>`, `<C-PageUp>`, `:tabnext`, `:tabprevious`, and `g<Tab>` over the tab pages; `[b`, `]b`, `[B`, `]B` over the buffers; `option.gt` for Vim's meaning; each with one and two tab pages; a tab ex argument that acts or refuses.

Non-goals: `:tabmove`, `:tabs`, `:tabdo`, a range or count before a tab ex command, Vim's `+N`, `-N`, `$`, and `#` arguments, the tab row's drawing.

## Decisions

### gt and gT are tabline actions that read option.gt

`gt` and `gT` bind to the new actions `tabline.next` and `tabline.previous`, registered by `TabHandler` with a `tabline` flag; `tab.next` and `tab.previous` keep their tab-page meaning and move to `<C-PageDown>` and `<C-PageUp>`. A `tabline` handler asks `state.options.gt_follows_buffers?`: false sends the same `TabRequest` the tab-page actions send, so `option.gt tabpages` is exactly Vim's `gt`; true sends a `BufferRequest` to `SwitchBuffer`: `{count}gt` the new target `:tab` (the count-th tabbed file buffer, `BufferList#file_at`, nothing when there is none, as `{count}gt` past the last tab page does nothing), else `:next` or `:previous` with the count, at least one, as `buffer.next` does. Reading the option in the handler keeps the keymap free of conditions: no keymap line reads an option today, and a binding chosen by an option would need a conditional syntax in `.caratrc`. Rebinding `gt` was the other choice, but the item asks for `option.gt`.

`TabHandler` takes `switch_buffer` beside `switch_tab`; a second handler class for two actions that share the tab-page path would repeat its registration and wiring.

### option.gt mirrors jumptab

`Options#gt` is a string of `buffers` or `tabpages` (`GT_BUFFERS`, `GT_TAB_PAGES`, `GTS`), checked in `apply` with `unknown gt mode WORD` as `jumptab` is; the record's built-in value is Vim's `tabpages`, and `config/default.caratrc` sets `buffers` with a comment. `gt_follows_buffers?` is the one place the rule is read.

### g<Tab> needs the last accessed tab page in TabList

`TabList` gains `last_index` (-1 for none) and `visit(index)`, which records the tab page left and makes the index current; `next_tab`, `previous_tab`, `add_tab`, `focus_buffer`, and `SwitchTab`'s `:first` and `:last` go through it, so every tab switch the user makes is a visit, as Vim's `lastused_tabpage`. `remove_tab` forgets `last_index` when the closed tab page is the current or the last accessed one, as Vim's pointer to a freed tab page is no longer valid, and shifts it down when a tab page before it closes. `last_accessed_tab` visits `last_index` when it names another existing tab page, else does nothing. The plugin host's window requests keep writing `tab_index` directly: they save and put back the current tab page around a request, which is not a visit.

### The tab ex argument

`TabCommandHandler` parses the argument itself, as `BufferCommandHandler` does: a run of ASCII digits, held below ten digits so it stays an Integer. For `:tabn`, `:tabc`, and `:tabo`, Vim's `get_tabpage_arg`: 0 is `E16: Invalid range`, anything else that is not a tab page number `E475: Invalid argument: ARG`; for `:tabp` and `:tabN` a positive count or `E475`; `:tabfir` and `:tabl` take none (`E488`). `:tabc` and `:tabo` check one tab page before the argument, as Vim's `ex_tabclose` and `ex_tabonly` do. `CloseTab#call(state, number)` and `CloseOtherTabs#call(state, number)` take the tab page number, 0 for the current one; `CloseOtherTabs` visits tab page N first, then closes the others.

### The Ctrl page keys

`Key::CTRL_PAGE_UP` and `CTRL_PAGE_DOWN` are new special codes; `KeyNotation` names them `<C-PageUp>` and `<C-PageDown>` (in `NAMED`, since `resolve` reads only three-character `c-x` names) and formats them back; `KeyDecoder#decode_csi` reads the second CSI parameter, and `tilde_key` gives the Ctrl codes for 5 and 6 when the modifier holds Ctrl (`(modifier - 1) & 4`); `encode` writes `ESC [ 5 ; 5 ~` and `ESC [ 6 ; 5 ~` so tests type them. Every other modified key stays as it was.

### The buffer keys

`[b` and `]b` bind to `buffer.previous` and `buffer.next`; `[B` and `]B` to the new `buffer.first` and `buffer.last`, two more `BufferHandler` variants over `SwitchBuffer`'s existing `:first` and `:last` targets, so their refusals are `:bfirst`'s and `:blast`'s.

## Risks / Trade-offs

- A user used to `gt` over tab pages gets buffers; `option.gt tabpages` and `<C-PageDown>` are the way back, both in `docs/compatibility.md` and the README.
- `gt` on a modified buffer answers `E37`, as `:bn` does here; that is the existing `'hidden'` difference, not a new one.
- `last_index` is one more member to keep right on every tab switch; the switches that bypass `visit` are the plugin requests only, named above.
