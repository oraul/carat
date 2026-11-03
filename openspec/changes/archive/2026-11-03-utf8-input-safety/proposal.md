# Proposal

## Why

The periodic security review at 66fd52b found two blocking Medium findings, both reached by bytes that are not UTF-8. Opening a file that is not valid UTF-8 (a Latin-1 text, a binary) kills the editor: `Buffer.from_text` splits with `String#split`, which the pinned Spinel answers with `ArgumentError: invalid byte sequence in UTF-8`, and `OpenFile` does not rescue it, so every unsaved buffer is lost. And `Utf8.size_at` accepts overlong forms, UTF-16 surrogates, and sequences above U+10FFFF, so a file name with the bytes F4 90 80 80 decodes to a code point the screen presenter cannot append, and listing its directory in the explorer raises `RangeError` outside any guarded path. Security fixes go to the front of the queue, so this change is taken before the next roadmap item; it is outside the roadmap order.

## What Changes

- A file with bytes that are not UTF-8 opens: its lines keep the bytes as they are, as Neovim does with `fileencoding=utf-8`, the message names the first such line Vim's way (`"f" [ILLEGAL BYTE in line 2] 3L, 12B`), and writing it unedited gives back the same bytes. Splitting text into lines walks bytes instead of calling `String#split`, in the buffer, the registers, `:registers`, a message of several lines, and the plugin API's path segments, so yanking, deleting, and putting such a line, and showing it in a message, raise nothing.
- `OpenFile` answers any failure to read or load a file with E484, never a crash.
- `Utf8.size_at` follows RFC 3629: the second byte of E0 must be A0 to BF, of ED 80 to 9F, of F0 90 to BF, and of F4 80 to 8F, and F5 to FF and C0, C1 start no sequence. Every byte outside a well-formed sequence is one character that is drawn as one U+FFFD cell, which matches how `String#length` counts it, so cursor columns and cells agree. The screen presenter writes U+FFFD for any cell code that is not a Unicode scalar value, a second guard at the terminal.
- `DisplayWidth.cell` and `of_char` decode their character with `Utf8` instead of `String#ord`, so an invalid byte measures one cell, as it is drawn. The keyword test of the word motions no longer uses a regular expression on a character. The case changes (`~` and the visual `~`, `u`, `U`) change only ASCII letters in text that is not valid UTF-8, so they never turn an overlong form into a "/" or a NUL.
- The explorer lists a name that is not UTF-8 with replacement cells and stays enabled.
- Bookkeeping the hard rules require: the window-navigation-and-scroll (#35) line in the delivered-changes list of `docs/codebase-map.md`; `docs/backlog.md` entries for the seven Low periodic findings, the lone-prefix wait without a time limit, and the five scroll advisories; and the four domain files that keep control characters off the terminal (`frame.rb`, `display_width.rb`, `utf8.rb`, `decoded_line.rb`) join the terminal output area of `REVIEW_AREAS` in `tools/run_state.sh`, the one-line part of the REVIEW_AREAS finding that lies in this domain.

Out of scope: file encodings other than UTF-8 (`fileencoding`, `fileencodings`, Latin-1 conversion), a read-only mode, showing invalid bytes as `<xx>` markers as Neovim does (they are one U+FFFD cell each, as today for a lone byte), byte-identical writes of files with mixed line endings or no final newline (unchanged: a final newline is added and the endings follow the first one, as `fixeol` does), `String#each_char` and `Carat::Json` on invalid text (no path sends buffer text to JSON yet), and the other Low findings, which go to the backlog.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `text-buffer`: bytes that are not UTF-8 are kept in the lines, through edits, registers, and the written file text.
- `command-line-mode`: `:e` of a file with an illegal byte names its first line in the message, and a failure to load is E484.
- `screen-rendering`: every byte outside a well-formed RFC 3629 sequence is one U+FFFD cell, and no code point above U+10FFFF or in the surrogate range reaches a cell's output.
- `file-explorer`: a name that is not UTF-8 is listed and the explorer stays enabled.

## Impact

- Code: `carat/domain/utf8.rb`, `carat/domain/display_width.rb`, `carat/domain/buffer.rb`, a new `carat/domain/text_lines.rb` (`TextLines.split`), `carat/domain/register_entry.rb`, `carat/domain/filetype.rb`, `carat/domain/motions.rb`, `carat/domain/operators.rb`, `carat/use_cases/files/open_file.rb`, `carat/use_cases/ex/register_command_handler.rb`, `carat/adapters/frame_presenter.rb`, `carat/adapters/screen_presenter.rb`, `carat/plugin_api.rb`, `carat.rb`; `tools/run_state.sh` and `tools/tools_test.sh`.
- Tests: a new `test/domain_utf8.rb` table of hostile sequences (truncated, overlong, surrogates, above U+10FFFF, lone continuation, NUL) for the decoder and display width; rows in `test/domain_buffer.rb`, `test/editor_registers.rb`, `test/editor_cmdline.rb`, `test/adapters_screen_presenter.rb`, `test/editor_explorer.rb`; a non-UTF-8 file in `test/smoke_editor.rb`.
- Docs: `docs/codebase-map.md`, `docs/backlog.md`, `docs/compatibility.md` (the illegal-byte message).
- No new dependency. Allocations per key stay at the baseline: the decoder adds integer comparisons only, the presenter guard is a range check per written cell, and the byte-walking split allocates the same strings and array as `String#split`.

Assumptions recorded here:

- "Never lose bytes on write unless the user edits" is met by keeping the bytes in the lines (Neovim's behavior with `fileencoding=utf-8`), so a write after an edit also keeps every byte the edit did not touch; no read-only state is added.
- The replacement is one U+FFFD cell per invalid byte, as the decoder already draws a lone byte, rather than Neovim's four-cell `<xx>` marker; the marker is a later change if wanted.
- The message follows Vim's order, the flag after the file name and before the counts.
