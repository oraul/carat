# Backlog: carat/use_cases/files/open_file.rb

## :e! on the current buffer moves the cursor to the top

- Where: `carat/use_cases/files/open_file.rb` line 62, at b76b722. Periodic quality. Queue item `file-access-tidy`.
- Why it matters: `Window#show` puts the cursor at 1,1 and the scroll at the top, where Vim keeps the cursor line when it edits the same file again; no test checks it and `docs/compatibility.md` lists no difference.
- Fix outline: keep the cursor, clamped by the reload, when the listed buffer is the current one, with an `editor_cmdline` row, or document the difference.
- Also: docs/compatibility.md
- Category: editor
- Added: 2026-11-09

## Two comments left unwrapped by the definitions change

- Where: `carat/use_cases/files/open_file.rb` line 20 (127 columns) and `carat/use_cases/handle_key.rb` line 63 at fafe59c. Quality advisories in `definitions`.
- Why it matters: the rest of each comment wraps near 72 columns, so the lines read as broken.
- Fix outline: rewrap both paragraphs at the file's width.
- Also: carat/use_cases/handle_key.rb
- Category: editor
- Added: 2026-11-10

## The read-only marker shows only on the first gd

- Where: `carat/use_cases/files/open_file.rb:40` and `:62` against `carat/use_cases/definitions/visit_target.rb:98` and `:109`; `docs/compatibility.md:264` and `:317` omit E382 and E45 for `:w`, `:wq`, `:x`, `:wa`.
- Why it matters: `:e` and `:e!` of a read-only buffer drop Vim's `[readonly]`; the write refusals differ from Vim unsaid.
- Fix outline: append the marker in both messages with rows in `adapters_definitions`; add E382 and E45 to the rows and one sentence to the differences. Queue item `definitions-tidy`.
- Also: carat/use_cases/definitions/visit_target.rb, docs/compatibility.md
- Category: editor
- Added: 2026-11-10

## A path written two ways opens a second buffer of one file

- Where: `carat/use_cases/files/open_file.rb:39` (`BufferList#for_path` by the literal path, `BufferList#add` dedupes by identity), against `VisitTarget#listed_for`, `WindowRequests#same_path?`, and `DeletePath`, which compare normalized absolute paths. Periodic quality blocking at bd86828.
- Why it matters: `:e ./a.txt` or `:e` of the absolute path beside a listed `a.txt` makes a second writable buffer of one file, where Neovim reuses one; `:wa` then writes one over the other.
- Fix outline: one lookup rule for every caller, with editor rows for `:e ./a.txt` and the absolute path. Queue item `periodic-blockers-b`.
- Category: editor
- Added: 2026-11-11

### Reloading the current buffer resets the cursor

- Location: carat/use_cases/files/open_file.rb:62, the class comment at :20. Sprint-6 sweep, quality. Queue item `file-access-tidy`.
- Why: `:e` and `:e!` on the current buffer call `window.show`, putting the cursor at the top and forgetting the last selection, though the comment says the cursors are kept and Vim keeps the cursor line.
- Fix outline: skip show for the current buffer and clamp the cursor, or state the reset in the spec; rewrap the comment.
- Category: editor
- Added: 2026-11-15

### The :e and :w messages still print a newline in a file name as a line break
- Location: carat/use_cases/files/open_file.rb:42, :63, :64; carat/use_cases/files/save_file.rb:56
- Why: these messages still put a raw path in quotes, so a file name holding a newline forges message lines the way `:ls` and E162 did before windows-buffers-tidy; no entry tracked them once the proposal left them out of scope.
- Fix: pass the path through Domain::ControlText.caret in those messages, with an editor test of a newline name for each.
- Also: carat/use_cases/files/save_file.rb
- Category: editor
- Added: 2026-11-17
