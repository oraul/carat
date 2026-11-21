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
