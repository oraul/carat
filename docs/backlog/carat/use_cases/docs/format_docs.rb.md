# Backlog: carat/use_cases/docs/format_docs.rb

## A fence's short name is never highlighted

- Where: `carat/use_cases/docs/format_docs.rb` line 49, at the `quick-docs-styles` change, where the fence's word goes straight to `PluginSyntax#provider` as a filetype. Quality advisory in `quick-docs-styles`.
- Why it matters: common fences such as `rb` (the parse test itself uses one), `sh`, or `bash` are never highlighted though a plugin tokenizes their filetype.
- Fix outline: resolve a name that is not a filetype through `Filetype`'s extension table before asking for a provider, with a row in `test/adapters_hover.rb`.
- Also: test/adapters_hover.rb
- Category: editor
- Added: 2026-11-09

## Fenced code paths in the documentation formatter have no test

- Where: `carat/use_cases/docs/format_docs.rb` line 40, at the `quick-docs-styles` change: the path where the tokenizer raises (block left plain, plugin disabled), and the tokenizer state carried across a block's rows and reset per block. Quality advisory in `quick-docs-styles`.
- Why it matters: a regression in either path would show wrong colors or keep a failing plugin enabled, unnoticed.
- Fix outline: add `test/adapters_hover.rb` rows with a raising tokenizer double, and with a fenced Ruby string spanning two lines followed by a second block.
- Also: test/adapters_hover.rb
- Category: editor
- Added: 2026-11-09

### Documentation floats draw tables with no test or spec saying so

- Location: carat/use_cases/docs/format_docs.rb:38, test/adapters_hover.rb, README.md, openspec/specs/markdown-reading/spec.md
- Why: parse now draws tables at the width for the K and completion documentation floats too, but the spec and README name only the reading view and no hover test shows a table, so the float behavior is unproven.
- Fix: say in the README sentence on the floats and in the spec that documentation floats draw tables the same way, and add one float row with a table to test/adapters_hover.rb.
- Also: test/adapters_hover.rb, README.md, openspec/specs/markdown-reading/spec.md
- Category: editor
- Added: 2026-11-17
