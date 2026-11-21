# Backlog: test/adapters_language_gateway.rb

### No replayed incremental sync row over a CRLF buffer
- Location: test/adapters_language_gateway.rb:112
- Why: no replayed row covers a CRLF buffer under sync kind 2, though the design relies on ranges joined with the buffer's own ending staying right.
- Fix: add a replayed row over a CRLF file to the sync kind 2 table.
- Category: ide
- Added: 2026-11-17

### The gateway test's synced helper repeats in_dir and ready_with
- Location: test/adapters_language_gateway.rb:67 and :23
- Why: synced repeats in_dir with another file text, then ready_with's open and initialize steps.
- Fix: give in_dir a text parameter and build synced from it plus ready_with's steps.
- Category: ide
- Added: 2026-11-17
