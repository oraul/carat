# Backlog: carat/domain/utf8.rb

## spinel-rebump quality advisory at carat/domain/utf8.rb:54

One clear way to do each thing: the boundary rule is applied by hand at seven `byteindex` call sites and only `docs/spinel-notes.md` states it, so the next `byteindex` with an offset can bring the `IndexError` back. Fix outline: a `test/lint.rb` rule refusing a `byteindex` or `byterindex` call with an offset argument not wrapped in `Utf8.boundary` (exempting the inlined copy in `PluginApi::Paths.segments`).

- quality advisory (carat-palette) test/adapters_screen_presenter.rb:337 spec drift: the unmodified scenario 'The theme paints' (openspec/specs/color-themes/spec.md:105) names one_dark and \e[0;38;5;249;48;5;236m, but its test now draws the default carat-dark and asserts 252;234, so after archive the scenario is proved by no test. Fix: add 'option.theme one_dark' to the harness config and keep the one_dark sequence, or modify the scenario to carat-dark in a delta.
- quality advisory (carat-palette) test/adapters_screen_presenter.rb:358 spec drift: the 'Status line' scenario (openspec/specs/color-themes/spec.md:68) names carat-dark, which was one_dark's alias and is now its own palette, while its test row still draws one_dark. Fix: draw the row with carat-dark and its StatusLine colors, or modify the scenario to one_dark in a delta.
- quality advisory (carat-palette) docs/compatibility.md:517 docs accuracy: the corrected sentence lists the thirty syntax, thirteen file-icon, and six markup groups after '56 UI groups:', as if they were among the 56, which are Neovim's 41, the status bar's eight, the two indent guides, FloatTitle, and four popup menu groups. Fix: say '56 UI groups (Neovim's 41, then ...), plus thirty syntax, thirteen file-icon, and six markup groups'.
- quality advisory (carat-palette) carat/domain/themes.rb:460 duplication: with the alias table gone, canonical repeats known?'s NAMES.include? test. Fix: write it as 'known?(name) ? name : DEFAULT' or fold it into find.
- Also: docs/spinel-notes.md, test/lint.rb, test/adapters_screen_presenter.rb, openspec/specs/color-themes/spec.md, docs/compatibility.md, carat/domain/themes.rb
- Category: editor
- Added: 2026-11-14

## Nothing enforces Utf8.boundary on an offset byteindex

- Where: `carat/domain/utf8.rb:54`; `carat/plugin_api.rb:347` repeats the loop inline. Sprint-3 quality review of `spinel-rebump`.
- Why it matters: a new `byteindex(needle, offset)` call that skips `Utf8.boundary` raises under the pinned Spinel on a continuation byte, and only memory keeps the rule.
- Fix outline: a `test/lint.rb` rule refusing a `byteindex` with an offset argument outside `Utf8.boundary`, the `plugin_api.rb` copy allowed. Queue item `spinel-workarounds`.
- Also: carat/plugin_api.rb, test/lint.rb
- Category: editor
- Added: 2026-11-14

### carat/domain/utf8.rb:49: the byteindex guard comment cites the wrong Spinel commit

- Location: carat/domain/utf8.rb:49, carat/plugin_api.rb:345, docs/spinel-notes.md:21 (spinel-rebump and spinel-compile-time quality advisories, merged by the sprint-4 grooming).
- Why: the comments date the `byteindex` refusal of a continuation offset to 6b43fe94 and describe it as current, while 84aa303b1 introduced it and the pinned 6af548c9 does not raise, so a reader bisecting starts wrong or takes the guard for dead code.
- Fix: say Spinel refuses it from 84aa303b1, after the pin, and the guard is kept for that bump, in all three places.
- Also: carat/plugin_api.rb, docs/spinel-notes.md
- Category: editor
- Added: 2026-11-14
