# Backlog: carat/plugins/explorer/tree.rb

## The explorer's sort downcases both names per comparison

- Where: `sorted` in `carat/plugins/explorer/tree.rb` line 252 at 847851d. Periodic quality. Queue item: backlog items, the explorer.
- Why it matters: about 2n log n strings per listing on every tree build.
- Fix outline: compute each lowercase key once and sort by it.
- Category: plugins
- Added: 2026-11-09

## The explorer tree takes positional arguments under a silent lint exemption

- Where: `Tree#initialize` in `carat/plugins/explorer/tree.rb` line 23; the plugins exemption in `test/lint.rb` line 1185. Periodic quality at e49f63d.
- Why it matters: CLAUDE.md requires keyword constructors and states no plugin exemption.
- Fix outline: keyword arguments at the constructor and its callers, then drop or document the exemption. Queue item: Backlog batches.
- Also: test/lint.rb, CLAUDE.md
- Category: plugins
- Added: 2026-11-10

### Explorer Tree has a positional constructor

- Location: carat/plugins/explorer/tree.rb:23, plugin.rb:484 (sweep, quality).
- Why: the one plugin behavior class without keywords, which lint misses since it exempts plugins (test/lint.rb:1188).
- Fix outline: initialize(root:, show_hidden:, ignore:) with its signature.
- Also: test/lint.rb
- Category: plugins
- Added: 2026-11-17

### The explorer's Tree takes positional arguments (sprint-16 sweep quality)

- Location: carat/plugins/explorer/tree.rb:23, exemption at test/lint.rb:1195.
- Why: the only positional constructor under carat/, against CLAUDE.md's keyword rule; @nodes is Array[untyped] though it holds Node.
- Fix outline: Tree.new(root:, show_hidden:, ignore:) with an Array[Node] pin, and drop the exemption or state it in CLAUDE.md.
- Also: test/lint.rb, CLAUDE.md
- Category: plugins
- Added: 2026-11-18

### Tree takes positional constructor arguments (sprint-20 sweep quality, tree.rb:23)

- Location: `carat/plugins/explorer/tree.rb:23`
- Why: Tree takes positional constructor arguments (root, show_hidden, ignore) while CLAUDE.md Coding conventions requires required keywords for behavior classes; test/lint.rb:1195 exempts carat/plugins/ from the constructor rule, which CLAUDE.md does not say
- Fix: initialize(root:, show_hidden:, ignore:) with a keyword signature at its one call site (explorer/plugin.rb:488), or document the plugin exemption in CLAUDE.md
- Also: CLAUDE.md, test/lint.rb
- Category: plugins
- Added: 2026-11-19

### carat/plugins/explorer/tree.rb:23: Tree takes positional constructor arguments, the only plugin class (sprint-22 sweep quality)

- Location: `carat/plugins/explorer/tree.rb:23`
- Why: Tree takes positional constructor arguments, the only plugin class that does (Node and Tokenizer take keywords), and test/lint.rb:1354 exempts the plugins layer from the keyword-constructor rule, which CLAUDE.md does not mention
- Fix: Tree.new(root:, show_hidden:, ignore:) in plugin.rb:488 and test/plugins_explorer.rb:65, then either drop the plugin exemption or document it
- Also: test/lint.rb, CLAUDE.md, test/plugins_explorer.rb
- Category: plugins
- Added: 2026-11-20

### Explorer Tree takes positional arguments (sprint-24 sweep quality)

- Location: `carat/plugins/explorer/tree.rb:23`
- Why: behavior classes take required keyword arguments.
- Fix: `initialize(root:, show_hidden:, ignore:)` and update the callers.
- Category: plugins
- Added: 2026-11-21
