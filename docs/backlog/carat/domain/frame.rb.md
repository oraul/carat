# Backlog: carat/domain/frame.rb

### Frame, status bar, and screen presenter repeats

- Location: carat/domain/frame.rb:36, carat/adapters/status_bar.rb:1 and :47, carat/adapters/screen_presenter.rb:193 (sprint-4 sweep, quality).
- Why: Frame::REPLACEMENT repeats Utf8::REPLACEMENT; an unused plugin_api require; NO_NAME defined in four files (also tab_bar.rb:22, winbar.rb:18, list_buffers.rb:20); two loops inline same_cell?.
- Fix: one constant each, drop the require, call same_cell? unless a bench shows a cost.
- Also: carat/adapters/status_bar.rb, carat/adapters/screen_presenter.rb
- Category: editor
- Added: 2026-11-14
