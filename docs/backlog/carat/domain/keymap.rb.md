# Backlog: carat/domain/keymap.rb

## Keymap exposes helpers and the map misses methods

- Where: `apply`, `bind_text`, and `holder_of` in `carat/domain/keymap.rb` lines 141, 162, and 205 are public with no outside caller; `leader_problem` and `no_actions` are missing from the map's `Keymap` entry; the `CommandGrammar` entry (`docs/codebase-map.md` line 146) omits `digit?`, `digit`, `char`, `wants_pattern?`, and `pattern`; the `Paths` list (line 503) omits `absolute` (`carat/plugin_api.rb` line 356), at b0dd342. Periodic quality. Queued in `docs-index`. Raised again at ce6abdb (periodic quality, `keymap.rb` 173 `apply` and 242 `holder_of` copying `node_at`), adding `bind` at 223 with no caller and `name_group` at 314 copying `bind_text`'s checks at 200: remove `bind` and its map mention, a private `keys_problem`; queue item: the backlog batches. Raised again at be4b63a.
- Why it matters: the map is the entry point for every change; missing methods send a reader to the code.
- Fix outline: make the three instance methods private and name the missing methods in their entries.
- Also: docs/codebase-map.md, carat/plugin_api.rb
- Category: editor
- Added: 2026-11-07

## A disabled plugin's group names stay in the keymap

- Where: `name_group` in `carat/domain/keymap.rb` line 285 at d828abb. Quality advisory in `discoverability`.
- Why it matters: the group name ignores the line's owner, so `remove_owner` keeps a disabled plugin's group names and a prefix it shared still shows that title over the key hints.
- Fix outline: record the owner with each group name and drop it in `remove_owner`, or refuse `keymap.group` from a plugin, with a row in `test/editor_key_hints.rb`.
- Also: test/editor_key_hints.rb
- Category: editor
- Added: 2026-11-09

## A plugin's keymap.pick line is silently ignored

- Where: `carat/domain/keymap.rb` line 181 at fafe59c, `apply`, which checks a `keymap.pick` line on a throwaway keymap whatever its owner, while `pick_from` binds only the configuration's lines. Quality advisory in `definitions`.
- Why it matters: a plugin manifest line `keymap.pick ...` is accepted without a problem and has no effect, so its author gets no report.
- Fix outline: refuse it as "a plugin cannot set keymap.pick" when the owner is not empty, as `keymap.leader` is refused, with a row in `test/domain_keymap.rb`.
- Also: test/domain_keymap.rb
- Category: editor
- Added: 2026-11-10

## The pick keymap binds a line refused as an unknown action

- Where: `carat/domain/keymap.rb` line 100, `pick_from`, and `test/domain_keymap.rb` line 194. Periodic quality at 8d8832f, queued in `definitions-tidy`.
- Why it matters: `keymap.pick zq foo.bar` is reported as unknown yet bound, answering Not implemented, against the test's comment.
- Fix outline: bind only the pick lines the action check accepted, and assert `zq` is unbound in the pick keymap.
- Also: test/domain_keymap.rb
- Category: editor
- Added: 2026-11-10

## Keymap repeats its key checks and trie walk

- Where: `carat/domain/keymap.rb:314` (`name_group` repeats `bind_text`'s checks at 200 to 203; `holder_of` 242, `node_at` 269, `lookup` 290 each walk the trie). Periodic quality at 9a92265.
- Why it matters: three copies of one walk drift apart when a key form is added.
- Fix outline: one private key parser and one private walk used by all. Queue item: backlog batches (copies).
- Category: editor
- Added: 2026-11-10

## A key-sequence mapping value loads unchecked

- Where: `carat/domain/keymap.rb:185` stores a non-action value unparsed; `carat/use_cases/handle_key.rb:353` replays it with `KeyNotation.parse(sequence, "")`. Periodic quality at d0d783c, the review's one blocking finding (the run state does not mark which; this one breaks CLAUDE.md Stack's `file:line` rule).
- Why it matters: `keymap.normal <leader>s <leader>w` and any value with an unknown `<Name>` load with no `file:line` problem and fail only when pressed, as Bad mapping.
- Fix outline: parse a non-action value with the leader when the line is applied, report its error on the line, and store the expanded sequence, with `test/editor_leader.rb` rows for `<leader>` in a replay and for an unknown name. Queue item `periodic-blockers-b`.
- Also: carat/use_cases/handle_key.rb, CLAUDE.md, test/editor_leader.rb
- Category: editor
- Added: 2026-11-11

### Keymap#bind has no caller

- Location: carat/domain/keymap.rb:223; docs/codebase-map.md area 5. Sprint-6 sweep, quality. Queue item `input-core-tidy`.
- Why: dead code the map still lists; only `bind_owned` and `bind_text` are used.
- Fix outline: remove the method and its map mention.
- Also: docs/codebase-map.md
- Category: editor
- Added: 2026-11-15

### Keymap unbind descends the trie twice

- Location: `carat/domain/keymap.rb:359` (`unbind`).
- Why: `unbind` re-walks the trie from the root for every depth it prunes, a second descent duplicating the first; quality advisory from core-correctness.
- Fix: collect the visited nodes in an array while descending and prune from it deepest first.
- Category: editor
- Added: 2026-11-15

### Keymap#holder_of repeats node_at's walk

- Location: carat/domain/keymap.rb:246, :273 (sweep, quality).
- Why: holder_of copies the trie walk of node_at.
- Fix outline: node = node_at(mode, codes), then the owner or "".
- Category: editor
- Added: 2026-11-17

### Small surface and wording tidy of the sweep (sprint-14 sweep quality)

- Location: carat/domain/keymap.rb:173 (apply public, two private callers); carat/adapters/frame_presenter.rb:320 (display_col with one internal caller); carat/use_cases/docs/format_docs.rb:36 and carat/domain/markdown_text.rb:261 (a bare positional framed flag beside two caps); carat/use_cases/plugins/window_requests.rb:30, file_requests.rb:25, carat/drivers/process_runner.rb:19 (mis-wrapped class comments); carat/use_cases/plugins/file_requests.rb:141 (the 2-second capture deadline spelled beside ProcessRunner::CAPTURE_SECONDS).
- Why: needless public surface, unclear call sites, and a constant two places must keep equal.
- Fix outline: make the helpers private, pass one layout value, rewrap, declare the deadline once on the port. Queued in `input-core-tidy`, `ui-code-tidy`, `markdown-reading-e`, `plugin-host-tidy`, `process-capture-hardening`.
- Also: carat/adapters/frame_presenter.rb, carat/use_cases/docs/format_docs.rb, carat/domain/markdown_text.rb, carat/use_cases/plugins/window_requests.rb, carat/drivers/process_runner.rb, carat/use_cases/plugins/file_requests.rb
- Category: editor
- Added: 2026-11-17

### Keymap and ControlText rely on another file's require (sprint-16 sweep quality)

- Location: carat/domain/keymap.rb:1 (KeyNotation, Mode), carat/domain/control_text.rb:1 (Utf8.size_at).
- Why: both work only because of the order in carat.rb, breaking the layer rule's explicit requires.
- Fix outline: add require_relative of key_notation and mode to keymap.rb and of utf8 to control_text.rb.
- Also: carat/domain/control_text.rb, carat.rb
- Category: editor
- Added: 2026-11-18

### Keymap#name_group repeats bind_text's parse (sprint-16 sweep quality)

- Location: carat/domain/keymap.rb:318
- Why: the notation parse, empty-key check, and MAX_KEYS check are copied from bind_text.
- Fix outline: one private helper returning the parsed codes or the problem, used by both.
- Category: editor
- Added: 2026-11-18

### Bind_text accepts a key-sequence value without parsing it (sprint-20 sweep quality, keymap.rb:199)

- Location: `carat/domain/keymap.rb:199`
- Why: bind_text accepts a key-sequence value without parsing it, so a bad sequence in a configuration line is reported only when pressed (HandleKey 'Bad mapping', handle_key.rb:367), never as file:line at load as every other configuration problem is
- Fix: parse the value with KeyNotation.parse in apply when it is not an action name and return its error
- Category: editor
- Added: 2026-11-19

### Keymap#bind has no caller in carat/, bin/, test/, or bench/ yet is (sprint-20 sweep quality, keymap.rb:223)

- Location: `carat/domain/keymap.rb:223`
- Why: Keymap#bind has no caller in carat/, bin/, test/, or bench/ yet is named in docs/codebase-map.md area 5; dead code
- Fix: remove bind and its map mention (bind_owned covers it)
- Also: docs/codebase-map.md
- Category: editor
- Added: 2026-11-19

### Apply is public but only add_lines and add_checked call it, and the (sprint-20 sweep quality, keymap.rb:173)

- Location: `carat/domain/keymap.rb:173`
- Why: apply is public but only add_lines and add_checked call it, and the map's keymap line lists neither apply, bind_text, holder_of, leader_problem, nor no_actions
- Fix: move apply under private and name the public helpers in docs/codebase-map.md area 5
- Also: docs/codebase-map.md
- Category: editor
- Added: 2026-11-19

### The walk from root (sprint-20 sweep quality, keymap.rb:246)

- Location: `carat/domain/keymap.rb:246`
- Why: the walk from root(mode) along codes is written four times (holder_of, node_at, lookup, unbind), and lookup inserts an empty root for an unbound mode
- Fix: have lookup and holder_of walk through node_at (which already answers an empty node) and keep one loop
- Category: editor
- Added: 2026-11-19

### carat/domain/keymap.rb:90: leader_problem refuses only an empty parse, so keymap.leader ab (sprint-22 sweep quality)

- Location: `carat/domain/keymap.rb:90`
- Why: leader_problem refuses only an empty parse, so keymap.leader ab is accepted though its message says takes one key and leader_from (:68) promises one key
- Fix: refuse parsed.codes.length != 1 (or reword the message and comment if a multi-key leader is meant), with a domain_keymap case
- Category: editor
- Added: 2026-11-20

### carat/domain/keymap.rb:246: duplication: the walk of the trie by codes is (sprint-22 sweep quality)

- Location: `carat/domain/keymap.rb:246`
- Why: duplication: the walk of the trie by codes is written five times (bind_owned :228, holder_of, node_at :273, lookup :294, unbind :348)
- Fix: one private find_node(mode, codes) returning nil when the keys lead nowhere, used by the four read-only walks
- Category: editor
- Added: 2026-11-20

### carat/domain/keymap.rb:318: duplication: name_group repeats bind_text (:199) parse, empty-key, and MAX_KEYS (sprint-22 sweep quality)

- Location: `carat/domain/keymap.rb:318`
- Why: duplication: name_group repeats bind_text (:199) parse, empty-key, and MAX_KEYS checks and messages
- Fix: one private parse_keys(keys, leader) returning the codes or the problem
- Category: editor
- Added: 2026-11-20


### holder_of repeats node_at's walk at carat/domain/keymap.rb:211 (sprint-28 sweep quality, note 5)

- Location: carat/domain/keymap.rb:211, :238
- Why: two copies of one trie walk.
- Fix: node = node_at(mode, codes); return "" when its value is nil, else node.owner.
- Category: editor
- Added: 2026-11-22
