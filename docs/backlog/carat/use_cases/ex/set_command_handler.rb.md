# Backlog: carat/use_cases/ex/set_command_handler.rb

### :set leaves jumptab and gt at E518 while the other options are set
- Location: carat/use_cases/ex/set_command_handler.rb (NAMES), the queue entry's backlog heading ":set jumptab answers E518 while :set breadcrumbs answers Not implemented"
- Why: set-options handles breadcrumbs by :set now, so the heading's inconsistency is half answered: jumptab and gt, Carat's own options outside PENDING, still answer E518 where every other option of the editor is set or answers Not implemented.
- Fix: add jumptab and gt (and keyhints.delay, indentguides, indentguides.char, layout.*) to NAMES with their kinds; Options#problem and #assign already serve them, so only the table rows, the listing tests, and the compatibility rows are new.
- Category: editor
- Added: 2026-11-22

### :set theme and :set background still answer Not implemented
- Location: carat/use_cases/ex/set_command_handler.rb (PENDING), the queue entry's backlog heading ":set handles only filetype, syntax, the search options, and cursorline"
- Why: set-options answers the heading for every option but theme and background (bg), which the planner split into colorscheme-command, so the heading is only partly answered until that change lands.
- Fix: colorscheme-command moves theme and background into NAMES, repainting every group when either changes, as its queue entry says.
none
- Category: editor
- Added: 2026-11-22

### dead parameter: value_part(word, op) never reads op at carat/use_cases/ex/set_command_handler.rb:234 (sprint-26 review quality, note 5)

- Location: carat/use_cases/ex/set_command_handler.rb:234
- Why: dead parameter: value_part(word, op) never reads op
- Fix: drop the parameter and its argument at the call site in set_word (line 137)
- Category: editor
- Added: 2026-11-22

### character and byte offsets mixed: operator, name_part (227), and at carat/use_cases/ex/set_command_handler.rb:209 (sprint-26 review quality, note 6)

- Location: carat/use_cases/ex/set_command_handler.rb:209
- Why: character and byte offsets mixed: operator, name_part (227), and value_part (235) each call word.index("="), a character index, then pass it to getbyte and byteslice, which take byte offsets, so an unknown name with a multi-byte character before = puts a split UTF-8 sequence into the E518 message (line 135), and the same index is computed three times
- Fix: find the byte offset of = once with byteindex or a getbyte loop in set_word and pass it to the three helpers
- Category: editor
- Added: 2026-11-22

### fragile parallel tables: SHORT_NAMES is matched to NAMES only at carat/use_cases/ex/set_command_handler.rb:43 (sprint-26 review quality, note 7)

- Location: carat/use_cases/ex/set_command_handler.rb:43
- Why: fragile parallel tables: SHORT_NAMES is matched to NAMES only by position, with empty-string placeholders, so inserting an option into one array alone silently gives the wrong short names to every later option
- Fix: keep one table of full and short name pairs, or a short-to-full Hash beside NAMES
- Category: editor
- Added: 2026-11-22
