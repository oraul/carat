# Backlog: carat/use_cases/files/resolve_inside.rb

## The outside-the-root refusal is built four times

- Where: `carat/use_cases/files/resolve_inside.rb` line 41, `delete_path.rb` line 39, `make_path.rb` line 37, and `rename_path.rb` line 42, at 3895e21. Periodic quality. Queue item `file-access-tidy`. Raised again at ce6abdb (periodic quality): lint's repeated-message rule sees only E-numbered messages, so the four drift unseen.
- Why it matters: the wording of one refusal lives in four places.
- Fix outline: one domain function returning the message, called by the four.
- Category: editor
- Added: 2026-11-09

### The outside-root message is built in four places

- Location: carat/use_cases/files/resolve_inside.rb:41, make_path.rb:37, rename_path.rb:42, delete_path.rb:39 (sprint-4 sweep, quality).
- Why: four copies of 'Outside the tree root: ' can drift.
- Fix: one PathPolicy method taking cwd and path.
- Category: editor
- Added: 2026-11-14
