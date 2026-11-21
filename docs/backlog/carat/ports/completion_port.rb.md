# Backlog: carat/ports/completion_port.rb

## CompletionPort carries the server source's request record

- Where: `carat/ports/completion_port.rb` line 29 at cd87445 (`request`), `carat/doubles/fixed_completions.rb` line 50, and `carat/adapters/server_completions.rb` line 23, which builds the shared `Domain::CompletionRequest`. Periodic quality at cd87445; related to the entry on the input controller reaching through ShowCompletion.
- Why it matters: the double carries a record nobody fills, and the one shared record is built inside an adapter instead of once beside the other shared objects.
- Fix outline: build the record once at the composition root, keep it in an assembly reader for its users, and drop it from the port; `completion-docs` deepened it, since `ShowCompletion` (`carat/use_cases/completion/show_completion.rb` line 72 at 925d759) and `InputController` now read `request.docs`, so move the documentation state out of the server record with it. Queued in `completion-tidy`.
- Also: carat/doubles/fixed_completions.rb, carat/adapters/server_completions.rb, carat/use_cases/completion/show_completion.rb
- Category: ide
- Added: 2026-11-07
