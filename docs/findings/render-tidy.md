### Match highlighting still walks the matches left of the horizontal scroll
- Location: carat/adapters/frame_presenter.rb, paint_matches (the walk starts at code point 0 of the row).
- Why: each match left of the scroll is an engine call charged to the frame's budget, so a long line scrolled far right spends the budget on matches nobody sees. Starting the walk at the scroll column instead changes which matches are found when matches overlap (the pattern aa on aaa), so the highlight would differ from Neovim's, which walks from the line start; the delivery fixed only the stale stamp of rows painted after the stop.
- Fix: keep the walk from 0 but skip the engine call chain left of the scroll when the pattern cannot match twice at overlapping offsets (a literal with no repeated prefix), or cache the match starts per decoded line in LineCache and read them per frame.

### Pasted text in normal and the other modes does nothing
- Location: carat/use_cases/handle_key.rb, paste.
- Why: Neovim puts pasted text in at the cursor in normal mode, and in the visual modes replaces the selection; here the paste is ignored outside insert mode and the command line, which is safe but a missing feature.
- Fix: add a paste use case that puts the text as a charwise put after the cursor in normal mode and replaces the selection in the visual modes, called from paste for those modes.

### A paste that never ends keeps the decoder in the paste
- Location: carat/adapters/key_decoder.rb, decode_paste and flush.
- Why: a terminal that sends the start mark and loses the end mark leaves every later byte read as pasted text, in which Escape and Ctrl-C are dropped, so the user cannot leave insert mode; ending the paste on an idle timeout would instead let a slow paste's remainder run as commands. A pasted end mark inside the text, which terminals strip, would end the paste early.
- Fix: end a paste after a long idle timeout (several seconds) with a message, or accept a key chord such as the quit chord inside a paste.

### A paste ended early by an end mark in its text is not defended in depth
- Location: carat/adapters/key_decoder.rb decode_paste
- Why: on a terminal that does not filter ESC [ 201 ~ out of the clipboard text, the paste ends there and the bytes after it decode as typed keys (security Low (4)); the decoder now documents the reliance and a decoder row shows it.
- Fix: after a paste ends, flag or drop the keys read in the same feed straight after the mark, changing the "a key after the paste is a key again" and "keys before and after" rows and their scenarios.
# Backlog

none: every finding and proposal of this plan is placed in the backlog queue.

### A paste can end itself early on a terminal that passes the end mark through (security Low (4))
- Location: carat/adapters/key_decoder.rb:186 (decode_paste)
- Why: If the clipboard text contains a literal ESC [ 201 ~ and the terminal does not strip it, decode_paste leaves paste mode there and decodes every byte after it as typed keys (for example Esc, then :w!, then Enter). Modern terminals filter this mark, so it only matters on terminals that do not. This change documents the reliance and adds a decoder test row showing it, which satisfies the fallback outline but does not remove the behavior.
- Fix: As defense in depth, drop or flag keys that arrive in the same read straight after the end mark.
