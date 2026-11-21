# Backlog: carat/use_cases/discovery/show_key_hints.rb

## The key hints keep two column guards that disagree (float-placement, quality advisory)

- Where: `carat/use_cases/discovery/show_key_hints.rb:125`.
- Why it matters: duplication: the state.screen_cols < 6 guard and the new limit < 1 check express one rule, and the old one now disagrees with text_room (it refuses a 5-column none screen whose limit is 1, and only limit < 1 protects rounded at 6).
- Fix outline: drop state.screen_cols < 6 from line 125 and keep return if limit < 1 as the single column guard.
- Category: editor
- Added: 2026-11-14

## menu-hints quality advisory at carat/use_cases/discovery/show_key_hints.rb:112

Location: `carat/use_cases/discovery/show_key_hints.rb:112`. Why: `segment` passes the empty literal `heads = []` to `collect_heads`, which appends Strings to it, the open pitfall of `docs/spinel-notes.md` where an empty literal is typed `Array[Integer]` and a callee's appends may be dropped. Fix outline: have `collect_heads` return the array it fills and the caller assign the result, as `Config#merge_runs` does.
- Also: docs/spinel-notes.md
- Category: editor
- Added: 2026-11-14

## menu-hints quality advisory at carat/use_cases/discovery/show_key_hints.rb:131

Location: `carat/use_cases/discovery/show_key_hints.rb:131`. Why: a prefix of plugin actions (`plugin.NAME.ACTION`) always reads `plugin`, even for one plugin's actions, which names the mechanism and not what the keys do. Fix outline: for a plugin action take the segment after `plugin.`, or state the choice in the key-hints spec.
- Category: editor
- Added: 2026-11-14

### The hints read only the editor keymap (sprint-20 sweep quality, show_key_hints.rb:63)

- Location: `carat/use_cases/discovery/show_key_hints.rb:63`
- Why: the hints read only the editor keymap (@keymap.node_at), while HandleKey#lookup (handle_key.rb:213) answers first from a scratch buffer's own keymap, so a prefix the buffer's keymap binds shows no hints or the editor keymap's children for the same keys
- Fix: look the node up in state.buffer.keymap first when it holds the prefix, as lookup does, with an editor_key_hints row for a scratch-buffer prefix
- Category: editor
- Added: 2026-11-19
