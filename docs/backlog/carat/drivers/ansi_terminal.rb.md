# Backlog: carat/drivers/ansi_terminal.rb

## The main loop spins at end of input

- Where: `read_key` in `carat/drivers/ansi_terminal.rb` line 54 and `InputController#pump` in `carat/adapters/input_controller.rb` line 86, at 3895e21. Periodic quality. Queue item 39 (backlog items).
- Why it matters: end of input reads as nil like a timeout, so with stdin closed and no SIGHUP the select returns at once on every pass and the editor spins at full CPU forever.
- Fix outline: record end of input behind a `TerminalPort` predicate (architecture section 6) that `MainLoop#run` stops on, with a `test/drivers_main_loop.rb` row over `FakeTerminal`.
- Also: carat/adapters/input_controller.rb, test/drivers_main_loop.rb
- Category: editor
- Added: 2026-11-09

### A late OSC 11 reply's tail is read as keys
- Location: carat/drivers/ansi_terminal.rb:78 (security Low, confidence 2)
- Why: the rest of an OSC 11 reply that arrives after a read timeout is passed on as keys; those bytes are hex digits, slashes, and ESC backslash, which can run normal-mode commands such as r, f, b, or a search; they come from the terminal emulator, not an attacker, so this is a robustness issue, and the change only documents the existing behavior and adds a test for it.
- Fix: after a timeout drops a held reply start, keep discarding until the next BEL or ESC backslash, but only for one more short read window, so keys typed later are not eaten.
- Category: security
- Added: 2026-11-20

### An unanswered OSC 11 query keeps the terminal awaiting for the whole session (sprint-22 sweep quality)

- Location: `carat/drivers/ansi_terminal.rb:84`
- Why: an OSC 11 query that is never answered leaves @awaiting true for the whole session, so every later read scans for the introducer and a key run that starts with it (pasted text, or Alt-] then 11;) is taken as an answer up to its terminator or LIMIT; the read_key comment says a timeout ends the awaiting, but it ends only while part of an answer is held
- Fix: stop awaiting after a set time or number of reads since the query (the late-answer test kept inside that limit) and correct the comment
- Also reported: sprint-22 sweep note 56 (ansi_terminal.rb:83)
- Category: editor
- Added: 2026-11-20

### An OSC 11 answer split inside its introducer reaches the keys (sprint-22 sweep quality)

- Location: `carat/drivers/ansi_terminal.rb:138`
- Why: blocking: take_reply finds the OSC 11 answer only by a whole INTRODUCER inside one read, so an answer split inside its first five bytes (a read ending in "\\e]1") is not held and its bytes reach the key parser as keys (in Normal mode 1, 1, ;, r, g, b, : can replace a character and open the command line); test/drivers_ansi_terminal.rb tests splits only after the introducer
- Fix: while awaiting, hold a trailing proper prefix of INTRODUCER at the end of a read for the next one, and add a row splitting the answer at "\\e]1"
- Also: test/drivers_ansi_terminal.rb
- Category: editor
- Added: 2026-11-20

### a read that times out with no held reply at carat/drivers/ansi_terminal.rb:83 (sprint-26 sweep quality, note 51)

- Location: carat/drivers/ansi_terminal.rb:83
- Why: a read that times out with no held reply leaves @awaiting true, so against a terminal that never answers OSC 11 every read for the whole session still scans for and strips \e]11; from the keys (a paste or key sequence starting with it would be eaten as a reply)
- Fix: end the awaiting at the first timeout or after a fixed bound of reads or seconds, with a driver test of a terminal that never answers
- Category: editor
- Added: 2026-11-22

### read_key awaits an OSC 11 answer for the whole session at carat/drivers/ansi_terminal.rb:79 (sprint-28 sweep quality, note 32)

- Location: carat/drivers/ansi_terminal.rb:79
- Why: a terminal that never answers leaves every later read scanned, so a later `ESC ]11;` in typed or pasted input is swallowed as an answer.
- Fix: stop awaiting at the first empty timeout or a deadline, with a missing-answer test.
- Category: editor
- Added: 2026-11-22
