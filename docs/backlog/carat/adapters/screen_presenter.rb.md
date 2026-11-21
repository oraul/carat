# Backlog: carat/adapters/screen_presenter.rb

### Bracketed paste is never enabled (sprint-14 sweep security Low (5))

- Location: carat/adapters/screen_presenter.rb:30.
- Why: pasted text holding an ESC byte leaves insert mode and the rest runs as normal-mode and ex commands (for example :w! over another file).
- Fix outline: enable bracketed paste on enter and disable it on leave, read the pasted text as literal input, test a paste holding ESC and a colon. Queued in `input-core-tidy`.
- Category: security
- Added: 2026-11-17
