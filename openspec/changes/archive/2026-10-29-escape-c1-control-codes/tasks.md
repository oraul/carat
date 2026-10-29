# Tasks

## 1. The unprintable predicate and the frame guard

- [x] 1.1 Add `DisplayWidth.control?(code)` to `carat/domain/display_width.rb` for code points below 32, U+007F, and U+0080 to U+009F, and make `Frame#put` in `carat/domain/frame.rb` store U+FFFD with width 1 for any such code point; verify with the new rows in `test/adapters_frame_presenter.rb` that write "a\u009Bb" to a frame directly and read back "a", U+FFFD, "b"

## 2. Markers in the frame presenter

- [x] 2.1 Change `char_width` and `shown_text` in `carat/adapters/frame_presenter.rb` to give U+007F and U+0080 to U+009F width 4 and the text `<xx>` with lowercase hexadecimal digits, keeping tabs and caret notation unchanged; verify with a table in `test/adapters_frame_presenter.rb` over lines containing U+007F, U+0080, U+009B, and U+009D asserting each row's text, the marker width, the cursor column on and after the marker, and that no cell of the frame holds a control code point
- [x] 2.2 Add to `test/adapters_screen_presenter.rb` a frame drawn from a line containing U+009B and U+009D, presented through the screen presenter, asserting that the bytes written contain `<9b>` and `<9d>` and, after the presenter's own escape sequences are removed, no code point from U+0080 to U+009F; verify the test passes

## 3. Documentation and integration

- [x] 3.1 Remove the C1 control code points entry from `docs/backlog.md`, leaving the `make types` entry; verify the file lists one entry
- [x] 3.2 Run `make snapshots` for the two presenter test programs, review the diff, then `make check` (build, gen-config, test, diagnose); verify everything passes and `spinel-doctor` reports clean

## Workflow follow-up

- Run the security review on the committed branch, then archive the change, open the pull request, and squash-merge it after CI is green.
