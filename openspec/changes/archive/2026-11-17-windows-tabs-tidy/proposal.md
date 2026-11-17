# Proposal

## Why

Five backlog findings in the windows and scrolling code, part one of the queue's `windows-tabs-tidy` item as the planner split it. `FloatSpec.offset_refusal` (`carat/domain/float_spec.rb:59-60`) bounds an offset with `Integer#abs`, which overflows at the integer minimum and leaves that value negative, so a plugin's float could open or move at an offset the spec of `plugin-windows` refuses (security Low, confidence 4). `ScrollHandler` writes the base class's `@breaks_insert` after `super`, a trait the base class's constructor had already set. The half-page scroll targets are named `:half_down` and `:half_up` while their actions and every other scroll target share one name (`scroll.page_down` and `:page_down`). `CloseOtherWindows` clears `tab.previous` after `BufferList#close_window` already cleared it for each window it closed. Nine comments break their file's wrap width.

## What Changes

- `FloatSpec.offset_refusal` compares each offset against both bounds, never through `abs`, so the integer minimum is refused with "No offset N: -10000 to 10000" like any other offset out of range, the row checked first as before.
- `ActionHandler#breaks_insert` becomes the predicate `breaks_insert?`, false in the base class and overridden to true by `ScrollHandler`, so no subclass writes a base class trait after `super`; the dispatcher reads the predicate. Behavior is unchanged: a scroll key in insert mode still breaks the insert session.
- The half-page targets are `:half_page_down` and `:half_page_up`, the suffixes of their actions, in `ScrollHandler`, `ScrollWindow`, and `ScrollRequest`'s comment.
- `CloseOtherWindows` no longer clears `tab.previous` itself: `BufferList#close_window` clears it for each window that closes, and the window that stays is never the previous one.
- Nine comments are re-wrapped to their file's width (below).
- Tests: the integer minimum refused as a row and as a column; `:only` and `<C-w>o` leaving `<C-w>p` with no previous window; the scroll keys in insert mode still breaking the insert session.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the `plugin-windows` spec already refuses any offset outside -10000 to 10000; the code now does so at the integer minimum too, and the other items alter no behavior (`skip_specs: true`).

## Impact

- `carat/domain/float_spec.rb`, `carat/use_cases/actions/action_handler.rb`, `carat/use_cases/actions/scroll_handler.rb`, `carat/use_cases/dispatcher.rb`, `carat/use_cases/windows/scroll_window.rb`, `carat/use_cases/windows/scroll_request.rb`, `carat/use_cases/windows/close_other_windows.rb`, and the comments of the nine files below.
- Tests: `test/domain_float_layer.rb` and the window and scroll editor tests, with their snapshots.
- README.md: unchanged, no spec or user-visible behavior changes.
- CLAUDE.md: unchanged, no process change.
- docs/architecture.md: unchanged, it names neither the handler trait nor the scroll targets.
- docs/codebase-map.md: changed, the `ActionHandler` and `ScrollHandler` entries name `breaks_insert?`; no file is added, moved, or removed.
- docs/compatibility.md and docs/actions.md: unchanged, the action names stay.

Outside the roadmap of `docs/architecture.md` section 12: a backlog tidy-up (T6 with a security Low) of sprint 11.

Backlog headings this change covers, from its queue entry: "## Float offset check overflows at the integer minimum (float-placement, security Low (4))", "## ScrollHandler sets a base class trait after super", "## Half-page scroll targets have two names", "## Nine comments break their file's wrap width", "## CloseOtherWindows clears tab.previous a second time", and the stale "## TabRequest#counted? and CommandGrammar#operator_pending? have no caller", fixed by ad28ebd (#132), listed only so groom removes it.

The nine comments: a delivery does not read the backlog, so the nine are those its queue item and the archived briefs name (`scroll_window.rb:18`, the class comment of `buffer_list.rb`, `handle_key.rb` from its definition-peek sentence, the class comment of `options.rb`) and the five widest comment lines left under `carat/` (`ports/terminal_port.rb:4`, `use_cases/files/open_file.rb:20`, `use_cases/completion/show_completion_docs.rb:25`, `plugin_api.rb:519`, `adapters/frame_presenter.rb:68`).

## Out of scope

- The split remainder `buffer-commands-tidy`: the doubled `digits?`, `:b 0000000001` answering E86, and BufferRequest's `:current` target.
- The other comment lines over their wrap width (about twenty under `carat/` and some in `tools/`, `tools/agent_guard.sh:31` among them), left for a later tidy so this one stays reviewable and touches no pipeline script.

Minor assumptions: the trait is moved into an overridden predicate rather than a third required keyword of `ActionHandler`, which would touch all 28 handlers; `breaks_insert` renamed `breaks_insert?` since a method returning bool is a predicate; the comments chosen as above.
