# Design

## Context

The refusal lives in two places: `FileCommandHandler#edit` for `:e` (`carat/use_cases/ex/file_command_handler.rb`) and `SwitchBuffer#switch` (`carat/use_cases/buffers/switch_buffer.rb`), the one use case behind `:b`, `:bn`, `:bp`, `:bN`, `:bfirst`, `:blast`, Ctrl-^, and the buffer tabs. Closing a window and `:qa` already treat a modified buffer left in the list as hidden. `Options` (`carat/domain/options.rb`) holds the flags with their kind in `KINDS`, `assign`, and `value_of`, and `SetCommandHandler` takes a flag by its entry in `NAMES` and `SHORT_NAMES`.

## Decisions

- `hidden` is one more flag member of `Options`, in the four places a flag is named (the `Struct` members with the pinned type, `KINDS`, `assign`, `value_of`), plus `NAMES` and `SHORT_NAMES` of the `:set` handler, so every `:set` form, `name&`, and the listings follow with no new code.
- Both refusal points read `state.options.hidden` when they would refuse; no state is copied, so `:set` takes effect on the next command.
- `:e` keeps E37 when it would reload the current buffer in place (`BufferList#for_path` returns the current buffer), since the reload drops the changes, which Vim refuses even with `hidden`. Alternative: let the reload through; refused, it would discard unsaved work without the bang.
- The default is on in both `Options.new` and the shipped configuration, like the other flags, so `Options.shipped` and `Options.new` agree and `:set hid&` restores it.
- Ctrl-^, `gt`, `gT`, and the bracket keys share `SwitchBuffer`, so they follow the option; a separate path for them would keep an `E37` that Neovim does not give with `hidden` on.

## Risks / Trade-offs

- Existing tests that expected E37 now run `:set nohidden` first; each keeps its coverage of the off path.
- Ctrl-O and `gd` into another file still refuse a modified buffer while `:e` does not; recorded as a finding, with a fix outline of reading the same option in `walk_jumps.rb` and `visit_target.rb`.
