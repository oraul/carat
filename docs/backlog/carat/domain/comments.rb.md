# Backlog: carat/domain/comments.rb

### Comments.toggle copies a row's indent up to four times

- Location: `carat/domain/comments.rb`, `toggle`, `blank?`, and `commented?`.
- Why: each helper calls `Buffer#indent_of`, which copies the leading blanks, so a toggle allocates up to four strings per row; one toggle runs per command and is no hot path, so it was left in the comment-operator change (quality self-review).
- Fix: compute the indent width once per row in `toggle` and pass it to `blank?`, `commented?`, and `uncommented`.
- Category: editor
- Added: 2026-11-21
