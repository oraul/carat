# Backlog: carat/use_cases/handle_key.rb

## A lone prefix of a user binding waits with no time limit

- Where: `HandleKey` in `carat/use_cases/handle_key.rb` (line 165 answers `:waiting` for every `:prefix` in a grammar mode), and `InputController#handle`, which sets no deadline then; `timeoutlen` (`config/default.caratrc` line 28) no longer applies there. Advisory of the periodic quality review at 66fd52b, left by `window-navigation-and-scroll`.
- Why it matters: Neovim waits without a limit only on its built-in multi-key commands and times user mappings out, so a configuration binding such as `<leader>x` with `<leader>` alone bound to nothing never resolves on its own here.
- Fix outline: mark the keymap trie nodes that only configuration-origin (user and project) bindings pass through, and have `HandleKey` answer `:pending` for such a prefix so `timeoutlen` applies, with a row in `test/editor_normal.rb`.
- Also: config/default.caratrc, test/editor_normal.rb
- Category: editor
- Added: 2026-11-03

## Resuming a pattern prompt resets the mode a second time

- Where: `HandleKey#resume` in `carat/use_cases/handle_key.rb` (line 215), which sets the mode to normal outside visual although `CancelCommandLine` and `ExecuteCommandLine` already restored the prompt's return mode. Quality advisory of `buffer-search` at 2b54295641e0 and again at a36858a2bc88.
- Why it matters: two places decide the mode after the prompt, so a change to the return mode of the prompt has to be made in both or the second one overrides it.
- Fix outline: drop the line and keep the return mode the command line restores, checked by the existing `editor_search` rows. Queued in `search-structure`.
- Category: editor
- Added: 2026-11-04

## HandleKey#step discards the queue dispatch returns

- Where: `step` in `carat/use_cases/handle_key.rb` (line 172 at `leader-layout`) ignores the queue `dispatch` returns, though `dispatch`'s comment says the caller assigns it; it works only because `call`'s queue starts as the one key. Quality advisory of `leader-layout`.
- Why it matters: the two call sites follow different rules, so a later change to the queue in `step` can silently drop or replay keys.
- Fix outline: assign the result in `step` too, or narrow the comment to the timeout path.
- Raised again as "HandleKey drops the queue dispatch returns": Where: `carat/use_cases/handle_key.rb:247` (`step`) and :272 (`complete`), against dispatch's contract at :278-280. Periodic quality at bd86828. Why it matters: the contract exists because the pinned Spinel can lose appends to the caller's array; `step` relies on in-place mutation anyway. Fix outline: honor the contract or drop it, with a test that fails without the fix. Queue item `spinel-workarounds`.
- Category: editor
- Added: 2026-11-05

## A multi-key keymap.completion line loads and never fires

- Where: `completion_key?` in `carat/use_cases/handle_key.rb` (line 201 at 334d899) answers only a single-key `:match`, while `Keymap#add_checked` accepts any `keymap.completion` line. Quality advisory in `completion`.
- Why it matters: a multi-key completion binding, or a single key that also starts a longer one, loads with no reported problem and silently does nothing, against the rule that every configuration problem is reported as `file:line: message`.
- Fix outline: report such `keymap.completion` lines as `file:line` problems in `add_checked`, with a configuration test row.
- Category: editor
- Added: 2026-11-07

## The completion layer is looked up twice per key and ShowCompletion runs twice per typed character

- Where: `carat/use_cases/handle_key.rb` line 166 at cd87445 (`completion_key?` at line 201, then `complete` at line 208, each allocating `[code]`; `insert_literal` line 313, then `call` line 102). Periodic quality at cd87445, again after 5722559.
- Why it matters: two lookups and two popup refreshes per key on the insert hot path, the line sliced twice.
- Fix outline: look up once and dispatch that match; run ShowCompletion once per key, and ShowCompletionDocs with it, which `completion-docs` added beside it and which also runs twice per typed character (quality advisory in `completion-docs` at `carat/use_cases/completion/show_completion.rb` line 72 at 925d759). Queued in `completion-tidy`.
- Also: carat/use_cases/completion/show_completion.rb
- Category: editor
- Added: 2026-11-07

## The signature request is passed beside the use case that holds it

- Where: the `signature:` keyword of `HandleKey` in `carat/use_cases/handle_key.rb` line 88 and of `InputController` in `carat/adapters/input_controller.rb` line 48 at c59a43d, while the same constructors read the hover request from its use case (`follow_hover.hover`, `show_hover.hover`). Quality advisory in `parameter-info`.
- Why it matters: two ways to reach the same kind of shared request in one constructor, so a reader cannot tell which is the rule; the hover entry above asks the opposite direction for hover, so both should end the same way.
- Fix outline: settle one way for hover and signature together: either drop the `signature:` keywords and read `follow_signature.signature` and `show_signature.signature`, removing their two assembly rows, or pass both requests from `EditorAssembly` as the hover entry proposes.
- Also: carat/adapters/input_controller.rb
- Category: editor
- Added: 2026-11-07

## The signature trigger tests bare key codes

- Where: `carat/use_cases/handle_key.rb` line 336 at c1b3a12. Queued in `signature-tidy`.
- Why it matters: codes 40 and 44 hide the characters the text already holds.
- Fix outline: compare the text with ( and , directly.
- Category: editor
- Added: 2026-11-09

## HandleKey takes the definition record beside its follower

- Where: `carat/use_cases/handle_key.rb` lines 105 to 129 at fafe59c, which take both `definition:` and `follow_definition:`, where the hover is read as `follow_hover.hover`. Quality advisories in `definitions`.
- Why it matters: the extra keyword duplicates wiring the follower already holds and widens the constructor and `EditorAssembly`'s call.
- Fix outline: set `@definition = follow_definition.definition` and drop the keyword from `HandleKey` and `EditorAssembly`, keeping `test/adapters_assembly.rb`'s shared-instance check.
- Also: test/adapters_assembly.rb
- Category: editor
- Added: 2026-11-10

## Signature help compares bare key codes

- Where: `carat/use_cases/handle_key.rb` line 364, the literals 40 and 44 for `(` and `,`. Periodic quality at 8d8832f, queued in `signature-tidy`. Raised again at ce6abdb (line 379; periodic quality): a private constant beside `MAX_REPLAYS`, membership tested there.
- Why it matters: bare codes hide which characters trigger signature help.
- Fix outline: name them as key constants or compare the character.
- Category: editor
- Added: 2026-11-10

## HandleKey reaches the plugin UI through the plugins

- Where: `carat/use_cases/handle_key.rb` line 117, which takes the shared `PluginUi` through `plugins.plugin_ui` instead of a `plugin_ui:` keyword from `EditorAssembly`, and keeps it with no reader. Quality review of `file-finder`.
- Why it matters: unlike `palette:`, `signature:`, and the other shared records, `test/adapters_assembly.rb` cannot check that `HandleKey` holds the one instance.
- Fix outline: pass `plugin_ui:` from `EditorAssembly`, add a reader, and check it in `test/adapters_assembly.rb`.
- Also: test/adapters_assembly.rb
- Category: editor
- Added: 2026-11-10

## menu-hints quality advisory at carat/use_cases/handle_key.rb:145

Location: `carat/use_cases/handle_key.rb:145`. Why: one way to do each thing; `HandleKey` still guards with `@key_hints.showing?` before `HideKeyHints#call`, which checks `showing?` itself, while `ShowKeyHints` now calls it with no guard. Fix outline: call `@hide_key_hints.call(state)` without the guard, so the check lives only in `HideKeyHints`.
- Category: editor
- Added: 2026-11-14

### The timeout path's magic numbers and dead clear

- Location: carat/use_cases/handle_key.rb:378 and :224 (sprint-4 sweep, quality advisory).
- Why: `code == 40 || code == 44` spells ( and , as numbers; clear_message inside the list_message? branch repeats the unconditional call at :227.
- Fix: named constants; drop the inner call.
- Category: editor
- Added: 2026-11-14

### A broken key sequence drops a bound shorter prefix

- Location: carat/use_cases/handle_key.rb:253, the timeout comment at :166. Sprint-6 sweep, quality. Queue item `input-core-tidy`.
- Why: when pending keys stop matching, or time out at a prefix, every pending key is dropped even when a shorter prefix is bound (with `a` bound beside `abc`, typing `abx` loses the `a` action), where Vim fires the longest bound prefix and replays the rest.
- Fix outline: dispatch the longest bound prefix and push the remaining keys back on the queue, with a table test in test/editor_leader.rb.
- Also: test/editor_leader.rb
- Category: editor
- Added: 2026-11-15

### Timeout follow-ups beyond hover have no test

- Location: `carat/use_cases/handle_key.rb:198` (the timeout path) and `test/editor_leader.rb`.
- Why: the timeout now also runs the completion, definition, and palette follow-ups, but only the hover follow-up has a test, so a regression in the others would pass; quality advisory from core-correctness.
- Fix: add a timeout row in which a resolved binding closes or refreshes the completion menu or the palette.
- Also: test/editor_leader.rb
- Category: editor
- Added: 2026-11-15

### HandleKey's step and complete drop the queue dispatch returns
- Location: carat/use_cases/handle_key.rb:252, :277 (dispatch 281-286)
- Why: dispatch says the caller assigns its returned queue because of the open Spinel pitfall on appends to a passed empty array; a remap reached in timeout's step loop, whose queue began as a [] literal, may lose its keys. Folded into input-core-tidy.
- Fix: keep the replay queue in one instance field cleared per call and timeout.
- Category: editor
- Added: 2026-11-17

### HandleKey clears a message twice and uses bare codes

- Location: carat/use_cases/handle_key.rb:230, :384 (sweep, quality).
- Why: the list_message? branch clears a message line 233 clears anyway; :384 uses the bare codes 40 and 44 for ( and ,.
- Fix outline: drop the first clear and name the two codes.
- Category: editor
- Added: 2026-11-17

### The signature trigger compares bare key codes (sprint-16 sweep quality)

- Location: carat/use_cases/handle_key.rb:384 (code == 40 || code == 44).
- Why: magic numbers for ( and , hide what triggers parameter info.
- Fix outline: name them as constants in Key or as private constants.
- Category: editor
- Added: 2026-11-18

### HandleKey's queue rule and signature triggers (sprint-18 sweep quality)
- Location: `carat/use_cases/handle_key.rb:259`, `:284`, `:391`.
- Why it matters: `dispatch` says its caller must assign the returned queue, yet `step` and `complete` discard it; `code == 40 || code == 44` are unnamed.
- Fix outline: state the rule once and apply it, or narrow the comment; named constants for ( and ,.
- Category: editor
- Added: 2026-11-18

### The clear_message inside the list_message? branch is redundant (sprint-20 sweep quality, handle_key.rb:237)

- Location: `carat/use_cases/handle_key.rb:237`
- Why: the clear_message inside the list_message? branch is redundant: line 240 clears the message unconditionally
- Fix: keep only the early return for CR and Space in that branch
- Merged: ### Step calls state.clear_message twice when a list message shows (sprint-20 sweep quality, handle_key.rb:237)
- Location: `carat/use_cases/handle_key.rb:237`
- Why: step calls state.clear_message twice when a list message shows (lines 237 and 240)
- Fix: drop the first call and keep the early return for CR and Space
- Category: editor
- Added: 2026-11-19

### The signature trigger compares code with the bare numbers 40 and 44 (sprint-20 sweep quality, handle_key.rb:391)

- Location: `carat/use_cases/handle_key.rb:391`
- Why: the signature trigger compares code with the bare numbers 40 and 44
- Fix: name them (a private SIGNATURE_TRIGGERS constant or Key constants for ( and ,)
- Merged: ### The magic numbers 40 and 44 stand for (sprint-20 sweep quality, handle_key.rb:391)
- Location: `carat/use_cases/handle_key.rb:391`
- Why: the magic numbers 40 and 44 stand for ( and ,
- Fix: name them (a private_constant list of signature trigger codes) as the comment above describes them
- Category: editor
- Added: 2026-11-19

### carat/use_cases/handle_key.rb:259: step (and complete at :284) drops the queue dispatch (sprint-22 sweep quality)

- Location: `carat/use_cases/handle_key.rb:259`
- Why: step (and complete at :284) drops the queue dispatch returns, while the comment at :288-292 says the caller must assign it because Spinel loses appends to an array created as []; timeout and dispatch itself assign it
- Fix: assign queue = dispatch(...) in step and complete (or reword the contract to say when in-place is safe) so the three callers agree
- Category: editor
- Added: 2026-11-20

### carat/use_cases/handle_key.rb:237: dead code: the clear_message inside the list_message? branch is (sprint-22 sweep quality)

- Location: `carat/use_cases/handle_key.rb:237`
- Why: dead code: the clear_message inside the list_message? branch is repeated unconditionally at :240
- Fix: keep only the early return in the branch
- Category: editor
- Added: 2026-11-20

### carat/use_cases/handle_key.rb:391: magic numbers 40 and 44 for the signature triggers (sprint-22 sweep quality)

- Location: `carat/use_cases/handle_key.rb:391`
- Why: magic numbers 40 and 44 for the signature triggers ( and ,
- Fix: name them (Key constants or a private SIGNATURE_TRIGGERS) as Key::CR and Key::SPACE are named
- Category: editor
- Added: 2026-11-20

### HandleKey#step drops the queue dispatch returns (sprint-24 sweep quality)

- Location: `carat/use_cases/handle_key.rb:259`, `:290`
- Why: dispatch's comment says the caller must assign the returned queue because appends on the pinned Spinel are lost, while step discards it and replay mutates in place.
- Fix: settle one contract, timeout's path included, and make the comment match.
- Category: editor
- Added: 2026-11-21

### HandleKey clears the message twice and compares bare key codes (sprint-24 sweep quality)

- Location: `carat/use_cases/handle_key.rb:236`, `:391`
- Why: the list-message path calls `state.clear_message` twice, and line 391 compares with bare 40 and 44.
- Fix: clear once and name the `(` and `,` codes as constants.
- Category: editor
- Added: 2026-11-21

### step clears the message inside the list_message? branch and at carat/use_cases/handle_key.rb:253 (sprint-26 sweep quality, note 5)

- Location: carat/use_cases/handle_key.rb:253
- Why: step clears the message inside the list_message? branch and again on the next line, so the inner clear_message is dead
- Fix: drop the inner call and keep the early return
- Category: editor
- Added: 2026-11-22

### step and complete drop the queue dispatch returns at carat/use_cases/handle_key.rb:275 (sprint-28 sweep quality, note 3)

- Location: carat/use_cases/handle_key.rb:275, :300, :306; docs/spinel-notes.md
- Why: dispatch says its caller must assign the returned queue because appends to an array created as [] can be lost on the pinned Spinel, and the cited pitfall is not in docs/spinel-notes.md; a remap replayed after a timeout relies on the in-place unshift.
- Fix: a test of a key-sequence binding that replays another after a timeout, then thread the queue through step or correct the comment and add the pitfall.
- Also: docs/spinel-notes.md
- Category: editor
- Added: 2026-11-22

### Bare byte literals 40 and 44 at carat/use_cases/handle_key.rb:407 (sprint-28 sweep quality, note 4)

- Location: carat/use_cases/handle_key.rb:407
- Why: 40 and 44 stand for `(` and `,` with no name.
- Fix: private constants or Key constants.
- Category: editor
- Added: 2026-11-22
- Merged: ### the signature triggers are the bare code points 40 at carat/use_cases/handle_key.rb:407 (sprint-26 sweep quality, note 6)
- Location: carat/use_cases/handle_key.rb:407
- Why: the signature triggers are the bare code points 40 and 44, and options.rb:234, :495, :504 scan listchars for bare 44 and 58, where Key names CR and SPACE and RcParser names NEWLINE
- Fix: name the bytes (OPEN_PAREN, COMMA, COLON) beside the existing constants

### Pasted text in normal and the other modes does nothing
- Location: carat/use_cases/handle_key.rb, paste.
- Why: Neovim puts pasted text in at the cursor in normal mode, and in the visual modes replaces the selection; here the paste is ignored outside insert mode and the command line, which is safe but a missing feature.
- Fix: add a paste use case that puts the text as a charwise put after the cursor in normal mode and replaces the selection in the visual modes, called from paste for those modes.
- Category: editor
- Added: 2026-11-23

### a pasted newline in insert mode goes through call(state at carat/use_cases/handle_key.rb:186 (sprint-30 sweep quality, blocking, note 5)

- Location: carat/use_cases/handle_key.rb:186
- Why: blocking quality finding of the sprint-30 whole-tree review: a pasted newline in insert mode goes through call(state, Key::CR), so it is looked up in the keymaps: with the completion popup showing, step (line 281) runs the completion layer binding (default keymap.completion <CR> completion.insert) and inserts the selected candidate instead of breaking the line, and a user keymap.insert <CR> remap applies too, against the key-input spec (a pasted code is never looked up in a keymap); no test pastes with the popup open
- Fix: break the line through the insert.newline handler or BreakLine directly (closing the popup first) and add an editor_insert row pasting x, a newline, and y with the popup shown
- Category: editor
- Added: 2026-11-23

### paste drops the Outcome of InsertText, which insert_literal reports at carat/use_cases/handle_key.rb:187 (sprint-30 sweep quality, note 6)

- Location: carat/use_cases/handle_key.rb:187
- Why: paste drops the Outcome of InsertText, which insert_literal reports, so a refused paste (a buffer that cannot be modified) shows no message
- Fix: report(state, @insert_text.call(...)) as insert_literal does, or share one helper with insert_literal
- Category: editor
- Added: 2026-11-23

### a pasted code skips the pending keys: a typed at carat/use_cases/handle_key.rb:160 (sprint-30 sweep quality, note 7)

- Location: carat/use_cases/handle_key.rb:160
- Why: a pasted code skips the pending keys: a typed prefix of a multi-key insert or cmdline binding (a user jk) stays pending and is inserted by the timeout after the pasted text, reversing the order
- Fix: resolve the pending keys (timeout) before the first pasted code, with a test
- Category: editor
- Added: 2026-11-23

### paste does nothing in replace mode, where Neovim overwrites at carat/use_cases/handle_key.rb:182 (sprint-30 sweep quality, note 8)

- Location: carat/use_cases/handle_key.rb:182
- Why: paste does nothing in replace mode, where Neovim overwrites with the pasted text, and docs/compatibility.md does not say so
- Fix: paste through the replace path in Mode::REPLACE or record the gap in the compatibility row
- Also: docs/compatibility.md
- Category: editor
- Added: 2026-11-23

### step clears the message twice (inside the list_message? branch at carat/use_cases/handle_key.rb:276 (sprint-30 sweep quality, note 9)

- Location: carat/use_cases/handle_key.rb:276
- Why: step clears the message twice (inside the list_message? branch and again at line 279)
- Fix: one state.clear_message before the CR and Space check
- Category: editor
- Added: 2026-11-23

### the signature trigger compares key codes with the bare numbers at carat/use_cases/handle_key.rb:430 (sprint-32 sweep quality, note 11)
- Location: carat/use_cases/handle_key.rb:430
- Why: the signature trigger compares key codes with the bare numbers 40 and 44 for ( and ,
- Fix: private constants OPEN_PAREN and COMMA, as MAX_REPLAYS is
- Category: quality
