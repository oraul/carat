# Backlog: bin/carat.rb

## A raise while leaving the screen skips stopping the language servers

- Where: the `ensure` in `bin/carat.rb` line 41 runs `screen_presenter.leave` then `services.stop`. Periodic quality at e49f63d.
- Why it matters: a raise in `leave` leaves server processes running after the editor exits.
- Fix outline: stop the services even when leaving raises, with a case. Queue item: `lsp-client-tidy`.
- Category: editor
- Added: 2026-11-10
