## 1. Decoder and display width

- [x] 1.1 `carat/domain/utf8.rb`: RFC 3629 second-byte ranges in `size_at`, and `scalar?`; test: new `test/domain_utf8.rb` table of hostile and edge sequences (truncated, overlong, surrogates, above U+10FFFF, lone continuation, NUL) for `size_at`, `code_at`, `codes` against `String#length`, `DecodedLine.decode`, and `DisplayWidth.column`, `col_at`, `cell`.
- [x] 1.2 `carat/domain/display_width.rb`: `cell` and `of_char` decode through `Utf8`; test: `test/domain_utf8.rb` rows for a lone byte and a C1 byte.
- [x] 1.3 `carat/adapters/screen_presenter.rb`: `write_run` writes U+FFFD for a code that is not a scalar value; test: `test/adapters_screen_presenter.rb` rows for 0x110000 and 0xD800.

## 2. Lines that keep their bytes

- [x] 2.1 New `carat/domain/text_lines.rb` (`TextLines.split`), required in `carat.rb`; test: `test/domain_utf8.rb` rows comparing it with `split` on valid text and checking hostile text.
- [x] 2.2 `carat/domain/buffer.rb`: `from_text` and `joined` through `TextLines`; `carat/domain/filetype.rb`: no split of an invalid first line; test: `test/domain_buffer.rb` table of hostile texts loading and round-tripping, CRLF with an illegal byte.
- [x] 2.3 `carat/domain/register_entry.rb`, `carat/use_cases/ex/register_command_handler.rb`, `carat/adapters/frame_presenter.rb` (`paint_list`) through `TextLines`; `carat/domain/motions.rb` `keyword?` without a regular expression; `carat/domain/operators.rb` `recase` with `tr` on invalid text; test: `test/editor_registers.rb` rows (yyp, dd and p, :registers) and case rows (VU, ~).
- [x] 2.4 `carat/plugin_api.rb`: `Paths.segments` walks bytes; test: a `test/editor_explorer.rb` session listing hostile names through `MemoryFiles`.

## 3. Opening a file

- [x] 3.1 `carat/use_cases/files/open_file.rb`: build the buffer inside the rescue, E484 on any failure, " [ILLEGAL BYTE in line N]" in the message; `docs/compatibility.md` row; test: `test/editor_cmdline.rb` rows (open a Latin-1 file, the message, :w writes the same bytes).
- [x] 3.2 `test/smoke_editor.rb`: open a non-UTF-8 file in the release binary, see the message and the replacement character, write it unedited and compare the bytes, then quit.

## 4. Bookkeeping

- [x] 4.1 `tools/run_state.sh`: the four domain files join the terminal output area of `REVIEW_AREAS`; test: a `tools/tools_test.sh` case.
- [x] 4.2 `docs/codebase-map.md`: the #35 delivered-changes line, this change's line, `text_lines.rb` and `test/domain_utf8.rb` in their areas; `docs/backlog.md`: the seven Low periodic findings (the REVIEW_AREAS entry keeping only the bin, tools, and CI part), the lone-prefix wait, the five scroll advisories, and the items this change leaves (`<xx>` markers, JSON on invalid text).
- [x] 4.3 Re-read the delta specs, confirm each scenario has code and a test; `make gates`, `make docs-lint`, `make lint`.
