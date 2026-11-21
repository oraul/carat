# Backlog: test/adapters_hover.rb

## The K tests are one scripted sequence

- Where: `test/adapters_hover.rb` line 176 at 78078ad. Quality advisory in `quick-docs`.
- Why it matters: CLAUDE.md asks a Neovim command for a table-driven test; the hover contents shapes are covered only along one script, so a new shape or a regression in one is hard to add or see.
- Fix outline: drive the contents shapes (string, markup, language pair, list, null, error) and their expected rows from a table converted with typed helpers.
- Also: CLAUDE.md
- Category: ide
- Added: 2026-11-07

## Hover paths in the spec or the code have no test

- Where: `test/adapters_hover.rb` line 232 at 78078ad, the cancellation block; `forget_server` (the hover ask) and the `hoverProvider` check in `carat/adapters/json_rpc_language_gateway.rb`, and the float's close in `carat/use_cases/docs/show_hover.rb`. Quality advisory in `quick-docs`.
- Why it matters: `forget_server` (the hover ask) on a crash or stop with a hover in flight, `hoverProvider` given as an object, and the float closing on `:q`, a window switch, or a buffer change can regress without a test failing.
- Fix outline: add those cases beside the cancellation block.
- Also: carat/adapters/json_rpc_language_gateway.rb, carat/use_cases/docs/show_hover.rb
- Category: ide
- Added: 2026-11-07

### Quality advisory: drawn helper and resizable Rig copied across float tests (test/adapters_hover.rb:216)

- Location: test/adapters_hover.rb:216, copies in test/adapters_signature.rb:197 and test/adapters_definitions.rb:285
- Why: duplication and test conventions; the drawn helper and the resizable Rig (@rows, @cols, resize) are copied verbatim, and drawn returns a mixed Array[untyped] instead of an object with typed readers.
- Fix: move one drawn helper returning a small record with typed readers into the shared test support and reuse it.
- Also: test/adapters_signature.rb, test/adapters_definitions.rb
- Category: ide
- Added: 2026-11-14

### Quality advisory: unguarded hover float lookup (test/adapters_hover.rb:383)

- Location: test/adapters_hover.rb:383
- Why: floats.at(floats.index_of(...)) has no guard for a missing float, unlike test/adapters_definitions.rb:592, so a missing hover float indexes -1 instead of failing clearly.
- Fix: guard with at < 0 ? [] : drawn(...) as the definitions test does.
- Also: test/adapters_definitions.rb
- Category: ide
- Added: 2026-11-14

### Quality advisory: drawn helper duplicated in three tests (test/adapters_hover.rb:215)

- Location: test/adapters_hover.rb:215, copies in test/adapters_definitions.rb:284 and test/adapters_signature.rb:196
- Why: duplication; the same drawn helper is copied into three test files.
- Fix: keep one shared helper in the test support or the rig the three share.
- Also: test/adapters_definitions.rb, test/adapters_signature.rb
- Category: ide
- Added: 2026-11-14

### No hover test shows a flowed paragraph, and the README names the flow only for the reading view
- Location: test/adapters_hover.rb, README.md:69
- Why: MarkdownText.parse is shared, so the paragraph and quote flow and the hanging prefix also reach the hover and completion floats, but no test proves it there and the README states it only for the reading view.
- Fix: add a two-line paragraph case to test/adapters_hover.rb and say in the README's floats sentence that paragraphs and quotes flow there too.
- Also: README.md
- Category: ide
- Added: 2026-11-17
