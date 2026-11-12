# Proposal

## Why

The user reported that `gt` and `gT` move tab pages while the top row shows buffer tabs, so with one tab page the buffer tabs the row shows are out of reach of the keys a Vim user reaches for (`config/default.caratrc:180`, `:181`, `docs/compatibility.md:447`), and that `:tabn 3`, `:tabc 2`, and `:tabo x` drop their argument without a word (`carat/use_cases/ex/tab_command_handler.rb:35` to `:38`, line 38 passing count 0). This is queue item `tab-keys`, sprint 2 item 1 (part 3 of the user's bug report), covering the backlog heading "The tab ex commands drop their argument". It is outside the roadmap of `docs/architecture.md` section 12: it corrects the delivered `buffers-windows-tabs` item (7).

## What Changes

- `gt` and `gT` follow the buffer tabs: `gt` shows the next buffer tab, wrapping, `gT` the previous one, `{count}gT` count back, and `{count}gt` the count-th buffer tab of the row, or nothing when the row has fewer, as `{count}gt` does for tab pages in Vim. They are the new actions `tabline.next` and `tabline.previous`.
- `option.gt` takes `buffers`, the shipped default, or `tabpages`, which gives `gt`, `gT`, and their counts Vim's tab-page meaning back; any other word is reported as `file:line: unknown gt mode WORD`.
- `<C-PageDown>` and `<C-PageUp>` (`tab.next`, `tab.previous`) move tab pages as `gt` and `gT` did, with their counts, and `g<Tab>` (`tab.last_accessed`) goes to the last accessed tab page, as in Vim; the key decoder reads the Ctrl-modified page keys (`ESC [ 5 ; 5 ~`, `ESC [ 6 ; 5 ~`) and key notation names them `<C-PageUp>` and `<C-PageDown>`.
- `[b` and `]b` go to the previous and next buffer (`buffer.previous`, `buffer.next`, with counts), `[B` and `]B` to the first and the last (`buffer.first`, `buffer.last`), as vim-unimpaired binds them.
- The tab ex commands read their argument as Vim does: `:tabn N` goes to tab page N, `:tabp N` and `:tabN N` go N back, `:tabc N` closes tab page N, `:tabo N` keeps only tab page N; `0` is `E16: Invalid range` for `:tabn`, `:tabc`, and `:tabo`, a word or a number past the last tab page `E475: Invalid argument: ARG`, and an argument to `:tabfir` or `:tabl` `E488: Trailing characters: ARG`. With one tab page `:tabc` and `:tabo` answer `E784` and "Already only one tab page" before reading the argument, as Vim does.

Assumptions:

- `g<Tab>` keeps Vim's meaning, the last accessed tab page, which is one of the "move tab pages" keys the item lists; a tab page closed or never left gives nothing to go to and the key does nothing. A plugin's focus request that changes tab page is not a visit.
- A buffer-tab move refuses a modified current buffer with `E37`, as `:bn` and the `<leader>bn` key already do here (`docs/compatibility.md`, Differences).
- The tab ex argument is a plain number; Vim's `+N`, `-N`, `$`, and `#` forms are refused with `E475` and named in the Differences line, since the item asks only that an argument act or refuse.
- `Options` keeps Vim's `tabpages` as its built-in value, as `jumptab` keeps `keep`, and the shipped configuration sets `buffers`.

Out of scope: `:tabm[ove]`, `:tabs`, `:tabdo`, a count before a tab ex command (`:2tabn`), the plugin focus requests as tab visits, and any change to the tab row's drawing.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `tab-pages`: the keys that move tab pages (`<C-PageDown>`, `<C-PageUp>`, `g<Tab>`), the tab ex arguments, and `gt` and `gT` leaving the requirement unless `option.gt tabpages` is set.
- `buffer-tabs`: `gt`, `gT`, and `{count}gt` over the buffer tabs, `[b`, `]b`, `[B`, `]B`, and `option.gt`.
- `key-input`: Ctrl-PageUp and Ctrl-PageDown decode to keys of their own, named `<C-PageUp>` and `<C-PageDown>`.

## Impact

- `carat/domain/tab_list.rb` (`last_index`, `visit`, `last_accessed_tab`), `carat/domain/buffer_list.rb` (`file_at`), `carat/domain/options.rb` (`gt`, `gt_follows_buffers?`), `carat/domain/key.rb`, `carat/domain/key_notation.rb`, `carat/adapters/key_decoder.rb`, `carat/use_cases/actions/tab_handler.rb`, `carat/use_cases/actions/buffer_handler.rb`, `carat/use_cases/buffers/switch_buffer.rb`, `carat/use_cases/buffers/buffer_request.rb`, `carat/use_cases/windows/switch_tab.rb`, `carat/use_cases/windows/tab_request.rb`, `carat/use_cases/windows/close_tab.rb`, `carat/use_cases/windows/close_other_tabs.rb`, `carat/use_cases/ex/tab_command_handler.rb`, `carat/adapters/editor_assembly.rb`, `config/default.caratrc` and the generated `carat/domain/default_config.rb`.
- Tests: `test/editor_tabs.rb` (the keys and the ex arguments with one and two tab pages), `test/use_cases_ex.rb`, `test/domain_options_config.rb`, `test/domain_keymap.rb`, `test/domain_keys.rb`, `test/adapters_key_decoder.rb`, and the tests that typed `gt` for a tab page (`test/editor_cmdline.rb`, `test/editor_floats.rb`, `test/editor_plugins.rb`).
- `docs/compatibility.md` (the tab-page key rows, the buffer keys, the tab ex rows, the Differences lines), `docs/actions.md`, `docs/codebase-map.md` (area 11).
- README.md: changed, the feature sentence names the buffer-tab and tab-page keys.
- docs/architecture.md: changed, the `TabList` entry names the last accessed tab page.
- CLAUDE.md: unchanged, no agent, workflow, command, or target changes.
