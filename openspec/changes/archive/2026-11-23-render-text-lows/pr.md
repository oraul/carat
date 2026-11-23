fix(render): show format code points in file text as markers

## Summary

File text containing bidirectional, zero-width, and other Unicode format code points now shows each one as a visible hexadecimal marker instead of being written raw to the terminal. A file holding U+202E could reorder the terminal row and U+200B could hide text, so what the user saw differed from what the buffer held.

---

## Changes

- Paint each format code point in a buffer line as a lowercase four-digit hexadecimal marker in angle brackets, six cells wide, so the cursor, columns, and horizontal scroll agree with the frame
- Add `DisplayWidth.format_char?` naming the set: U+061C, U+200B to U+200F, U+2028 to U+202E, U+2060 to U+206F, and U+FEFF
- Move the first-character decoder from `DisplayWidth.code_of` to `Utf8.code_of`, leaving one decoder
- Add scenarios to the screen-rendering spec and tests for the painter, the width table, and the decoder, including U+202E and U+200B rows in the frame presenter test
- Document the marker in the README, the architecture, the code map, and the compatibility differences
- Close three backlog entries by evidence, with no code: the single `NO_NAME` copy, and `DisplayWidth.of_char` and `TabBar#icon_group` already gone

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or blocking finding and one Low recorded as a finding
- Run the benchmark review, pass with no blocking finding
- Run the fast stages (docs-lint, dev-build, test-build, test-run, gates, tools-test, diagnose, bench-budget, metrics), all pass
- Run `make spec-validate` after the archive, 56 of 56 pass

---

## Notes

Names, menus, and markdown text written through `Frame#put` still draw a format code point raw; this is recorded in the findings file with a fix outline and left out because it is a different writer outside the brief. U+00AD, U+180E, and U+034F stay unmarked, following Vim and the file finder.
