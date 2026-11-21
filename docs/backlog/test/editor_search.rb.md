# Backlog: test/editor_search.rb

## A test helper's comment sits above the wrong method

- Where: `test/editor_search.rb`, the comment of the `editor` helper (lines 8 and 9 at d5036f4) now sits above the `group` helper `cursor-shapes` added, with `def self.editor` at line 16. Advisory of the periodic quality review at d5036f4.
- Why it matters: the two comments read as one comment for `group`, and `editor` has none.
- Fix outline: move the `editor` comment above `def self.editor`. Queued in the backlog item of `docs/queue.md` with the comment-wrap entry.
- Category: code-quality
- Added: 2026-11-05
