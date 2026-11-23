### A query wider than its float is cut, not scrolled
- Location: carat/use_cases/discovery/follow_palette.rb (query_row), carat/plugins/finder/plugin.rb (refresh), carat/adapters/frame_presenter.rb (place_cursor)
- Why: the query row shows the start of the text and the cursor stays on the float's last cell, so the tail of a long query is not visible; the command line scrolled nothing either, but it was a screen wide.
- Fix: show the tail of the text that fits before the cursor, with the leading cut marked, in the palette and the finder, and place the cursor at the cut text's end.
### The grep picker's title keeps its two-count form
- Location: carat/plugins/finder/plugin.rb (refresh, GREP_TITLE and Grep#counts)
- Why: the palette and the other pickers read `Name N/M`, the grep picker `Grep F of M files, L of N lines`, so the title form is not yet one for every picker.
- Fix: decide one count for the grep title (matching lines over lines read) with the files count moved to the border or dropped, with float-polish's title work.
