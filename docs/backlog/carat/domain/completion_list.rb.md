# Backlog: carat/domain/completion_list.rb

## CompletionList#add returns a bool nobody reads

- Where: `carat/domain/completion_list.rb` line 21 (`add`), the `add` exemption in `test/lint.rb` line 222, which `BOOL_COMMANDS` gives for `FloatLayer`, and the caller `carat/adapters/json_rpc_language_gateway.rb` line 595, which re-checks `LIMIT` at line 592, at 31919d9. Periodic quality at cd87445 and 847851d. Queue item `completion-tidy`.
- Why it matters: an unread result invites a caller to rely on it and hides behind an exemption whose reason is about floats.
- Fix outline: break on a false `add` and drop the gateway's check, or make `add` return nothing, and word the exemption for what remains.
- Also: test/lint.rb, carat/adapters/json_rpc_language_gateway.rb
- Category: ide
- Added: 2026-11-07
