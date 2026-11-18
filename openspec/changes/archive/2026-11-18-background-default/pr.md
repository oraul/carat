feat(themes): paint the theme background by default

## Summary

Carat now paints its theme's background under every cell by default, so a fresh start shows carat-dark's palette instead of the terminal's own background. The shipped `option.background terminal` left the palette's background, the one its contrast rules are measured on, unseen unless the user asked for it, against decision 1 of the accepted Facet plan.

---

## Changes

- Change the shipped `option.background` line to `theme` and regenerate its mirror in `carat/domain/default_config.rb`, so the cleared screen and scrolled-in rows are painted with the theme's background by default
- Change the built-in background default in `Options` to `theme` so a configuration read without the shipped defaults agrees with the shipped line
- Keep a background or theme the user's or the project's configuration names: `option.background terminal` still leaves the terminal its colors and `option.theme carat-light` paints carat-light
- Add editor screen tests for the painted first frame and the named background and theme kept, and update the theme defaults test and its snapshot
- Change the screen presenter and smoke tests to name the terminal background in a configuration line where they check it
- Update the color-themes spec for the new default and archive the background-default OpenSpec change
- Document the new default in README.md and the option.background row of `docs/compatibility.md`
- Record the plan's queue, the metrics history row, and the change's findings, among them the delta spec advisory

---

## Testing

- Run the security review of the committed diff at 96d9a9cb63f4, pass with no High, Medium, or Low finding
- Run the checker's stages at 96d9a9cb63f4 (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass
- Run the quality review at 96d9a9cb63f4, pass with no blocking finding
- Run the benchmark review against main's recorded figures, pass with no blocking finding
- Run make spec-validate after archiving, 54 of 54 items pass

---

## Notes

This is part a of Facet wave 1 item 5: the terminal background query (OSC 11), swallowing its reply in the key decoder, choosing carat-light on a light reply and carat-dark on a dark or no reply, and keeping startup from waiting on it are queued as background-detect in `docs/queue-feature.md`, so until it lands the painted default is carat-dark on every terminal. Users who want the terminal's own background keep it with `option.background terminal`. The delta spec removes and re-adds the background requirement because openspec validate refuses a modified block that drops the Transparent by default scenario; that advisory is recorded in `docs/findings/background-default.md`.
