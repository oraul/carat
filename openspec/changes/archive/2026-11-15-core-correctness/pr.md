fix: correct four editing paths that disagreed with vim

## Summary

Fixes four editing paths that disagreed with their sibling paths and with Vim: expandtab Tab now lands on the tab stop after a tab or a wide character, a `none` unbinding no longer turns a key into an empty prefix, a reverted edit inside `:g` keeps the global marks on their lines, and a binding resolved by timeoutlen runs the same follow-ups as a typed key. The sprint-6 quality sweep raised these four bugs again as blocking, each leaving the editor in a state a user could see, such as a hover float left open or a key that waits for a second keystroke.

---

## Changes

- Fix `InsertTab` to pad to the next tab stop from the cursor's display column, as the rendering and the block operators measure it.
- Fix `Keymap` so a `none` unbinding walks only existing trie nodes and prunes the nodes it leaves with neither a value nor children, creating nothing for keys never bound.
- Fix `Buffer#revert_to` to move the global marks back with each record it undoes, as `splice` moves them forward.
- Fix `HandleKey#timeout` to run the completion, hover, definition, signature, palette, and plugin prompt follow-ups through one private method shared with `HandleKey#call`.
- Add test rows that fail before and pass after in the insert, keymap, global, and leader tests, with their snapshots.
- Add the four requirements to the insert-mode, keymap-config, and global specs and archive the OpenSpec change.
- Document three quality advisories in the backlog and record the sprint-7 queue and the previous change's metrics row.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the quality review, pass with no blocking finding and three advisories recorded in the backlog
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run the benchmark comparison against main's recorded figures, pass
- Run spec validation after the archive, all 51 items pass

---

## Notes

The key hints float is still not hidden after a timeout, since the brief did not name it, and the pruning of `remove_owner` is unchanged. Rows a reverted edit had deleted come back without their global mark, which the backlog records as a follow-up.
