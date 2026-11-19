## Why

The grep picker (`<leader>fg`) lists lines but never shows the file around the highlighted one, while the file finder shows a preview float on a terminal of 100 columns or more; the user asked for the same in the grep picker (T2 user request, 2026-11-19). Outside the roadmap of `docs/architecture.md` section 12: the user's Sprint 21 work on the finder plugin.

## What Changes

- On a terminal of `PREVIEW_COLUMNS` (100) columns or more the grep picker opens the file finder's preview float beside its list, with the same layout and sizing, titled with the highlighted row's path.
- The preview shows the row's file from the text the picker read when it opened, never a new file read: a window of as many lines as the float is high (18 on a 24-row terminal), the matched line in the middle, the window moved to start at line 1 near the top of the file and to end at the file's last stored line near its end. The matched line starts with the list's `> ` highlight mark, the others with two spaces; no new style or colour. Lines the index did not store because they are empty show as empty lines, put back from the gaps in the stored line numbers; a line over 400 bytes shows cut, as stored.
- The preview follows the highlighted row (a move) and the query (a new first row); a result with no row, and the empty query, show no preview. A terminal under 100 columns shows none, as before.
- Each preview line and the title go through `Grep#safe` (control bytes, C1 controls, invalid UTF-8, bidirectional and format code points).
- `Grep#safe` returns a printable ASCII text as it is instead of copying it, so a plain row or preview line costs no copy and the second float does not raise the allocations of a key.
- The grep list is sized as the file finder's list beside its preview (half the screen on 120 columns) where it used the whole width before.
- No new host request and no API version bump.
- Out of scope: the host's float styles (the match mark is the list's text prefix), any change to the file finder's preview, and a preview of lines past the 1000 the picker stores.

## Capabilities

### New Capabilities

### Modified Capabilities
- `file-finder`: the grep picker's preview, and the grep list's width.

## Impact

- Code: `carat/plugins/finder/plugin.rb` (the gate, the preview rows), `carat/plugins/finder/grep.rb` (`preview`, `shown_path`, the file starts, `plain?`); tests in the new `test/editor_finder_grep_preview.rb` and its snapshot, and two updated rows of `test/editor_finder_grep.rb`.
- Memory: one integer per stored file (where its lines start in the stored text).
- Specs: file-finder (a modified requirement, A wide screen previews the highlighted file; the requirement The grep list uses the whole width removed and replaced by the added requirement The grep list is sized as the file finder's list; added requirements for the grep preview).
- README.md: changed, the grep picker's preview.
- docs/plugins.md: changed, the finder's grep section describes the preview.
- docs/codebase-map.md: changed, the finder area's plugin and grep bullets and its tests line.
- docs/architecture.md: unchanged, no layer, port, or API change; the plugin keeps to `plugin_api.rb`.
- docs/compatibility.md, docs/actions.md: unchanged, no Neovim command and no action is added or changed.
- CLAUDE.md: unchanged, no process change.
