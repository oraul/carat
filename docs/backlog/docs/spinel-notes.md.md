# Backlog: docs/spinel-notes.md

## A blank line splits the Known miscompilations list in the Spinel notes

- Where: `docs/spinel-notes.md:482`, before the two items `spinel-bump` added for f34005bf. Quality advisory at spinel-bump.
- Why it matters: Markdown renders the two new items as a separate list, so they read as apart from the Known miscompilations section.
- Fix outline: remove the blank line.
- Category: design
- Added: 2026-11-10

### docs/spinel-notes.md:47: the compile-time check of a Spinel bump has no place in the bump procedure

The new rule that a bump past 2440954d1 is checked for compile time is not in the bump procedure: the SPINEL_REF comment (Makefile:16) and the CLAUDE.md Commands toolchain bullet still say only after make check passes, nothing measures compile seconds (analysis-budget only warns on analysis ms), and Makefile:79 still cites 22 to 26 s of analysis against the 47.2 s and 106.7 s spinel-compile-time measured. Why: the next bump can reintroduce the regression unnoticed. Fix: name the compile-time comparison (test-build and diagnose seconds) in the SPINEL_REF comment and the CLAUDE.md toolchain bullet, or record test-build seconds as a metric, and refresh Makefile:79.
- Merged: ### docs/spinel-notes.md:47: the Spinel regression bullet mixes terms, stale advice, and dated figures
- Location: docs/spinel-notes.md:47 and the comment at carat/testing.rb:52 (merged at the sprint-11 grooming from four quality advisories on the one bullet).
- Why: the bullet calls the rebuilt structure both the position map and the load record; it still advises an element reader (Array[untyped], Integer) -> T although a bare reader given an untyped argument narrows nothing; it records 125 runner rebuilds at 93d7883b without saying why the bump was accepted against the old pin's 39; and it names a pin ("stays at its parent 6af548c9") and grows a dated figure per bump, so every bump makes it false (the pin is c0502112 since #151).
- Fix outline: rewrite the bullet once: one term, load record, as SP_TIMING names it (also in carat/testing.rb:52); the reader must narrow with is_a?(Array) as Carat::Json.element does; keep the rule (no [] on an untyped receiver; read through Testing#cell, Testing#cases, Carat::Json.field, element, reach) and the current figures only, saying compile time (test-build 169 s, diagnose 219 s) met the target; "6af548c9, its parent, is the newest commit without it"; leave the pin to SPINEL_REF and the history to the archived changes.
- Also: Makefile, CLAUDE.md, carat/testing.rb
- Category: design
- Added: 2026-11-14

### docs/spinel-notes.md:55: the open notes were not rechecked at the new pin 6af548c9

The header (line 3) says open notes are rechecked when the pin is bumped, but this pin move leaves lines 15-16 and 48-61 at Rechecked at f34005bf or new at f34005bf, and the f34005bf workarounds cited in docs/architecture.md:197, carat/domain/mode.rb:58, carat/ports/file_port.rb:41, and carat/plugin_api.rb:657 are not said to hold at 6af548c9. Why: a note that no longer holds keeps a workaround alive or hides a pitfall. Fix: recheck the open notes at 6af548c9 in a follow-up and update their Rechecked lines.
- Also: docs/architecture.md, carat/domain/mode.rb, carat/ports/file_port.rb, carat/plugin_api.rb
- Category: design
- Added: 2026-11-14

### docs/spinel-notes.md:21: the byteindex IndexError rule describes a commit after the pin without a recheck marker

The file's opening says each note holds at the pinned compiler, but the byteindex IndexError rule now describes 84aa303b1, after the pin 6af548c9, with no recheck marker like the other notes about other commits. Why: a reader takes it as true at the pin, which it is not. Fix: mark it as not at the pin and rechecked when a bump passes 84aa303b1, the reason Utf8.boundary is kept.
- Category: design
- Added: 2026-11-14
