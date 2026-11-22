# Backlog: carat/adapters/json_rpc_language_gateway.rb

## Completion text edits ignore their range

- Where: `candidate_of` in `carat/adapters/json_rpc_language_gateway.rb` (line 519 at 376d264), which takes `textEdit.newText` and drops the edit's range, while the menu replaces only the word from `FuzzyMatch.word_start`. Quality advisory in `completion-request`; the design leaves range edits out of scope.
- Why it matters: an edit whose range starts before the word, such as ruby-lsp's `@ivar` or `Foo::Bar` constant edits, inserts `@@foo` or `Foo::Foo::Bar`.
- Fix outline: use `newText` only when the edit's range starts at the word's start column (else `insertText`, else the label) now; later carry the range in `CompletionItem` and apply it through the `Buffer` primitives, with gateway and editor rows for both edits.
- Category: ide
- Added: 2026-11-07

## An incomplete completion answer is never asked again

- Where: `completed` in `carat/adapters/json_rpc_language_gateway.rb` (line 492 at 376d264), which ignores `isIncomplete` and keeps the first `CompletionList::LIMIT` items, and `answer_for?`, which serves that list to every longer word at the same start. Quality advisory in `completion-request`; the design's non-goal.
- Why it matters: a match outside the first 200 items of an incomplete answer is never offered, however much more of the word is typed.
- Fix outline: record `isIncomplete` in `Domain::CompletionRequest` and ask again when the typed part grows past an incomplete answer, with a gateway row.
- Category: ide
- Added: 2026-11-07

## The typed part before the cursor is computed twice

- Where: `carat/adapters/json_rpc_language_gateway.rb` (line 463 at 376d264) repeats `ShowCompletion`'s slice, `word_start`, `byteslice`, and `col - length` (`carat/use_cases/completion/show_completion.rb`, lines 74 to 77), and `carat/use_cases/completion/complete_word.rb` line 47 at 8d8832f is a third copy. Quality advisory in `completion-request` and `word-completion`.
- Why it matters: a change to how the word is found must be made in all three places or the request and the menu disagree on the word.
- Fix outline: one domain helper (for example in `FuzzyMatch`) answering the typed part and its start column before a column, used by both, with a table row.
- Also: carat/use_cases/completion/show_completion.rb, carat/use_cases/completion/complete_word.rb
- Category: ide
- Added: 2026-11-07

## Completion-request style and docs advisories

- Where: the `result.is_a?(Hash)` guards of `initialized` in `carat/adapters/json_rpc_language_gateway.rb` (lines 417 and 423 at 376d264); the comment of `complete` in the same file (line 441) and the class comment of `carat/doubles/fixed_completions.rb` (line 10), each with a line past the file's wrap; `until_sent` in `test/adapters_server_completions.rb` (line 263), which returns at once because the first request is already sent; the `LanguageServicePort` row of `docs/architecture.md` (line 204), which omits `start`. Quality advisories in `completion-request`.
- Why it matters: `receive` now crashes the server unless the result is a Hash, so the guards are dead and mislead; the long lines break the files' wrap; the test's wait is a no-op and the `10.times` fallback does the waiting; the architecture row disagrees with the port and the map.
- Fix outline: read `result["serverInfo"]` and `result["capabilities"]` directly; rewrap both comment paragraphs; wait until `count_of` reaches 2 with a bounded helper and drop the no-op call; add `start(state)` to the row.
- Also: carat/doubles/fixed_completions.rb, test/adapters_server_completions.rb, docs/architecture.md
- Category: ide
- Added: 2026-11-07

## The completion resolve timeout restarts with every pick

- Where: `carat/adapters/json_rpc_language_gateway.rb` line 562 at 925d759 (558 at d46ecff), which measures the resolve timeout from `docs.due`, which a new pick resets. Quality advisory in `completion-docs`, raised again at d46ecff. At c1b3a12 the cursor's screen row is recomputed at seven sites (periodic note at `carat/use_cases/completion/show_completion.rb` line 167), the hover and signature floats included.
- Why it matters: every new pick during the flight moves `docs.due` forward, so a server that never answers is not cancelled while the selection keeps moving.
- Fix outline: keep the send time (or a deadline) of the request in flight and time it out from that, with a case in `test/adapters_server_completions.rb` that keeps moving the selection. Queued in `completion-docs-tidy`.
- Also: carat/use_cases/completion/show_completion.rb, test/adapters_server_completions.rb
- Category: ide
- Added: 2026-11-07

## The gateway repeats the markdown size limit as a literal

- Where: `DOCUMENT_LIMIT` in `carat/adapters/json_rpc_language_gateway.rb` line 60 at 925d759 repeats `MarkdownText::RAW_LIMIT` (16_384). Quality advisory in `completion-docs`.
- Why it matters: two literals for one bound drift apart when one is changed.
- Fix outline: use `Domain::MarkdownText::RAW_LIMIT` in the gateway, or say in a comment why the two differ. Queued in `completion-docs-tidy`.
- Category: ide
- Added: 2026-11-07

## Completion resolve state outlives a switch of completion language

- Where: `complete` in `carat/adapters/json_rpc_language_gateway.rb` line 498 at d46ecff, which sets `ask.language` to the new request's server but leaves `@items` and `docs` alone, and `resolve`, `cancel_resolve`, and the answer match (lines 552 to 558), which read `@completion.language`. Low (3) finding of the security review of `completion-docs`, and a quality advisory there.
- Why it matters: after a completion request for a file of another type, a pending pick can send server A's raw completion item to server B as `completionItem/resolve`, the `$/cancelRequest` for A's request id reaches B, and A's real answer is dropped; a minor cross-server leak between servers that can already read the workspace, plus a misrouted cancel.
- Fix outline: record the answer's language in `CompletionDocs` in `completed` and use it for `resolve`, `cancel_resolve`, and the answer match, or call `cancel_resolve` then clear `docs` and `@items` in `complete` before `ask.language` changes; add a case in `test/adapters_server_completions.rb` that completes in two file types with a resolve in flight. Queued in `completion-docs-tidy`.
- Also: test/adapters_server_completions.rb
- Category: security
- Added: 2026-11-07

## A server crash during a resolve has no test

- Where: `forget_completion` in `carat/adapters/json_rpc_language_gateway.rb` line 455 at d46ecff, which now resets `docs.sent_id` and drops the language from `@resolvers`. Quality advisory in `completion-docs`.
- Why it matters: the crash path of the resolve flow can regress, leaving `waiting?` true or sending a resolve to a restarted server, without a test failing.
- Fix outline: in `test/adapters_server_completions.rb`, crash the server while a resolve is in flight and assert `waiting?` is false and no resolve is sent after. Queued in `completion-docs-tidy`.
- Also: test/adapters_server_completions.rb
- Category: ide
- Added: 2026-11-07

## Plaintext hover text is read as markdown

- Where: the MarkupContent reader in `carat/adapters/json_rpc_language_gateway.rb` line 706 at 78078ad. Quality advisory in `quick-docs`.
- Why it matters: a MarkupContent of kind `plaintext` is passed to `MarkdownText` as markdown, so underscores, asterisks, and backslashes in plain hover text (identifiers such as `snake_case_name`) are taken as markup; the client advertises `plaintext`, so a server may answer with it.
- Fix outline: wrap a `plaintext` value in a fence before `MarkdownText` reads it, with a row in the hover contents table.
- Category: ide
- Added: 2026-11-07

## The hover poll keeps a return that never fires

- Where: `return if ask.sent == ask.want` in `carat/adapters/json_rpc_language_gateway.rb` line 646 at 41297d6. Quality advisory in `quick-docs`.
- Why it matters: after the in-flight block the equal case has already returned, so the line is dead and suggests a path the poll does not have.
- Fix outline: drop the line, with the hover rows of `test/adapters_hover.rb` unchanged.
- Also: test/adapters_hover.rb
- Category: ide
- Added: 2026-11-07

## The signature gateway's forget and activeSignature paths are untested

- Where: `forget_server` (the signature ask, `forget_signature` before periodic-blockers-a; line 526 at d73f03f) in `carat/adapters/json_rpc_language_gateway.rb` (dropping the language and the request in flight on a crash, `:LspStop`, or `:LspRestart`) and the in-range `activeSignature` choice at line 818, at c59a43d. Quality advisory in `parameter-info`.
- Why it matters: a server crash with a signature request in flight, or a server that names a later signature as active, takes a path no test runs, so a stale request or the wrong signature could ship unnoticed.
- Fix outline: add rows to `test/adapters_signature.rb` for a server crashing while a signature request is in flight and for an answer with `activeSignature` 1 of two signatures.
- Also: test/adapters_signature.rb
- Category: ide
- Added: 2026-11-07

## K shows an older request's hover answer at the new anchor

- Where: `hovered` in `carat/adapters/json_rpc_language_gateway.rb` line 674 at b0dd342; `test/adapters_hover.rb` covers only an answer arriving after the cancel. Periodic quality, blocking. Queued in `hover-tidy`.
- Why it matters: K at one position, a cursor move, and K again while the first request is in flight: the first answer drained in the next poll before the cancel is marked arrived, so `ShowHover` shows the old position's documentation at the new anchor and keeps it when the new request times out.
- Fix outline: drop an answer whose request is not the one last asked, as the completion path does for its serial, with a hover row queuing the first answer after the second K and before its idle tick.
- Also: test/adapters_hover.rb
- Category: ide
- Added: 2026-11-07

## A signature parameter label is marked inside the method name

- Where: `carat/adapters/json_rpc_language_gateway.rb` line 835 at c1b3a12, the string-label branch of the signature marking (periodic quality blocking). Queued in `signature-tidy`.
- Why it matters: ruby-lsp sends string labels, and a parameter whose name occurs in the method name is highlighted inside the name (each(e) marks the e of each), so parameter info points at the wrong text.
- Fix outline: search for the label only after the signature's opening parenthesis and after the previous parameter's match, with no mark when absent, and a `test/adapters_signature.rb` row for each(e).
- Also: test/adapters_signature.rb
- Category: ide
- Added: 2026-11-09

## The gateway times out requests two ways

- Where: `carat/adapters/json_rpc_language_gateway.rb` lines 523 and 604 (completion and resolve cancel at due plus a limit) against 662 and 768 (hover and signature keep a deadline), at 38628bb (periodic quality). Queued in `lsp-client-tidy`.
- Why it matters: the 1,127-line class grows a send, cancel, and answer path per request kind, and the next kind (`breadcrumbs`, `definitions`) adds a third copy.
- Fix outline: one deadline per request record set when sent, and one shared send, cancel, and timeout path.
- Category: ide
- Added: 2026-11-09

## A restarted server is never asked again for the same text's symbols

- Where: `forget_server` (the symbol ask, `forget_symbols` before periodic-blockers-a; line 526 at d73f03f) in `carat/adapters/json_rpc_language_gateway.rb`; quality advisory of `breadcrumbs`.
- Why it matters: it clears the request in flight but keeps `asked_buffer` and `asked_changes`, so after a crash and restart the winbar shows no symbols until an edit or a buffer switch.
- Fix outline: reset the asked text (`asked_changes = -1`) in `forget_server`, with an `editor_breadcrumbs` row for a restart.
- Category: ide
- Added: 2026-11-09

## The progress segment bounds its percent twice and follows any server

- Where: `carat/adapters/json_rpc_language_gateway.rb` lines 1037 to 1045 (`set_progress`), against `show` at line 398, and `carat/domain/status_slots.rb` line 63, at 31919d9. Quality advisories of `feedback`; periodic quality at 31919d9. Queue item `messages-tidy`.
- Why it matters: the percent is bounded in three places; and any running server's `$/progress` overwrites the title and label, while `show` follows only the current buffer's server, so a second server's report can relabel the current one's indexing, or be wiped in the same poll and restart the bar's step.
- Fix outline: `server.percent = given if given >= 0` and one clamp; call `set_progress` only for the server `show` follows, or keep the progress per server, with an `editor_messages` row for two servers reporting at once.
- Also: carat/domain/status_slots.rb
- Category: ide
- Added: 2026-11-09

## Definition target paths keep decoded control bytes

- Where: `carat/adapters/json_rpc_language_gateway.rb` line 789 at fafe59c, `path_of`, which refuses a raw or escaped NUL but keeps a decoded `%0A` or `%1B`. Security Low (5) and quality advisory in `definitions`. Owned by queue item 13, `bidi-controls`. Raised again at bff9a02 (#96): decoded C0 and C1 bytes, periodic security Low (4) at `carat/adapters/json_rpc_language_gateway.rb:789`; queue item `bidi-controls`.
- Why it matters: a hostile language server can put a newline or ESC into a target path, which reaches the read-only and E484 message text (split into extra message lines by `TextLines.split`), the buffer path shown in the tab label and the status line (an outside target now opens as a read-only file buffer since `gd-ghost-tab`), the float title, and a pick-list buffer line that then holds a newline, breaking the one-line invariant. `Frame#put_from` replaces every control with U+FFFD, so no escape sequence reaches the terminal.
- Fix outline: in `path_of`, return "" when a decoded byte is below 0x20 or is 0x7F, as a NUL is refused (or pass the path through `Domain::ControlText.strip` before it is stored), with rows in the escapes test of `test/adapters_definitions.rb` for a URI holding `%0A` and `%1B`.
- Also: test/adapters_definitions.rb
- Category: security
- Added: 2026-11-10

## File URI decoding is hand-rolled inside the language gateway

- Where: `carat/adapters/json_rpc_language_gateway.rb` lines 789 to 850 at fafe59c, `path_of`, `escaped`, and `hex_value`, far from `uri_of`; `test/adapters_definitions.rb` line 338 covers only `%2E` and `%00`. Quality advisories in `definitions`.
- Why it matters: about twenty lines validate UTF-8 by hand (lead size, continuation bytes, overlongs, surrogates, range, `pack("U")`) in an adapter of over 1200 lines, and that multibyte branch has no test, so a regression in it would pass the suite.
- Fix outline: move the decoding into a domain value (a `FileUri` with `path_of` beside the encoding of `uri_of`) tested in a domain test; decode each escape to its byte and refuse unless `out.valid_encoding?`, as `OpenFile` already relies on; add rows for a `%C3%A9` path that opens and an overlong `%C0%AE` and a surrogate `%ED%A0%80` that are skipped.
- Also: test/adapters_definitions.rb
- Category: ide
- Added: 2026-11-10

## The definition ask copies the hover ask in the gateway

- Where: `send_definition` (line 690) and `send_hover` (line 837) in `carat/adapters/json_rpc_language_gateway.rb` at d73f03f, which still differ only by their record, its offer predicate, and the method name; `Domain::DefinitionRequest` repeats `HoverRequest`'s anchor, serial, deadline, and languages fields. The cancel, forget, position-params, and running-server steps are shared since `periodic-blockers-a`. Quality advisories in `definitions` and `periodic-blockers-a`.
- Why it matters: a fix to the replace-or-overdue check or the field writes of one send (such as the stale-answer defect queued in `hover-tidy`) has to be made in both. One private helper over both records is not possible as they stand: Spinel types a parameter once for the whole program (`docs/spinel-notes.md`, Signatures and inference), so a record parameter taking both would be `untyped` and widen every call on it.
- Fix outline: a shared anchored-ask record in the domain that `HoverRequest` and `DefinitionRequest` both hold, so one private send in the gateway takes that record and the method name, with the hover and definition request rows unchanged.
- Also: docs/spinel-notes.md
- Category: ide
- Added: 2026-11-10

## The definition answer loop stops before LIMIT targets are kept

- Where: `carat/adapters/json_rpc_language_gateway.rb` line 753 at fafe59c, `defined`, which reads only the first `DefinitionRequest::LIMIT` entries of an answer even when some were skipped as non-file, while `DefinitionRequest#add_target` caps the kept targets again. Quality advisory in `definitions`.
- Why it matters: an answer whose first entries are not files drops file targets that follow, and the cap is held in two places.
- Fix outline: scan a bounded number of entries larger than `LIMIT` (or until `LIMIT` are kept) and keep the one cap in `add_target`, with a row whose first entries are non-file.
- Category: ide
- Added: 2026-11-10

## The completion send slices the cursor-prefix line twice

- Where: `complete` in `carat/adapters/json_rpc_language_gateway.rb` line 583 at 75fa4fd, which already holds the line up to the cursor, while `position_params` slices the line again. Quality advisory in `periodic-blockers-a`. Raised again at ce6abdb (lines 576 and 1024; periodic quality), queue item `lsp-client-tidy`.
- Why it matters: one more string is allocated per completion send, on the typing path.
- Fix outline: let `position_params` take the prefix line (or the column computed from it) when the caller has it, or accept the one string and drop this entry.
- Category: ide
- Added: 2026-11-10

## cancel_request's comment names the running server

- Where: the comment of `cancel_request` in `carat/adapters/json_rpc_language_gateway.rb` line 1003 at 75fa4fd, which says the running server though the method looks up `server_for`, now beside `running_server`. Quality advisory in `periodic-blockers-a`. Raised again at ce6abdb (periodic quality), queue item `lsp-client-tidy`.
- Why it matters: the comment points the reader at `running_server`, the other lookup, so a later change could pick the wrong one.
- Fix outline: say the language's server in the comment.
- Raised again as "cancel_request's comment names the running server but asks any": Where: `carat/adapters/json_rpc_language_gateway.rb:1006`. Why it matters: the comment and the lookup (`server_for` beside `running_server`) disagree. Fix outline: call `running_server` or reword the comment. Queue item `lsp-client-tidy`.
- Category: ide
- Added: 2026-11-10

## The language gateway is one 1373-line class

- Where: `carat/adapters/json_rpc_language_gateway.rb:1`. Periodic quality.
- Why it matters: 80 methods and every request kind in one class, which every new request grows.
- Fix outline: one sender and reader per request kind over a small shared collaborator built in `EditorAssembly`. Queue item `lsp-client-tidy`.
- Category: ide
- Added: 2026-11-10

### The language gateway's copies and relative URIs

- Location: carat/adapters/json_rpc_language_gateway.rb:267, :837, :232, :1328 (sprint-4 sweep, quality).
- Why: listed is public for two private callers; send_hover and the cancels copy send_definition; restart copies start's tail; uri_of keeps ./ segments, so one file syncs under two URIs.
- Fix: make listed private; one sender and canceller if Spinel types them; one launch helper; build the URI from PluginApi::Paths.absolute with a test.
- Category: ide
- Added: 2026-11-14

### The language gateway is one class of 1,373 lines (architecture-review M1)

Location: `carat/adapters/json_rpc_language_gateway.rb`. Why: lifecycle, document sync, diagnostics, progress, and five request kinds share one class, so every language feature edits it, and `docs/architecture.md` section 9.3 expects the plugin gateway to reuse framing and process handling that are woven into the language protocol. Fix outline: extract a JSON-RPC session (ids, pending requests, cancellation, framing over `ProcessPort`) and one small class per request kind, before `plugin-protocol` (roadmap item 13).
- Also: docs/architecture.md
- Category: ide
- Added: 2026-11-15

### carat/adapters/json_rpc_language_gateway.rb:469 receive reads the same fields in many branches

- Quality advisory, duplication: receive reads Json.field(value, "id") in seven branches of its elsif chain and Json.field(value, "result") in six.
- Fix: read id = Json.field(value, "id") once after name and compare each branch against it.
- Category: ide
- Added: 2026-11-15

### carat/adapters/json_rpc_language_gateway.rb:1065 signed reads each bound twice

- Quality advisory, duplication: signed reads Json.element(part, 0) and Json.element(part, 1) twice each.
- Fix: read the two bounds into locals once and test is_a?(Integer) on them.
- Category: ide
- Added: 2026-11-15

### A crash then :LspStart never asks the new server for the outline

- Location: carat/adapters/json_rpc_language_gateway.rb:537 (`forget_server`, called from the crash at :451 and from stop; start at :188). Sprint-6 review, quality. Queue item `gateway-split-a`.
- Why: `forget_server` clears the symbol request's sent id but keeps the text last asked (`SymbolRequest#asked?`), so after a crash with a symbol request in flight the new server is never asked for the unchanged text and the outline stays stale; winbar-outline fixed only the restart path.
- Fix outline: forget the symbol request in `forget_server` when its language matches, drop the separate forget from restart, and add a `test/editor_breadcrumbs.rb` case for a crash then `:LspStart`.
- Also: test/editor_breadcrumbs.rb
- Category: ide
- Added: 2026-11-15

### send_symbols decides the winbar apart from ArrangeView

- Location: carat/adapters/json_rpc_language_gateway.rb:931 (`send_symbols` reads `TabPage#winbar?`). Sprint-6 review, quality. Queue item `gateway-split-a`.
- Why: `ArrangeView#reserve_winbars` is the one place that decides (`Window#winbar`), so symbols are asked for a one-row layout window or a scratch buffer that shows no winbar.
- Fix outline: return unless the layout window's winbar flag is set.
- Category: ide
- Added: 2026-11-15

### markdown_of reads the value field twice

- Location: carat/adapters/json_rpc_language_gateway.rb:910 and :911. Sprint-6 review, quality advisory. Queue item `gateway-split-a`.
- Why: duplication: `Json.field(part, "value")` is read twice.
- Fix outline: read it once into a local, then check its class and convert it.
- Category: ide
- Added: 2026-11-15

### The language gateway holds a URI codec, UTF-16 walkers, and missing requires

- Location: carat/adapters/json_rpc_language_gateway.rb:774 and :1328 (URI codec), :1089 and :1135 with carat/use_cases/definitions/visit_target.rb:204 (three UTF-16 walkers), :1 and carat/drivers/process_runner.rb:1 and carat/use_cases/plugins/plugin_registry.rb:1 (names constants they do not require) (sprint-8 sweep, quality); queued in `gateway-split-a`.
- Why: the 1,374-line gateway keeps conversions no protocol state needs, three copies of one walk, and compiles alone only through carat.rb's order.
- Fix: Domain modules for the file URI and UTF-16 with table tests, the gateway and VisitTarget calling them; add the require_relative lines.
- Also: carat/use_cases/definitions/visit_target.rb, carat/drivers/process_runner.rb, carat/use_cases/plugins/plugin_registry.rb, carat.rb
- Category: ide
- Added: 2026-11-16

### The gateway repeats its request send, cancel, and start paths

- Location: carat/adapters/json_rpc_language_gateway.rb:691 and :838 (send_definition and send_hover alike), :594, :665, :719, :865, :945, :998 (six cancels), :222 (restart repeats start), :268 (listed public), :208 (waiting? comment) (sprint-8 sweep, quality); queued in `gateway-split-b`.
- Why: 22 duplicated lines, six copies of one cancel, a repeated start tail, and public surface only the class calls.
- Fix: one cursor-request send and cancel path, one private start tail, listed below private, the comment completed.
- Category: ide
- Added: 2026-11-16

### Incremental sync misses a reload that only changes the line ending
- Location: carat/adapters/json_rpc_language_gateway.rb:1356
- Why: an :e! reload that only changes the line ending (OpenFile sets line_ending, open_file.rb:60) leaves the stored lines equal, so under sync kind 2 nothing is sent and the server keeps the old terminators, mixed after later ranged edits (positions stay right).
- Fix: store the line ending sent beside the remembered texts and replace the whole document when it changed.
- Category: ide
- Added: 2026-11-17

### UTF-16 counts by lead byte desynchronize incremental sync on invalid UTF-8
- Location: carat/adapters/json_rpc_language_gateway.rb:1146 (utf16_length), :1100 (utf16_offset), :1385 (ranged_change); carat/use_cases/definitions/visit_target.rb:204
- Why: a stray 0x80-0xBF byte counts 0 units and a lone 0xF0-0xFF byte 2, while Carat::Json sends each illegal byte as one U+FFFD (1 unit), so in a file that is not valid UTF-8 each ranged didChange after such a byte corrupts the server's copy of the line. Queued in lsp-sync-fixes.
- Fix: one domain helper walking Utf8.size_at and code_at, 2 units only above 0xFFFF, used by the gateway and VisitTarget, with a replayed sync row over a line holding 0xB0 and 0xFC.
- Also: carat/use_cases/definitions/visit_target.rb
- Category: ide
- Added: 2026-11-17

### send_change repeats remember and the didChange envelope per sync kind
- Location: carat/adapters/json_rpc_language_gateway.rb:1335
- Why: kinds 1 and 2 repeat remember and the notify, and the kinds are bare literals. Queued in lsp-sync-fixes.
- Fix: compute the content change by a named kind, then remember and notify once.
- Category: ide
- Added: 2026-11-17

### The incremental-sync text diff lives in the 1438-line gateway

- Location: carat/adapters/json_rpc_language_gateway.rb:1331 (ranged_change, shared_head, shared_tail, continuation?, content_change). Sprint-11 review, quality advisory, architecture layers 3 and 5.
- Why: a pure text-diff algorithm sits inside a 1438-line adapter, tested only end to end.
- Fix outline: move the diff into a Domain module (for example a line delta between the sent lines and the buffer's) with its own table test, keeping only the JSON shaping in the gateway.
- Category: ide
- Added: 2026-11-17

### The gateway repeats the UTF-8 continuation-byte test

- Location: carat/adapters/json_rpc_language_gateway.rb:1377, inlined again at :1074 and :1119. Sprint-11 review, quality advisory.
- Why: the & 0xC0 == 0x80 test is written three times beside Domain::Utf8 (boundary, size_at), which holds the same knowledge.
- Fix outline: add a Utf8 continuation predicate and use it at all three places.
- Category: ide
- Added: 2026-11-17

### The gateway's six cancel wrappers share one body

- Location: carat/adapters/json_rpc_language_gateway.rb:601, :672, :726, :872, :952, :1005 (sweep, quality).
- Why: each is cancel_request then sent_id = 0.
- Fix outline: cancel_request returns 0 and the call sites assign it.
- Category: ide
- Added: 2026-11-17

### The gateway holds three UTF-16 walks and a URI codec (sprint-14 sweep quality)

- Location: carat/adapters/json_rpc_language_gateway.rb:1116, :1162, :801, :1440; carat/use_cases/definitions/visit_target.rb:204.
- Why: three hand-rolled UTF-16 code unit walks over one lead-byte rule inside a 1486-line adapter.
- Fix outline: one domain UTF-16 module and a URI value, used by both callers. Queued in `gateway-split-a`.
- Also: carat/use_cases/definitions/visit_target.rb
- Category: ide
- Added: 2026-11-17

### path_of validates UTF-8 by hand (sprint-16 sweep quality)

- Location: carat/adapters/json_rpc_language_gateway.rb:801 (path_of).
- Why: lead byte sizes, continuation, overlong, and surrogate checks are written out after percent decoding.
- Fix outline: append decoded bytes to a binary string and accept it only when valid_encoding? as UTF-8. Pool item `lsp-tidy`.
- Category: ide
- Added: 2026-11-18

### The language gateway repeats send, cancel, receive, and start bodies (sprint-16 sweep quality)

- Location: carat/adapters/json_rpc_language_gateway.rb:865 and :718 (send_hover, send_definition), :494 to :505 (receive), :621, :746, :892, :972, :1025 (cancels), :201 and :235 (start, restart).
- Why: one body is copied per request kind and the start messages twice.
- Fix outline: one send_at_cursor, one cancel over the requests' shared readers, a request table for receive, a private launch_shown. Pool item `lsp-tidy`.
- Category: ide
- Added: 2026-11-18

### UTF-16 conversions live in three places (sprint-16 sweep quality)

- Location: carat/adapters/json_rpc_language_gateway.rb:1116 and :1162, carat/use_cases/definitions/visit_target.rb:204.
- Why: each walks lead bytes by hand.
- Fix outline: Domain::Utf8 utf16_length, utf16_offset, column_of_units called from both. Pool item `lsp-tidy`.
- Also: carat/use_cases/definitions/visit_target.rb
- Category: ide
- Added: 2026-11-18

### Untrusted text is cut at a byte limit without a character boundary (sprint-16 sweep quality)

- Location: carat/adapters/json_rpc_language_gateway.rb:926, :943, :1141; ProcessRunner#cut_point (process_runner.rb:155) and MarkdownText.gather carry their own back-off.
- Why: an answer at the cap shows a trailing U+FFFD, and three cuts differ from the two that back off.
- Fix outline: one Utf8.cut(text, limit) backing off continuation bytes, used by all five. Pool item `lsp-tidy`.
- Category: ide
- Added: 2026-11-18

### The language server gateway holds every request kind in one class (sprint-18 sweep quality)
- Location: `carat/adapters/json_rpc_language_gateway.rb:1` (1486 lines, 87 methods).
- Why it matters: lifecycle, sync, and five request kinds each carry their own send, cancel, and answer code.
- Fix outline: a collaborator per request kind sharing `cancel_request` and `position_params`.
- Category: ide
- Added: 2026-11-18

### Duplication (sprint-20 sweep quality, json_rpc_language_gateway.rb:1116)

- Location: `carat/adapters/json_rpc_language_gateway.rb:1116`
- Why: duplication: UTF-16 to UTF-8 conversion lives three times, utf16_offset (1116) and utf16_length (1162) here and column_of in carat/use_cases/definitions/visit_target.rb:204, each re-deriving the 0xF0 two-unit rule
- Fix: one domain helper (Domain::Utf8 units_of and offset_of_units, or a Utf16 module) used by the gateway and VisitTarget, with its own table test
- Also: carat/use_cases/definitions/visit_target.rb
- Category: ide
- Added: 2026-11-19

### Public method used only inside the class (sprint-20 sweep quality, json_rpc_language_gateway.rb:281)

- Location: `carat/adapters/json_rpc_language_gateway.rb:281`
- Why: public method used only inside the class: listed(uri) is called only by diagnostics (275) and apply (1260)
- Fix: move it below private
- Category: ide
- Added: 2026-11-19

### The language gateway's root check does not resolve symlinks
- Location: carat/adapters/json_rpc_language_gateway.rb:1368 (security Low, confidence 3)
- Why: inside_root? checks the buffer path lexically and does not resolve links, so a symlink inside the project that points outside it counts as inside and, when the user opens it, the file's text goes to the server in didOpen; impact is small since the server only starts on its own under a trusted root and runs the project's code anyway.
- Fix: optionally resolve the path with File.realpath once, when the buffer is first opened (the definitions' project check already does this), and cache the result per URI so the idle tick stays off the disk.
- Category: security
- Added: 2026-11-20

### Requests for a buffer outside the working directory are sent though it was never opened
- Location: carat/adapters/json_rpc_language_gateway.rb `complete`, `send_hover`, `send_definition`, `send_signature`, and `send_symbols` (each checks only that the buffer has a path)
- Why: since lsp-tidy a buffer outside the working directory is never opened on the server, yet a completion, hover, definition, signature, or symbol request still names its URI; the server answers for a document it was never sent, usually with an error or nothing, and it learns the path
- Fix: have `running_server` or the request senders skip a buffer the server has no version for (`server.versions[uri]` nil), with a test that K and gd in an outside file send no request
- Category: ide
- Added: 2026-11-20

### carat/adapters/json_rpc_language_gateway.rb:1320: sync resets @root on every call, so FilePort#cwd is (sprint-22 sweep quality)

- Location: `carat/adapters/json_rpc_language_gateway.rb:1320`
- Why: sync resets @root on every call, so FilePort#cwd is read once per running server per idle tick, though head_of's comment (line 336) relies on the working directory never changing (there is no :cd)
- Fix: read the working directory once and drop the per-sync reset
- Category: ide
- Added: 2026-11-20

### carat/adapters/json_rpc_language_gateway.rb:228: the waiting? comment lists completion, documentation, hover, signature, and (sprint-22 sweep quality)

- Location: `carat/adapters/json_rpc_language_gateway.rb:228`
- Why: the waiting? comment lists completion, documentation, hover, signature, and symbol asks but not the definition ask its expression checks
- Fix: name the definition ask
- Category: ide
- Added: 2026-11-20

### carat/adapters/json_rpc_language_gateway.rb:270: stop queues shutdown and exit, then ProcessRunner#stop sends TERM (sprint-22 sweep quality)

- Location: `carat/adapters/json_rpc_language_gateway.rb:270`
- Why: stop queues shutdown and exit, then ProcessRunner#stop sends TERM at once (process_runner.rb:95), so the server never answers shutdown before TERM and the graceful requests are effectively dead
- Fix: wait briefly for the shutdown answer before stopping, or drop the two requests and document TERM as the stop
- Category: ide
- Added: 2026-11-20

### Removal of the byte basename heading dropped the gateway File.basename calls
- Location: docs/backlog.md:230, the removed heading '## Three copies of the byte basename'; carat/adapters/json_rpc_language_gateway.rb (File.basename calls near :394, :408, :425)
- Why: syntax-tidy left the gateway calls out of scope and they still stand, so the removal dropped that part of the entry.
- Fix: re-add a short entry for the gateway's File.basename calls, or record why they need no change.
- Category: ide
- Added: 2026-11-21

### one adapter of 1539 lines and about 110 methods at carat/adapters/json_rpc_language_gateway.rb:1 (sprint-26 sweep quality, note 34)

- Location: carat/adapters/json_rpc_language_gateway.rb:1
- Why: one adapter of 1539 lines and about 110 methods holds the server lifecycle, document sync, diagnostics, and five request kinds, each with its own near-identical send, cancel, and answer trio (cancel :628, cancel_resolve :699, cancel_definition :753, cancel_hover :900, cancel_symbols :980, cancel_signature :1033)
- Fix: move each request kind into its own adapter collaborator sharing request, cancel_request, and running_server through a small session object built in EditorAssembly
- Category: ide
- Added: 2026-11-22

### Two blank lines in a row after the completion item method at carat/adapters/json_rpc_language_gateway.rb:1175 (sprint-27 review quality, note 7)

- Location: carat/adapters/json_rpc_language_gateway.rb:1175
- Why: removing utf16_length left two consecutive blank lines, against the file's style.
- Fix: remove one.
- Category: ide
- Added: 2026-11-22
