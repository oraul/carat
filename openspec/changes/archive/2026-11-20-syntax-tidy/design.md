# Design

## Context

Three headings of the queue line are bugs or copies that a test can pin down. Two more need a design choice, and this first part of the split leaves them out (proposal, Out of scope).

## Decisions

- Nesting depth: the tokenizer's per-frame `@depths` and `@braces` are plain integers, so nothing stops them from counting past the packed field. The cap moves from the increments to `Tokenizer#frame_bits`, the one place a frame is packed. Within a line every pair then matches its opener. Across lines the state still holds at most 7 pairs and 3 braces, which the existing requirement allows as graceful degradation. The scenario "A depth past seven is held to seven across lines" pins down that degradation. The state layout is unchanged, so states stay within 58 bits.
- `Filetype.program_name` is public, so the byte cut can be tested directly. `PROGRAMS` holds only `ruby`, so no detected filetype shows the old mismatch. The name is a domain helper, not a plugin API function.
- One basename: `PluginApi::Paths.basename` is already the byte cut that `Buffer.icon_of` and `PathPolicy.last_name` use. `Filetype` requires `carat/plugin_api.rb`, as `buffer.rb` and `path_policy.rb` already do. `Buffer#name_start` returns an index, and the tab bar reads it twice per buffer tab per frame. Deriving it from `Paths.basename` would allocate a string on every call, and a byte-index function in `Paths` would change the plugin API and bump its version. So it keeps its `byterindex`, which already cuts by bytes like `Paths.basename`, and takes the one rule where the two disagreed: the root `/` starts its name at 0, since `Paths.basename` keeps the root whole.

## Risks

- The tokenizer's depth counters are unbounded within a line, but a line's length bounds them. The packed state keeps its 58-bit layout.
