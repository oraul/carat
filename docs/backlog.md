# Backlog

Known items to fix in later changes. A finding that a change does not fix, because it is outside the change's scope or below the confidence the contributor agent acts on, is recorded here with where it is in the code, why it matters, and how to fix it, so that it is not lost and the next change can start from it. Each item is removed by the change that fixes it, through the OpenSpec loop like any other change.

## C1 control code points reach the terminal unescaped

- Where: `carat/adapters/frame_presenter.rb`, `shown_text` and `char_width`, which escape only code points below 32 as caret notation; `Frame#put` and `ScreenPresenter#render_row` pass U+007F and U+0080 to U+009F through raw.
- Why it matters: on xterm and VTE terminals the UTF-8 forms of U+009B and U+009D act as CSI and OSC introducers, so an attacker-supplied file can repaint rows to hide or alter displayed lines, set the window title, or change colors. Found by a security review; severity medium.
- Fix outline: treat U+007F and U+0080 to U+009F as unprintable in `char_width` and `shown_text`, rendering them as `<7f>` and `<9b>` style markers with width 4 as Vim does; optionally enforce the invariant in `Frame#put`; add a table-driven presenter test with a line containing U+009B asserting that no raw C1 code point reaches the frame.

## make types leaves build/carat.rbs that a later spin build warns about

- Where: the `types` target in the `Makefile` writes `build/carat.rbs` with `--emit-rbs`, inside the tree `spin` scans.
- Why it matters: `spinel_rbs_extract` reports a parse failure on the emitted file at every later `spin build`, `spin test`, and `make snapshots`, because of a doubled namespace separator in the class names it writes; the noise hides real warnings and the file has to be deleted by hand. Observed during the Struct change and again during the command grammar change.
- Fix outline: have the `types` target write the file outside the `spin` source tree, or delete it after printing.
