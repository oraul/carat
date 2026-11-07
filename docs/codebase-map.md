# Codebase map

Where everything is, by area. Read the section of the area a change touches, then only the files, tests, and design sections it names. `docs/architecture.md` is the binding design; this map is the index into the code. Every file under `carat/`, `bin/`, `test/`, `bench/`, and `tools/` has its home in exactly one area, under its Files or its Tests (a test's `.expected` snapshot goes with its test), and `test/lint.rb` fails when a file is missing here or a path named here does not exist. A change that adds, moves, or removes a file updates its area in the same pull request.

Method names are given without line numbers; find them with `grep -n "def name"`. Designs are archived OpenSpec changes under `openspec/changes/archive/`, named without their date prefix, with the sections that explain the area.

Areas:

1. Build and CI
2. Toolchain
3. Configuration
4. Composition and state
5. Grammar and keymap
6. Motions and text objects
7. Operators and registers
8. Edit path, transactions, and insert mode
9. Undo and repeat
10. Visual modes
11. Windows and tabs
12. Ex commands, the command line, and files
13. Rendering
14. Syntax highlighting
15. Plugin host and API
16. Explorer plugin
17. Ports, drivers, and language services
18. Tests and benchmarks

The last section, Delivered changes, lists every change merged so far in order with what it left for later.

---

## 1. Build and CI

What: builds with `spin`, maps commands to `make` targets, runs the checks locally and in CI, and keeps the pipeline's run state and gates.

Flow: `make build` (release, `build/bin`) and `make dev-build` (development flags, `build/dev/carat`, analysis budget checked). `make check` runs `CHECK_STAGES`; the checker runs them one logged stage at a time through `tools/run_state.sh check`, in a throwaway clone outside the delivery clone, detached from it and ending in a verdict line by which the workflow reruns a killed or superseded check with no fix round, and CI mirrors them after `tools/ci_scope.sh`, its differences recorded in the Makefile. `.claude/workflows/deliver-change.js` runs the agents, from the planner to the retrospective, which closes a run in one start (its last records, proposals, and the report), and, when due, `.claude/workflows/periodic-review.js`; `tools/run_state.sh push` runs `tools/gates.sh`, and the merger, which also waits for CI, runs the copy of a fresh worktree of `origin/main` at `tmp/.merge-gates`. The `metrics` stage writes `build/metrics/current.tsv` with `tools/metrics.sh`, which `tools/run_state.sh bench` compares with main's recorded figures (the newest merged change without a history row, else the last row), the benchmark agent with `main` when they differ, and CI with the last push to `main`; the run state keeps each run's figures until the next change appends them to `docs/metrics.tsv`.

Files:

- `carat.rb`: the production require graph, innermost layer first, ending with the plugin registry; requires no test double.
- `carat/version.rb`: `Carat::VERSION`.
- `tools/ci_scope.sh`: `documentation` (Markdown but `docs/actions.md`, `docs/compatibility.md`, and the map, `docs/metrics.tsv`, or under `openspec/` or `.claude/`) and `answer`; skips documentation-only changes and a push to `main` whose tree passed as a pull request head.
- `tools/ci_wait.sh`: the merger's foreground wait of 1 to 540 seconds between two reads of the check runs (180, 240, then 300), so one merger start covers a 30-minute CI run; a failed `sleep` fails it.
- `tools/analysis_budget.sh`: compiles `ANALYSIS_ROOTS` to C with `SP_TIMING=1`, prints analysis milliseconds and rounds, fails above `ANALYSIS_ROUNDS`; `--check` reads a report a build already wrote; `--fields` prints a report's milliseconds and rounds.
- `tools/metrics.sh`: `measure` (rounds and analysis time of both roots, allocations and time per key of `DEFAULT_SCENARIOS`) and `compare` (fails on more allocations or rounds, warns on time above `TIME_TOLERANCE`).
- `tools/run_state.sh`: the one writer of `build/pipeline/<change>.json`, the stage logs, and `docs/metrics.tsv`, every write through `write_key`, which refuses a control character (`plain`, `plain_key`); `init`, `show`, `trusted` (`trusted_state`, `supported`: only the records at a commit of the branch or of main, for the workflow's resume), `get`, `set` (refusing `review.*`, `phase.*`, `stage.*`, `gated`, and a `merged` or `pushed` value but a commit hash; `merged` runs `drop_backup`), `phase` (`PHASES`, `commit_at`), `review` (`REVIEW_KINDS`), `stage` (`run_stage`: a `running`, `killed`, or `superseded` record at the commit it started on), `check` (`check_wait`, the waiter: refuses a dirty tree, rejoins or supersedes the runner of `check.pid`, reports a lost one, `check_lost`, removing its clone, `clone_lost`, and exits 3 after `CHECK_WAIT`; `check_run`, the detached runner, and `check_signalled`, its trap; the check clone every stage runs in, `in_clone`: a new repository under `TMPDIR` fetched from HEAD, `clone_make`, its `build/` carried in `build/stages/CHANGE/carry` and removed on exit, `clone_drop`; `check_stages`: a record counts only at the last recorded check, `phase.check`, which the workflow writes; `TEST_STAGES`, `tests_only_since`; `COMPILE_STAGES` skipped on the `code_key` of their last pass with their outputs unchanged, `compiled_same`, kept beside the run states), `scope` (`fix_scope`: a fix within the files its findings name), `bench` (`bench_compare`, `newest_pending`, `merged_commit`), `push` (deleting the backup refs, `drop_backup`, and resetting `gated` to `none`), `gated` (the merge gates' record: `none` at their start in every run state, `gated_clear`, the head when every gate passed), `backup` (`backup_branch`: `branch_base`, recorded as `base`, the `backup` gates from it, then `refs/backup/BRANCH` and `refs/backup-base/BRANCH` in one atomic push), `restore` (`restore_branch`: refuses a backup without its base, a base off main, or a commit not descended from it), `abandon` (`drop_backup`, the user's alone), `metric`, `metrics`, `note` (one `quality-advisory` per text), `usage` (`add_usage`: a start's total tokens and wall minutes, summed), `budget` (`budget_line`, `TOKEN_BUDGETS` and `MINUTE_BUDGETS` on the totals), `spent` (`spent_line`: the output tokens so far against `TOKEN_BUDGETS` over `OUTPUT_SHARE`, after a passing check), `review-due` (`REVIEW_AREAS`, `keymap_only`, `agent_hooks`), `plan-needed` (`plan_needed`, `PLAN_NOTES`), `pending`, `history` (`first_of`, `keys_under`, `out_tokens`, `estimate_of`, `metric.estimate`, else the size word of the queue item at the squash commit's parent; `total_tokens` and `wall_min` last), `status` (`rates`).
- `tools/gates.sh`: the rule gates `origin` (no `RISKY_CONFIG` key in `.git/config`, no hook but a sample in the hooks directory, the global and system configuration unread; an `origin/` base with the default fetch refspec, a hosted origin, and the commit `ls-remote` reports), `trailer`, `content` (every commit's added lines against each parent, an added `.env` file), `snapshots`, `docs`, `security`, `stages` (every stage at the commit of `phase.check`, the list from the `Makefile` beside the script, `stage_list`), `pushes`, `passed` (a clean tree and the check, quality, security, and bench pass records at the pushed head), `records` (the run state's reviews and check against the workflow's `RECORDS`, security required), `pr-body` (never a link), `attribution` (`.claude/settings.json`: the trailer only, no pull request text, no session link), and the groups `static`, `pre-push`, `backup`, `merge` (which records `gated`).
- `tools/agent_guard.sh`: the PreToolUse hook of every agent file, run from `origin/main` and refusing on any failure; a refusal of every call while `.git/config` sets a `RISKY_CONFIG` key (a copy of `rules.sh`'s) or the hooks directory holds a hook but a sample, its git reading no global or system configuration; an allowlist per profile (`read`, `merger`, `contributor`, and `close`, the read profile with the phases no merge gate reads, listed in its header): `field` reads the hook's JSON (a line break marked), `lex` splits a command as the shell does (line continuations, comments, descriptors) and refuses expansions, substitutions, subshells, here-documents, and globs, `judge` matches each simple command to a form (`git_form`, `make_form`, `script_form`, `run_state_form`, `gates_form`, `files_form`), `word_rules` refuses a parent step and the run state's directory, `write_target` judges every write by its real path (`real_path`), `metrics_out` admits only `build/metrics/current.tsv` as the measurement's OUT, `body_arg` admits the body file only to its gate, and `merge_tool` admits the merger's GitHub merge, its hook's second matcher, only as a squash at a head exactly one run state names, holding it as `pushed` and `gated`, while `origin/main` is origin's `main`.
- `tools/tools_test.sh`: `expect`, `fresh`, `docs`, `kit`, `guard`, `hook`; the scope, the CI wait, the measurement, the run state and history, the guard (every bypass form per profile, each agent's commands, the hook lines), the docs lint, the generators, and every gate in temporary repositories; the call caps against each agent's `maxTurns`; and `js`, which runs the workflows' pure helpers (the continuation of an unfinished start, the pushed sha, the periodic quality slices) with `node`.
- `tools/rules.sh`: the forbidden-content patterns (`URL_RE`, `EMAIL_RE`, `SESSION_RE`, `MODEL_RE`, and the secrets `KEY_RE`, `TOKEN_RE`, `ASSIGN_RE`, reported by label only) `scan`, and `RISKY_CONFIG`, the configuration keys the origin gate refuses, sourced by the gates and the docs lint.
- `tools/docs_lint.sh`: `make docs-lint`; `check_budgets` (`BUDGETS`, `docs/queue.md` among them), `check_content`, `check_wraps`, `check_paths` over the documents agents read, and `check_queue` (every numbered item of `docs/queue.md` with a tier and a size).
- `tools/spec_validate.sh`: `make spec-validate`; strict validation of `openspec/`, then each active change archived in a copy under `build/spec-preview/` and the copy validated strictly (`OPENSPEC_CMD` overrides the command for the tools test).
- `tools/new.sh`: the generators behind `make new-use-case`, `new-action`, `new-ex-command`, `new-test`, and `new-plugin`; `use_case`, `action`, `ex_command`, `test_program`, `plugin`, and the insertion helpers `before`, `after`, `sorted`, `map_file`, `map_test`; each checks every anchor before writing.
- Outside the five roots: `Makefile` (`make help`), `spin.toml`, `.gitignore`, `.github/workflows/ci.yml`, `.github/pull_request_template.md`, `.claude/settings.json` (the attribution, the OpenSpec telemetry, the denied merge), `.claude/workflows/deliver-change.js` and `periodic-review.js`, `.claude/agents/` (the planner and the retrospective among them), `.claude/commands/deliver.md`, `status.md`, `plan.md`, and `review.md`, `docs/metrics.tsv`, the history, `docs/goals.md`, the charter and rubric the planner orders by, and `docs/examples.md` and `docs/spinel-notes.md`, the authoring guides the generators and the docs lint keep current.

Tests: `make check` itself; `tools/tools_test.sh`; `test/smoke_editor.rb` (area 18) runs the built binary.

Designs: `test-build` (One runner, one process per test; Development builds; The analysis budget comes from the runner's own compile; CI), `ci-speed-2` (The compile cache; The allocation budget at `-O 0`; The smoke test on a development build), `analysis-speed` (The budget counts re-narrowing rounds), `delivery-pipeline` (every section), `planner-and-metrics` (every section), `authoring-kit` (every section), `pipeline-speed` (every section).

Rules: CLAUDE.md Hard rules and Commands; `docs/architecture.md` sections 2 and 10. A new command gets a target, a Commands line, and a README line; a new stage goes into `CHECK_STAGES` and CI or the recorded reasons; a new generator writes the shape of its golden example in `docs/examples.md` and gets a test in `tools/tools_test.sh`.

## 2. Toolchain

What: fetches and builds the pinned Spinel commit with no Ruby interpreter, and keeps CRuby unreachable from every target.

Flow: `make toolchain` clones `SPINEL_REF` into `tmp/.spinel`, copies the vendored header in, builds, and installs `spinel`, `spin`, and `spinel-doctor` into `tmp/.toolchain`; every target exports `PATH` with `tmp/.toolchain/bin` and `tools/noruby/` first. `make doctor` reports the tools and `ruby: refused (stub)`; `make no-cruby` proves the stub refuses a snapshot-less `spin test`.

Files:

- `tools/noruby/ruby`: POSIX `sh` stub that prints its refusal with its arguments to standard error and exits 127.
- `tools/spinel/spinel_rt_responds_generated.h`: the header Spinel's build would generate with CRuby, vendored at `SPINEL_REF`; regenerated in the pull request that bumps the pin.

Tests: `make no-cruby`, `make doctor`.

Designs: `toolchain-under-tmp` (Decisions), `no-cruby-guard` (Decisions).

Rules: CLAUDE.md Hard rules (Ruby 4 only through Spinel) and Stack; bump `SPINEL_REF` in its own pull request after `make check` passes.

## 3. Configuration

What: reads `.caratrc` lines (shipped defaults, the user file, the project file) into a `Config` that options, the keymap, and plugins read, and generates the default mirror and the plugin registry.

Flow: `bin/carat.rb` builds `RcConfigGateway` over the file driver; `EditorAssembly` calls `ConfigPort#load` once, which runs `Config#read_defaults` (the embedded `DEFAULT_CARATRC`) and `Config#read` for `~/.config/carat/caratrc` and the untrusted `.caratrc`; each line goes through `RcParser.parse` into an `RcParse` and then `RcLine.from_parse`; `Options.from_config` applies `option.*`, `Keymap#add_checked` the `keymap.*` lines, the plugin host `plugin.<name>.*`; problems are noted with `Config#note` and reported in file and line order (`Config#report`), the first shown after startup. `make gen-config` runs `bin/carat-gen-config.rb`, which writes `carat/domain/default_config.rb` from `config/default.caratrc` and `carat/plugins/registry.rb` through `RegistrySource.render` from `config/plugins.caratrc`.

Files:

- `bin/carat-gen-config.rb`: the generator; writes only what changed and refuses a line that does not read.
- `carat/domain/rc_parser.rb`: `RcParser.parse`, `parse_range`, `key?`, `illegal?`, `unquote`, `failure`; walks a line's bytes into a key and words, with quotes, escapes, and comments, refusing control characters and bytes that are not UTF-8.
- `carat/domain/rc_parse.rb`: `RcParse`, one parse result; `ok?`, `blank?`.
- `carat/domain/rc_line.rb`: `RcLine`, a kept setting with file label, ordinal, line number, scope, name, and words; `from_parse`, `problem`, `order`.
- `carat/domain/rc_value.rb`: `RcValue` bool, integer, string, and list kinds; `valid?`, `expectation`, `text`, `number?`.
- `carat/domain/config.rb`: `Config`; `read_defaults`, `shipped?`, `read`, `refuse`, `line_at`, `last`, `note`, `report` (a stable merge of the ascending runs the readers note); scope and language checks, the project file refused language commands and key-sequence bindings.
- `carat/domain/default_config.rb`: generated, `DEFAULT_CARATRC`; never edited by hand.
- `carat/domain/options.rb`: `Options` record (`icons`, `timeoutlen`, `undolevels`, `theme`, `syntax_on`, `cursorline`, and the rest); `from_config`, `apply`, `width_problem` (tabstop 1 to 9999, shiftwidth 0 to 9999), `tab_width`.
- `carat/domain/registry_source.rb`: `RegistrySource.render`, `entry?`, `names`; the registry text from the plugin list lines.
- `carat/adapters/rc_config_gateway.rb`: `RcConfigGateway#load`, the `ConfigPort` driver over `FilePort` (`home`, `cwd`); refuses a linked project file, a file that is not regular, and one over `LIMIT`.
- Outside the five roots: `config/default.caratrc` (every default option, binding, language command, and plugin setting) and `config/plugins.caratrc` (`plugin.<name> <path> <class>` per compiled plugin).

Tests: `test/domain_rc_parser.rb`, `test/domain_options_config.rb`, `test/adapters_config_gateway.rb`, `test/config_sync.rb` (the mirror and the registry match their sources, the defaults read cleanly and bind every mode).

Designs: `caratrc-config` (all Decisions), `dependency-injection` (Configuration problems at load time), `state-and-ports` (Configuration).

Rules: CLAUDE.md Coding conventions (key bindings are never hard-coded; regenerate with `make gen-config`); `docs/architecture.md` section 7.

## 4. Composition and state

What: builds every record and collaborator once and wires them; the editor state the use cases share.

Flow: `bin/carat.rb` checks the arguments and the terminal, installs `Signals`, builds the drivers and the gateway, and hands them to `EditorAssembly.new`; `EditorAssembly#open` opens the file, or starts the `StartScreen` for no file or a directory; `MainLoop#run` calls `EditorAssembly#render` and `InputController#pump`. Every handler returns an `Outcome`, shown through `Reporting#report`.

Files:

- `bin/carat.rb`: entry point and the only place drivers are constructed; runs `MainLoop` inside the single-call `STDIN.raw` block, entering the screen and opening the file inside the `ensure` that leaves it.
- `carat/adapters/editor_assembly.rb`: `EditorAssembly`; `initialize` (reads the configuration once, builds records and collaborators with a reader for each, builds the ex table and runner before the plugin host, has each feature `register` its handlers, core ex commands before plugin commands, registers and activates plugins, then adds the configuration's bindings with `add_checked`), `open`, `render` (resize, `PluginHost#resized`, `ArrangeView`, `HighlightView`, `FramePresenter`, `ScreenPresenter#present`), `config_errors`.
- `carat/domain/editor_state.rb`: `EditorState`, the thin aggregate of the current view (tab list, mode, options, command line, message, quit flag, pending block insert, screen size); `resize`, `tab`, `window`, `buffer`, `cursor`, `current_line`, `max_col`, `clamp_col`, `selection`, `end_visual`, `show`, `list_message?`, `clear_message`.
- `carat/domain/position.rb`: `Position` value; `sure`, `before?`, `to_a`.
- `carat/domain/range.rb`: `Range` value; `charwise`, `normalized`.
- `carat/domain/cursor.rb`: `Cursor` record (`row`, `col`, `want_col`); `position`, `move_to`.
- `carat/domain/messages.rb`: `Messages`, messages several use cases show (`E36`, `E37`, the register refusals, `seconds_ago`).
- `carat/use_cases/outcome.rb`: `Outcome`; `success`, `failure`, `none` (shared).
- `carat/use_cases/concerns/reporting.rb`: `Reporting#report(state, outcome)`, the one place an outcome reaches the message row.

Tests: `test/adapters_assembly.rb` (every holder of a shared object holds the one the assembly built), `test/editor_normal.rb`.

Designs: `state-and-ports` (The records; Wiring; Constructors), `dependency-injection` (Outcomes and the Reporting concern; Constructors), `editor-foundation` (Entities; Use cases), `data-value-objects`, `struct-record-types`, `struct-keyword-init` (all Decisions).

Rules: CLAUDE.md Coding conventions (keyword constructors, shared objects built once in `EditorAssembly`, record kinds, concerns); `docs/architecture.md` sections 3 and 4.

## 5. Grammar and keymap

What: turns key codes into commands: decoding, keymap lookup per mode, the count-operator-motion grammar, and dispatch to the handler registered for each action.

Flow: `InputController#pump` reads bytes, `KeyDecoder#feed` turns them into key codes, `HandleKey#call(state, code)` tries a scratch buffer's keymap, then the mode's keymap (`Keymap#lookup` over `KeymapNode` with a `KeymapMatch`), and feeds actions to `CommandGrammar#accept` (or `accept_visual`), which reads each action's kind from `ActionTable#kind_of`; a complete `Command` goes to `Dispatcher#call`, which finds the handler (`ActionTable#find`), runs it inside a transaction on the current buffer, records the last change, and reports the `Outcome`; then the plugin host observes and `ArrangeView` runs. `Key::TIMEOUT` resolves keys `HandleKey` kept `:pending` after `timeoutlen`; keys it kept `:waiting` (a lone prefix in a grammar mode) wait for the next key with no deadline.

Files:

- `carat/adapters/key_decoder.rb`: `KeyDecoder`; `feed`, `flush`, `pending?`, `encode`.
- `carat/adapters/input_controller.rb`: `InputController`; `pump` (the `timeoutlen` wait from the options; the start screen's next frame, `tick`, and its dismissal on a key; a 0.02 second wait while the language services wait, and the popup refreshed when a completion answer arrived at the idle tick), `decoder`.
- `carat/domain/key.rb`: `Key` codes; `printable?`, `alt?`, `base`, `char`, `TIMEOUT`.
- `carat/domain/key_notation.rb`: `KeyNotation`; `parse`, `resolve`, `format`, `control_code`, `special_name`; Vim notation such as `<C-w>`.
- `carat/domain/mode.rb`: `Mode`; `from_name`, `name_of`, `visual?`, `visual_kind`, `for_kind`.
- `carat/domain/keymap.rb`: `Keymap`; `action_name?`, `leader_from`, `from_lines`, `add_lines`, `add_checked` (applies the configuration's keymap lines, `none` unbinding, refuses an unknown action and more than `MAX_KEYS` (64) keys, notes problems), `bind`, `bind_owned`, `remove_owner`, `lookup`.
- `carat/domain/keymap_node.rb`: `KeymapNode` trie node; `child?`, `child_for`, `child_named`, `leaf?`.
- `carat/domain/keymap_match.rb`: `KeymapMatch` value (`kind`, `value`), a lookup result.
- `carat/domain/command.rb`: `Command` value (`register`, `count`, `operator`, `action`, `char`, `linewise`, `keys`); `plain`, `count_or`, `operator?`.
- `carat/domain/command_grammar.rb`: `CommandGrammar` state machine; `accept`, `accept_visual`, `take`, `reset`, `wants_char?`, `operator_pending?`, `pending?`, `display`.
- `carat/domain/input_state.rb`: `InputState`, the pending keys and the grammar, owned by `HandleKey`; `pending?`, `take_keys`.
- `carat/use_cases/handle_key.rb`: `HandleKey#call`.
- `carat/use_cases/dispatcher.rb`: `Dispatcher#call`; an arrow key in insert mode closes the session's undo state and opens the next.
- `carat/use_cases/actions/action_handler.rb`: `ActionHandler`, the input port of an action: `kind`, `repeat`, `call(state, command)`.
- `carat/use_cases/actions/action_table.rb`: `ActionTable`; `register` (with the action's short description), `describe`, `register_namespace` (for `plugin.`), `find`, `kind_of`, `include?`, `names`.
- `carat/use_cases/actions/normal_mode_handler.rb`: `NormalModeHandler`, leaving a visual mode itself.
- `carat/use_cases/actions/message_handler.rb`: `MessageHandler`, the quit hint and the reserved actions.
- `carat/use_cases/actions/file_handler.rb`: `FileHandler.register` (`file.save`, `file.find`, `quit.all`, `quit.write_all`); `:w`, `:qa`, and `:wqa` through `SaveFile`, `SaveAll`, and `QuitAll` for the leader groups and Ctrl-S; `file.find` answers "Not implemented" until the finder.
- `carat/use_cases/actions/buffer_handler.rb`: `BufferHandler.register` (`buffer.list`, `buffer.next`, `buffer.previous`, `buffer.delete`); `:ls`, `:bn`, `:bp`, and `:bd` through the buffer use cases, a count stepping or naming the buffer.

Tests: `test/domain_keys.rb`, `test/domain_keymap.rb`, `test/domain_grammar.rb`, `test/adapters_key_decoder.rb`, `test/use_cases_actions.rb` (the tables, the kinds, every handler returning an `Outcome`, the action table against `docs/actions.md`), `test/editor_grammar.rb`, `test/editor_leader.rb`.

Designs: `command-grammar` (The grammar sits between the keymap and the dispatcher; Counts are optional; Dispatcher receives a Command; Bindings), `dependency-injection` (Input ports; The grammar reads kinds), `editor-foundation` (Use cases).

Rules: CLAUDE.md Coding conventions (bindings in `config/default.caratrc` only; every action has a handler and a line in `docs/actions.md`; the action kinds; a new motion binds in five modes); `docs/architecture.md` sections 4, 5.1, and 8.1.

## 6. Motions and text objects

What: every motion as a function of state and count, the text objects as ranges, and pattern search.

Flow: `MotionHandler` (kind `:motion` or `:find`) calls `Move#call`, which asks `Motions.call` for a target and moves the cursor; an operator's motion or `TextObjectHandler`'s object reaches `Operate` (area 7); `;` and `,` repeat through `LastFind`. Search: `/` and `?` (kind `:search`) make the grammar wait for a pattern; `HandleKey` opens the prompt through `OpenSearchPrompt`, and when Enter closed it hands the text to the grammar, whose command `SearchHandler` runs through `JumpToMatch` or `Operate` through `FindMatch`; `n N * # g* g#` are `:motion` actions on the same path. `VimPattern` translates the pattern for Spinel's engine and `Search` matches line by line under a `SearchBudget` (`docs/spinel-notes.md`).

Files:

- `carat/domain/motions.rb`: `Motions`; `call`, `for_command`, `remember`, `NAMES`, `FIND_NAMES`, and one function per motion (`left`, `right`, `line_end`, `find_char`, `vertical`, `word_forward`, `word_backward`, `word_end`, `sentence_forward`, `paragraph_forward`, `screen`, and the rest).
- `carat/domain/motion.rb`: `Motion` value (`target`, `linewise`, `inclusive`, `want`), a target with its kind, never a range.
- `carat/domain/walker.rb`: `Walker`, classifies the code points of the line it walks; `step_forward`, `step_backward`, `char_class`.
- `carat/domain/sentence_starts.rb`: `SentenceStarts`; `add`, `index_at`, `after?`, `before?`.
- `carat/domain/find.rb`: `Find` value (`char`, `forward`, `till`) of `f F t T`; `reversed`.
- `carat/domain/last_find.rb`: `LastFind`, the `;` and `,` repeat; `remember`.
- `carat/domain/text_objects.rb`: `TextObjects`; `call`, `object?`, `NAMES`, `word`, `sentence`, `paragraph`, `pair`, `quote`.
- `carat/domain/runs.rb`: `Runs`, the character class runs of a line; `add`, `class_at`, `index_of`.
- `carat/use_cases/move.rb`: `Move#call`.
- `carat/use_cases/actions/motion_handler.rb`: `MotionHandler.register`, registers `Motions::NAMES` and `FIND_NAMES`.
- `carat/use_cases/actions/text_object_handler.rb`: `TextObjectHandler.register`, registers `TextObjects::NAMES`.
- `carat/domain/vim_pattern.rb`: `VimPattern`; `compile`, `escape`, `pattern_end`; the magic modes, Vim's errors, `MAX_SIZE`, and no backtracking construct.
- `carat/domain/search_pattern.rb`: `SearchPattern` value (`source`, `regexp`, `size`, `error`); `ok?`, `refused`, `none`.
- `carat/domain/search.rb`: `Search`; `find`, `match_at`, `last_before`, `searchable` (U+FFFD for illegal bytes), `action?`, `PROMPT_NAMES`, `MOTION_NAMES`, and the messages.
- `carat/domain/search_budget.rb`: `SearchBudget`, the work a search (`SEARCH`) or a frame (`FRAME`) may do; `charge`, `refund`, `reset`.
- `carat/domain/search_hit.rb`: `SearchHit`, where a search landed, its status and message; `land`, `refused`.
- `carat/domain/last_search.rb`: `LastSearch`, the pattern `n` repeats and what is highlighted; `remember`, `hide`, `show`, `recompile`, `preview_at`, `highlighted`, `drawn`.
- `carat/domain/search_prompt.rb`: `SearchPrompt`, the open `/` or `?` prompt; `open`, `restore`, `enter`, `take_text`.
- `carat/domain/history.rb`: `History`, a prompt's entries; `add`, `older`, `newer`, `restart`.
- `carat/use_cases/search/find_match.rb`: `FindMatch#call`, a search command to a `SearchHit`, remembering the pattern, the `/` register, and the history.
- `carat/use_cases/search/jump_to_match.rb`: `JumpToMatch#call`, moves the cursor to the hit.
- `carat/use_cases/search/open_search_prompt.rb`: `OpenSearchPrompt#call`, opens the prompt for the grammar.
- `carat/use_cases/search/preview_search.rb`: `PreviewSearch#call`, incsearch.
- `carat/use_cases/actions/search_handler.rb`: `SearchHandler.register`, registers `Search::PROMPT_NAMES` (`:search`) and `MOTION_NAMES` (`:motion`).
- `carat/use_cases/ex/nohlsearch_command_handler.rb`: `NohlsearchCommandHandler.register` (`:noh[lsearch]`), hides the highlight.

Tests: `test/editor_motions.rb`, `test/editor_text_objects.rb`, `test/domain_vim_pattern.rb`, `test/domain_search.rb`, `test/editor_search.rb`.

Designs: `command-grammar` (Motions return a target with its kind; Text objects return a range); `buffer-search` (Translate to Spinel's engine; Charge a budget before the engine runs; The grammar reads a pattern).

Rules: a new motion needs a binding in `normal`, `operator_pending`, `visual`, `visual_line`, and `visual_block`, a row in `docs/compatibility.md`, and a table-driven test.

Bench: `lh`, `j`, `w`, `lh-utf8`, `j-utf8`, `long-ascii`, `long-utf8`, `n`.

## 7. Operators and registers

What: the operators over motions, text objects, and doubled forms, the standalone edits, and the registers they write and read.

Flow: `OperatorHandler` (kind `:operator`, the five pending operators) and `EditHandler` (`x s S C D Y J p P r ~`) run `Operate#call` or a standalone use case; `Operate` resolves the range from `Motions.call` or `TextObjects.call`, runs `Operators.extract`, `delete`, `shift`, `recase`, or `join`, and writes `Registers#yank` or `Registers#delete` by Vim's rules; `PutRegister` reads `Registers#read` and calls `Operators.put` or `put_block`.

Files:

- `carat/domain/operators.rb`: `Operators`; `extract`, `delete`, `put`, `join`, `extract_block`, `delete_block`, `put_block`, `shift_block`, `shift`, `unindent`, `recase`, `make_indent`.
- `carat/domain/operator_kind.rb`: `OperatorKind`, the five operator action names.
- `carat/domain/register_entry.rb`: `RegisterEntry` (charwise, linewise, or blockwise); `charwise`, `lines`, `block`, `linewise?`, `blockwise?`, `joined`.
- `carat/domain/registers.rb`: `Registers` (unnamed, named, numbered, small delete, black hole, read-only `. : % /`); `yank`, `delete`, `read`, `read_with_file`, `numbered_at`, `valid_name?`, `read_only?`.
- `carat/use_cases/operate.rb`: `Operate#call`; refuses a read-only register with `E354`.
- `carat/use_cases/replace_chars.rb`: `ReplaceChars#call` (`r`).
- `carat/use_cases/toggle_case.rb`: `ToggleCase#call` (`~`).
- `carat/use_cases/put_register.rb`: `PutRegister#call` (`p`, `P`).
- `carat/use_cases/join_lines.rb`: `JoinLines#call` (`J`).
- `carat/use_cases/actions/operator_handler.rb`: `OperatorHandler.register`.
- `carat/use_cases/actions/edit_handler.rb`: `EditHandler.register`, the standalone edits over a fixed operand.
- `carat/use_cases/ex/register_command_handler.rb`: `RegisterCommandHandler` (`:registers`, `:display`); `line`.

Tests: `test/domain_registers.rb`, `test/editor_operators.rb`, `test/editor_registers.rb`.

Designs: `command-grammar` (Operators are functions over ranges), `undo-and-registers` (Registers), `visual-modes` (Registers get a kind), `use-case-boundaries` (The splits; Shared logic).

Rules: CLAUDE.md Coding conventions (use cases expose one `call`; shared logic in the domain).

Bench: `ddp`, `dd`, `r`, `ciw`.

## 8. Edit path, transactions, and insert mode

What: every change to buffer text goes through one splice in `Buffer`, is recorded, and is grouped into a transaction per command, insert session, or plugin edit request; insert mode types through it.

Flow: a use case calls a `Buffer` primitive (`insert`, `delete`, `replace`, `set_lines`, `reload`), which ends in the private splice: `LineSplice.apply` changes the line array in place, a `ChangeRecord` joins the open `Transaction`, the sign layers and the syntax cache shift. `Dispatcher` opens `begin_transaction` and closes `commit_transaction` (only when the open returned true); `LeaveInsert` closes the insert session's. A closed transaction goes to the file buffer's `UndoTree` and through `BufferFeed#push` as a `BufferNotice` to `TabList#clamp_cursors` and the plugin host. Insert mode: `InsertModeHandler` enters, `InsertTextHandler` routes typed keys to `InsertText`, `BreakLine`, `EraseCharacter`, and `InsertTab`, each noting its step in `LastChange`; `LeaveInsert` repeats a block insert and stores the typed text in the `.` register.

Files:

- `carat/domain/buffer.rb`: `Buffer` record; the primitives `insert`, `delete`, `replace`, `set_lines`, `reload`; `begin_transaction`, `commit_transaction`, `transaction_open?`, `begin_history`, `start_at`, `transaction_mark`; `revert`, `reapply`, `revert_to`; `modified?`, `mark_saved`, `mark_unsaved`, `settle_saved`; `rename`, `detect_filetype`, `assign_filetype`, `icon_of` and `icon` (the file's icon name), `name_start`; `from_text`, `to_text`, `line`, `line_count`, `text_of`, `lines_of`, `first_nonblank`, `indent_of`; `place_sign`, `clear_signs`, `sign_at`; `set_diagnostics`, `clear_diagnostics`, `diagnostic_at` (a language server's diagnostics as the `lsp.diagnostics` sign layer and per-line marks that move with the lines); `scratch?`.
- `carat/domain/text_lines.rb`: `TextLines.split`, text cut at its newlines by bytes, so bytes that are not UTF-8 stay in their lines; used by `from_text`, `joined`, `RegisterEntry#lines`, `:registers`, and messages of several lines.
- `carat/domain/line_splice.rb`: `LineSplice.apply` (per-line `insert` and `delete_at` up to `SMALL` lines, one tail move above) and `shift_marks`.
- `carat/domain/change_record.rb`: `ChangeRecord` (buffer id, row, removed and inserted lines sharing the buffer's strings); `delta`.
- `carat/domain/transaction.rb`: `Transaction` (records, cursor before and after, cause, merged row span, history flag); `add`, `seal`, `truncate`, `span`, `record_at`, `empty?`.
- `carat/domain/buffer_feed.rb`: `BufferFeed`, the one sink of opens, closes, renames, and closed transactions, carrying the command's time and `undolevels`; `push`, `notice_at`, `count`, `clear`, `note`.
- `carat/domain/buffer_notice.rb`: `BufferNotice`; `change?`.
- `carat/domain/buffer_list.rb`: `BufferList` (listed buffers, their ids, the feed, keep or release policy: file buffers stay until `:bd`); `add`, `remove`, `release`, `load` (the empty buffer's number reused, the cursor remembered and restored), `for_path`, `with_id`, `scratch_for`, `hidden_modified`, `any_modified?`, `first_unsaved`, `bring`, `step_from`, `file_count`, `tab_row?`, `replacement_for`, `close_window`, `close_tab`, `close_windows_of`.
- `carat/use_cases/insert_text.rb`: `InsertText#call`.
- `carat/use_cases/break_line.rb`: `BreakLine#call` (Enter).
- `carat/use_cases/erase_character.rb`: `EraseCharacter#call(state, forward)` (Backspace, Delete).
- `carat/use_cases/insert_tab.rb`: `InsertTab#call`.
- `carat/use_cases/leave_insert.rb`: `LeaveInsert#call`.
- `carat/use_cases/actions/insert_mode_handler.rb`: `InsertModeHandler`, entering insert mode itself (`i a I A o O`).
- `carat/use_cases/actions/insert_text_handler.rb`: `InsertTextHandler`.
- `carat/domain/completion_item.rb`: `CompletionItem` (label, kind, detail, insert text); `from_source` drops escape sequences and controls and bounds each string, `icon_name`.
- `carat/domain/completion_list.rb`: `CompletionList`, at most 200 candidates; `add`, `at`, `count`, `clear`.
- `carat/domain/completion_menu.rb`: `CompletionMenu`, the popup's state (cleaned candidates of a word, matches, selection, float id); `showing?`, `for_word?`, `fill`, `chosen`, `clear`.
- `carat/domain/fuzzy_match.rb`: `FuzzyMatch.score` (underscore parts anchored at the word's part starts, in order), `word_start`, `word_length`.
- `carat/use_cases/completion/show_completion.rb`: `ShowCompletion#call(state, typed)`, after a typed character, any key while the popup shows, or an answer the source's request marks arrived: asks the source, filters, ranks, and reopens the popup float, or closes it; no allocation when no popup shows and the source is not ready.
- `carat/use_cases/completion/select_completion.rb`: `SelectCompletion#call(state, step)`, Ctrl-N, Ctrl-P, and the arrows, wrapping.
- `carat/use_cases/completion/accept_completion.rb`: `AcceptCompletion#call(state, replace)`, Enter over the typed part and Tab over the word, in the insert session with its `LastChange` steps.
- `carat/use_cases/completion/close_completion.rb`: `CloseCompletion#call`, Esc while the popup shows.
- `carat/use_cases/actions/completion_handler.rb`: `CompletionHandler.register` (`completion.next`, `completion.previous`, `completion.insert`, `completion.replace`, `completion.close`), bound in the `keymap.completion` layer that `HandleKey` consults first while the popup shows.
- `carat/use_cases/completion/show_completion_docs.rb`: `ShowCompletionDocs#call`; TODO: one line on what it does.

Tests: `test/domain_buffer.rb`, `test/domain_edits.rb` (splice, records, transactions, derived modified flag), `test/domain_buffer_list.rb`, `test/editor_insert.rb`, `test/editor_transactions.rb` (one transaction per command, insert session, reload, and plugin edit), `test/domain_fuzzy_match.rb` (matching, escape sequences, bounds), `test/editor_completion.rb` (every popup key, filtering, placement, the session, untrusted text).

Designs: `edit-pipeline` (all Decisions; Measured result), `state-and-ports` (Cursor clamping from the change records), `plugin-host-hardening` (Events from the edit path).

Rules: CLAUDE.md Coding conventions (buffer text changes only through the primitives; never mutate a line string; the modified flag is derived; who opens transactions); `docs/architecture.md` section 4.1; the lint rule on `lines`.

Bench: `insert`, `ddp`, `memory`, `memory-10k`.

## 9. Undo and repeat

What: the undo tree per buffer with branches and time travel, and the dot command.

Flow: `HistoryHandler` (`u`, `<C-r>`, `U`, `g-`, `g+`, `.`) and `HistoryCommandHandler` (`:undo`, `:redo`, `:undolist`, `:earlier`, `:later`) run `UndoStep`, `RedoStep`, `UndoToState`, `TravelHistory`, `RestoreLine`, or `ListUndo`; each asks `UndoTree` for a path (`undo_path`, `redo_path`, `path_to`) and `WalkHistory#call` replays it inside `Buffer#begin_history` through `revert` and `reapply`, applying Neovim's cursor rule and messages. `RepeatLast#call` reruns `LastChange`'s handler with a new count, the next numbered register, a visual region of the same size, and its insert steps.

Files:

- `carat/domain/undo_tree.rb`: `UndoTree`, a flat table by state number; `push`, `undo_step`, `redo_to`, `undo_seq`, `redo_seq`, `path_to`, `undo_path`, `redo_path`, `nearest`, `leaves`, `mark_saved`, `mark_unsaved`, `at_saved?`, `note_line`, trimming at `undolevels`.
- `carat/domain/last_change.rb`: `LastChange`; `start`, `begin_session`, `add_text`, `add_action`, `stop`, `measure`, `step_at`, `text_at`.
- `carat/use_cases/history/walk_history.rb`: `WalkHistory#call` (clock read for "seconds ago"; `Already at oldest change`).
- `carat/use_cases/history/undo_step.rb`: `UndoStep#call` (`u`).
- `carat/use_cases/history/redo_step.rb`: `RedoStep#call` (`<C-r>`, `:redo`).
- `carat/use_cases/history/undo_to_state.rb`: `UndoToState#call` (`:undo N`).
- `carat/use_cases/history/travel_history.rb`: `TravelHistory#call` (`g-`, `g+`, `:earlier`, `:later`).
- `carat/use_cases/history/restore_line.rb`: `RestoreLine#call` (`U`).
- `carat/use_cases/history/list_undo.rb`: `ListUndo#call` (`:undolist`).
- `carat/use_cases/repeat_last.rb`: `RepeatLast#call`.
- `carat/use_cases/actions/history_handler.rb`: `HistoryHandler.register`.
- `carat/use_cases/ex/history_command_handler.rb`: `HistoryCommandHandler.register`, `digits?`.

Tests: `test/domain_undo_tree.rb`, `test/editor_undo.rb`, `test/editor_repeat.rb`.

Designs: `undo-and-registers` (The undo tree is a flat table; Applying a state goes through the splice; Saved state; Records on one line are merged; Time and undolevels; The U line; The dot command records commands, not keys; Measured result), `use-case-boundaries` (The splits).

Rules: undo applies through the splice as a history transaction that observers see but that makes no state.

Bench: `undo`, `undo-line`, `dot-r`, `dot-dd`, `dot-ciw`.

## 10. Visual modes

What: charwise, linewise, and blockwise selection, with every motion and text object and the operators on the selection.

Flow: `VisualModeHandler` runs `StartVisual` (enter, switch, leave), `ReselectVisual` (`gv`), `SwapVisualEnds` (`o`, `O`), and `ExtendVisual` (text objects); the anchor and the last selection live on the `Window`, and `EditorState#selection` resolves them to a `Selection`. In a visual mode the five operators complete at once; `SelectionHandler` runs one use case per operator, which use `SelectionCut.call`, the `Operators` block functions, and `BlockInsert` (repeated by `LeaveInsert`).

Files:

- `carat/domain/selection.rb`: `Selection`; `none`, `cells`, `active?`, `start`, `finish`, `top`, `bottom`, `covers?`, `char_range`, `line_range`, `block`, `span`, `lines_or_block`.
- `carat/domain/span.rb`: `Span`, one row's columns; `empty`.
- `carat/domain/block.rb`: `Block` of display columns; `span`, `short?`, `reaching_rows`.
- `carat/domain/block_insert.rb`: `BlockInsert`, the repetition a blockwise `I`, `A`, or `c` owes; `start`, `row_at`, `clear`.
- `carat/domain/selection_cut.rb`: `SelectionCut.call`, shared by visual delete, change, and put.
- `carat/use_cases/visual/start_visual.rb`: `StartVisual#call`.
- `carat/use_cases/visual/reselect_visual.rb`: `ReselectVisual#call`.
- `carat/use_cases/visual/swap_visual_ends.rb`: `SwapVisualEnds#call`.
- `carat/use_cases/visual/extend_visual.rb`: `ExtendVisual#call`.
- `carat/use_cases/visual/delete_selection.rb`, `carat/use_cases/visual/yank_selection.rb`, `carat/use_cases/visual/change_selection.rb`, `carat/use_cases/visual/shift_selection.rb`, `carat/use_cases/visual/join_selection.rb`, `carat/use_cases/visual/recase_selection.rb`, `carat/use_cases/visual/insert_at_selection.rb`, `carat/use_cases/visual/put_over_selection.rb`: one `call` per operator, the uppercase keys as a shape or a flag.
- `carat/use_cases/actions/visual_mode_handler.rb`: `VisualModeHandler.register`.
- `carat/use_cases/actions/selection_handler.rb`: `SelectionHandler.register`.

Tests: `test/domain_selection.rb`, `test/editor_visual.rb`.

Designs: `visual-modes` (all Decisions), `use-case-boundaries` (The splits; Shared logic).

Rules: the visual keys whose meaning differs are `visual.*` actions; motions bind in the three visual maps.

## 11. Windows and tabs

What: the split layout per tab page, the `<C-w>` commands, scrolling a window, tab pages, the buffer list commands, and their ex commands.

Flow: `WindowHandler` (`<C-w>` keys, equalizing itself) and `WindowCommandHandler` (`:sp`, `:vs`, `:new`, `:vnew`, `:close`, `:only`) run `SplitWindow`, `CloseWindow`, `CloseOtherWindows`, and `FocusWindow` with a `FocusRequest`; `ScrollHandler` (`<C-f> <C-b> <C-d> <C-u> <C-e> <C-y> zt zz zb <PageDown> <PageUp>`) runs `ScrollWindow` with a `ScrollRequest`, which moves `Window#top` and the cursor; `TabHandler` (`gt`, `gT`) and `TabCommandHandler` (the `:tab*` commands) run `OpenTab`, `CloseTab`, `CloseOtherTabs`, and `SwitchTab` with a `TabRequest`; `BufferCommandHandler` runs `ListBuffers`, `SwitchBuffer` with a `BufferRequest`, and `DeleteBuffer` over `BufferList`. They change `Layout` (`split`, `split_edge`, `close`, `neighbour`, `equalize`) in the current `TabPage` and `TabList`; `BufferList#close_window` lets go of buffers. `ArrangeView#call` runs after every key and before every render: `Layout#arrange` for the screen size, every window scrolled to its cursor, then each float of the `FloatLayer` placed and scrolled. A focused float is `TabPage#window`; `FocusWindow` leaves it, `CloseWindow` and `Quit` close it, and `FloatHandler` (normal `<Esc>`) runs `CloseFloat` on the topmost.

Files:

- `carat/domain/window.rb`: `Window` record (id, buffer, cursor, scroll, rectangle, fixed width, visual anchor, last selection); `show`, `copy_from`, `gutter_width`, `scroll_to_row`, `scroll_top_to`, `max_top`, `margin` (the clamp and scrolloff cap `ArrangeView` and `ScrollWindow` share), `scroll_to_col`.
- `carat/domain/layout_node.rb`: `LayoutNode`; `leaf?`.
- `carat/domain/layout.rb`: `Layout`, a flat node table; `split`, `split_edge`, `close`, `leaves`, `leaf_of`, `neighbour`, `equalize`, `arrange`, `number_of`, `first_leaf`, `fixed_width?`.
- `carat/domain/tab_page.rb`: `TabPage` with its `FloatLayer`; `window` (the focused float first), `layout_window`, `window_count`, `focus` (leaves a float), `previous?`.
- `carat/domain/float_spec.rb`: `FloatSpec` (anchor, offset, size, border, title, z); `edge`, `moved`, `refusal`.
- `carat/domain/float_window.rb`: `FloatWindow` (a window, its spec, and `selected`, a menu's selected row or -1); `menu?`, `place` clamps the box to the screen, `box_top`, `box_bottom`, `box_left`, `box_right`.
- `carat/domain/float_layer.rb`: `FloatLayer`, a tab page's floats by z with the focused index, at most 16; `add`, `close`, `close_top`, `close_focused`, `enter`, `leave`, `move`.
- `carat/domain/tab_list.rb`: `TabList`; `tab`, `window`, `add_tab`, `remove_tab`, `next_tab`, `previous_tab`, `adopt`, `window_tab`, `float_tab`, `total_windows`, `shown?`, `windows_showing`, `focus_buffer`, `modified_in_windows`, `clamp_cursors`.
- `carat/use_cases/arrange_view.rb`: `ArrangeView#call`; the top row goes to the buffer tabs when `BufferList#tab_row?`.
- `carat/use_cases/windows/split_window.rb`: `SplitWindow#call`; every new window gets its id.
- `carat/use_cases/windows/open_side_window.rb`: `OpenSideWindow#call`, a plugin's fixed-width side window.
- `carat/use_cases/windows/open_float.rb`, `carat/use_cases/windows/close_float.rb`: `OpenFloat#call` (the id, the layer, enter), `CloseFloat#call` (the topmost for 0, else by id in any tab page).
- `carat/use_cases/windows/close_window.rb`, `carat/use_cases/windows/close_other_windows.rb`: `call`.
- `carat/use_cases/windows/focus_window.rb`: `FocusWindow#call`; `carat/use_cases/windows/focus_request.rb`: `FocusRequest` (target, count); `steps`.
- `carat/use_cases/windows/scroll_window.rb`: `ScrollWindow#call`, the page, half-page, line, and `zt zz zb` scrolls of the current window, the cursor kept in view with scrolloff and its wanted column; `carat/use_cases/windows/scroll_request.rb`: `ScrollRequest` (target, count); `steps`.
- `carat/use_cases/windows/open_tab.rb`, `carat/use_cases/windows/close_tab.rb`, `carat/use_cases/windows/close_other_tabs.rb`: `call`.
- `carat/use_cases/windows/switch_tab.rb`: `SwitchTab#call`; `carat/use_cases/windows/tab_request.rb`: `TabRequest`; `counted?`.
- `carat/use_cases/actions/window_handler.rb`: `WindowHandler.register`.
- `carat/use_cases/actions/tab_handler.rb`: `TabHandler.register`.
- `carat/use_cases/actions/float_handler.rb`: `FloatHandler.register`, `float.close` (normal-mode `<Esc>`).
- `carat/use_cases/actions/scroll_handler.rb`: `ScrollHandler.register`, the nine `scroll.*` actions, each a `ScrollRequest` target for `ScrollWindow`.
- `carat/use_cases/ex/window_command_handler.rb`: `WindowCommandHandler.register`.
- `carat/use_cases/ex/tab_command_handler.rb`: `TabCommandHandler.register`.
- `carat/use_cases/buffers/buffer_request.rb`: `BufferRequest` (target, count, bang); `steps`.
- `carat/use_cases/buffers/list_buffers.rb`: `ListBuffers#call(state, flags, bang)`, the `:ls` listing with Neovim's columns and flag filters.
- `carat/use_cases/buffers/switch_buffer.rb`: `SwitchBuffer#call(state, request)`, `:bn`, `:bp`, `:bN`, `:b N` (`E37`, `E85`, `E86`).
- `carat/use_cases/buffers/delete_buffer.rb`: `DeleteBuffer#call(state, number, bang, typed)`, `:bd` in the order of Neovim's `do_buffer` (`E89`, `E516`).
- `carat/use_cases/ex/buffer_command_handler.rb`: `BufferCommandHandler.register` (`:ls`, `:buffers`, `:files`, `:b[uffer]`, `:bn[ext]`, `:bp[revious]`, `:bN[ext]`, `:bd[elete]`), the number and count arguments.

Tests: `test/domain_layout.rb`, `test/domain_tab_list.rb`, `test/use_cases_arrange_view.rb`, `test/editor_windows.rb`, `test/editor_tabs.rb`, `test/editor_scroll.rb`, `test/editor_buffers.rb`, `test/domain_float_layer.rb`, `test/editor_floats.rb`.

Designs: `windows-and-splits` (all Decisions), `buffer-list` (all Decisions), `render-core` (ArrangeView and the screen size), `use-case-boundaries` (Variants), `floating-windows` (all Decisions).

Rules: CLAUDE.md Coding conventions (variants through one `call`, as a `Data` request when they carry a count).

## 12. Ex commands, the command line, and files

What: command-line mode, the ex grammar, ranges, and names, the ex table, the file commands (`:w`, `:q`, `:e`, and their families), substitute (`:s`, `:&`, `&`, `g&`), the global commands (`:g`, `:g!`, `:v`), and `:d`.

Flow: `CommandLineHandler` runs `EnterCommandLine` (`:`), `EditCommandLine` (typed text), `EraseCommandLine`, `CancelCommandLine`, and `ExecuteCommandLine` (Enter; a plugin's open prompt gets Enter and cancel; an executed line becomes the `:` register); `ExecuteCommandLine` calls the `CommandRunner`, `ExecuteEx#call`, which parses with `ExGrammar.parse` into an `ExCommand`, finds the first handler whose `ExName` matches in the `ExTable` (`E492` otherwise), and runs `ExHandler#call(state, ex_command)`; a range before a handler whose `ranged?` is false is `E481`, and a range alone moves the cursor. A ranged handler resolves `ExCommand#range` with `ExRange.resolve`. Substitute: `SubstituteCommandHandler` (`:s`, `:&`) and `SubstituteHandler` (`&`, `g&`) parse `SubstituteArgs` and call `SubstituteLines`, which applies the flags to `LastSubstitute`, compiles with `VimPattern.compile_substitute`, runs `Substitution.line` per row under one `SearchBudget`, and replaces the changed span in one `set_lines`. `FileCommandHandler` runs `OpenFile`, `SaveFile`, `SaveAll`, `Quit`, and `QuitAll`.

Files:

- `carat/domain/ex_command.rb`: `ExCommand` value (`range`, `name`, `bang`, `args`).
- `carat/domain/ex_grammar.rb`: `ExGrammar.parse`, `range_end`, `letter?`; the `&` name.
- `carat/domain/ex_range.rb`: `ExRange` value (`first`, `last`, `given`, `error`); `resolve` (`%`, `.`, `$`, numbers, `'<`, `'>`, `E16`, `E20`, `E493`).
- `carat/domain/delimited_pattern.rb`: `DelimitedPattern` value; `parse` (the delimiter and pattern of `:s`, `:g`, and `:v`; `E146`), the one reader `SubstituteArgs` and `GlobalArgs` call.
- `carat/domain/substitute_args.rb`: `SubstituteArgs` value; `parse` (delimiter, pattern, string, flags, count; `E146`, `E488`).
- `carat/domain/last_substitute.rb`: `LastSubstitute`, what the next substitute reuses; `apply_flags`, `keep_replacement`, `keep_previous`.
- `carat/domain/replacement.rb`: `Replacement`; `tilde`, `check`, `expand` (the string's special characters; a line break as `BREAK`).
- `carat/domain/substituted_line.rb`: `SubstitutedLine` value (`text`, `count`); `changed?`.
- `carat/domain/substitution.rb`: `Substitution.line`, one line under the budget, Vim's empty-match rule, `OUTPUT_COST` per character of replacement.
- `carat/domain/global_args.rb`: `GlobalArgs` value; `parse` (delimiter, pattern, command; `E146`, `E148`).
- `carat/domain/global_marks.rb`: `GlobalMarks`, a running global's marked lines, moved by `Buffer#splice` through `LineSplice.shift_marks`; `mark`, `take`, `shift`, `clear`.
- `carat/domain/register_count.rb`: `RegisterCount` value; `parse` (`[x] [count]` of a line command; `E488`, `E939`).
- `carat/domain/ex_name.rb`: `ExName` in Vim's `name[suffix]` notation; `parse`, `match?`, `to_s`; the one matcher for core and plugin commands.
- `carat/use_cases/ex/command_runner.rb`: `CommandRunner`, the interface the command line and the plugin host depend on.
- `carat/use_cases/ex/execute_ex.rb`: `ExecuteEx#call`.
- `carat/use_cases/ex/ex_handler.rb`: `ExHandler`; `matches?`, `call`.
- `carat/use_cases/ex/ex_table.rb`: `ExTable`, handlers in order of precedence; `register`, `find`, `names`.
- `carat/use_cases/ex/file_command_handler.rb`: `FileCommandHandler.register`.
- `carat/use_cases/ex/substitute_command_handler.rb`: `SubstituteCommandHandler.register` (`:s[ubstitute]`, `:&`), `ranged?`.
- `carat/use_cases/ex/global_command_handler.rb`: `GlobalCommandHandler.register` (`:g[lobal]`, `:g!`, `:v[global]`), `ranged?`; every line without a range.
- `carat/use_cases/ex/delete_command_handler.rb`: `DeleteCommandHandler.register` (`:d[elete] [x] [count]`), `ranged?`.
- `carat/use_cases/search/global_command.rb`: `GlobalCommand#call(state, first, last, text, invert)`: marks under the budget, remembers the pattern, runs the command per marked line through the `CommandRunner` in one transaction, lists without one, `E147` when nested with a range.
- `carat/use_cases/delete_lines.rb`: `DeleteLines#call(state, first, last, register)`, the linewise delete into a register.
- `carat/use_cases/search/substitute_lines.rb`: `SubstituteLines#call(state, first, last, args)`, the one substitute use case.
- `carat/use_cases/actions/substitute_handler.rb`: `SubstituteHandler.register` (`substitute.repeat`, `substitute.repeat_all`).
- `carat/use_cases/enter_command_line.rb`, `carat/use_cases/edit_command_line.rb`, `carat/use_cases/erase_command_line.rb`, `carat/use_cases/cancel_command_line.rb`, `carat/use_cases/execute_command_line.rb`: `call`.
- `carat/use_cases/actions/command_line_handler.rb`: `CommandLineHandler.register`.
- `carat/use_cases/files/open_file.rb`: `OpenFile#call` (`:e!` reloads through `Buffer#reload`; a directory, a FIFO, a device, or a file over 64 MiB is refused).
- `carat/use_cases/files/save_file.rb`: `SaveFile#call` (`E382` for a scratch buffer, `mark_saved`, `buffer_save` to the host).
- `carat/use_cases/files/save_all.rb`: `SaveAll#call`, the write-all loop of `:wa`, `:wqa`, `:xa`.
- `carat/use_cases/files/quit.rb`: `Quit#call(state, way)` with `:quit`, `:force`, or `:written`; a file window beside only side windows counts as the last.
- `carat/use_cases/files/quit_all.rb`: `QuitAll#call` (`:qa`).
- `carat/use_cases/files/probe_path.rb`: `ProbePath#call`, the one call of `FilePort#stat`, shared by `OpenFile` and the plugin file operations.
- `carat/use_cases/files/make_path.rb`, `carat/use_cases/files/rename_path.rb` (the listed buffers following), `carat/use_cases/files/delete_path.rb`: `call`; make, rename, and delete inside a root with every check, used by the plugin file requests, each refusing a parent (create) or an entry's directory (rename, delete) that `ResolveInside` places outside the root.
- `carat/use_cases/files/resolve_inside.rb`: `ResolveInside#call(root, dir, path)`, the one comparison of real paths (`FilePort#real_path`): `Outside the tree root: path` unless the directory with its links resolved is the resolved root or inside it; built by `PluginHost` and shared by the three.
- `carat/use_cases/recall_history.rb`: `RecallHistory#call`, `<Up>` and `<Down>` through the prompt's `History` (`:` or search).
- `carat/use_cases/ex/lsp_start_command_handler.rb`: `LspStartCommandHandler.register` (`:LspStart`): starts the current buffer's language server, trusted directory or not, through `LanguageServicePort#start`.
- `carat/use_cases/ex/lsp_restart_command_handler.rb`: `LspRestartCommandHandler.register` (`:LspRestart`): stops every language server and starts the current buffer's again through `LanguageServicePort#restart`.

Tests: `test/domain_ex_grammar.rb`, `test/use_cases_ex.rb` (every documented ex spelling), `test/editor_cmdline.rb`, `test/domain_ex_range.rb`, `test/domain_substitute.rb`, `test/editor_substitute.rb`, `test/domain_global.rb`, `test/editor_global.rb`.

Designs: `ex-write-quit-all` (all Decisions), `dependency-injection` (Ex names; ExecuteEx moves to use_cases/ex), `editor-foundation` (Use cases), `plugin-explorer` (The file requests are validated in the host), `use-case-boundaries` (The splits), `buffer-substitute` (all Decisions), `buffer-global` (all Decisions).

Rules: CLAUDE.md Coding conventions (a new ex command is an `ExHandler` registered in the order of `docs/compatibility.md`; every Neovim command gets a row there and a table-driven test); `docs/architecture.md` section 5.2.

## 13. Rendering

What: paints the state into flat frames from decoded lines and writes only the changed cells to the terminal.

Flow: `EditorAssembly#render` runs `ArrangeView` and `HighlightView`, then `FramePresenter#call(state)` paints every window of the current tab page (sign column, the visual selection, the syntax tokens from `SyntaxCache#lookup`) with a `WinSeparator` row under each window above another, the buffer tabs row through `TabBar#paint` when `BufferList#tab_row?`, the one status bar through `StatusBar#paint`, and the message row from decoded lines (`LineCache#fetch`, `DecodedLine.decode`) into one of two `Frame`s in turn, painting a row only when `PaintedRows` says what it shows changed and recording dirty rows and a full-width window's scroll; `ScreenPresenter#present(frame)` writes the changed runs of the dirty rows, scroll regions, or a full redraw, in one `TerminalPort#write`, each group in its `SgrTable` sequence. While the `StartScreen` shows, the presenter paints its `StartArt` frame over the current window after the windows.

Files:

- `carat/adapters/frame_presenter.rb`: `FramePresenter#call`, `display_col`, `display_width`; reads the state only; the floats of the tab page by z over everything but the message row (`paint_floats`, `paint_float_row`, `paint_border_row`, `mend_edges`), their boxes kept as the frame's float key (`build_float_key`, `forget_rows`, `compare_boxes`, `clear_repainted`, `under_float?`: no scroll under a float); a message of several lines over the bottom rows with the hit-enter line; in normal mode with no message the cursor line's diagnostic (`paint_diagnostic`, `diagnostic_group`); the current window's cursor line lifted onto the cursor-line layer, and `shape_of` the mode.
- `carat/adapters/status_bar.rb`: `StatusBar#paint`, the global bar: the mode pill, file, branch, diagnostics, plugin segments, `lsp` slot, file type, encoding, position, and percent, dropped by `PRIORITIES` when narrow without allocating; `mode_name`, `mode_group`, `lsp_group`.
- `carat/adapters/tab_bar.rb`: `TabBar#paint`, a tab per listed file buffer with its icon and modified dot, overflow counts, and the tab-page numbers at the right end, without allocating.
- `carat/domain/status_slots.rb`: `StatusSlots` record (`branch`, the diagnostics counts, `lsp_name`, `lsp_state`), empty until git and language services fill it; `count_diagnostics`, `diagnostics?`, `lsp?`.
- `carat/adapters/painted_rows.rb`: `PaintedRows`, what every window row segment of a frame shows, its cursor-line layer included; `same?`, `store`, `invalidate`, `forget` (one row), `painted?`.
- `carat/adapters/screen_presenter.rb`: `ScreenPresenter`; `enter`, `leave` (the terminal's own cursor shape back), `present` (`shape_sequence`: block, bar, underline); a cell code that is not a scalar value is written as U+FFFD, and one of 0x80 or more from the UTF-8 text `glyph` keeps for it (`GLYPH_LIMIT`); a theme that paints the background has Normal in effect at each clear and scroll.
- `carat/domain/frame.rb`: `Frame`, cells in three flat integer arrays, the layout key and the float key; `put`, `put_code`, `put_within`, `put_from`, `fill`, `blank`, `set_hl`, `lift`, `same_row?`, `dirty?`, `dirty_rows`, `reset_rows`, `mark_all_dirty`, `add_scroll`, `row_text`.
- `carat/domain/cell.rb`: `Cell`, a value view of one cell for tests.
- `carat/domain/start_art.rb`: `StartArt`, the start screen's six frames and wordmark computed once from the gem's legend, Unicode in the theme's groups or ASCII in Normal; `from_plain`, `none`, `paint` (centred in a window, the wordmark alone when it does not fit).
- `carat/domain/start_screen.rb`: `StartScreen` record (`showing`, `step`, `started`, `art`); `start`, `animating?`, `due?`, `advance`, `wait`, `dismiss`, `paint`; the input controller advances it on the clock and dismisses it on a key, the frame presenter paints it over the current window.
- `carat/domain/utf8.rb`: `Utf8`; `size_at` (RFC 3629, every other byte one U+FFFD character, as `String#length` counts), `code_at`, `codes`, `scalar?`; decodes by walking bytes.
- `carat/domain/display_width.rb`: `DisplayWidth`; `of`, `of_char`, `text_width`, `cell`, `code_of`, `column`, `col_at`, `private_use?`, `control?`; the private use areas are one cell wide.
- `carat/domain/decoded_line.rb`: `DecodedLine`, a line's code points and display columns; `decode`, `plain?`, `code`, `col`, `width`, `index_at`.
- `carat/domain/identity_table.rb`: `IdentityTable`, keyed by object identity; `find`, `store`, `clear`.
- `carat/domain/line_cache.rb`: `LineCache`, decoded lines of the visible rows in two generations, shared by `ArrangeView` and the presenter; `fetch`, `turn`, `holds?`.

Tests: `test/domain_frame.rb`, `test/domain_line_cache.rb`, `test/adapters_frame_presenter.rb`, `test/adapters_dirty_rows.rb`, `test/adapters_screen_presenter.rb`, `test/editor_screen.rb`, `test/domain_utf8.rb` (hostile byte sequences through the decoder, display width, `TextLines`, and the plugin API's path segments), `test/editor_start_screen.rb` (every start screen frame, in color and plain, in its snapshot; the options, `NO_COLOR`, small windows, and the key that ends it), `test/adapters_status_bar.rb` (each segment, each width, the pills and the `lsp` states), `test/adapters_tab_bar.rb` (tabs, overflow, tab-page numbers).

Designs: `render-core` (all Decisions; Measured result), `escape-c1-control-codes` (all Decisions), `windows-and-splits` (Rendering), `visual-modes` (Rendering), `cursor-shapes` (all Decisions), `bars` (all Decisions), `floating-windows` (Painting by z with a float key), `diagnostics-display` (The message row), `completion` (The popup is a float).

Rules: the presenters read the state only; `docs/architecture.md` section 8.2.

Bench: `lh`, `j`, `long-ascii`, `long-utf8`, `open-plain`, `lh-float` (a 60 by 15 float open); `make profile` for `j` and `lh`; `make bench-budget` on `lh`.

## 14. Syntax highlighting

What: the highlight engine in the core, each language a plugin: filetype detection, highlight groups, the syntax cache, themes, and color output.

Flow: a buffer detects its `filetype` when made or renamed (`Filetype.detect`); before every render `HighlightView#call` brings the `SyntaxCache` of every visible buffer up to date for its window, tokenizing only the visible rows and those above them through `PluginSyntax#tokenize`, which calls the first enabled plugin declaring the syntax (`Plugin#tokenize`, here `Ruby::Plugin` and `Tokenizer#call`) on the guarded path and validates the tokens; the splice invalidates the cache from the changed row until the state settles; `FramePresenter` reads `SyntaxCache#lookup` and `ScreenPresenter` writes each group in its `SgrTable` sequence from the `Theme` at the terminal's `ColorDepth`. `:syntax` and `:set filetype=`/`syntax=` switch it.

Files:

- `carat/domain/highlight.rb`: `Highlight` group ids (49 UI groups, the status bar's last, thirty syntax groups from `SYNTAX_FIRST`, thirteen file-icon groups from `ICON_FIRST`, with Neovim's `NAMES`, and each again from `CURSOR_LINE_LAYER` below `LIMIT` on the cursor line); `token_id`, `token?`, `name_of`, `base`.
- `carat/domain/theme.rb`: `Theme`, per group 24-bit, 256-color, and 16-color colors and attributes; `fg`, `bg`, `fg256`, `bg256`, `fg16`, `bg16`, `attr`, `attr16`, `paints_background?`.
- `carat/domain/themes.rb`: `Themes`, the palettes as colors per role and `GROUPS`, the roles of every group; `known?`, `background?`, `canonical`, `find`, `palette`, `from_palette` (the cursor-line layer included; `one_dark`, `one_light`, `dark_plus`, `light_plus`, aliases `carat-dark`, `carat-light`).
- `carat/domain/color_depth.rb`: `ColorDepth.detect` from `COLORTERM` and `TERM`.
- `carat/domain/filetype.rb`: `Filetype`; `detect`, `from_name`, `from_shebang`.
- `carat/domain/syntax_line.rb`: `SyntaxLine`, one line's tokens for a start state with its end state.
- `carat/domain/syntax_table.rb`: `SyntaxTable`, the identity table of them; `find`, `store`, `clear`.
- `carat/domain/syntax_cache.rb`: `SyntaxCache`; `prepare`, `active?`, `drop`, `start_of`, `find`, `store`, `advance`, `shift`, `lookup`.
- `carat/use_cases/syntax/highlight_view.rb`: `HighlightView#call`, `tokenized` (read by the benchmark); a failing plugin's buffer dropped or taken over by the next plugin in the same frame.
- `carat/use_cases/plugins/plugin_syntax.rb`: `PluginSyntax`; `provider`, `tokenize`, `copied_tokens`.
- `carat/use_cases/ex/syntax_command_handler.rb`: `SyntaxCommandHandler` (`:syntax on`, `enable`, `off`).
- `carat/use_cases/ex/set_command_handler.rb`: `SetCommandHandler` (`:set` for `filetype`, `syntax`, the four search options, and `cursorline`).
- `carat/adapters/sgr_table.rb`: `SgrTable`; `from_theme`, `at`, `sequence`, `index_256`.
- `carat/plugins/ruby/plugin.rb`: `Ruby::Plugin`; `manifest`, `activate`, `tokenize`.
- `carat/plugins/ruby/tokenizer.rb`: `Tokenizer#call`, the Ruby tokenizer.
- `carat/plugins/ruby/line_state.rb`: `LineState`, the documented integer state encoding (`pack`, `mode`, `heredoc`, `frame`, and their fields).
- `carat/plugins/ruby/keywords.rb`: `Keywords`; `find`, `lookup`, `kind`.
- `carat/plugins/ruby/groups.rb`: `Groups`, the integer group constants the tokenizer emits (`COMMENT`, `CONSTANT`, `STRING`, and the rest).

Tests: `test/domain_filetype.rb`, `test/domain_theme.rb`, `test/domain_syntax_cache.rb`, `test/use_cases_plugin_syntax.rb`, `test/plugins_ruby.rb`, `test/editor_syntax.rb`.

Designs: `syntax-highlighting` (all ten Decisions), `cursor-shapes` (The cursor line is a layer of group ids).

Rules: `docs/architecture.md` section 4.2; the plugin rules of area 15. Range highlights, virtual text, other languages, the rest of `:set`, user themes, and semantic highlighting are in `docs/backlog.md`.

Bench: `lh-ruby`, `j-ruby`, `insert-ruby`, `heredoc-ruby`, `string-ruby`, `quote-ruby`, `open-ruby`, `G-ruby`.

## 15. Plugin host and API

What: the plugin API every plugin requires and the host that registers plugins, routes actions, ex commands, and prompt answers to them, delivers events, and serves their requests.

Flow: `EditorAssembly` registers `Plugins::Registry.all` with `PluginHost#register` (`PluginRegistry#register`, every manifest rule in `ManifestCheck.check`) and calls `activate_all` once every ex command is registered. A `plugin.<name>.<action>` binding reaches `PluginActionHandler` through the action table's namespace and `PluginHost#action` → `PluginRouter#action`; an unknown ex command reaches `PluginCommandHandler` (registered last) → `PluginHost#command`. Every call into a plugin goes through `Guarded#guarded`, which disables and cleans up a plugin that raises. A plugin calls its `PluginLink` (a `PluginApi::Host`), which refuses a disabled plugin and forwards to `BufferRequests`, `WindowRequests`, `FileRequests`, or `UiRequests`. After each key `HandleKey` calls `PluginHost#observe`; `PluginEvents` compares the state, queues events caused during plugin calls, and delivers them after the outermost call in bounded rounds.

Files:

- `carat/plugin_api.rb`: `Carat::PluginApi` (`VERSION` 2.3, `STATUS_PRIORITY`, `PRIORITY_MAX`, `EVENTS`, `OPTION_TYPES`, `SIDES`), the values `Manifest`, `Event`, `Context`, `Command`, `Edit`, `Response`, `WindowResponse`, `FloatOptions` (`at`), `TextResponse`, `BufferView`, `FileInfo`, `Input`, the path functions `Paths` (`normalize`, `join`, `dirname`, `basename`, `relative`, `inside?`), the file-icon table `FileIcons` (`file_type`, `group_of`, shared by the explorer and the buffer tabs), the `Host` base class (one method per request: `read_buffer`, `edit_buffer`, `open_scratch`, `open_in_split`, `run_ex`, `list_dir`, `make_file`, `prompt`, `syntax_group`, `set_segment`, and the rest), and the `Plugin` base class (`manifest`, `activate`, `deactivate`, `on_event`, `on_action`, `on_command`, `on_input`, `tokenize`).
- `carat/domain/manifest_check.rb`: `ManifestCheck.check` and its `check_*` rules (API version, shapes, actions, commands, events, bindings, options, filetypes).
- `carat/domain/path_policy.rb`: `PathPolicy`; `create_problem`, `rename_problem`, `inside?`, `shown`.
- `carat/domain/path_info.rb`: `PathInfo` value `FilePort#stat` returns (`exists`, `size`, `mtime`, `directory`, `symlink`, `regular`); `missing`, `real_directory?`.
- `carat/domain/plugin_ui.rb`: `PluginUi`, status segments with their order (`owners`) and `priorities`, and the open prompt; `open_prompt`, `close_prompt`, `prompting?`, `segment`, `text_at`, `remove_segment`, `drop`.
- `carat/domain/sign_layer.rb`: `SignLayer`, one plugin's signs in one buffer, moved with the lines; `place`, `glyph_at`.
- `carat/use_cases/plugins/plugin_host.rb`: `PluginHost`, the facade the core calls; `register`, `activate_all`, `action`, `command?`, `command`, `answer`, `observe`, `saved`, `resized`, `option`, `enabled?`, `errors`.
- `carat/use_cases/plugins/plugin_registry.rb`: `PluginRegistry`; `register`, `activate_all`, `deactivate_all`, `disable` (cleanup), `refusal`, `enter`, `leave`, `depth`, `busy?`, `cause`, `owner_of_command`.
- `carat/use_cases/plugins/plugin_entries.rb`: `PluginEntries`, the list with a typed reader; `add`, `entry`, `find`.
- `carat/use_cases/plugins/plugin_entry.rb`: `PluginEntry` record; `subscribed?`, `command?`, `tokenizes?`.
- `carat/use_cases/plugins/plugin_router.rb`: `PluginRouter`; `action`, `command?`, `command`, `answer`.
- `carat/use_cases/plugins/plugin_events.rb`: `PluginEvents`; `observe`, `flush`, `saved`, `resized`.
- `carat/use_cases/plugins/pending_event.rb`: `PendingEvent`; `for?`.
- `carat/use_cases/plugins/plugin_link.rb`: `PluginLink`, the per-plugin `Host`; one override per `Host` method.
- `carat/use_cases/plugins/buffer_requests.rb`: `BufferRequests`; `read_buffer`, `edit_buffer` (validated item by item, one transaction), `move_cursor`, `place_sign`, `clear_signs`.
- `carat/use_cases/plugins/window_requests.rb`: `WindowRequests`; `open_scratch`, `set_scratch_lines`, `close_scratch`, `focus_window`, `open_file`, `open_in_split`, `open_in_tab`, `editing_window`, `scratch_window`, `open_float`, `move_float`, `close_float` (a plugin's own floats only, `own_float_tab`); `focus_window` enters a float.
- `carat/use_cases/plugins/file_requests.rb`: `FileRequests`; `list_dir`, `stat`, `make_file`, `make_dir`, `rename_path`, `delete_path`.
- `carat/use_cases/plugins/ui_requests.rb`: `UiRequests`; `message`, `set_status`, `set_segment`, `prompt`, `icon`, `syntax_group`, `option`, `working_directory`, `run_ex`.
- `carat/use_cases/plugins/boundary.rb`: `Boundary.copied_lines`, the copies of strings crossing the boundary.
- `carat/use_cases/concerns/guarded.rb`: `Guarded#guarded`, the one guarded path into a plugin.
- `carat/use_cases/actions/plugin_action_handler.rb`: `PluginActionHandler.register`.
- `carat/use_cases/ex/plugin_command_handler.rb`: `PluginCommandHandler`; `matches?`, `call`.
- `carat/plugins/registry.rb`: generated from `config/plugins.caratrc`; `Registry.all`, one `require_relative` and one constructor per plugin; never edited by hand.
- `carat/plugins/hello/plugin.rb`: `Hello::Plugin`, the smallest example and a test fixture outside the registry.

Tests: `test/domain_plugin_manifest.rb`, `test/use_cases_plugins.rb`, `test/use_cases_plugin_files.rb`, `test/use_cases_plugin_hardening.rb`, `test/editor_plugins.rb`.

Designs: `plugin-host` (all Decisions), `plugin-host-hardening` (all Decisions), `plugin-explorer` (The API grows by requests; The prompt reuses command-line mode; Window rules), `caratrc-config` (Plugin manifests use lines), `use-case-boundaries` (The plugin side).

Rules: CLAUDE.md Coding conventions (plugins require only `carat/plugin_api.rb`; ids across the API; strings copied; a new request is a `Host` method, a `PluginLink` override, and a family method with a minor version bump; every plugin call guarded; icons by name); `docs/architecture.md` section 9; `docs/plugins.md`. The host leaving `use_cases/plugins/` is in `docs/backlog.md`.

## 16. Explorer plugin

What: the built-in file tree in a side window, with icons, follow, and file operations inside a root.

Flow: `<leader>e`, `:Explorer`, or `:ExplorerFind` reach `Explorer::Plugin#on_action` or `on_command` through the host; the plugin keeps a `Tree` of `Node`s, renders it into a scratch buffer with `Host#set_scratch_lines` and icons by name (`FileIcons.name_for`, `Host#icon`), answers the tree keys (`<CR> l h o s v t a r d R H - C q ?`) in its scratch keymap, opens files through `open_file`, `open_in_split`, and `open_in_tab`, asks for names through `prompt` and `on_input`, and follows the editing window on `on_event`.

Files:

- `carat/plugins/explorer/plugin.rb`: `Explorer::Plugin`; `manifest`, `activate`, `deactivate`, `on_event`, `on_action`, `on_command`, `on_input`, `tokenize` (the icon colors of the tree's `explorer` syntax).
- `carat/plugins/explorer/tree.rb`: `Tree`; `build`, `lines`, `expand`, `collapse`, `toggle`, `reroot`, `reveal`, `mark`, `moved`, `toggle_hidden`, `at`, `row_of`, `parent_row`, `icon_name`.
- `carat/plugins/explorer/node.rb`: `Node` record; `root?`.
- `carat/plugins/explorer/file_icons.rb`: `FileIcons`; `name_for`, the file case from `PluginApi::FileIcons`, `GROUPS` (each icon's file-icon group).
- `carat/domain/icons.rb`: `Icons`, the icon table per set and the `icons` option; `glyph`, `table`, `set?`.

Tests: `test/domain_icons.rb`, `test/plugins_explorer.rb` (the tree over a fake host), `test/editor_explorer.rb` (every key of the file tree).

Designs: `plugin-explorer` (all Decisions).

Rules: the plugin rules of area 15; its actions are in `docs/actions.md` and its `plugin.explorer.*` lines in `config/default.caratrc`.

Bench: `lh-explorer`, `j-explorer`.

## 17. Ports, drivers, and language services

What: the interfaces the core uses to reach the terminal, files, clock, configuration, signals, child processes, and language servers, the drivers that implement them, and the language server client.

Flow: each port is a class whose methods raise `NotImplementedError`; drivers subclass them and are built only in `bin/carat.rb`; doubles (area 18) subclass them for tests. `MainLoop#run` polls the `SignalPort` (terminate, resize), renders on a resize, and pumps input. On an idle read `InputController#pump` calls `LanguageServicePort#poll`: `JsonRpcLanguageGateway` drains at most 64 queued `ServiceMessage` values that `ProcessRunner`'s reader threads framed with `RpcFramer`, starts the current buffer's server when the working directory is under a root of `language.trusted_roots` (else the slot reads `untrusted :LspStart`), sends `didOpen`, `didChange`, `didSave` (reported by `SaveFile`), and `didClose`, and writes the `lsp` slot through `StatusSlots#set_lsp`; `bin/carat.rb` calls `stop` in its `ensure`. The completion source `ServerCompletions` records the wanted word in the `CompletionRequest` it shares with the gateway, which sends `textDocument/completion` after a 0.1 second debounce, cancels a stale request, and keeps the bounded answer for the popup.

Files:

- `carat/ports/terminal_port.rb`: `TerminalPort`; `size`, `read_key`, `write`, `colors`, `no_color?`, `enter`, `leave`.
- `carat/ports/clock_port.rb`: `ClockPort`; `now`, `sleep`.
- `carat/ports/file_port.rb`: `FilePort`; `read` (bounded, regular files only), `write`, `exist?`, `list`, `stat` (a `Domain::PathInfo`), `real_path`, `mkdir`, `rename`, `delete`, `cwd`, `home`.
- `carat/ports/config_port.rb`: `ConfigPort#load`, the `Domain::Config` of every configuration file.
- `carat/ports/signal_port.rb`: `SignalPort`; `install`, `terminated?`, `resized?`, `acknowledge_resize`.
- `carat/drivers/ansi_terminal.rb`: `AnsiTerminal`; reads `COLORTERM` and `TERM` once for `colors` and `NO_COLOR` for `no_color?`, the only environment reads.
- `carat/drivers/disk_files.rb`: `DiskFiles`, the `FilePort` driver; `read` opens with `O_NONBLOCK` and checks the opened file.
- `carat/drivers/monotonic_clock.rb`: `MonotonicClock`.
- `carat/drivers/signals.rb`: `Signals`; INT and TERM terminate, WINCH resizes, flags only.
- `carat/drivers/main_loop.rb`: `MainLoop#run`.
- `carat/domain/json.rb`: `Carat::Json` (`parse`, `generate`, `pretty_generate`), for JSON-RPC; the configuration is not JSON. Nesting is capped at `MAX_DEPTH`, illegal UTF-8 bytes read and write as U+FFFD.
- `carat/ports/process_port.rb`: `ProcessPort`; `spawn` (a handle, 0 when the command cannot start), `write`, `stop`.
- `carat/ports/message_queue_port.rb`: `MessageQueuePort`; `push`, `pop` (nil at once when empty).
- `carat/ports/language_service_port.rb`: `LanguageServicePort`; `poll`, `start`, `restart`, `saved`, `waiting?`, `stop`.
- `carat/ports/completion_port.rb`: `CompletionPort`, the completion source that never waits; `ready?`, `candidates`, `request`.
- `carat/domain/completion_request.rb`: `CompletionRequest`, the asynchronous ask a source shares with the gateway (wanted word, debounce, request in flight, answer, `arrived`, completing languages); `ask`, `wanted?`, `answer_for?`, `completes?`, `waiting?`.
- `carat/drivers/process_runner.rb`: `ProcessRunner`; `Process.spawn` over `IO.pipe` pairs, a reader thread (`pump`) and a writer thread (`drain`) per child, the only threads; `Process.detach` reaps.
- `carat/drivers/runtime_queue.rb`: `RuntimeQueue`, the runtime's `Queue`.
- `carat/domain/rpc_framer.rb`: `RpcFramer`; `frame`, `feed`, `next_body`, `refused?`; `HEADER_LIMIT` and `BODY_LIMIT`.
- `carat/domain/control_text.rb`: `ControlText.strip`, server text without controls, capped on a character boundary; `ControlText.line`, the same with breaks and tabs as spaces; `ControlText.plain`, whole escape sequences dropped first.
- `carat/domain/service_message.rb`: `ServiceMessage`, a body, `exit`, or `overflow` from a reader thread.
- `carat/domain/diagnostic.rb`: `Diagnostic`, a published diagnostic as a value.
- `carat/domain/diagnostic_list.rb`: `DiagnosticList`, a file's published diagnostics with a typed reader, built once per publish and shared by the server, its buffers, and the counts; `add`, `at`, `count`, `empty?`.
- `carat/domain/language_server.rb`: `LanguageServer`, one server's state, documents, and diagnostics.
- `carat/adapters/json_rpc_language_gateway.rb`: `JsonRpcLanguageGateway`; `poll` (a publish handed to its buffers and the current buffer's counts to the slot at the idle tick, then the debounced completion request), `start`, `restart`, `saved`, `waiting?`, `stop`, `diagnostics`, `server_for`; a failed initialize is a crash.
- `carat/doubles/fake_processes.rb`: `FakeProcesses`; `install`, `break_input`, `spawned`, `bodies`, `methods_sent`, `stopped`.
- `carat/doubles/memory_queue.rb`: `MemoryQueue`; `body`, `count`.
- `carat/doubles/fake_language_services.rb`: `FakeLanguageServices`, no server, never `waiting?`, the writes recorded in `saves`, for use cases built by hand.
- `carat/adapters/server_completions.rb`: `ServerCompletions`, the editor's completion source: ready for a completing server's file type, the answer held for the word or the word recorded as wanted; `request`.
- `carat/doubles/fixed_completions.rb`: `FixedCompletions`, a source a test fills with `add`, ready once it holds a candidate, counting `asked`, its `request` filled by nobody.

Tests: `test/drivers_main_loop.rb` (a resize, a terminate, and `:q` over the signal double, and the driver's flags), `test/json.rb`, `test/drivers_disk_files.rb` (`DiskFiles`, `MakePath`, `RenamePath`, and `DeletePath` over a real directory: a link to `/dev/zero`, a FIFO, files at and over a limit, links inside and outside a root), `test/domain_rpc_framer.rb` (frames, their limits, and `ControlText`), `test/drivers_process_runner.rb` (`cat` and `sh` as children), `test/adapters_language_gateway.rb` (the lifecycle, trusted roots, progress, diagnostics and their signs and counts, hostile output over the doubles), `test/editor_lsp.rb` (`:LspStart`, `:LspRestart`, the drawn slot, and the drawn diagnostics), `test/adapters_server_completions.rb` (the server as the completion source: debounce, cancellation, the answer with no key, the short wait, hostile and oversized answers), `test/domain_markdown_text.rb`.

Designs: `state-and-ports` (Signals; The stat value; Configuration), `editor-foundation` (Ports, adapters, drivers, doubles), `cursor-shapes` (Every exit path), `lsp-diagnostics` (Spike; Three ports, two drivers, two doubles; The gateway works only on idle ticks; Untrusted output), `diagnostics-display` (The buffer keeps what is shown; The gateway applies a publish at the idle tick), `completion` (A source port that never waits), `completion-request` (all Decisions).

Rules: `docs/architecture.md` sections 2.1 (signal handlers set a flag; `STDIN.raw` single call; `Process.spawn` with `IO.pipe`), 6, and 8.4. An overridden port method carries `# @rbs` parameter lines, not an applied return type.

## 18. Tests and benchmarks

What: the assertion harness, the doubles, the test runner, the lint and smoke tests, and the key benchmark.

Flow: `make test-build` compiles `test/runner/run_all.rb`, which requires every test module, into one program; `make test-run` runs each test by name in its own process through `tools/run_tests.sh` and compares its merged output with its `.expected` snapshot; `make test-one T=test/NAME.rb` compiles one test alone (its `main if __FILE__ == $0` guard). Editor tests drive `EditorHarness` over the doubles with keys in Vim notation. `make bench` compiles `bench/keys.rb` and runs its scenarios through `bench/run.sh`; `make bench-budget` checks `lh`'s allocations; `make metrics` measures eight scenarios through `bench/run.sh` (area 1); `make profile` runs `bench/profile.sh`.

Files:

- `carat/testing.rb`: `Carat::Testing`; `assert_equal`, `assert_true`, `assert_raises`, `table`, `finish`.
- `carat/test_support.rb`: the require graph of tests and the benchmark, `carat.rb` and the doubles.
- `carat/doubles/fake_terminal.rb`: `FakeTerminal` (256 colors, `no_color=`); `push`, `writes`, `last_write`, `read_key`, `write`.
- `carat/doubles/manual_clock.rb`: `ManualClock`; `now`, `advance`, `sleep`.
- `carat/doubles/memory_files.rb`: `MemoryFiles`, files and directories under `/project` and a home `/home/user`, both movable; `put`, `get`, `link`, `link_to`, `special`, `move_to`, `move_home`, and the `FilePort` methods.
- `carat/doubles/fixed_config.rb`: `FixedConfig`; `defaults`, `with(text)`, `with_user`, `load`.
- `carat/doubles/manual_signals.rb`: `ManualSignals`; `resize`, `terminate`, `resize_after`, `terminate_after`.
- `carat/doubles/editor_harness.rb`: `EditorHarness`; `default` (no plugins), `with_plugins`, `open`, `type`, `raw`, `wait`, `resize`, `lines`, `cursor`, `mode`, `message`, `screen`, `row`, `window_count`, `tab_count`, `status_row`.
- `test/runner/run_all.rb`: the runner; a new test file gets a `require_relative` and a `when` line here; an unknown name exits 2.
- `test/lint.rb`: `LintTest`, the rules the compiler does not enforce (layer requires and references, plugin references, `PluginLink` coverage, concerns, naming, constructors, records, use case rules, the `lines` rule, inline RBS, and this map's coverage), each with a self-check.
- `test/smoke_editor.rb`: the binary (`build/bin/carat` or `CARAT_BIN`) in a pseudo-terminal, also in a hostile project and home.
- `tools/run_tests.sh`: runs tests from a compiled runner, compares each with its snapshot, prints a diff and a summary.
- `bench/keys.rb`: the key benchmark over the doubles at 200 by 60; `SCENARIOS` (name, keys, count, lines, setup, text kind, plugins); time per key, slowest key, bytes, collector share, open time, lines tokenized, live heap.
- `bench/run.sh`: runs the scenarios pinned to one core with `SPINEL_ALLOC_REPORT`, allocations per key, and the budget.
- `bench/profile.sh`: the `perf` report with Ruby names from the symbol map.

Tests: every file under `test/`; snapshots only through `make snapshots`, diff reviewed.

Designs: `test-build` (One runner, one process per test; The helpers that returned arrays return objects), `analysis-speed` (The widening is fixed where it starts, in the tests), `render-core` (Benchmark, profile, and budget), `editor-foundation` (Tests), `agents-and-map` (The coverage rule lives in the lint test).

Rules: CLAUDE.md Hard rules (tests, snapshots, and benchmarks only through `make`) and Coding conventions (test modules, typed table values, helpers returning objects); `docs/architecture.md` section 10.

Bench: every scenario, `lh` for the allocation budget, and `lh j insert ddp undo dot-ciw lh-ruby open-ruby` for `make metrics`.

---

## Delivered changes

In merge order, by pull request number, with the roadmap item of `docs/architecture.md` section 12 where there is one; from #7 on each is archived under `openspec/changes/archive/`.

- #1 to #6: the conventions, OpenSpec, the contributor agent, the architecture, the Makefile, and item 1, `project-skeleton` (manifest, require graph, `Carat::Json`, `Carat::Testing`, the config generator, the lint and config tests).
- #7, item 2, `editor-foundation`: one window; normal, insert, and command-line modes; `:w`, `:q`, `:wq`, `:x`, `:e` with bang and long forms; the editor harness over doubles; the smoke test.
- #8, `data-value-objects` and `struct-record-types`: the record kinds.
- #9, item 3, `command-grammar`: counts, the `"x` prefix, operator-pending mode, the motion set, text objects, `d c y > <` with doubled forms and `x s S C D Y J p P`, unnamed and named registers.
- #10 `toolchain-under-tmp`, #11 `escape-c1-control-codes`, #12 `ex-write-quit-all` (`:wa`, `:qa`, `:wqa`, `:xa`).
- #13, item 7, first half, `windows-and-splits`: layout per tab page, `<C-w>s v h j k l w W p c o = q`, `gt`, `gT`, `:sp`, `:vs`, `:new`, `:vnew`, `:close`, `:only`, the `:tab*` commands, the tab line, and the file commands over several windows. Left for `buffer-list`: `:ls`, `:bn`, `:bp`, `:bd`, `:b N`, and the `E162` line of `:qa`.
- #14, item 11, `plugin-host`: the plugin API, manifest rules, the host with actions, ex commands, events, and requests, scratch buffers in side windows with their own keymaps, the generated registry, the icon table, the `hello` fixture.
- #15, item 12, first half, `plugin-explorer`: the file tree, API 1.1 (working directory, window numbers, file requests inside a root, a prompt), `FilePort` `mkdir`, `rename`, `delete`, `cwd`. Left: `plugin-finder`, which can start on the host at any time.
- #16, item 5, `visual-modes`, taken ahead of item 4 at the user's request: the three kinds with every motion, count, register prefix, text object, and operator, block insert and append, the blockwise register kind, the `Visual` highlight. The `'<` and `'>` marks wait for marks.
- #17 to #21, the core-quality queue approved before more plugins: `edit-pipeline` (one splice, change records, transactions, derived modified flag, buffer ids), `plugin-host-hardening` (guarded calls, queued events, ids, validation, copies, cleanup, API 1.2, request families), `dependency-injection` (action and ex tables, kinds, `Outcome`, ex abbreviations, keyword constructors), `state-and-ports` (focused records, `CommandRunner`, `ConfigPort`, `SignalPort`, doubles out of the production graph), `render-core` (flat frames, the line cache, dirty rows, scroll regions, `ArrangeView`, the benchmarks).
- #22, `no-cruby-guard`: the `tools/noruby/ruby` stub first on every target's `PATH` and `make no-cruby`.
- #23, item 4, `undo-and-registers`, last of the queue: the undo tree and its keys and ex commands, the dot command, the numbered, small delete, black hole, and read-only registers, `:registers`, messages of several lines. Time arguments of `:earlier` and `:later` are in the backlog.
- #24 `analysis-speed` and #25 `test-build`, the time effort asked for before syntax highlighting: typed test table values and `make analysis-budget`; one test runner, `make test-one`, `make diagnose-one`, and CI caching the units of C.
- #26, item 8, `syntax-highlighting`: filetypes, highlight groups, the syntax cache, `HighlightView`, themes, plugin API 1.3, the `ruby` plugin, `:syntax`, `:set filetype` and `syntax`; the rest is in the backlog.
- #27, `ci-speed-2`, the third of the time effort: pull requests under two minutes on development builds; `main` builds and smoke tests the release binary.
- #28, `struct-keyword-init`: every record built with keyword arguments, checked by the lint test.
- #29, `caratrc-config`, item 9's files ahead of it: `.caratrc` lines, the user and project files, `none` to unbind, problems by file and line, plugin API 2.0, `config/plugins.caratrc`. Item 9 keeps the rest of `:set` and the local options.
- #30, `use-case-boundaries`: one public `call` per use case, the many-method use cases split into 37 classes, shared logic in the domain, the lint rules. The plugin host under `use_cases/plugins/` is left for a plugin-side change.
- `agents-and-map`: this map, its lint rule, the scout agent, the slim `CLAUDE.md`, and the contributor's instructions.
- `delivery-pipeline`: the workflow, `/deliver`, `/status`, seven agents, run state, gates, one stage list. Next: `planner-and-metrics`, `authoring-kit`.
- `planner-and-metrics`: the planner and the Plan phase, the metrics history `docs/metrics.tsv`, `make metrics` and the comparison with `main` in CI, the retrospective, periodic reviews, `/plan` and `/review`, archived briefs. Acting on what the retrospective and the reviews find is left to the queue.
- `authoring-kit`: the golden examples `docs/examples.md`, the generators `make new-use-case`, `new-action`, `new-ex-command`, `new-test`, and `new-plugin`, the Spinel notes `docs/spinel-notes.md`, the `docs-lint` stage with its budgets, and a slimmer `CLAUDE.md` (41,066 to about 30,600 bytes) and `docs/architecture.md`. A compile of the generators' output in `make check` is left in `docs/backlog.md`.
- #35, `window-navigation-and-scroll`, a user-reported fix: a lone prefix in the grammar modes waits for its next key with no time limit, so `<C-w>` and its second key work however slowly they are typed, also between the file tree and the file windows; the scroll actions (`<C-f>`, `<C-b>`, `<PageDown>`, `<PageUp>`, `<C-d>`, `<C-u>`, `<C-e>`, `<C-y>`, `zt`, `zz`, `zb`) and the `scroll` option. Left: `z<CR>`, `z.`, `z-`, `:set scroll`, `<C-w>` outside normal mode, and a time limit for the prefixes of user bindings (`docs/backlog.md`).
- #36, `utf8-input-safety`, the security fix from the periodic review after #35: files and names that are not UTF-8 open, list, and draw without raising, their bytes kept through edits and writes, `[ILLEGAL BYTE in line N]` on open, RFC 3629 decoding with one U+FFFD cell per illegal byte, and no code point outside Unicode written to the terminal. Left: `<xx>` markers and `Carat::Json` on such text (`docs/backlog.md`).
- #37, `untrusted-config-limits`, the security fix from the periodic reviews at 66fd52b and 6ea61b1: configuration lines with an illegal byte reported and skipped and `Keymap.action_name?` reading bytes; a project `.caratrc` that is a link, not a regular file, or over 1 MiB refused with a report; `tabstop` and `shiftwidth` bounded to 9999; `:e` and every open refusing a directory, a FIFO or device, and a file over 64 MiB, read through a bounded non-blocking read; and a plugin create refused through a link that leaves the tree root. Left: rename and delete through such a link, an unbounded binding length, and quadratic problem sorting (`plugin-path-containment`).
- #38, `plugin-path-containment`, the security fix from the periodic review at 389c118: a plugin's rename or delete outside the tree root, with every link resolved, refused through the one use case `ResolveInside`; keymap lines longer than 64 keys reported and skipped; `Config#report` merging its sorted runs. The check-then-act race of the file operations is in the backlog.
- #39, `agent-authority`, the security fix from the periodic review at 389c118: the workflow alone records phases and reviews, from the results it received, and the merger's `records` gate compares them; `set` refuses `review.*`, `phase.*`, and `stage.*`; `tools/agent_guard.sh` guards every agent's shell and file tools; the contributor's explicit tools. Left: the `records` gate refusing a merge without `RECORDS` (`docs/backlog.md`).
- `workflow-trim`, moved to the front by the user: at most three scouts for the edited areas and plan notes for the contributor; the CI watcher folded into the merger, which waits for CI without giving up and squashes with the contributor's body file; the benchmark agent only when the check's allocations or rounds differ from main's recorded figures (`tools/run_state.sh bench`); test-only fix rounds carry all but the test stages; every figure stored in the run state as it happens and history rows built from them; `report` as a phase; four record flushes a run. The first run under it measures the effect.
- `planner-priorities`, the user's now-request: the rubric of `docs/goals.md` (tiers T0 to T6, value by size, token budgets, the size check, aging, a user feature in every three changes, problem-first briefs) applied by the planner; every queue item tagged with a tier and a size, checked by `tools/docs_lint.sh`; the history's `estimate` column and `tools/run_state.sh budget`, with which the retrospective flags an overrun.
- `window-ctrl-keys`, the user's request and the every-three rule's feature: `<C-w><C-s> <C-v> <C-h> <C-j> <C-k> <C-l> <C-w> <C-p> <C-o> <C-q>` bound in `config/default.caratrc` to the actions of their plain forms, counts included, in file windows and the explorer tree; `<C-w><C-c>` left unbound because the `<C-c>` cancels, as in Vim; the every-three rule clarified in `docs/goals.md` and the planner. Left for later: the held-Ctrl forms of the window commands not yet implemented.
- `workflow-records`: each quality advisory kept as a `quality-advisory` note and handed to the package step for `docs/backlog.md`; the merger's wait through `tools/ci_wait.sh` until 30 minutes; two record starts a run, the package, CI, and merge phases recorded at the end and a resume reading `pushed`, `pr`, and `merged`; every figure in each metric line, which the merger and the retrospective run, so the run state's totals equal the workflow's; the plan's estimate stored as `metric.estimate`.
- `guard-hardening`: the agent guard matches a command with its quotes and backslashes removed, judges a file edit by its real path, and never lets the body file be or become a link, which `pr-body` refuses too; `REVIEW_AREAS` gains the entry point and the tooling and CI, and a keymap-only edit of `config/default.caratrc` is not config loading; the quality advisories of every round reach `docs/backlog.md`, a CI fix's through its push; `tools/ci_wait.sh` fails on a failed `sleep`. Left for later: the `/status` phase display and the merger's foreground sleep (`docs/backlog.md`).
- #46, `buffer-search`, the every-three rule's feature and the search half of roadmap item 6: `/`, `?`, `n`, `N`, `*`, `#`, `g*`, and `g#` with counts, wrapping, operators, and the visual modes; Vim's magic pattern basics translated by `VimPattern` into constructs the engine matches without backtracking, under a size cap and a per-line work budget; the `/` register, the `:` and search histories on `<Up>` and `<Down>`, `ignorecase`, `smartcase`, `hlsearch`, `incsearch`, `:noh`, and the `Search` and `IncSearch` groups. Left for later: `:s`, `:g`, `:v`, and ex ranges (`buffer-substitute`), search offsets, and the match count.
- `pipeline-speed`, part A of the user's decision that token and pipeline efficiency is goal 1 and security goal 2: each start's total tokens and wall minutes recorded by `/deliver` (`tools/run_state.sh usage`) and budgeted (small 500k and 25 minutes, medium 1.2M, large 2.5M); the three fix rounds counted across starts, one more after a restart the limit did not cause; the periodic review due after the agent guard and the gates, not other tooling; the planner only when `plan-needed` finds a decision.
- `pipeline-speed-b`, part B: the quality and security reviews in parallel on one commit, both answered in one fix round; a fix round's quality review scoped to the fix by `tools/run_state.sh scope`; stage records counted only at the check the workflow recorded, which the `stages` and `records` gates compare; the merge gates run from a worktree of `origin/main`; one note per repeated advisory.
- `pipeline-speed-c`: `dev-build`, `test-build`, and `diagnose` skipped on the code they last passed with their outputs unchanged; `check` refuses a dirty tree and leaves `phase.check` to the workflow; the retrospective closes a run in one start, its last records, proposals, and the report, under the guard's `close` profile, the reporter gone; the budget line starts `under:` or `over:`.
- `buffer-list`, item 7, second half: file buffers stay listed until `:bd` with stable numbers and a remembered cursor, the startup buffer's number reused; `:ls`, `:bn`, `:bp`, `:bN`, `:b N`, `:bd`; `E162` naming and showing the buffer that refuses `:qa`, `:q`, `:wq`, and `:x`. Left: `:b name`, ranges and several numbers for `:bd`, the alternate buffer, `:badd`, `:bwipeout`, and the split forms.

Next: `docs/queue.md`, ordered against the charter `docs/goals.md`.
