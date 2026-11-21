# Backlog: carat/drivers/ansi_terminal.rb

## No test reads NO_COLOR through AnsiTerminal

- Where: the `NO_COLOR` read in `carat/drivers/ansi_terminal.rb` (line 24 at `start-screen`); the start screen tests set only the `FakeTerminal` writer. Quality review of `start-screen`.
- Why it matters: a regression in the driver's read would show the colored glyphs to a user who set `NO_COLOR` with every test still passing.
- Fix outline: a `test/smoke_editor.rb` session spawned with `NO_COLOR=1` asserting the output holds no U+25E2 and still shows the hints.
- Merged: ### No test reads NO_COLOR through AnsiTerminal
- Location: carat/drivers/ansi_terminal.rb:24 (`@no_color` read once from the environment), :30 (`no_color?`); only bin/carat.rb:27 constructs it
- Why: every NO_COLOR test goes through FakeTerminal's writer, so a regression in the driver's own read of the variable (set, empty, unset) passes every test; split from lsp-tidy by the plan and queued as `lsp-tidy-c`
- Fix: a driver test constructing AnsiTerminal over pipes with NO_COLOR set, set empty, and unset, checking `no_color?` for each
- Also: test/smoke_editor.rb, bin/carat.rb
- Category: editor
- Added: 2026-11-05

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
