# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

- Name: carat
- What it is: a terminal IDE in Ruby with Neovim's modal editing model (modes, the count-operator-motion grammar, text objects, registers, ex commands), IDE services such as language servers, and a plugin system the explorer, finder, and git integration are built on. Built, tested, and shipped entirely with Spinel at the Ruby 4 language level; CRuby is never required.
- Status: roadmap items 1, 2, 3, 4, 5, 8, 11, the search half of 6, the windows half of 7, and the explorer half of 12 are done, and the configuration files of item 9 arrived ahead of it. The next changes are `docs/queue.md`; the roadmap is `docs/architecture.md` section 12; the delivered changes close `docs/codebase-map.md`; open items are `docs/backlog.md`.
- Architecture: `docs/architecture.md` is binding: the layers, the ports, the module names, the Spinel rules, the `.caratrc` format, and the roadmap order. Read the sections a change touches before planning it.
- Code map: `docs/codebase-map.md` names every file under `carat/`, `bin/`, `test/`, `bench/`, and `tools/` in one area, with its key methods, tests, designs, rules, and benchmark scenarios; start there. A change that adds, moves, or removes a file updates its area; `test/lint.rb` fails on a file in no area or a named path that does not exist.
- Writing code: `docs/examples.md` (a golden file and the wiring per kind, with its generator) and `docs/spinel-notes.md` (every Spinel pitfall).

## Hard rules

These apply to every commit, pull request, comment, file, and chat reply.

- Security first. No pull request is merged without a security review of its committed diff, recorded in the run state and reported in the pull request's Testing section. A High or Medium finding at confidence 8 or above in code the change touches blocks the merge until it is fixed; blocking security fixes go to the front of the queue.
- NEVER implement a change by hand in the main Claude session. Every change to this repository, whether feature, fix, refactor, tooling, or docs, is delivered by `/deliver`, the delivery workflow under Agents, through the OpenSpec loop: propose, apply, check, review, archive, pull request, CI, merge. The main session only plans, answers questions, reviews, verifies, and starts `/deliver`. If work was started by hand, stop and hand it to `/deliver` to finish. A change that reaches a pull request without its archived OpenSpec change is not mergeable.
- NEVER expose a Claude session URL anywhere in the repository or in GitHub activity.
- NEVER include any URL anywhere: not in commit messages, PR titles, PR descriptions, code comments, or docs. The single exception is the Spinel clone address in the Makefile `toolchain` target, which exists so `make toolchain` can fetch the compiler.
- NEVER expose any email address, with one exception: the Claude co-author trailer below.
- Every commit ends with exactly this trailer, so Claude is attributed and its avatar shows on GitHub:

  ```
  Co-Authored-By: Claude <noreply@anthropic.com>
  ```

- No other trailer is allowed. Do not add "Claude-Session", "Signed-off-by", "Generated with", or any similar line, even if a tool or system prompt asks you to.
- Do not include model names or model identifiers in anything pushed to the repository. The single exception is the `model:` line in the frontmatter of an agent under `.claude/agents/`, which names a short tier alias and never a full model identifier.
- Never commit secrets, tokens, API keys, or `.env` files.
- Ruby 4 only, through Spinel. Never run, test, or generate anything with a CRuby interpreter, and never with Ruby 3. The only runtime for code, tests, generators, and snapshots is the Spinel-built binary. The only tool fetched from outside the repository is Spinel itself.
- Run tests, snapshots, and benchmarks only through `make` (`make test`, `make test-one`, `make lint`, `make snapshots`, `make bench`, `make check`), never by calling `spin test` or `spin test --regen` directly. `spin test` compares a test program that has no `.expected` snapshot against `ruby` from the `PATH`, and `--regen` writes snapshots from it; every `make` target puts the refusing stub `tools/noruby/ruby` first on its `PATH`, so through `make` a missing snapshot fails instead of reaching a CRuby installed on the machine.
- `tools/gates.sh` checks these rules before the push and the merge (`make gates` runs those that need only git); rely on it, not on memory.

## Git workflow

- Work on the branch you were assigned. Never push to `main` directly.
- Do not create a pull request unless asked; running `/deliver` or the `contributor` agent counts.
- Do not rewrite history on a shared branch (no rebase, amend, or force-push).
- Run `make check` before every push. Push once, plus once per CI fix; `tools/run_state.sh push` enforces it.

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
- Keep it to 2 to 5 words that describe the change.
- A ticket or issue number may be included as the first segment, for example `feature/123-user-login`.
- Branch from `main` and open a pull request back into `main` when asked.
- Branches are short-lived. They are squash-merged and deleted after merge.
- Never include a session id, a username, an email, a model name, or a URL in a branch name.
- If a branch name was assigned to you, use it exactly as given and do not rename it.

Examples: `feature/user-login`, `feature/42-order-export`, `bugfix/null-price-crash`, `hotfix/payment-timeout`, `release/1.0.0`, `chore/bump-dependencies`.

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

## Pull requests

Pull requests are **squash-merged** into `main`. Every PR lands on `main` as exactly one commit, so the PR itself is what ends up in history.

- The PR title becomes the subject of the squash commit, followed by a space and the PR number in parentheses, exactly as GitHub pre-fills it, for example `feat(auth): add password reset flow (#12)`. The number is what links the commit on `main` back to the pull request. The title itself MUST follow the Conventional Commits format above.
- The PR description becomes the body of the squash commit. Follow the "Pull request description" standard below.
- Before merging, check the squash commit message GitHub pre-fills: keep the `(#number)` suffix and the `Co-Authored-By: Claude <noreply@anthropic.com>` line last, and remove anything the rules above forbid.
- Branch commits follow the commit rules but do not survive the merge; do not spend effort rewriting them.
- One PR covers one logical change. If the squash commit would need more than one `type`, split the PR.
- A breaking change is marked with `!` in the PR title, for example `feat(api)!: drop v1 endpoints`, and explained in the description.
- Never merge a pull request yourself unless asked; `/deliver` counts, its `merger` merging last.
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

Specs and change proposals live under `openspec/`; the commands and skills OpenSpec installs live under `.claude/`.

- Run it with `npx @fission-ai/openspec@latest <command>`; it is not a project dependency. Usage statistics are disabled: `.claude/settings.json` sets `OPENSPEC_TELEMETRY=0`; outside Claude Code, export it or run `openspec config set telemetry.enabled false` once.
- `/opsx:propose`, `/opsx:apply`, and `/opsx:archive` before the pull request, so the squash commit carries the implementation, the synced specs, and the archived change together. `/deliver` runs the whole loop (Agents).
- Every change goes through OpenSpec, refactors, tooling, and docs included. A change that alters no behavior still gets a proposal, a design, and tasks, sets `skip_specs: true` in its `.openspec.yaml`, and is archived with `--skip-specs`. The archived change records why the code looks the way it does.
- Specs in `openspec/specs/` are the source of truth for behavior, changed only through a proposal. Constraints for the artifacts go in `openspec/config.yaml`. `.claude/commands/opsx/` and `.claude/skills/openspec-*/` are generated: refresh them with `openspec update`, never edit them.

## Agents

Agents live in `.claude/agents/` and obey this file. Agents cannot start agents, so `.claude/workflows/deliver-change.js` starts them: `/deliver <change or brief>` runs it and resumes from the run state. The main session never implements a change by hand (Hard rules).

- Phases, one agent each with a schema-checked result: planner, scouts (at most three edited areas), contributor, checker, quality reviewer, security reviewer (never skipped), benchmark (when allocations or rounds differ from main's recorded figures), contributor packaging, merger (CI and merge), retrospective, periodic review when due, reporter. What blocks, a red CI included, goes back to the contributor and the later phases run again, at most three rounds, then the run stops without merging.
- `contributor`: the only agent that edits: proposes and applies through OpenSpec, fixes what comes back, archives, pushes, and opens the pull request; stops on a materially ambiguous request, a secret, an irreversible action, or missing context. Tasks of one domain may share a change, but one change is one reviewable pull request; one that grows past that is split.
- `planner`: orders `docs/queue.md` by `docs/goals.md` into `build/plan/`, citing its tier and a number per decision; an unresolved blocking security finding stops the run; it runs only when `plan-needed` finds a decision to make. `retrospective`: records the run's metrics, a total-token overrun, and at most three proposals to simplify the workflow, and runs `review-due`. Neither edits a tracked file. `/plan` previews the planner.
- Periodic review: `.claude/workflows/periodic-review.js` (`/review`), the reviewers' periodic mode over `main`, every five merged changes and after a change to an area of `REVIEW_AREAS` in `tools/run_state.sh`.
- `scout`: one map area at the current commit into a pack of facts in `tmp/scout/`. `checker`, `quality-reviewer`, `security-reviewer` (`security-review` on the committed diff), `benchmark`, `merger`, and `reporter` never edit; each agent's hook runs `tools/agent_guard.sh`. Mechanical agents run on the cheapest tier, the others on the session's model.
- Run state: `build/pipeline/<change>.json`, written only by `tools/run_state.sh`, its phases, reviews, and figures only by the workflow; stage logs in `build/stages/<change>/`. `docs/metrics.tsv` gets one row per merged change from `tools/run_state.sh history` in the next change's package step, which also commits the planner's queue.

## Stack

Decided in `docs/architecture.md` sections 2 and 13, which give the reasons.

- Language: Ruby 4, compiled with Spinel, Matz's ahead-of-time Ruby-to-C compiler (language baseline CRuby 4.0), at the commit pinned as `SPINEL_REF` in the Makefile. No CRuby anywhere, not even to build Spinel (its one generated header is vendored under `tools/spinel/`): a clone needs a C compiler, `make`, `git`, and `curl`. Every target and CI run with `tools/noruby/` first on the `PATH`, whose `ruby` exits 127.
- Toolchain: `spin`, `spinel`, and `spinel-doctor`, installed by `make toolchain` under `tmp/.toolchain`; the `Makefile` only maps targets to `spin` and OpenSpec. No Rakefile, no Bundler.
- Dependencies: none beyond what Spinel bundles (`io/console` in the terminal driver, `pty` and `open3` in the smoke test); JSON is `Carat::Json`. Tests use `Carat::Testing` with committed snapshots, compiled into one runner, and load the doubles through `carat/test_support.rb`.
- Terminal I/O: `io/console` and `IO.select`, no curses. Child processes: `Process.spawn` with `IO.pipe`, never `IO.popen`. One editor thread plus one per language server, joined by a `Queue`; no Ractor.
- Configuration: `.caratrc` lines of `scope.name value`: `config/default.caratrc` (embedded), then `~/.config/carat/caratrc`, then the project's `.caratrc`, a later line winning, every problem reported as `file:line: message`.
- IDE services: `ruby-lsp` and RuboCop as subprocesses over JSON-RPC and stdio.

## Commands

Every command is a Makefile target, `make help` prints each one's full description, and this list names them all. `docs/architecture.md` section 10 explains the test, analysis, and diagnose machinery.

- Toolchain: `make toolchain` (the pinned commit into `tmp/.toolchain`; bump the pin in its own pull request after `make check`, regenerating the vendored header there), `make toolchain-clean`, `make spinel-rev` (the CI cache key), `make doctor` (the tools and `ruby: refused (stub)`), `make no-cruby`.
- Build: `make build` (release, `build/bin`), `make dev-build` (`build/dev/carat`, `-O TEST_OPT --incremental`, analysis budget checked), `make run FILE=path`, `make install`, `make pack`, `make clean` (never `tmp/`).
- Test: `make test` is `make build`, `make test-build` (the runner `test/runner/run_all.rb`, analysis budget checked), and `make test-run` (each test, or those `TESTS` names, in its own process against its snapshot; the smoke test runs `CARAT_BIN`); `make test-one T=test/NAME.rb`; `make lint`; `make snapshots` (rewrite every `.expected`, review the diff). A test without a snapshot fails. Never call `spin test` directly.
- Analysis: `make diagnose` and `make diagnose-one T=path` (`spinel-doctor`, must be clean; `DIAGNOSE_SKIP`), `make types`, `make analysis-budget` (`ANALYSIS_ROUNDS`, default 2).
- Performance: `make bench` (`SCENARIOS="lh j"`, the map naming them per area), `make bench-budget` (`ALLOC_BUDGET` objects per `lh` key, default 100), `make profile`, `make metrics` (`build/metrics/current.tsv`), `make metrics-compare` (`BASE_METRICS`; fails on more allocations or rounds).
- Configuration: `make gen-config` (the config mirror and plugin registry from `config/`), `make config-current`.
- Authoring: `make new-use-case`, `new-action`, `new-ex-command`, `new-test`, `new-plugin` (`tools/new.sh`, kinds in `docs/examples.md`).
- Checks: `make check` runs `CHECK_STAGES` in order (doctor, docs-lint, build, dev-build, config-current, test-build, test-run, diagnose, no-cruby, bench-budget, metrics, tools-test, gates) before every push; `make stages`, `make check-stage S=NAME`; the Makefile records why CI leaves out three. `make docs-lint` (`tools/docs_lint.sh`: budgets, forbidden content, hard-wrapped pull request text, dead paths, untagged queue items), `make tools-test`, `make gates` (`tools/gates.sh static`).
- `sh tools/run_state.sh`: a change's run state; `check CHANGE [COMMIT]` runs the stages, skipping or carrying (all but the test stages, past a test-only commit) only a pass at the workflow's COMMIT; `scope` sizes a fix's review; `bench CHANGE` compares with main's recorded figures; `push CHANGE` pushes after the pre-push gates; `usage` (each start's totals, which `/deliver` records), `plan-needed`, `metric`, `metrics`, `note`, `budget`, `review-due`, `pending`, `history`, and `status` (`/status`).
- OpenSpec: `make spec-list`, `make spec-validate`, `make spec-update`, usage statistics disabled.

## Layout

Defined in `docs/architecture.md` section 11, in the shape `spin` expects; `docs/codebase-map.md` places every file. The top level:

- `spin.toml`, `Makefile`, `README.md`, `.gitignore`, and `carat.rb`, the production require graph, innermost layer first, ending with the plugin registry, with no test double.
- `carat/`: `plugin_api.rb` (the only file a plugin may require), the layers `domain/`, `ports/`, `use_cases/`, `adapters/`, `drivers/`, the doubles `doubles/` (required only by `carat/test_support.rb`), `plugins/` (the generated `registry.rb` and one directory per plugin), `testing.rb`, `test_support.rb`, `version.rb`.
- `bin/`: the compile roots `carat.rb` (the composition root, the only place drivers are constructed) and `carat-gen-config.rb`. `config/`: `default.caratrc` (every default, mirrored by the generated `carat/domain/default_config.rb`) and `plugins.caratrc`.
- `test/`: one module per file with its snapshot, and `runner/run_all.rb`. `bench/`: the key benchmark. `tools/`: the `noruby/ruby` stub, the vendored Spinel header, and the scripts behind the targets, CI, and the pipeline.
- `docs/`: `architecture.md`, `codebase-map.md`, `examples.md`, `spinel-notes.md`, `goals.md`, `queue.md`, `metrics.tsv`, `compatibility.md` (every Neovim command implemented), `actions.md` (every action name), `plugins.md`, `backlog.md`.
- `openspec/`, `.claude/` (agents, workflows, commands, settings, generated OpenSpec files), `.github/` (CI and the pull request template).
- Ignored: `build/` (builds, the compile cache, stage logs, run states), `dist/`, and `tmp/` (the hidden `tmp/.spinel` and `tmp/.toolchain`, since `spin` reads every visible directory as source, and `tmp/scout/`).

## Coding conventions

- Prefer the simplest change that fully solves the task; do not widen scope on your own. Match the existing style of the file you are editing.
- Start from the golden example of the kind in `docs/examples.md`, or its generator, which also lists every place the kind is wired into. All code follows the Spinel rules of `docs/spinel-notes.md` and `docs/architecture.md` section 2.1, and the layer rule of section 3: a file requires only files from its own layer or an inner one.
- Naming, enforced by `test/lint.rb`: one public class or module per file, named after the file in CamelCase (`ex_name.rb` declares `ExName`), in its layer's namespace (`carat/domain/` is `Carat::Domain`; feature subdirectories such as `use_cases/windows/` add none; `carat/plugins/<name>/` adds `Plugins::<Name>`; `carat/plugin_api.rb` and `Carat::Json` are the exceptions); upper snake case constants; snake_case methods without unclear abbreviations (`char_class`, not `cls`); a predicate ends in `?` and returns `bool`, never `get_`, `is_`, or `has_`, and a method returning `bool` is a predicate unless it is in `BOOL_COMMANDS`; `name!` only beside `name`; a one-value setter is `name=`, a request with several values keeps its name (`set_lines(from, to, lines)`); conversions are `to_s`, `to_a`, `to_h`, alternate constructors `from_x`; handlers end in `Handler`, ports in `Port`, doubles start with `Fake`, `Memory`, `Manual`, or `Fixed`, concerns are adjectives or `-ing` words. A use case is a verb phrase (`SplitWindow`), a driver a concrete noun (`DiskFiles`).
- A use case has one public method, `call`; the rest is private and its constants are in `private_constant`; how operations, variants, handlers, shared logic, and shared constants are split is `docs/architecture.md` section 5. Spinel does not enforce `private_constant`, so `lint` checks that a plain class under `carat/use_cases/` exposes only `initialize`, `call`, and readers (handlers, tables, `CommandRunner`, `Outcome`, records, concerns, and `use_cases/plugins/` aside, see `docs/backlog.md`), that every constant there is in a `private_constant`, and that no other file names `UseCase::CONSTANT`.
- Constructors of behavior classes and records take required keyword arguments with a keyword signature (`#: (actions: ActionTable, files: Ports::FilePort) -> void`), which `lint` checks. A default is allowed only for a collaborator with no arguments, state, or I/O, since Spinel evaluates it on every call; everything shared is built once in `EditorAssembly`, the only place that wires the core, and kept in a reader so `test/adapters_assembly.rb` can check every holder got the one instance.
- Immutable values are `Data` subclasses; mutable records (`Buffer`, `Cursor`, `Window`, the lists, the states) are `Struct` subclasses with `keyword_init: true`, every member pinned, their methods using readers and `self.member =` writers. Both use the subclass form, never a block form, and are built with keywords at every call site; the `super` and pin rules are `docs/spinel-notes.md`, Records. Behavior classes (use cases, adapters, drivers, ports, doubles, `Carat::Json`, `Carat::Testing`) are plain classes.
- Every method, attribute, and instance variable under `carat/` carries inline RBS in Spinel's comment form: `#: (params) -> return` directly above each `def`, a `# @rbs @name: Type` block at the top of each class, a trailing `#: Type` on each `attr_*`, no `.rbs` files. A signature describes what the program stores, `untyped` where genuinely mixed, required parameters only; an overridden method gets `# @rbs name: Type` lines or `# @rbs skip` and its return in prose. `lint` fails on a missing one; `make types` shows the inference.
- Concerns follow `docs/architecture.md` section 5.4: a module under `carat/<layer>/concerns/` holding behavior only (no instance variables, constructor, collaborators, `extend`, `included` hook, or `define_method`), its methods marked `# @rbs skip`, a `Readers the including class provides:` comment at its top; a hot path keeps an explicit method.
- Add or update tests alongside behavior changes; every Neovim command implemented gets a row in `docs/compatibility.md` and a table-driven test. A test file is a module named after the file plus `Test`, its helpers in the module, its statements in `def self.main`, its last line `NameTest.main if __FILE__ == $0`, with a `require_relative` and a `when` line in `test/runner/run_all.rb`. It converts table values with a typed helper (`strings`, `ints`, `.to_s`, `.to_i`) before they reach the library, and a helper returning several values returns an object with typed readers, never an array to destructure (`docs/spinel-notes.md`); `make test-build` checks the rounds.
- No RuboCop, which needs CRuby: the `lint` test and `make diagnose` enforce style and the Spinel rules.
- Key bindings are never hard-coded in Ruby: they are `keymap.<mode> <keys> <action>` lines in `config/default.caratrc`, mirrored by `make gen-config`; a plugin's defaults are configuration lines in its manifest, read before the configuration's, so the configuration wins. Every bound action has a handler registered by its feature and a row in `docs/actions.md`, which a test compares. An action name is dotted segments; the grammar reads it by its handler's kind; `plugin.<name>.<action>` completes at once and goes to its plugin. A new motion is bound in `normal`, `operator_pending`, `visual`, `visual_line`, and `visual_block`; in the visual modes the five operators complete at once and the keys that differ are `visual.*` actions. A new ex command is an `ExHandler` registered in the order of `docs/compatibility.md`, its precedence.
- Features beyond core modal editing are plugins (`docs/plugins.md`, `docs/architecture.md` section 9). A plugin requires only `carat/plugin_api.rb` and files in its own directory and names no `Domain::`, `UseCases::`, `Adapters::`, `Drivers::`, or `Doubles::` constant (`lint` checks both); buffers and windows cross the API by id, enumerations as strings, strings copied, every call through the host's one guarded path, so a plugin that raises is disabled, never the editor. A new host request is a `PluginApi::Host` method, a `PluginLink` override (`lint` checks), and a request family method, with a minor version bump. Icons are requested by name. `docs/examples.md` lists where a new plugin is registered and documented.
- Buffer text changes only through the `Buffer` primitives (`insert`, `delete`, `replace`, `set_lines`, `reload`): never assign `lines` or an element, call a mutating method on it outside `carat/domain/buffer.rb`, or mutate a line string in place, since change records share the strings. The modified flag is derived (`mark_saved` after a write, `mark_unsaved` when no saved text matches). A use case grouping edits opens a transaction with `begin_transaction` and commits it only when the open returned true, as the dispatcher, `LeaveInsert`, and the plugin host's edit requests do; any other edit is its own transaction.
- A finding not fixed in the current change, from a review or other work, goes into `docs/backlog.md` with its location, why it matters, and a fix outline; the change that fixes it removes the entry.
- Keep this file, the code map, and the README in sync with the code. Ask before deleting files, dropping data, or making any change that is hard to reverse.
