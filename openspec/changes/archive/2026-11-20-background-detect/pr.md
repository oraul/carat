feat(terminal): ask the terminal for its background at startup

## Summary

Carat now asks the terminal for its background color with an OSC 11 query at its first key read and reports the answer as dark, light, or unknown through the terminal port. A light terminal starts on the dark theme because Carat never learns the background; this change delivers the detection, and choosing the theme from it is the queued background-theme change.

---

## Changes

- Add the OSC 11 query to AnsiTerminal, written at the first read_key after enter so it goes out in raw mode after the first frame, which waits for no answer
- Change AnsiTerminal#read_key to take the reply out of the bytes it reads, holding a partial reply across reads only up to a bound and dropping it when a read times out, so the bytes around it stay keys
- Add Domain::TerminalBackground, which finds where a reply ends and parses it within a bound: rgb or rgba with one to four hex digits per channel, light when the luminance is over half, anything else unknown
- Add TerminalPort#background, answered by AnsiTerminal from the reply and by FakeTerminal as unknown
- Add tests for a dark, a light, a malformed, a split, a delayed, and no reply, for the query going out at the first read and not before, and for keys around a reply
- Add the editor-startup requirement that the editor asks the terminal for its background without waiting
- Document the background answer in the TerminalPort row of the architecture ports table and in the code map
- Record the plan's split into background-theme in the feature queue, the metrics history, and the review findings left for later

---

## Testing

- Run the security review of the committed diff, pass with no High or Medium finding; its Low findings are recorded in docs/findings/background-detect.md
- Run the checker stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics, all pass
- Run the quality review, pass with no blocking finding; its one open advisory is recorded in the findings file
- Run the benchmark review, pass with no allocation or round regression
- Run make spec-validate after the archive, 54 passed and 0 failed
- Run make gates on the packaged branch, all pass

---

## Notes

The theme choice, carat-light on a light answer with a configured theme winning, is left to background-theme, so config/default.caratrc and the README are unchanged. A terminal that never answers leaves the background unknown and the reply detection on, at one byte search per read. The rest of a reply delayed past a read timeout reaches the keys, as the spec states; bounding that is recorded as a finding.
