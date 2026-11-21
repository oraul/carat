# Backlog: carat/domain/keymap_node.rb

## menu-hints quality advisory at carat/domain/keymap_node.rb:76

Location: `carat/domain/keymap_node.rb:76`. Why: dead code; `ShowKeyHints` no longer shows `+N`, so `KeymapNode#binding_count` has no production caller left (only `test/domain_keymap.rb:262` and the map entry at `docs/codebase-map.md:149`). Fix outline: remove the method, its assertion, and its map mention.
- Also: test/domain_keymap.rb, docs/codebase-map.md
- Category: editor
- Added: 2026-11-14
