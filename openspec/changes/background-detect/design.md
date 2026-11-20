# Design

## Context

`bin/carat.rb` builds `AnsiTerminal` and calls `ScreenPresenter#enter`, which calls `TerminalPort#enter` before the first frame; `InputController#pump` reads keys with `read_key(timeout)`, at least 0.02 s, a timeout answering nil. `ColorDepth` shows the shape of a terminal fact decided by a pure domain module and read by the driver.

## Decisions

### Ask on enter, never wait

`enter` writes `TerminalBackground::QUERY` and sets the awaiting flag; nothing reads there, so the first frame is drawn before any answer. The answer arrives as input bytes, so `read_key` takes it out while awaiting. Alternative: a blocking read with a short timeout at start, as some editors do; rejected, since the brief says never wait.

### Taking the reply out of the input

A reply starts with `ESC ] 11 ;`. `TerminalBackground.reply_size(text)`, for text starting there, scans once: BEL or `ESC \` ends a reply (its size through the terminator); an `ESC` followed by another byte or a control byte ends a reply cut short before that byte, which goes to the keys; with no end, 0 asks the driver to hold the bytes while they are shorter than `LIMIT`, else the whole text is a reply too long and is dropped. A read that times out drops held bytes as a reply cut short. Any found reply ends the awaiting, so a later `ESC ] 11 ;` is keys again. A reply is searched only from the start of the introducer, never a lone `ESC`, so the Escape key keeps its timing.

### Parsing, bounded

`parse(reply)` answers unknown for a reply over `LIMIT` bytes or without a terminator, and reads `rgb:R/G/B` or `rgba:R/G/B/A`, each channel one to four hex digits scaled to 16 bits, by bytes only (`getbyte`), so a byte that is not UTF-8 cannot raise. Light when `299 R + 587 G + 114 B` is over half of its maximum, the luma weights the terminal convention uses.

### The port

`TerminalPort#background` answers `"dark"`, `"light"`, or `""`, the strings `background-theme` will read; `FakeTerminal` answers `""`, so no test of the editor changes.
