## Context

The finder lists files once per open and filters paths with `Matcher`. A content search needs file text, which a plugin reads only through `read_file` (first 1000 lines of a file up to 256 KiB, line endings removed), and a way to place the cursor, which `move_cursor` gives after any open request.

## Decisions

- One picker, two modes: `plugin.finder.grep` sets a flag on the existing plugin so the prompt, floats, highlight, and picks are shared; `Grep` holds the stored lines and the search, `Plugin` the wiring.
- Reading happens once at open, never per key, and the grep picker shows no preview, so typing reads nothing. Lines are stored flat (file index, line number, text) with a 100,000 line cap that also keeps the line index within `Matcher.key`'s 20 bits.
- Scoring reuses Matcher on the line from byte 0 with `Matcher.span_score`, so a line holding a slash gets no file-name bonus, and `Matcher.key` with the path's length, so equal scores order by shorter path then listing order.
- The column is the first byte of the line that equals the query's first byte, a simple stand-in for the match start, converted to characters because `move_cursor` takes a character column.
- `move_cursor` follows the open call; open requests make the opened window current, so it moves the right cursor.

## Risks

- Reading every file at open is synchronous and costs more in a large tree; the 100,000 line cap bounds it, and streaming is left to later work.
