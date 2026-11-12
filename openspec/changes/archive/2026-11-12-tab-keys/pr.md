fix(tabs): move gt over the buffer tabs and read tab ex arguments

## Summary

Makes `gt` and `gT` move over the buffer tabs the top row shows, moves tab pages to Ctrl-PageDown, Ctrl-PageUp, and `g` followed by Tab, and makes the tab ex commands act on their argument or refuse it with Vim's message. With one tab page the buffer tabs were out of reach of the keys a Vim user reaches for, and `:tabn 3`, `:tabc 2`, and `:tabo x` dropped their argument without a word.

---

## Changes

- Change `gt`, `gT`, and their counts to follow the buffer tabs through the new `tabline.next` and `tabline.previous` actions, a modified current buffer refused with E37 as `:bn` does.
- Add `option.gt` taking `buffers`, the shipped default, or `tabpages`, which restores the tab-page meaning, any other word reported as an unknown gt mode.
- Add Ctrl-PageDown and Ctrl-PageUp to move tab pages with counts and `g` followed by Tab to go to the last accessed tab page, the key decoder reading the Ctrl-modified page keys and key notation naming them.
- Add `[b`, `]b`, `[B`, and `]B` for the previous, next, first, and last buffer, as vim-unimpaired binds them.
- Fix the tab ex commands to read their argument: `:tabn N`, `:tabp N`, `:tabN N`, `:tabc N`, and `:tabo N` act on it, `0` gives E16, a word or a number past the last tab page E475, and an argument to `:tabfir` or `:tabl` E488.
- Add the editor, ex, option, keymap, key, and decoder test rows for every new key and argument, and retarget the tests that typed `gt` for a tab page.
- Document the keys and arguments in the compatibility table, the actions table, the code map, the README feature sentence, and the architecture entry of `TabList`, and update the buffer-tabs, tab-pages, and key-input specs.

---

## Testing

- Run the security review of the committed diff, pass with no findings: 0 High, 0 Medium, 0 Low
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass
- Run the quality review, pass with 0 blocking findings and 6 advisories recorded in the backlog
- Run the benchmark comparison against main's recorded figures, pass with `lh` 26.0, `j` 27.0, and `insert` 34.0 allocations held
- Run make spec-validate after the archive, 51 of 51 pass

---

## Notes

The tab ex argument is a plain number: Vim's `+N`, `-N`, `$`, and `#` forms are refused with E475 and named in the compatibility Differences. A plugin's focus request that changes tab page is not counted as a visit for `g` followed by Tab. Left out: `:tabmove`, `:tabs`, `:tabdo`, and a count before a tab ex command. The commit also records the planner's queue and the metrics row of the previous merged change.
