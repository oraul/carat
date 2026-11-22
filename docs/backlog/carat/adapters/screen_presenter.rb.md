# Backlog: carat/adapters/screen_presenter.rb

### Bracketed paste is never enabled (sprint-14 sweep security Low (5))

- Location: carat/adapters/screen_presenter.rb:30.
- Why: pasted text holding an ESC byte leaves insert mode and the rest runs as normal-mode and ex commands (for example :w! over another file).
- Fix outline: enable bracketed paste on enter and disable it on leave, read the pasted text as literal input, test a paste holding ESC and a colon. Queued in `input-core-tidy`.
- Category: security
- Added: 2026-11-17

### the constructor derives its palette name from theme.name and at carat/adapters/screen_presenter.rb:64 (sprint-26 sweep quality, note 37)

- Location: carat/adapters/screen_presenter.rb:64
- Why: the constructor derives its palette name from theme.name and its background word from paints_background? mapped to theme or terminal, while use_theme (:95) compares the option words, agreeing only because Themes::BACKGROUNDS is exactly those two words and find keeps a known name
- Fix: take theme_name: and background: words in the constructor (EditorAssembly has them) so both paths compare the same values
- Category: editor
- Added: 2026-11-22

### the constructor rebuilds the background word from theme.paints_background? and at carat/adapters/screen_presenter.rb:65 (sprint-26 sweep quality, note 52)

- Location: carat/adapters/screen_presenter.rb:65
- Why: the constructor rebuilds the background word from theme.paints_background? and takes the theme name from the found theme, a second way to set the palette beside use_theme that mirrors Themes.find's "theme" rule
- Fix: construct with the options' theme and background words (or have the constructor call use_theme) so one method decides the table
- Category: editor
- Added: 2026-11-22
