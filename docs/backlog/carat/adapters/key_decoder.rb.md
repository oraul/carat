# Backlog: carat/adapters/key_decoder.rb

## Key handling allocates two dozen objects per key

- Where: the key path outside rendering: the byte slices of `Carat::Adapters::KeyDecoder` in `carat/adapters/key_decoder.rb`, the `Command` the grammar builds, the `Motion` and `Position` values of `carat/domain/motions.rb`, the `Transaction` and `ChangeRecord` the dispatcher and the buffer open for every command in `carat/use_cases/dispatcher.rb` and `carat/domain/buffer.rb`, and the `KeymapMatch` of `Keymap#lookup` in `carat/domain/keymap.rb`.
- Why it matters: after `render-core` a key takes about 14 us and rendering allocates about nine objects, so these allocations set how often Spinel collects; typing spends 3.43 percent of its time in the collector (about six collections per 10,000 typed keys, each marking a live set of 10 to 16 MB) against the 3 percent target.
- Fix outline: decode from an offset into the pending bytes instead of slicing them, reuse one `KeymapMatch` and one `Command` per `HandleKey` (they are read before the next key), return motion targets as two integers instead of a `Position`, and open a transaction only when the command edits, creating it on the first change record; measure with `make bench` and lower the budget of `make bench-budget` to what the cursor and typing scenarios reach.
- Also: carat/domain/motions.rb, carat/use_cases/dispatcher.rb, carat/domain/buffer.rb, carat/domain/keymap.rb
- Category: editor
- Added: 2026-11-01

## The key decoder repeats the letter finals

- Where: `carat/adapters/key_decoder.rb` line 143 (csi_key) against line 186 (ss3_key) at c1b3a12 (periodic quality). Queued in item 46.
- Why it matters: ten finals are listed twice and can drift.
- Fix outline: csi_key keeps 126 and hands every other final to ss3_key.
- Category: editor
- Added: 2026-11-09

### The key decoder repeats final-byte cases and loses a key after invalid UTF-8

- Location: carat/adapters/key_decoder.rb:148 and :212 (sprint-4 sweep, quality advisory).
- Why: csi_key copies ss3_key's ten cases; a lead byte followed by a non-continuation (C3 41) consumes the whole length, losing the ASCII key.
- Fix: csi_key handles 126 and passes the rest to ss3_key; on an invalid sequence emit U+FFFD for the lead byte alone.
- Category: editor
- Added: 2026-11-14

### csi_key repeats ss3_key's final-byte cases
- Location: carat/adapters/key_decoder.rb:148 and 193-206
- Why: ten final-byte cases copied word for word. Folded into input-core-tidy.
- Fix: handle 126 in csi_key and answer ss3_key(final) for the rest.
- Category: editor
- Added: 2026-11-17

### KeyDecoder#csi_key repeats ss3_key's finals

- Location: carat/adapters/key_decoder.rb:148 (sweep, quality).
- Why: csi_key repeats the letter finals A to D, H, F, P to S of ss3_key.
- Fix outline: keep the 126 tilde branch and send the rest to ss3_key(final).
- Category: editor
- Added: 2026-11-17

### Csi_key repeats ss3_key's mapping of the finals A, B, C, D, H, F, P, Q, (sprint-20 sweep quality, key_decoder.rb:148)

- Location: `carat/adapters/key_decoder.rb:148`
- Why: csi_key repeats ss3_key's mapping of the finals A, B, C, D, H, F, P, Q, R, S
- Fix: have csi_key handle 126 through tilde_key and fall back to ss3_key(final) for the rest
- Category: editor
- Added: 2026-11-19

### carat/adapters/key_decoder.rb:193: duplication: ss3_key repeats the arrow, Home, End, and F1-F4 (sprint-22 sweep quality)

- Location: `carat/adapters/key_decoder.rb:193`
- Why: duplication: ss3_key repeats the arrow, Home, End, and F1-F4 table of csi_key (:148)
- Fix: one private letter_key(final) that csi_key falls back to after the tilde case
- Category: editor
- Added: 2026-11-20

### carat/adapters/key_decoder.rb:220: decode_utf8 consumes the whole expected length of an invalid (sprint-22 sweep quality)

- Location: `carat/adapters/key_decoder.rb:220`
- Why: decode_utf8 consumes the whole expected length of an invalid sequence, so a stray lead byte followed by an ASCII key (bytes C3 61) swallows the a
- Fix: check each continuation byte (& 0xC0 == 0x80) and on a bad one emit U+FFFD consuming only the lead, with an adapters_key_decoder case
- Category: editor
- Added: 2026-11-20

### KeyDecoder#ss3_key repeats csi_key's letter finals (sprint-24 sweep quality)

- Location: `carat/adapters/key_decoder.rb:193`
- Why: the ten letter finals are written twice.
- Fix: csi_key handles 126 and delegates every other final to ss3_key.
- Category: editor
- Added: 2026-11-21

### A paste that never ends keeps the decoder in the paste
- Location: carat/adapters/key_decoder.rb, decode_paste and flush.
- Why: a terminal that sends the start mark and loses the end mark leaves every later byte read as pasted text, in which Escape and Ctrl-C are dropped, so the user cannot leave insert mode; ending the paste on an idle timeout would instead let a slow paste's remainder run as commands. A pasted end mark inside the text, which terminals strip, would end the paste early.
- Fix: end a paste after a long idle timeout (several seconds) with a message, or accept a key chord such as the quit chord inside a paste.
- Category: editor
- Added: 2026-11-23

### A paste ended early by an end mark in its text is not defended in depth
- Location: carat/adapters/key_decoder.rb decode_paste
- Why: on a terminal that does not filter ESC [ 201 ~ out of the clipboard text, the paste ends there and the bytes after it decode as typed keys (security Low (4)); the decoder now documents the reliance and a decoder row shows it.
- Fix: after a paste ends, flag or drop the keys read in the same feed straight after the mark, changing the "a key after the paste is a key again" and "keys before and after" rows and their scenarios.
- Category: security
- Added: 2026-11-23

### A paste can end itself early on a terminal that passes the end mark through (security Low (4))
- Location: carat/adapters/key_decoder.rb:186 (decode_paste)
- Why: If the clipboard text contains a literal ESC [ 201 ~ and the terminal does not strip it, decode_paste leaves paste mode there and decodes every byte after it as typed keys (for example Esc, then :w!, then Enter). Modern terminals filter this mark, so it only matters on terminals that do not. This change documents the reliance and adds a decoder test row showing it, which satisfies the fallback outline but does not remove the behavior.
- Fix: As defense in depth, drop or flag keys that arrive in the same read straight after the end mark.

none
- Category: security
- Added: 2026-11-23

### the class comment says every control byte of a at carat/adapters/key_decoder.rb:213 (sprint-30 sweep quality, note 10)

- Location: carat/adapters/key_decoder.rb:213
- Why: the class comment says every control byte of a paste is dropped, but the C1 controls U+0080 to U+009F (0xC2 0x80 to 0x9F) pass into the buffer as pasted characters; line 176 is also left unwrapped
- Fix: drop code points 0x80 to 0x9F in decode_paste as RecentFilesText.usable? does, with a decoder row, and rewrap the comment
- Category: editor
- Added: 2026-11-23

### a paste whose end mark never arrives keeps @pasting at carat/adapters/key_decoder.rb:163 (sprint-30 sweep quality, note 11)

- Location: carat/adapters/key_decoder.rb:163
- Why: a paste whose end mark never arrives keeps @pasting set for the rest of the session, so every later key, Escape included, becomes pasted text and the editor cannot leave insert mode or quit
- Fix: end the paste on the escape timeout flush after an idle gap, with a test
- Category: editor
- Added: 2026-11-23
