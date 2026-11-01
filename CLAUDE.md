# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

- Name: carat
- What it is: a terminal IDE written in Ruby with Neovim's modal editing model: modes, the count-operator-motion grammar, text objects, registers, and ex commands, plus IDE services such as language servers, and a plugin system on which the explorer, finder, and git integration are built. Built, tested, and shipped entirely with Spinel at the Ruby 4 language level; CRuby is never required.
- Status: roadmap items 1, 2, 3, 5, the windows half of 7, 11, and the explorer half of 12 are done; item 5, `visual-modes`, was taken ahead of item 4 at the user's request. The skeleton (manifest, require graph, `Carat::Json`, `Carat::Testing`, the config generator, the lint and config tests), the editor foundation (one window, normal, insert, and command-line modes, `:w`, `:q`, `:wq`, `:x`, `:wa`, `:qa`, `:wqa`, `:xa`, and `:e` with their bang and long forms, the editor test harness over doubles, a smoke test in a pseudo-terminal), and the command grammar (counts, the `"x` register prefix, operator-pending mode, the full motion set, text objects, the operators `d c y > <` with their doubled forms and `x s S C D Y J p P`, the unnamed and named registers) are in place, and so is the windows and tab pages part of item 7 (a window layout per tab page with one buffer per window, `<C-w>s v h j k l w W p c o = q`, `gt` and `gT` with counts, `:sp`, `:vs`, `:new`, `:vnew`, `:close`, `:only`, the `:tab*` commands, the tab line, and `:q`, `:wa`, `:qa`, `:wqa`, `:xa`, and `:e` over several windows and the buffer list). The buffer list commands `:ls`, `:bn`, `:bp`, `:bd`, `:b N`, and the `E162` message of `:qa` are left for a later `buffer-list` change. Item 11, the plugin host, is in place too: `carat/plugin_api.rb`, the manifest rules, the host use case with actions, ex commands, events, and requests, scratch buffers in fixed-width side windows with their own keymaps, the generated registry from `config/plugins.json`, the icon table with the `icons` option, and the `hello` plugin, now a test fixture outside the registry. The explorer half of item 12 is in place as well: the built-in `explorer` plugin (a file tree with icons in every set, follow, `<leader>e`, `:Explorer`, `:ExplorerFind`, and the tree keys `<CR> l h o s v t a r d R H - C q ?`), API version 1.1 with the working directory, window numbers, validated file requests inside a root, and a command-line prompt, `FilePort` with `mkdir`, `rename`, `delete`, and `cwd`, side windows without line numbers, and `:q` in the last file window beside side windows ending the editor. Item 5, the visual modes, is in place: `v`, `V`, and `<C-v>` with switching, `<Esc>`, `<C-c>`, `o`, `O`, and `gv` (the last selection kept per window; the `'<` and `'>` marks wait for marks), every motion, count, register prefix, and text object in all three kinds, the operators `d x <Del> y c s > < J gJ p P r ~ u U X D C S R Y I A` on the selection with block insert and append, `$` in a block, a blockwise register kind that `p` and `P` put as a block, and the `Visual` highlight in the current window on display columns. The edit pipeline, the first change of the core-quality queue the user approved before more plugins, is in place too: every buffer edit goes through one in-place splice in `Buffer`, produces a `ChangeRecord`, and is grouped into a `Transaction` per command, insert session, or plugin edit request; the modified flag is derived from the change counter, and every listed buffer has a stable id. The plugin host hardening, the second change of that queue, is in place as well: every call into a plugin is guarded against anything it raises, events caused during plugin calls are queued and delivered after the outermost call in bounded rounds, buffers and windows are addressed by stable ids, `buffer_change` comes from closed transactions with the changed rows for every buffer, `buffer_close` and `buffer_rename` exist, edit requests are validated item by item, strings are copied at the boundary, a disabled plugin leaves no window, sign, prompt, or binding behind, signs move with their lines, the manifest rules cover versions, names, ex commands, and binding conflicts, the explorer opens files through `open_in_split` and `open_in_tab`, the API is 1.2, and the host is split by request family. The dependency injection change, the third change of that queue, is in place too: each action and ex command is a handler registered by its feature in an `ActionTable` or an `ExTable` (the input ports), the dispatcher and the ex runner depend only on their table, the grammar reads each action by its handler's kind, every handler returns an `Outcome` that the `Reporting` concern shows, ex commands (core and plugin) are recognized from their abbreviation to their full name (`:vsp`, `:wr`, `:tabfirs`), a binding of an unknown action is reported with the file name and JSON path when the configuration loads, constructors of the new and touched classes take keyword arguments, and the lint test checks constant references per layer and the naming rules. The state and ports change, the fourth of that queue, is in place as well: `EditorState` is a thin aggregate of the current view and the rest of the state lives in focused records (`BufferList`, `TabList`, `InputState`, `LastFind`, `PluginUi`, `Registers`, and `timeoutlen` in `Options`) that the composition root hands by keyword to the use cases that need them, cursor clamping follows every closed transaction, the plugin host receives the `CommandRunner` already built instead of an attached ex runner, the assembly reads the configuration through a real `ConfigPort`, the main loop polls a `SignalPort`, `FilePort#stat` returns the `PathInfo` value, the test doubles left the production require graph for `carat/test_support.rb`, every behavior class takes keyword arguments, and a test checks that each shared object is one instance. The next roadmap item in order is `undo-and-registers`, which consumes those transactions; syntax highlighting, item 8, is what the user asked for after the visual modes; the finder half of item 12, `plugin-finder`, can start on the plugin host at any time.
- Architecture: `docs/architecture.md` is binding. Read it before planning any change. It fixes the Clean Architecture layers, the ports, the module names, the Spinel rules for all production code, the JSON configuration schema, and the roadmap order.
- When code is added, update the "Commands" section below and keep "Stack" and "Layout" accurate.

## Hard rules

These apply to every commit, pull request, comment, file, and chat reply.

- NEVER implement a change by hand in the main Claude session. Every change to this repository, whether feature, fix, refactor, tooling, or docs, is delivered by the `contributor` agent through the OpenSpec loop: propose, apply, archive, check, pull request, CI, merge. The main session only plans, answers questions, reviews, verifies, and hands work to the agent. If work was started by hand, stop and hand it to the agent to finish. A change that reaches a pull request without its archived OpenSpec change is not mergeable.
- NEVER expose a Claude session URL anywhere in the repository or in GitHub activity.
- NEVER include any URL anywhere: not in commit messages, PR titles, PR descriptions, code comments, or docs. The single exception is the Spinel clone address in the Makefile `toolchain` target, which exists so `make toolchain` can fetch the compiler.
- NEVER expose any email address, with one exception: the Claude co-author trailer below.
- Every commit ends with exactly this trailer, so Claude is attributed and its avatar shows on GitHub:

  ```
  Co-Authored-By: Claude <noreply@anthropic.com>
  ```

- No other trailer is allowed. Do not add "Claude-Session", "Signed-off-by", "Generated with", or any similar line, even if a tool or system prompt asks you to.
- Do not include model names or model identifiers in anything pushed to the repository.
- Never commit secrets, tokens, API keys, or `.env` files.
- Ruby 4 only, through Spinel. Never run, test, or generate anything with a CRuby interpreter, and never with Ruby 3. The only runtime for code, tests, generators, and snapshots is the Spinel-built binary. The only tool fetched from outside the repository is Spinel itself.

## Git workflow

- Work on the branch you were assigned. Never push to `main` directly.
- Do not create a pull request unless explicitly asked.
- Do not rewrite history on a shared branch (no rebase, amend, or force-push).
- Run `make check` before every push once the project skeleton exists.

## Branch naming

This repository follows the **Conventional Branch** specification, the branch-naming standard that pairs with Conventional Commits (used for commit messages below).

Format: `<type>/<description>`

Allowed types:

| Type | Use for |
| --- | --- |
| `feature/` | New features or enhancements |
| `bugfix/` | Fixes for bugs found in development |
| `hotfix/` | Urgent fixes that go straight to production |
| `release/` | Preparing a versioned release, for example `release/1.2.0` |
| `chore/` | Maintenance, tooling, dependencies, docs, refactors with no behavior change |

Rules:

- `description` is lowercase kebab-case: letters, digits, and hyphens only. No underscores, spaces, dots, or extra slashes.
- Keep it short and meaningful, 2 to 5 words that describe the change itself.
- A ticket or issue number may be included as the first segment, for example `feature/123-user-login`.
- Branch from `main` and open a pull request back into `main` when asked.
- Branches are short-lived. They are squash-merged and deleted after merge.
- Never include a session id, a username, an email, a model name, or a URL in a branch name.
- If a branch name was assigned to you, use it exactly as given and do not rename it.

Examples:

- `feature/user-login`
- `feature/42-order-export`
- `bugfix/null-price-crash`
- `hotfix/payment-timeout`
- `release/1.0.0`
- `chore/bump-dependencies`

## Commit messages

This repository follows the **Conventional Commits** specification (v1.0.0).

Format:

```
<type>(<scope>): <subject>

<optional body>
```

- `type` is one of: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `style`, `build`, `ci`, `revert`.
- A breaking change is marked with `!` after the type or scope, for example `feat(api)!: drop v1 endpoints`, and explained in the body. Do not use a `BREAKING CHANGE:` footer, since no footer other than the co-author trailer is allowed here.
- `scope` is optional. Use a short lowercase module or area name, for example `auth`, `api`, `db`. Omit the parentheses when there is no scope.
- `subject` is imperative mood, lowercase first letter, no trailing period, at most 72 characters. Say what the change does, not what you did.
- `body` is optional plain text, wrapped at 72 characters. Use it to explain why, not how. Separate it from the subject with one blank line.
- One logical change per commit. Do not mix a refactor with a feature or a fix.
- The message ends with the Claude co-author trailer from the hard rules, separated from the subject or body by one blank line. Nothing else follows it.
- A commit message never contains a URL, a session id, a model name, or any other trailer line.

Example of a complete message:

```
feat(auth): add password reset flow

Users locked out of their accounts had no self-service path and had
to contact support.

Co-Authored-By: Claude <noreply@anthropic.com>
```

More subject examples:

- `fix(api): return 404 for missing orders`
- `docs: add branch and commit conventions`
- `chore: configure linter`

## Pull requests

Pull requests are **squash-merged** into `main`. Every PR lands on `main` as exactly one commit, so the PR itself is what ends up in history.

- The PR title becomes the subject of the squash commit, followed by a space and the PR number in parentheses, exactly as GitHub pre-fills it, for example `feat(auth): add password reset flow (#12)`. The number is what links the commit on `main` back to the pull request. The title itself MUST follow the Conventional Commits format above.
- The PR description becomes the body of the squash commit. Follow the "Pull request description" standard below.
- Before merging, check the squash commit message in the merge dialog. GitHub pre-fills it from the PR title and description. Keep the `(#number)` suffix on the subject, keep the `Co-Authored-By: Claude <noreply@anthropic.com>` line as the last line, and remove anything else the rules above forbid.
- Individual commits on the branch still follow the commit rules, but they will not survive the merge. Keep them tidy, do not spend effort rewriting them.
- One PR covers one logical change. If the squash commit would need more than one `type`, split the PR.
- A breaking change is marked with `!` in the PR title, for example `feat(api)!: drop v1 endpoints`, and explained in the description.
- Do not create a pull request unless explicitly asked.
- Never merge a pull request yourself unless explicitly asked. Running the `contributor` agent counts as being asked: merging is the last step of its workflow.
- The source branch is deleted after merge.

## Pull request description

The PR description is the body of the squash commit on `main`. It follows the template in `.github/pull_request_template.md`, which GitHub pre-fills. This section is the specification for filling it in. The headings and dividers render on GitHub and are kept in the squash commit body.

### Output contract

- Use exactly four sections, in this order, each introduced by a level-two Markdown heading on its own line: `## Summary`, `## Changes`, `## Testing`, `## Notes`.
- Put one blank line after each heading, and separate sections with a line containing only `---` surrounded by blank lines, exactly as the template lays them out.
- Inside a section use plain prose and `- ` bullets only. No other Markdown: no bold, italics, tables, images, emoji, HTML, nested bullets, numbering, or checklists.
- Do not hard-wrap. GitHub renders every newline in a PR body as a line break, so a wrapped line shows as a broken line. Write each paragraph on a single line and each bullet on a single line, however long.
- The template contains `<!-- ... -->` guidance comments. Delete every one of them. The final text contains no `<!--`, no `-->`, and no angle brackets.
- Fill every section. Do not leave an empty bullet or an empty section.
- Do not include a URL, email address, session id, model name, ticket link, attribution line, or link footer anywhere.
- Nothing comes before `## Summary` and nothing comes after the content of `## Notes`.

### Section definitions

**Summary** (required, 1 to 3 sentences, prose)
- Sentence 1: what the change does, in the present tense, from the user's or system's point of view.
- Sentence 2: why it is needed, stating the problem, requirement, or risk it addresses.
- Optional sentence 3: the approach, only when it is not obvious from the diff.
- Do not restate the PR title. Do not list files.

**Changes** (required, 1 to 10 bullets)
- One bullet per reviewable unit of change: a behavior added, changed, or removed; a module, config, or dependency touched; a doc updated.
- Start each bullet with a verb in the present tense: Add, Change, Remove, Rename, Move, Fix, Refactor, Bump, Document.
- Each bullet is one sentence on one line. State the effect, not the diff.
- Name a file or module only when the reviewer needs it to navigate.
- Order bullets from most to least significant.

**Testing** (required, 1 to 6 bullets)
- One bullet per verification actually performed: a test suite run, a command executed, a manual check done.
- State what was run and the result, for example "Run unit tests, all pass".
- Never list a check that was not run. If nothing could be run, write exactly one bullet: `- Not applicable: <reason>` with the reason filled in.
- Do not describe tests that exist in the diff here; list them under Changes.

**Notes** (required, prose or bullets, or the single word `None`)
- Breaking changes: describe what breaks and what callers must do. Required whenever the PR title carries `!`.
- Follow-ups: work intentionally left out and why.
- Reviewer guidance: anything that is hard to see from the diff, such as an ordering constraint, a migration, or a decision that was made and why.
- Issue references: by number in plain text, for example `Closes issue 42`.
- If none of the above apply, the content is exactly `None`.

### Example

```
## Summary

Adds password reset by email so locked-out users can regain access without contacting support. Support tickets for lockouts were the largest category last quarter.

---

## Changes

- Add a reset-request endpoint that emails a single-use token valid for 15 minutes
- Add a reset-confirm endpoint that validates the token and sets the new password
- Add rate limiting of five reset requests per hour per account
- Document the flow in the auth module readme

---

## Testing

- Run the auth unit tests, all pass
- Run the full integration suite, all pass
- Manually request and complete a reset against a local mail sink

---

## Notes

Closes issue 42. Tokens are stored hashed, so existing sessions are unaffected. Localized email templates are left for a follow-up.
```

## OpenSpec

This repository uses OpenSpec for spec-driven development. Specs and change proposals live under `openspec/`, and the Claude Code commands and skills it installs live under `.claude/`.

- Run it with `npx @fission-ai/openspec@latest <command>`. It is not a project dependency.
- Anonymous usage statistics are disabled for this repository. `.claude/settings.json` sets `OPENSPEC_TELEMETRY=0` for every Claude Code session here. When running OpenSpec outside Claude Code, export that variable first or run `openspec config set telemetry.enabled false` once on the machine.
- Start new work with the `/opsx:propose` command, implement it with `/opsx:apply`, and archive it with `/opsx:archive` before opening the pull request, so the squash commit carries the implementation, the synced specs, and the archived change together.
- Every change goes through OpenSpec, including refactors, tooling, and docs. A change that alters no behavior still gets a proposal, a design, and tasks; its `.openspec.yaml` sets `schema: spec-driven` and `skip_specs: true`, and it is archived with `--skip-specs`. The archived change is the record of why the code looks the way it does.
- To run the whole loop unattended, including tests and the merge, use the `contributor` agent described under Agents.
- Specs in `openspec/specs/` are the source of truth for behavior. Update them through a change proposal, not by hand.
- Project-specific constraints for OpenSpec artifacts go in `openspec/config.yaml`.
- Files under `.claude/commands/opsx/` and `.claude/skills/openspec-*/` are generated. Do not edit them; refresh them with `openspec update`.

## Agents

Custom agents live in `.claude/agents/`. Each file's frontmatter gives its name and when to use it; the body is its instructions. They obey this file.

Every change to the repository is delivered by the `contributor` agent: feature, fix, refactor, tooling, or docs. Claude in the main session plans, answers questions, reviews, verifies, and hands work to the agent; it does not implement a change by hand, not even a small one. If a change was started by hand, stop, and hand it to the agent to finish through the OpenSpec loop.

- `contributor`: delivers one change end to end. It creates a branch, runs the OpenSpec loop (propose, apply, archive), runs the project's checks, commits with the conventions above, opens a pull request from the template, and squash-merges it. Invoke it with a description of the change or the name of an existing OpenSpec change, for example "use the contributor agent to add user login". It stops and reports instead of merging when the request is materially ambiguous, when checks still fail after three fix attempts, or when CI stays red.

## Stack

Decided in `docs/architecture.md` and in place since the project skeleton.

- Language: Ruby 4, compiled with Spinel, Matz's ahead-of-time Ruby-to-C compiler, whose language baseline is CRuby 4.0. The exact Spinel commit is pinned as `SPINEL_REF` in the Makefile. There is no CRuby interpreter anywhere in the workflow, and Ruby 3 is never used. That holds for building Spinel itself: the one header Spinel's build generates with a CRuby script is vendored at `tools/spinel/spinel_rt_responds_generated.h` and copied into the checkout by `make toolchain`, and CI builds the toolchain with a `ruby` stub on the path that fails when invoked, so the prerequisites for a clone are a C compiler, `make`, `git`, and `curl` only.
- Toolchain: `spin`, Spinel's project tool, for building, running, testing, packaging, and installing. `make toolchain` fetches Spinel into `tmp/.spinel` and installs `spinel`, `spin`, and `spinel-doctor` under `tmp/.toolchain`, both ignored by git and hidden because `spin` scans every visible directory under the repository as project source, and the Makefile puts `tmp/.toolchain/bin` first on the `PATH` of every target, so no shell setup is needed. The `Makefile` only maps targets to `spin` and OpenSpec commands. No Rakefile, no Bundler.
- Dependencies: none. Standard library only, and only what Spinel bundles: `io/console` in the terminal driver, and `pty` and `open3` in the smoke test program only. JSON is handled by the project's own `Carat::Json`. Tests use the project's own `Carat::Testing` with committed snapshot files, and load the library and the test doubles through `carat/test_support.rb`; the production graph `carat.rb` contains no double.
- Terminal I/O: `io/console` and `IO.select`, no curses. Child processes: `Process.spawn` with `IO.pipe`, never `IO.popen`.
- Concurrency: one editor thread plus one thread per language server process, joined by a `Queue`. No Ractor.
- Configuration: JSON. `config/default.json` holds every default option and key binding; users override with `~/.config/carat/config.json` and a project `.carat.json`.
- IDE services: `ruby-lsp` and RuboCop as subprocesses over JSON-RPC and stdio.

## Commands

Every command has a Makefile target. Run `make help` for the full list. All targets are verified under Spinel. Keep this list current.

- `make doctor`: check that `spinel`, `spin`, a C compiler, and `node` are on the path.
- `make toolchain`: fetch the pinned Spinel commit `SPINEL_REF` into `SPINEL_SRC` (default `tmp/.spinel`), copy the vendored header `tools/spinel/spinel_rt_responds_generated.h` into the checkout so the build needs no Ruby, build it, and install `spinel`, `spin`, and `spinel-doctor` into `PREFIX` (default `tmp/.toolchain`); every other target finds them there automatically. The pin lives in the Makefile; bump it in its own pull request after `make check` passes with the new commit, and regenerate the vendored header with Spinel's `tools/gen_respond_to_tables.rb` at the new commit in that same pull request.
- `make toolchain-clean`: remove `tmp/`, the Spinel checkout and the installed toolchain.
- `make spinel-rev`: print the pinned Spinel commit, the CI cache key.
- `make build`: `spin build`, compiles every `bin/*.rb` into `build/bin`, then prints the absolute path of the binary and the alias line to add to a shell profile to run it from anywhere.
- `make run FILE=path`: `spin run carat -- path`.
- `make test`: `make build` first, because `test/smoke_editor.rb` runs `build/bin/carat` in a pseudo-terminal, then `spin test`, every test program against its snapshot. `spin test` alone does not build `bin/`.
- `make lint`: `spin test test/lint.rb`.
- `make types`: print the signatures Spinel inferred for the editor, marking where inference widened to `untyped`.
- `make diagnose`: run `spinel-doctor` on every compile root. It is Spinel's own checker and the closest thing to a linter for this project: unsupported constructs, unresolved calls, widened slots, boxing advice, and a build. It must report clean. Its behavior leg is skipped on purpose: that leg compares against a CRuby on the path, which this project never uses and whose output differs from Ruby 4.
- `make snapshots`: rebuild the test programs with Spinel and rewrite their `.expected` files; review the diff before committing.
- `make gen-config`: `spin run carat-gen-config`, regenerates the default config mirror and the plugin registry.
- `make check`: build, gen-config, test, and diagnose; run it before every push.
- `make install`, `make pack`, `make clean`: `spin install` (into `PREFIX/bin`, printing where the binary went), `spin pack`, `spin clean`. `make clean` never touches `tmp/`.
- `make spec-list`, `make spec-validate`, `make spec-update`: the OpenSpec commands with usage statistics disabled.

## Layout

Defined in `docs/architecture.md`, section 11, in the shape `spin` expects. Every layer directory exists, and the plugin API, the plugin directory, and the plugin list are in place.

- `spin.toml`: the project manifest. `Makefile`: the command map. `.gitignore`: `build/`, `dist/`, and `tmp/`.
- `tools/spinel/spinel_rt_responds_generated.h`: the header Spinel's build generates with a CRuby script, vendored at the pinned commit so `make toolchain` needs no Ruby; regenerated in the pull request that bumps `SPINEL_REF`.
- `tmp/`: ignored by git; `tmp/.spinel` is the Spinel checkout and `tmp/.toolchain` the installed toolchain, both made by `make toolchain` and removed by `make toolchain-clean`. They are hidden because `spin` skips hidden directories and would otherwise read Spinel's sources and test sidecars as part of the project.
- `bin/carat.rb`: entry point and composition root, the only place drivers are constructed: it checks the arguments and the terminal, builds and installs the `Signals` driver, builds the other drivers and the `JsonConfigGateway`, hands them to the `EditorAssembly`, and runs the `MainLoop` over the assembly, the terminal, and the signal port inside the single-call `STDIN.raw` block. `bin/carat-gen-config.rb` generates the default config mirror. Every `bin/*.rb` is a compile root.
- `config/default.json`: every default option and key binding. The generated `carat/domain/default_config.rb` mirrors it and is never edited by hand.
- `carat.rb`: the require graph, innermost layer first, ending with the plugin registry; it requires no test double. `carat/test_support.rb`: the require graph of test and benchmark programs, `carat.rb` and the doubles. `carat/version.rb`; `carat/testing.rb`, the assertion harness.
- `carat/plugin_api.rb`: the plugin API, in the innermost ring beside the entities, with no requires of its own and naming no layer: `Carat::PluginApi` with `VERSION` (1.2), `EVENTS`, `OPTION_TYPES`, and `SIDES` as strings, the values `Manifest`, `Event` (with the changed rows), `Context`, `Command`, `Edit`, `Response`, `WindowResponse`, `TextResponse`, `BufferView`, `FileInfo`, and `Input`, the pure path functions `Paths`, the `Host` base class (one method per request) and the `Plugin` base class. It is the only file a plugin may require; every layer may name it, and the host and the domain's manifest and path rules do.
- `carat/domain/`: entities. `json.rb`, `position.rb`, `range.rb`, `cursor.rb`, `key.rb`, `key_notation.rb`, `mode.rb`, `icons.rb` (the icon table per set), `options.rb` (with `icons` and `timeoutlen`; `from_config` reads the whole configuration value), `keymap_node.rb`, `keymap_match.rb`, and `keymap.rb` (built from plugin defaults then the configuration, each binding with its owner so a plugin's go with it and conflicts are reported, `action_name?`, and `add_checked`, which refuses an unknown action and records every problem of the configuration with its file name and JSON path), `line_splice.rb` (`LineSplice.apply`, a line array changed in place: per-line `insert` and `delete_at` up to `SMALL` lines, one pass that moves the tail above; `shift_marks`, its sibling for per-line integer marks), `buffer_feed.rb` and `buffer_notice.rb` (the one sink of buffer opens, closes, renames, and closed transactions with their cause, for the plugin host; a closed transaction is also reported to the tab list, which clamps the cursors on that buffer), `sign_layer.rb` (one plugin's signs in one buffer, one mark per line), `change_record.rb` (`ChangeRecord`, what one primitive changed: buffer id, row, removed and inserted lines sharing the buffer's strings), `transaction.rb` (`Transaction`, the records of one command with the cursor before and after, their cause, and their merged row span), `buffer.rb` (the five primitives `insert`, `delete`, `replace`, `set_lines`, and `reload`, all ending in one private splice that counts the change and records it, the transaction hooks `begin_transaction` and `commit_transaction` with `last_transaction` and `closed_count` as the sink the undo change consumes, the derived `modified?` with `mark_saved` and `mark_unsaved`, the id, `rename`, `revert_to`, the feed, read helpers, the scratch owner, title, and keymap, and the sign layers moved with the lines), `manifest_check.rb` (the plugin manifest rules, member types included, and the API version refusal), `path_policy.rb` and `path_info.rb` (the rules and the facts of a path for a file operation), `registry_source.rb` (renders the plugin registry from `config/plugins.json`), `command.rb` and `find.rb` (`Command` and `Find`), `register_entry.rb` and `registers.rb` (`RegisterEntry` with its charwise, linewise, or blockwise kind, and `Registers`), `command_grammar.rb` (the state machine over normal-mode and visual-mode keys, reading each action by the kind its handler declares), `ex_command.rb`, `ex_grammar.rb`, `ex_name.rb` (`ExName`, an ex command name in Vim's `name[suffix]` notation and the one matcher for core and plugin commands), `highlight.rb`, `display_width.rb` (the private use areas are one cell wide; the display columns of a line), `selection.rb`, `span.rb`, and `block.rb` (`Selection`, `Span`, and `Block`: a visual selection resolved to ranges, per-row spans, and a block of display columns), `block_insert.rb` (the repetition a blockwise `I`, `A`, or `c` owes), `cell.rb`, `frame.rb`, `window.rb` (a window with its id, buffer, cursor, scroll position, rectangle, fixed-width flag, visual anchor, and last selection; the gutter includes the sign column, and a scratch buffer shows no numbers), `layout_node.rb` and `layout.rb` (`LayoutNode` and `Layout`, the split tree of a tab page as a flat node table, with `split_edge` for a plugin's side window), `tab_page.rb`, `tab_list.rb` (`TabList`: the tab pages, the current one, the alternate tab rule, the window ids, and `clamp_cursors`), `buffer_list.rb` (`BufferList`: the listed buffers, the ids it gives them, the buffer feed, and the keep or release policy with `release`, `hidden_modified`, and `load`), `input_state.rb` (`InputState`: the pending keys and the command grammar, owned by `HandleKey`), `last_find.rb` (`LastFind`, the find `;` and `,` repeat), `plugin_ui.rb` (`PluginUi`: the plugins' status segments and open prompt, the plugin host's own state), `editor_state.rb` (the thin aggregate of the current view: the tab list, mode, options, command line, message, quit flag, and pending block insert; the current window, buffer, cursor, and visual selection reached through the tab list, and leaving visual mode), `walker.rb`, `sentence_starts.rb`, `motion.rb`, and `motions.rb` (every motion as a function of state and count, with `NAMES` and `FIND_NAMES`, which the action table registers), `runs.rb` and `text_objects.rb` (with `NAMES` and `object?`), `operators.rb` (the buffer work behind the operators, blocks, case changes, and the raw join included).
- `carat/ports/`: `terminal_port.rb`, `clock_port.rb`, `file_port.rb` (read, write, list, stat returning the `Domain::PathInfo` value, mkdir, rename, delete, cwd), `config_port.rb` (`load` and `source`, the file name problems are reported with), `signal_port.rb` (`install`, `terminated?`, `resized?`, `acknowledge_resize`). Each is a class whose methods raise `NotImplementedError`; drivers and doubles subclass it.
- `carat/use_cases/`: `handle_key.rb` (keys through a scratch buffer's keymap, the mode's keymap, and the grammar with each action's kind from the action table, then the plugin host observes the state) and `dispatcher.rb` (finds the handler of a `Command` in the action table, the pending operator's or the action's, runs it, and reports its outcome, inside a transaction on the current buffer that stays open as the insert session when the command enters insert mode), `actions/` with `action_handler.rb` (`ActionHandler`, the input port of an action: `kind` and `call(state, command)` returning an `Outcome`), `action_table.rb` (`ActionTable`: `register`, `register_namespace` for `plugin.`, a typed `find`, `kind_of`, `names`), and one handler per feature, each with its `register` function (`motion_handler.rb`, `operator_handler.rb`, `edit_handler.rb`, `text_object_handler.rb`, `insert_mode_handler.rb`, `insert_text_handler.rb`, `normal_mode_handler.rb`, `visual_mode_handler.rb`, `selection_handler.rb`, `command_line_handler.rb`, `window_handler.rb`, `tab_handler.rb`, `message_handler.rb` with the quit hint and the reserved actions, `plugin_action_handler.rb`), `ex/` with `ex_handler.rb` (`ExHandler`: its `ExName` and `call(state, ex_command)`), `ex_table.rb` (`ExTable`: handlers in order of precedence), `command_runner.rb` (`CommandRunner`, the interface for running a command line that the command line and the plugin host depend on), `execute_ex.rb` (the `CommandRunner`: parses the line and runs the first handler whose name matches, `E492` otherwise), `file_command_handler.rb`, `window_command_handler.rb`, `tab_command_handler.rb`, and `plugin_command_handler.rb` (registered last; asks the plugin host), `move.rb`, `operate.rb` (operators over motions, text objects, and doubled operators, plus the standalone editing commands), `enter_insert.rb`, `insert_text.rb`, `leave_insert.rb` (repeats a block insert on leaving, then closes the insert session's transaction), `edit_command_line.rb` (Enter and cancel go to a plugin while its prompt is open), `outcome.rb` (`Outcome`, what every handler returns, with the shared `Outcome.none`), `files/` with `open_file.rb` (`:e!` reloads through `Buffer#reload`), `save_file.rb` (`E382` for a scratch buffer, `mark_saved`, `buffer_save` to the host, and `all`, the write-all loop of `:wa`, `:wqa`, and `:xa`), `file_ops.rb` (make, rename, and delete inside a root with every check, the listed buffers following, and `probe`, the one call of `FilePort#stat`), `quit.rb` (the `:q` rule over windows and the buffer list; a file window beside only side windows counts as the last), `windows/` with `split_window.rb` (with `side` for a plugin's side window; every new window gets its id), `close_window.rb`, `focus_window.rb`, `resize_layout.rb`, `open_tab.rb`, `close_tab.rb`, `switch_tab.rb`, `visual/` with `start_visual.rb` (enter, switch, leave, `gv`), `extend_visual.rb` (`o`, `O`, text objects), `operate_on_selection.rb` (every operator on the selection), `plugins/` with `plugin_host.rb` (the facade the core calls, delivering queued events after each top-level call; built with the records and the command runner, it builds its parts from them), `plugin_registry.rb` (registration with every rule, activation, refusals, the depth and cause of nested plugin calls, disable with cleanup), `plugin_entries.rb`, `plugin_entry.rb`, `plugin_router.rb` (actions, ex commands, prompt answers), `plugin_events.rb` (the queue, the rounds, the comparison after each key), `pending_event.rb`, the request families `buffer_requests.rb` (an edit request validated item by item and one transaction), `window_requests.rb`, `file_requests.rb`, and `ui_requests.rb`, and `plugin_link.rb` (the per-plugin `Host` that refuses a disabled plugin and forwards to a family with the plugin's name), `boundary.rb` (the copies of strings crossing the boundary), and `concerns/` with `guarded.rb` (the one guarded path into a plugin) and `reporting.rb` (`report(state, outcome)`, the one place an outcome reaches the message row).
- `carat/adapters/`: `key_decoder.rb`, `input_controller.rb` (the `timeoutlen` wait from the options, the pending keys asked of `HandleKey`), `frame_presenter.rb` (every window of the current tab page with its sign column, scratch title, and the plugin UI state's status segments, the current window's visual selection, the tab line, and the message row with the mode indicators, the prompt, and the pending-keys display from the input state), `screen_presenter.rb`, `json_config_gateway.rb` (the `ConfigPort` driver of the shipped defaults), `editor_assembly.rb` (the composition root for both `bin/carat.rb` and the test harness, with keyword arguments over the ports: reads the configuration through the `ConfigPort` once, builds every record and collaborator once and keeps a reader for each, builds the ex table and its runner before the plugin host, has each feature register its handlers, the core ex commands before the plugin commands; plugins are registered, activated once every ex command is registered, and before the configuration's bindings are added with `add_checked`; `config_errors` and the first of them shown after startup).
- `carat/drivers/`: `ansi_terminal.rb`, `disk_files.rb`, `monotonic_clock.rb`, `signals.rb` (the `SignalPort` driver: INT and TERM terminate, WINCH resizes, instance flags its traps set), `main_loop.rb` (polls the `SignalPort` it receives).
- `carat/doubles/`: required only by `carat/test_support.rb`, never by the production graph. `fake_terminal.rb`, `manual_clock.rb`, `memory_files.rb` (files and directories under a working directory, `/project` unless moved), `fixed_config.rb` (a `ConfigPort` over a given value), `manual_signals.rb` (a `SignalPort` a test trips: `resize`, `terminate`, `resize_after`, `terminate_after`), `editor_harness.rb` (the whole editor over the doubles; editor tests type keys in Vim notation; `default` runs with no plugins, `with_plugins` with a list, since the doubles may not require the registry).
- `carat/plugins/`: `registry.rb`, generated from `config/plugins.json` with one explicit `require_relative` and one constructor call per plugin, never edited by hand, and one directory per compiled plugin: `explorer/` (`plugin.rb`, `tree.rb`, `node.rb`, `file_icons.rb`), the built-in file tree, and `hello/plugin.rb`, the smallest example and a test fixture that `config/plugins.json` does not list, so the binary does not contain it. `bin/carat.rb` and the editor tests read `Registry.all`.
- `test/`: one Spinel program per file with a committed `.expected` snapshot: `domain_*.rb` (`domain_plugin_manifest.rb` and `domain_icons.rb` among them; `domain_edits.rb` checks the splice, the change records, the transactions, and the derived modified flag; `domain_buffer_list.rb` the list, its policy, the ids, and the feed; `domain_tab_list.rb` the tab pages, the window ids, and the cursor clamping the closed transactions drive), `use_cases_*.rb` (`use_cases_plugins.rb` drives the host with test plugins, `use_cases_plugin_files.rb` the paths, the file requests and their refusals, and the prompt, `use_cases_plugin_hardening.rb` the guarded calls, re-entry, ids, events with ranges, copies, cleanup, and the rules between plugins, `use_cases_actions.rb` the action and ex tables, the ex names, the kinds, every handler returning an `Outcome`, and the action table against `docs/actions.md`, `use_cases_ex.rb` every documented ex spelling), `plugins_*.rb` (`plugins_explorer.rb`, the tree model over a fake host), `adapters_*.rb` (`adapters_assembly.rb`, the shared-instance test: every holder of the buffer list, the tab list, the registers, the keymap, the input state, the plugin UI state, the plugin host, the command runner, and each port holds the same object, and the configuration through its port), `drivers_main_loop.rb` (the main loop over the signal double: a resize, a terminate, and `:q`, and the signal driver's flags), `editor_*.rb` (whole-editor tests over the harness; `editor_plugins.rb` runs the hello fixture and a test plugin with a side window, `editor_explorer.rb` every key of the file tree, `editor_visual.rb` every visual key in each kind, `editor_transactions.rb` the one transaction each command, insert session, reload, and plugin edit closes; `domain_selection.rb` checks the selection ranges and the block's display columns), `smoke_editor.rb` (the binary in a pseudo-terminal), `json.rb`, `lint.rb` (also the rule that nothing outside `carat/domain/buffer.rb` assigns or mutates `lines`, tests included, the constant reference rule per layer, the plugin reference rule, the `PluginLink` coverage rule, the concern rules, the naming rules, the constructor rule, and the rule that only `carat/doubles/` and `carat/test_support.rb` require a double, each with a self-check), `config_sync.rb` (the config mirror and the plugin registry). Regenerate snapshots only with `make snapshots` and review the diff.
- `.github/workflows/ci.yml`: restores `tmp/.toolchain` from the Actions cache keyed by the pinned Spinel commit, builds it with `make toolchain` only on a cache miss, with a `ruby` stub that fails when invoked first on the path of that step so the build is proven Ruby-free, then runs `make doctor`, `make build`, checks the generated config, and runs `make test` on Ubuntu.
- `build/`: `spin` output, ignored by git; `build/smoke/` holds the smoke test's files.
- `docs/`: `architecture.md`, `compatibility.md` (every Neovim command implemented, with its test), `actions.md` (every action name a keymap may use, plugin actions included), `plugins.md` (how to write a compiled plugin), `backlog.md` (known items left for later changes, each with its location and fix outline).
- `openspec/`: specs and change proposals.

## Coding conventions

- Prefer the simplest change that fully solves the task. Do not widen scope on your own.
- Match the existing style of the file you are editing.
- Ruby naming conventions, the mechanical ones enforced by `test/lint.rb`: one public class or module per file, named after the file in CamelCase (`ex_name.rb` declares `ExName`), in the namespace of its layer directory (`carat/domain/` is `Carat::Domain`; feature subdirectories such as `use_cases/windows/` add no namespace; `carat/plugins/<name>/` adds `Plugins::<Name>`; `carat/plugin_api.rb` and `Carat::Json` in `carat/domain/json.rb` are the recorded exceptions); CamelCase classes and modules; upper snake case constants; snake_case methods without unclear abbreviations (`char_class`, not `cls`); a predicate ends in `?` and returns `bool`, never `get_`, `is_`, or `has_`, and a method returning `bool` is a predicate unless it is a command listed in the lint table's `BOOL_COMMANDS` (`pump`, `handle`, `register`); `name!` only beside a safe `name`; a setter of one value is `name=`, while a request with several values keeps its name (`set_lines(from, to, lines)`, and the plugin API's request names); conversions are `to_s`, `to_a`, `to_h`; an alternate constructor is a `from_x` class method; subclasses of `ActionHandler` and `ExHandler` end in `Handler`, ports in `Port`, doubles start with `Fake`, `Memory`, `Manual`, or `Fixed` (`EditorHarness` is a harness, not a double), and concerns are adjectives or `-ing` words (`Guarded`, `Reporting`). The rest is convention: a use case is a verb phrase (`SplitWindow`) whose main entry point is `call`, and a driver is a concrete noun (`DiskFiles`).
- Constructors of behavior classes take required keyword arguments, as `def initialize(actions:, files:)` with `#: (actions: ActionTable, files: Ports::FilePort) -> void`; Spinel types required keywords fully, also through `super(kind: kind)`. A default value such as `store: Store.new` is typed too, but Spinel evaluates it again on every call, so two objects built with the default do not share it (probed on the pinned compiler: two services with the default kept separate state, two given one object shared it). Defaults are therefore allowed only for a collaborator that takes no arguments, keeps no state, and does no I/O; everything shared or needing input is a required keyword built once in the composition root, `EditorAssembly`, which is the only place that wires the core. Records (`Data` and `Struct` subclasses) keep positional construction. The lint test applies the rule to every behavior class, and `test/adapters_assembly.rb` checks that every holder of a shared object received the one the assembly built; a class that receives a shared object keeps a reader for it so the test can see it.
- Concerns: a module under `carat/<layer>/concerns/` that classes of the layer, or of an outer layer, include for shared behavior, such as `Guarded` and `Reporting`. A concern holds behavior only: it lists the readers it depends on in a `Readers the including class provides:` comment at its top (or says none), has no instance variables and no constructor, builds no collaborators, and uses no `extend`, no `included do` or other class-method metaprogramming, and no `define_method`. A signature on a module method is not applied (Spinel copies the method into each including class and infers its parameter types), so its methods carry `# @rbs skip`; a hot path keeps an explicit method, and a concern whose results widen in `make types` becomes a module function instead, as `Boundary.copied_lines` did. The lint test enforces the mechanical rules.
- Add or update tests alongside behavior changes.
- A finding that is not fixed in the current change, from a review or from work on something else, goes into `docs/backlog.md` with its location, why it matters, and a fix outline; the change that fixes it removes the entry.
- All production code follows the Spinel rules in `docs/architecture.md`, section 2.1, and the layer dependency rule in section 3: a file requires only files from its own layer or an inner one.
- Every method, attribute, and instance variable under `carat/` carries an inline RBS signature; `test/lint.rb` enforces it. Use required parameters only, since Spinel seeds no optional, rest, or keyword-splat parameters. A method that a subclass overrides (every port method and its driver and double overrides) cannot have its return type applied, so give it `# @rbs name: Type` parameter lines, or `# @rbs skip` when it takes no parameters, and describe the return in prose; a `-> void` return is annotated normally. A `Hash` type pins only with `String` or `Symbol` keys, and `Array[T]` only with a builtin `T`.
- There is no RuboCop, because RuboCop needs a CRuby interpreter. Style and Spinel rules are enforced by the `lint` test program and by `make diagnose`, which runs `spinel-doctor`, Spinel's own checker.
- Domain classes come in two record kinds and one behavior kind. Immutable values are `Data` subclasses in the form `class Position < Data.define(:row, :col)`: equal by value, frozen, usable as hash keys, built with positional or keyword arguments, and copied with `with`. Mutable records, whose state is a set of fields with readers and writers (Buffer, Cursor, Window, Frame, Cell, Options, EditorState, BufferList, TabList, InputState, PluginUi, Keymap, KeymapNode), are `Struct` subclasses in the form `class Cursor < Struct.new(:row, :col, :want_col)`: a reader and a writer per member, positional construction, and a custom `initialize` that keeps the old arity and fills the rest through `super`. Both use the subclass form only, never `Data.define(...) do ... end` or `Name = Struct.new(...) do ... end`, because Spinel ignores inline RBS inside the block. Behavior classes (use cases, adapters, drivers, ports, doubles, `Carat::Json`, `Carat::Testing`) are plain classes.
- A `Struct` record's methods use the readers and the `self.member =` writers, never instance variables. Every member is pinned with a `# @rbs @member: Type` line in the block at the top of the class, which Spinel applies exactly as it does for a plain class's instance variable. An empty array literal is typed `Array[Integer]` by default and a pinned member of another element type does not coerce it inside a `super` call, so a record whose default is an empty, non-integer collection calls `super()` and stores the literal through the writer, as `Keymap` does.
- Every method and attribute under `carat/` carries an inline RBS signature in Spinel's comment form: a `#: (params) -> return` line directly above each `def`, a `# @rbs @name: Type` block at the top of each class for its instance variables, and a trailing `#: Type` on each `attr_*`. The `lint` test fails on a missing one. Signatures describe what the program actually stores, because Spinel trusts them without verifying; use `untyped` where a value is genuinely mixed. Optional, rest, and keyword-splat parameters are not seeded by Spinel, so prefer required parameters or a second method. No sidecar `.rbs` files. `make types` prints what Spinel inferred and where it widened to `untyped`.
- Key bindings are never hard-coded in Ruby. Add or change them in `config/default.json` and regenerate the Ruby mirror. A plugin's default bindings live in its manifest and go into the keymap before the configuration's, so the configuration wins. Every action a binding names has a handler registered in the action table by its feature (`self.register(table, ...)` with keyword dependencies, called by `EditorAssembly`), and `docs/actions.md` lists it; a test compares the two. The command grammar reads an action by its handler's kind: `:motion` (the names in `Motions::NAMES`), `:find`, `:operator` (the five pending operators), `:text_object` (`TextObjects::NAMES`), `:register`, `:char`, or `:action`; `plugin.<name>.<action>` completes at once and is routed to its plugin through the namespace handler. A new ex command is an `ExHandler` registered in the ex table with its Vim name spec, in the order of `docs/compatibility.md`, which is its precedence. A new motion needs a binding in the `normal`, `operator_pending`, `visual`, `visual_line`, and `visual_block` maps. In the visual modes the five operators complete at once on the selection, and the keys whose meaning differs there are `visual.*` actions. An action name is one or more namespace segments and the action, joined by dots.
- Features beyond core modal editing are plugins, written as `docs/plugins.md` describes. A plugin under `carat/plugins/<name>/` requires only `carat/plugin_api.rb` and files in its own directory, never the editor's entities, use cases, or drivers, and names none of `Domain::`, `UseCases::`, `Adapters::`, `Drivers::`, or `Doubles::` either; the `lint` test enforces both. Buffers and windows are addressed by id across the API, enumerations are strings, and every string crossing the boundary is copied. A new host request is a method on `PluginApi::Host`, an override in `PluginLink` (the `lint` test checks that every method has one), and a method on the request family that serves it, with a minor version bump. It is listed in `config/plugins.json` (name, path, class), the registry is regenerated with `make gen-config`, its configuration entry goes into the `plugins` object of `config/default.json`, and its actions into `docs/actions.md`. Every plugin call goes through the host's one guarded path: a plugin that raises anything is disabled and cleaned up, never the editor. Icons are requested by name through the host, never by code point.
- Spinel pins `Array[T]` and `Hash[K, V]` only with builtin element types, and `Symbol` is not among them: a signature naming `Array[Symbol]` is not applied, so such a parameter is typed `untyped` and checked with `is_a?`, and a `Hash[String, Symbol]` pin leaves the values `untyped`. `# @rbs @member` pins apply to a `Data` subclass as to a `Struct`, but only when the class body holds at least one statement, so give a pinned value at least one method; a pinned hash member refuses an empty hash literal passed to the constructor, so a member that callers may fill with `{}` stays unpinned. A hash literal whose key is a constant reads as `Hash[untyped, untyped]`; write the key as a literal. A line array stored through a `Struct` writer after `super()` lost its slice assignment in this codebase, so `Buffer` passes its original members to `super` and stores only the plugin members through writers.
- Buffer text changes only through the `Buffer` primitives (`insert`, `delete`, `replace`, `set_lines`, `reload`); never assign `lines`, one of its elements, or call a mutating method on it outside `carat/domain/buffer.rb`, and never mutate a line string in place, because change records share the strings. The modified flag is derived: call `mark_saved` after a write and `mark_unsaved` when no saved text matches any more, never set it. A use case that groups edits opens a transaction with `begin_transaction` and closes it with `commit_transaction` only when the open returned true; today that is the dispatcher, `LeaveInsert`, and the plugin host's edit requests, and an edit outside them is its own transaction.
- Shared behavior of several classes of one layer may be a concern: a module under `carat/<layer>/concerns/` that lists the readers it depends on at its top (`Readers the including class provides:`), keeps no instance variables, has no constructor, builds no collaborators, uses no `extend`, `included` hook, or `define_method`, and marks its methods `# @rbs skip`, since Spinel does not apply a signature to a mixed-in method; the `lint` test enforces it. Hot paths keep explicit methods. A list of objects of a program class is a class of its own with a pinned `Array[untyped]` and a typed reader, as `PluginEntries` is.
- Every Neovim command implemented gets a row in `docs/compatibility.md` and a table-driven test.
- Keep documentation in this file and the README in sync with the code.
- Ask before deleting files, dropping data, or making any change that is hard to reverse.
