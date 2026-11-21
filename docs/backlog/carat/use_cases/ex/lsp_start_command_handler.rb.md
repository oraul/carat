# Backlog: carat/use_cases/ex/lsp_start_command_handler.rb

## LspStart and LspRestart handlers are copies

- Where: `carat/use_cases/ex/lsp_start_command_handler.rb` line 25 and `lsp_restart_command_handler.rb` line 65 at cd87445, differing only in `start` or `restart`. Periodic quality at cd87445; the restart half is the entry on `LanguageServer#words`.
- Why it matters: a fix to one command misses the other.
- Fix outline: one handler with a start and a restart variant registered twice, as CompletionHandler does. Queued in `lsp-client-tidy`.
- Category: ide
- Added: 2026-11-07
