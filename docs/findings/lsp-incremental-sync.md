### Incremental sync misses a reload that only changes the line ending
- Location: carat/adapters/json_rpc_language_gateway.rb:1356
- Why: an :e! reload that only changes the line ending (OpenFile sets line_ending, open_file.rb:60) leaves the stored lines equal, so under sync kind 2 nothing is sent and the server keeps the old terminators, mixed after later ranged edits (positions stay right).
- Fix: store the line ending sent beside the remembered texts and replace the whole document when it changed.

### No replayed incremental sync row over a CRLF buffer
- Location: test/adapters_language_gateway.rb:112
- Why: no replayed row covers a CRLF buffer under sync kind 2, though the design relies on ranges joined with the buffer's own ending staying right.
- Fix: add a replayed row over a CRLF file to the sync kind 2 table.
