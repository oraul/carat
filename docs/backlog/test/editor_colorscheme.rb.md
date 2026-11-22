# Backlog: test/editor_colorscheme.rb

### hard-codes carat-dark's 256-color Normal sequence as a literal although at test/editor_colorscheme.rb:95 (sprint-26 sweep quality, note 38)

- Location: test/editor_colorscheme.rb:95
- Why: hard-codes carat-dark's 256-color Normal sequence as a literal although the file builds sequences through SgrTable, so a palette tweak fails the test without a behavior change
- Fix: compute it with SgrTable.sequence(Themes.find("carat-dark", "theme"), Highlight::NORMAL, C256) as test/editor_screen.rb:25 does
- Also: test/editor_screen.rb
- Category: code-quality
- Added: 2026-11-22
