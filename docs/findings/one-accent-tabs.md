
### The color-themes requirement lists a stale count of groups
- Location: `openspec/specs/color-themes/spec.md`, the requirement "The editor's own highlights are groups too".
- Why: it names a count of highlight groups that no longer matches `Domain::Highlight` (TabLineName is id 69 and the syntax groups moved up by one), so a reader cannot check the list against the code.
- Fix: replace the number with a statement that every group of `Domain::Highlight` is drawn by each theme, and let `test/domain_theme.rb` hold the count.

### Buffer#icon may be unused after the tab icon is gone
- Location: `carat/domain/buffer.rb` (`icon`, `Buffer.icon_of`), `test/domain_buffer.rb:92`.
- Why: the tab row no longer draws the file icon, so `Buffer#icon` may be read by no production caller, and the field and its update in `path=` would be dead weight on a hot record.
- Fix: search the adapters and plugins for a reader of `buffer.icon`; when none remains, remove the member, `icon_of`, and the test lines in one change.
