# Backlog: carat/domain/recent_files_text.rb

### RecentFilesText restates the finder's control character rule at carat/domain/recent_files_text.rb:32 (sprint-30 review quality)

- Location: carat/domain/recent_files_text.rb:32 (usable?), carat/plugins/finder/safe_text.rb:17 (SafeText.of)
- Why: both test C0, DEL, and C1 bytes of a path by hand with different rules: a persisted path may hold the bidirectional and zero-width format characters SafeText blanks, so one path is kept by one rule and masked by the other, and a fix to one misses the other.
- Fix: one byte rule in the plugin API (the innermost ring both may require) for control and format characters, used by both; accepted when one rule decides both, with a recent-files row and a finder row for a path holding U+202E.
- Also: carat/plugins/finder/safe_text.rb
- Category: editor
- Added: 2026-11-23
