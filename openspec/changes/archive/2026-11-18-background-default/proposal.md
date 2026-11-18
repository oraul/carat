## Why

The shipped configuration sets `option.background terminal`, so out of the box Carat leaves the terminal's own background under every cell and the palette's background, the one its contrast rules are measured on, is never seen unless the user asks for it. The user accepted the design council's Facet plan, whose decision 1 is that Carat paints its theme background by default; this is its wave 1 item 5, part a.

## What Changes

- The shipped `option.background` line becomes `theme`, and the built-in default of the background option (`Options.new`) follows it, so with no line of its own the editor paints carat-dark's background under every cell, the cleared screen and scrolled-in rows included.
- A theme or a background the user's or the project's configuration names is kept: `option.background terminal` still leaves the terminal its own colors, and `option.theme carat-light` paints carat-light.
- An unknown background value keeps the value before it, which with no other line is now `theme`.
- Roadmap: outside the numbered roadmap of `docs/architecture.md` section 12; a user request from the Facet plan (wave 1 item 5).
- Out of scope, queued as `background-detect`: the OSC 11 query of the terminal's background, swallowing its reply in `KeyDecoder`, choosing carat-light on a light reply and carat-dark on a dark or no reply, and keeping startup from waiting on it.

## Capabilities

### New Capabilities

### Modified Capabilities
- `color-themes`: the background option's default becomes `theme`; a named theme or background is kept.

## Impact

- Configuration: `config/default.caratrc` and its generated mirror `carat/domain/default_config.rb` (`make gen-config`).
- Domain: `Options` (the background's built-in default and its comment).
- Tests: `test/editor_screen.rb` (the painted first frame, the named background and theme kept), `test/domain_theme.rb` (the defaults), `test/adapters_screen_presenter.rb` and `test/smoke_editor.rb` (their terminal-background checks name the background in a configuration line).
- Docs: `docs/compatibility.md` (the option.background row), README.md.
- README.md: changed, its colors paragraph says the palette paints its background by default and `option.background terminal` keeps the terminal's.
- docs/architecture.md: unchanged, it names the two background choices without saying which is the default.
- Assumptions: the built-in default in `Options.new` follows the shipped line so that a configuration read without the shipped defaults agrees with it; the smoke test's color check, which proves `:syntax off` writes the plain reset, names the terminal's background in a user file rather than matching a depth-dependent painted sequence.
