## Context

`option.background` takes `terminal` or `theme`; `Themes.find(name, background)` paints only for `theme`, and `EditorAssembly` picks the theme once from the options. The shipped line and `Options.new` both default to `terminal`. Configuration lines are read in order (shipped defaults, user file, project file), a later line winning, so a named value already overrides the shipped one.

## Goals / Non-Goals

**Goals:**
- Paint the palette's background by default, carat-dark when no theme is named.
- Keep a theme or background a configuration line names.

**Non-Goals:**
- Querying the terminal's background (OSC 11), swallowing the reply in `KeyDecoder`, or choosing carat-light from it: the follow-up `background-detect`.

## Decisions

- Change the default value, not the painting path: the shipped `option.background theme` line, its generated mirror, and `Options.new`'s `background: "theme"`. The painted path already exists and is tested (the screen cleared and regions scrolled after the Normal sequence), so the change is a default flip. Alternative: a third value such as `auto`, left to `background-detect`, which needs it to mean "ask the terminal".
- `Options.new` follows the shipped line so the option has one default whether or not the shipped configuration was read (the domain tests read lines without it).
- Tests that prove the terminal-background behavior name it in a configuration line, which also proves a named background is kept; the smoke test does so through a user file under a temporary HOME, so it never reads a file outside the build directory.

## Risks / Trade-offs

- [A terminal without background color erase shows unpainted gaps after a clear] → `option.background terminal` restores the old look; README and `docs/compatibility.md` say so.
- [A light terminal now gets carat-dark's dark background] → accepted by the Facet plan's fallback until `background-detect` chooses carat-light from the terminal's reply.
