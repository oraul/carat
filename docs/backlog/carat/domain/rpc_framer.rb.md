# Backlog: carat/domain/rpc_framer.rb

## spinel-rebump quality advisory at carat/domain/rpc_framer.rb:68

Tests beside every behavior change: only the header-line loop (line 106) is tested; the `read_header` search from `@start` on a continuation byte, the one in the language-server reader thread, has no row, so a regression there would raise in the reader thread unseen. Fix outline: add a framer row whose second frame's header starts with 0x80 right after the first body.
- Category: editor
- Added: 2026-11-14
