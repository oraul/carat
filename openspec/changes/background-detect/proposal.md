# Proposal

## Why

A light terminal starts on the dark theme, since Carat never learns the terminal's background. This is the user's order of 2026-11-19 (queue item 1 of Sprint 22, feature lane); it is outside the numbered roadmap of `docs/architecture.md` section 12, which closed. The plan splits it: this change asks the terminal for its background and reads the answer; choosing the theme from it, with a configured theme winning, is the queued `background-theme`.

## What Changes

- `AnsiTerminal#enter` writes the OSC 11 query (`ESC ] 11 ; ? ESC \`) and returns at once, so the first frame waits for no answer.
- While the answer is awaited, `AnsiTerminal#read_key` takes the reply out of the bytes it reads, the reply held across reads only while it is shorter than a bound and dropped when a read times out, so no reply byte reaches the key stream; the bytes around it are the keys.
- The new `Domain::TerminalBackground` finds where a reply ends and parses it, bounded: `rgb:` or `rgba:` with one to four hex digits per channel, light when the luminance is over half, anything else unknown.
- `TerminalPort#background` reports `dark`, `light`, or `""` (unknown: no answer yet, none, or a malformed one); `FakeTerminal` answers `""`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `editor-startup`: ADDED requirement "The editor asks the terminal for its background without waiting".

## Out of scope

- Choosing `carat-light` from the answer and a configured `option.theme` winning over it (`background-theme`); `config/default.caratrc` is not changed.
- A deadline for the answer: a terminal that never answers leaves the background unknown and the reply detection on, at the cost of one byte search per read.
- A reply whose first five bytes (`ESC ] 11 ;`) are split across two reads passes to the keys, since holding a lone `ESC` would delay the Escape key.
- No `tools/rules.sh` edit; no file of the backlog lane.

## Impact

- README.md: unchanged, the answer is read but nothing a user sees uses it yet; `background-theme` documents the theme choice.
- docs/architecture.md: changed, the `TerminalPort` row of the ports table names `background`, the OSC 11 query, and the double's answer.
- CLAUDE.md: unchanged, no process changes.
- docs/codebase-map.md: area 17 (`TerminalPort#background`, `AnsiTerminal`, the new domain module and the two tests), area 18 (`FakeTerminal#background`).
- docs/compatibility.md and docs/actions.md: unchanged, no command or action.
- Security: the reply is untrusted input; it is scanned once within the bytes of one read, held at most up to the bound, and parsed only within the bound.
- Performance: the benchmarks run on `FakeTerminal`; the driver adds one byte search per read while the answer is awaited.
