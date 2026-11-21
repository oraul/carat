### :set leaves jumptab and gt at E518 while the other options are set
- Location: carat/use_cases/ex/set_command_handler.rb (NAMES), the queue entry's backlog heading ":set jumptab answers E518 while :set breadcrumbs answers Not implemented"
- Why: set-options handles breadcrumbs by :set now, so the heading's inconsistency is half answered: jumptab and gt, Carat's own options outside PENDING, still answer E518 where every other option of the editor is set or answers Not implemented.
- Fix: add jumptab and gt (and keyhints.delay, indentguides, indentguides.char, layout.*) to NAMES with their kinds; Options#problem and #assign already serve them, so only the table rows, the listing tests, and the compatibility rows are new.

### wrap and clipboard are still accepted and dropped by the configuration
- Location: carat/domain/options.rb (KINDS, assign), the queue entry's backlog heading "Two shipped options are accepted and dropped, and Config settings are untyped"
- Why: set-options split apply into problem and assign but left wrap and clipboard as kinds with no member, so a line setting them is checked and dropped silently, and :set answers E518 for them; the heading's problem is unchanged.
- Fix: either drop the two names from KINDS (a line then reports unknown option) or give them members when a change reads them; config-guards-b in the backlog lane names them.

### :set theme and :set background still answer Not implemented
- Location: carat/use_cases/ex/set_command_handler.rb (PENDING), the queue entry's backlog heading ":set handles only filetype, syntax, the search options, and cursorline"
- Why: set-options answers the heading for every option but theme and background (bg), which the planner split into colorscheme-command, so the heading is only partly answered until that change lands.
- Fix: colorscheme-command moves theme and background into NAMES, repainting every group when either changes, as its queue entry says.
