### A project .caratrc can rebind a key only a plugin manifest binds
- Location: carat/domain/config.rb, held_keys (the held keys are read from the configuration's lines only)
- Why: a plugin's default bindings come from its manifest, applied to the keymap before the configuration, and Config never sees them, so a project file may unbind or rebind such a key; no shipped manifest binds a write, a quit, or the command line today, but a later plugin's could.
- Fix: hold the manifest bindings too, by passing the registry's keymap lines to Config before the project file is read, or by checking a project line against the built keymap in Keymap#add_checked with the same held rule.

### A project binding that starts with a held key takes that key
- Location: carat/domain/config.rb:323 (binding_problem, held-key check), security Low, confidence 7
- Why: The held-key check matches only the exact key, so a project .caratrc can take ':' by binding a longer sequence that starts with it: 'keymap.normal :w cursor.down' turns ':' into a match_prefix in HandleKey#step, a quickly typed ':w' runs the project's action, and other ':x' input is dropped. This breaks the promise that ':' still works, though it grants no write or program choice beyond rebinding other keys.
- Fix: In binding_problem, also refuse a project binding whose key codes start with a held key's codes, and one whose codes are a proper prefix of a held key's codes, compared per mode in held_key form (store the held code lists and compare with a prefix check). Add gateway tests for ':w' and '<leader>wx'.

### A project can bind an insert-mode key to open the command line or the palette
- Location: carat/domain/config.rb:49 (PROJECT_BINDABLE, the 'mode.' and 'palette.' families), security Low, confidence 5
- Why: The 'mode.' and 'palette.' families stay project-bindable in every mode, insert included, so a project can bind insert-mode <CR> to mode.cmdline or palette.open; the user's next typed line then becomes an ex command (:w PATH, :x) or a palette query that runs any action, refused writes, quits, and plugin actions included, when Enter is pressed. This was already possible before the change and needs the user to type matching text while the command line or palette shows.
- Fix: Remove OPEN_COMMAND_LINE and palette.open from PROJECT_BINDABLE outside the normal and visual modes, or refuse them in the insert, cmdline, and completion modes in binding_problem by checking line.name.

### Keys only a plugin manifest binds are never held (merges the two reports at config.rb:333 and :373 into the entry recorded earlier)
- Location: carat/domain/config.rb:333 and :373 (held_keys and the held_overlap check), security Low, confidence 6; a near-duplicate of the plugin-manifest held-key entry already in this file, reported twice by the review
- Why: held_keys reads only the configuration's lines, so a binding from a plugin manifest is never held, and a project .caratrc can unbind or rebind it, or bind keys around it past the overlap check. No shipped manifest binds a write, a quit, or the command line yet.
- Fix: Before the project file is read, pass the registry's manifest keymap lines to Config so they count toward the held keys and the held_overlap check, or apply the same held and overlap rule in Keymap#add_checked against the built keymap.

### A completion-mode project binding shadows a held insert-mode key while the popup shows
- Location: carat/domain/config.rb:347 (binding_problem, held and overlap checks per mode), security Low, confidence 5
- Why: The held and overlap checks compare keys within one mode only, but the completion layer answers before insert mode while the popup shows (HandleKey#complete); a project line such as 'keymap.completion <C-s> completion.close' is kept, so the user's held insert-mode <C-s> file.save closes the popup instead of saving.
- Fix: In binding_problem, refuse a completion-mode binding whose single key is held in insert mode, for example by also looking up held_key("insert", keys, leader) when line.name is "completion". Add a gateway test.

### A project can bind an insert-mode key to leave insert mode
- Location: carat/domain/config.rb:69 (PROMPT_MODES), security Low, confidence 4
- Why: PROMPT_MODES covers only the actions that open a prompt directly; a project can still bind an insert-mode key such as <CR> to mode.normal or another mode.* action, so the text the user types next runs as normal-mode commands, their own ':' and Enter or ZZ included (typing 'x:wq' after Enter writes and quits). Less direct than the fixed case and already possible before this change.
- Fix: Refuse mode.* actions other than the insert-entry ones in the insert, replace, and completion modes, or limit project insert-mode bindings to keys outside the printable range and <CR>. Add a gateway test for 'keymap.insert <CR> mode.normal'.
none
