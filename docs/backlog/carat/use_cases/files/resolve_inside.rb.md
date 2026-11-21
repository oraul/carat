# Backlog: carat/use_cases/files/resolve_inside.rb

## File operations check containment and act in separate calls

- Where: `carat/use_cases/files/resolve_inside.rb` (line 28, the real-path containment check) and the operations it guards, `call` of `carat/use_cases/files/make_path.rb` (its `mkdir` and `write`), `carat/use_cases/files/rename_path.rb` (its `rename`), and `carat/use_cases/files/delete_path.rb` (its `delete`). Low (2) finding of the periodic security review at 16cdcf7, a recorded non-goal of `plugin-path-containment`.
- Why it matters: a directory of the tree replaced by a link pointing outward between the check and the create, rename, or delete redirects the operation outside the tree root, so the containment holds only against a tree that does not change while the explorer acts on it.
- Fix outline: when the file port gains directory-relative operations, open the resolved directory once and act through its descriptor (`openat`, `renameat`, `unlinkat` with no-follow), with a test row in `test/drivers_disk_files.rb`; until then record in `docs/spinel-notes.md` whether the pinned Spinel exposes them.
- Also: carat/use_cases/files/make_path.rb, carat/use_cases/files/rename_path.rb, carat/use_cases/files/delete_path.rb, test/drivers_disk_files.rb, docs/spinel-notes.md
- Category: security
- Added: 2026-11-03

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
