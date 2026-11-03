# Design

## Context

Probed on the pinned Spinel (a scratch program outside the repository, compiled with `spinel`): on a string holding bytes that are not UTF-8, `split`, `scan`, `=~`, and `match?` raise `ArgumentError: invalid byte sequence in UTF-8`; `index`, `byteindex`, `byteslice`, `getbyte`, `gsub` with a string, `+`, `join`, `start_with?`, `rindex`, `sort`, `<`, and `tr` work; `length` counts every byte outside a well-formed RFC 3629 sequence as one character (C0 AF is two, ED A0 80 three, F4 90 80 80 four); `ord` of such a byte answers the byte; `upcase` and `downcase` reinterpret invalid bytes (C0 AF upcased gives "/", E0 80 80 gives a NUL, a lone E9 gives two bytes); and `String#<<` of an Integer above 0x10FFFF raises `RangeError`, while a surrogate is appended as its three bytes.

So bytes that are not UTF-8 can live in line strings safely as long as no code on their way splits or matches them with a regular expression, and the decoder must agree with `String#length`, which is strict.

## Goals / Non-Goals

Goals: open, show, edit, yank, put, and write a file with any bytes without raising; keep every byte the user did not edit; one U+FFFD cell per invalid byte everywhere text reaches the screen; nothing above U+10FFFF or in the surrogate range reaches the terminal; no allocation per key added.

Non-goals: file encodings and conversion, a read-only state, `<xx>` markers for invalid bytes, byte-identical writes of mixed line endings or a missing final newline (unchanged behavior, as Vim's `fixeol`).

## Decisions

### Keep the bytes in the lines

The buffer stores the file's bytes as they are, as Neovim does with `fileencoding=utf-8`. Writing joins the lines, so an unedited buffer writes the same bytes (for the line-ending cases that already round-trip), and an edited one keeps every byte outside the edit. Alternatives: scrubbing to U+FFFD loses bytes on any write; keeping the original text beside the lines and refusing a write after an edit adds a member and a state for no gain over keeping the bytes. Opening read-only was offered by the brief as an alternative, but Neovim opens such files writable.

### One byte-walking splitter: `Domain::TextLines.split`

`TextLines.split(text, crlf)` answers what `text.split("\n", -1)` answers ([] for ""), by `byteindex("\n", from)` and `byteslice`, and with `crlf` true drops the "\r" before each "\n", which replaces the `gsub("\r\n", "\n")` copy of the whole text in `from_text`. It allocates the same strings and array as `split`. It replaces `split("\n", -1)` in `Buffer.from_text`, `Buffer#joined` (insert and put of text with newlines), `RegisterEntry#lines`, `RegisterCommandHandler.line`, and `FramePresenter#paint_list` (a message of several lines, which can hold a file name). `from_text` finds the first terminator with `byteindex` and `getbyte` instead of `index` and a one-character slice.

`PluginApi::Paths.segments` splits on "/" with the same byte walk, written inline because `plugin_api.rb` requires nothing from the core; `MemoryFiles` keys every path through it, and the explorer normalizes paths with it.

`Filetype.from_shebang` returns "" for a first line that is not valid UTF-8 before its `split(" ")`: a shebang naming a program is ASCII, and the check runs once per buffer.

`Motions.keyword?` tests the code point with `code_class` instead of a regular expression.

### Decoding per RFC 3629

`Utf8.size_at` checks the second byte's range by lead byte (E0: A0 to BF; ED: 80 to 9F; F0: 90 to BF; F4: 80 to 8F; other E1 to EF and F1 to F3: 80 to BF) and refuses C0, C1, and F5 to FF as before. A refused byte is size 1, which `code_at` maps to U+FFFD. This makes the decoder's character count equal `String#length` for every byte string, so `DecodedLine`, `Utf8.codes`, and the cursor's code point columns agree; before, ED A0 80 was one decoded character but three `length` characters. Only integer comparisons are added, on the non-ASCII path.

`Utf8.scalar?(code)` answers whether a code is 0 to 0x10FFFF and outside D800 to DFFF. `ScreenPresenter#write_run` writes U+FFFD for a cell code that is not a scalar value: the one place a code becomes bytes, so a code from any source (a future plugin cell writer, a bug) cannot raise there. It runs only for changed cells.

`DisplayWidth.cell` and `of_char` take the code point with `Utf8.code_at(ch, 0, Utf8.size_at(ch, 0, ch.bytesize))`, so an invalid byte measures as the one cell it is drawn with (before, a lone 9B measured four cells as a C1 control but was drawn as one U+FFFD cell), and nothing is allocated.

### Case changes on invalid text

`Operators.recase` keeps `swapcase`, `downcase`, and `upcase` for valid text and uses `tr` over ASCII letters when `text.valid_encoding?` is false, so no invalid byte is reinterpreted. `valid_encoding?` runs only on the recased slice.

### Open: E484 for any failure, the illegal-byte message

`OpenFile` builds the buffer inside the same `rescue StandardError` as the read, so any failure is E484 and the editor keeps running. When `text.valid_encoding?` is false, the message gets " [ILLEGAL BYTE in line N]" after the file name, N the first line whose `valid_encoding?` is false, Vim's wording and place. Only the open pays for the scan.

### Explorer

No explorer code changes: its names already pass through `start_with?`, `downcase`, `<`, `rindex`, and `+`, none of which raises, and reach the screen through the decoder fixed above. A test lists hostile names over the harness, and a unit row checks `Paths.segments` on one.

## Risks / Trade-offs

- An invalid byte shows as one U+FFFD cell, so two files differing only in an invalid byte look alike; Neovim's `<xx>` marker would tell them apart. Recorded in the backlog.
- Other `String` methods that raise on invalid text remain reachable by plugin code with buffer text; a plugin that raises is disabled through the guarded path, not the editor. `Carat::Json` uses `each_char`, which groups invalid bytes differently from `length`; no path sends buffer text to JSON yet (backlog).
- `from_text` reaches more Ruby code per byte than `split` did only through `byteindex`, which is the runtime's own search; the open scenarios of the benchmark measure it.

## Migration Plan

None: no format or option changes.
