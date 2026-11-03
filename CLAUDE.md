# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

- Name: carat
- What it is: a terminal IDE written in Ruby with Neovim's modal editing model: modes, the count-operator-motion grammar, text objects, registers, and ex commands, plus IDE services such as language servers, and a plugin system on which the explorer, finder, and git integration are built. Built, tested, and shipped entirely with Spinel at the Ruby 4 language level; CRuby is never required.
- Status: roadmap items 1, 2, 3, 4, 5, 8, 11, the windows half of 7, and the explorer half of 12 are done, and the configuration files of item 9 arrived ahead of it. The order of the next changes is `docs/queue.md`. The roadmap is `docs/architecture.md` section 12; the delivered changes, in order and with what each left for later, close `docs/codebase-map.md`; known open items are in `docs/backlog.md`.
- Architecture: `docs/architecture.md` is binding. It fixes the Clean Architecture layers, the ports, the module names, the Spinel rules for all production code, the `.caratrc` configuration format, and the roadmap order. Before planning a change, read the sections of it the change touches.
- Code map: `docs/codebase-map.md` names every file under `carat/`, `bin/`, `test/`, `bench/`, and `tools/` in one area, with its key methods, tests, archived designs, rules, and benchmark scenarios. Start there to find what a change touches. A change that adds, moves, or removes a file updates its area; `test/lint.rb` fails on a file in no area or a named path that does not exist.
- When code is added, update the "Commands" section below and keep "Stack", "Layout", and the code map accurate.

## Hard rules

These apply to every commit, pull request, comment, file, and chat reply.

- Security first. No pull request is merged without a security review of its committed diff, recorded in the run state and reported in the pull request's Testing section. A High or Medium finding at confidence 8 or above in code the change touches blocks the merge until it is fixed; security fixes go to the front of the queue.
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
- Do not create a pull request unless explicitly asked; running `/deliver` or the `contributor` agent counts as being asked for the pull request and the merge.
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
- Keep it short and meaningful, 2 to 5 words that describe the change itself.
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

More subject examples: `fix(api): return 404 for missing orders`, `docs: add branch and commit conventions`, `chore: configure linter`.

## Pull requests

Pull requests are **squash-merged** into `main`. Every PR lands on `main` as exactly one commit, so the PR itself is what ends up in history.

- The PR title becomes the subject of the squash commit, followed by a space and the PR number in parentheses, exactly as GitHub pre-fills it, for example `feat(auth): add password reset flow (#12)`. The number is what links the commit on `main` back to the pull request. The title itself MUST follow the Conventional Commits format above.
- The PR description becomes the body of the squash commit. Follow the "Pull request description" standard below.
- Before merging, check the squash commit message in the merge dialog. GitHub pre-fills it from the PR title and description. Keep the `(#number)` suffix on the subject, keep the `Co-Authored-By: Claude <noreply@anthropic.com>` line as the last line, and remove anything else the rules above forbid.
- Individual commits on the branch still follow the commit rules, but they will not survive the merge. Keep them tidy, do not spend effort rewriting them.
- One PR covers one logical change. If the squash commit would need more than one `type`, split the PR.
- A breaking change is marked with `!` in the PR title, for example `feat(api)!: drop v1 endpoints`, and explained in the description.
- Never merge a pull request yourself unless explicitly asked. Running `/deliver` or the `contributor` agent counts as being asked: the `merger` agent's merge is the workflow's last step.
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
- To run the whole loop unattended, including tests and the merge, use `/deliver`, described under Agents.
- Specs in `openspec/specs/` are the source of truth for behavior. Update them through a change proposal, not by hand.
- Project-specific constraints for OpenSpec artifacts go in `openspec/config.yaml`.
- Files under `.claude/commands/opsx/` and `.claude/skills/openspec-*/` are generated. Do not edit them; refresh them with `openspec update`.

## Agents

Custom agents live in `.claude/agents/`, their frontmatter giving name, tools, and use, their body the instructions; they obey this file. Agents cannot start agents, so the workflow `.claude/workflows/deliver-change.js` starts them: `/deliver <change or brief>` runs it, and running it again resumes from the run state; `/status` shows the running change. The main session never implements a change by hand (Hard rules).

- Phases, one agent each with a schema-checked result: planner, scouts, contributor, checker, quality reviewer, security reviewer (never skipped), benchmark, contributor packaging, CI watcher, merger, retrospective, periodic review when due, reporter. What blocks goes back to the contributor and the later phases run again on the new commit, at most three rounds, then the run stops without merging.
- `contributor`: the only agent that edits: it proposes and applies through OpenSpec, committing early, fixes what comes back, archives, pushes, and opens the pull request. It stops when the request is materially ambiguous or needs a secret, an irreversible action, or missing context.
- `planner`: orders the queue by `docs/goals.md`, citing a metric, finding, or request per decision, into `build/plan/`, which the contributor's package step commits; an unresolved blocking security finding stops the run so its fix goes first. `retrospective`: after the merge, records the run's metrics and at most three proposals to simplify the workflow, each with its numbers, and runs `review-due`. Neither edits a tracked file.
- Periodic review: `.claude/workflows/periodic-review.js`, the security and quality reviewers' periodic mode over the whole tree at `main`, every five merged changes and after a change to config loading, file access, plugin boundaries, terminal output, or process spawning; `/review` runs it on demand, `/plan` previews the planner.
- `scout`: reads one map area at the current commit into a context pack of facts in `tmp/scout/`; its file gives the shape and the reuse rules.
- `checker`, `quality-reviewer` (`code-review` and this file's rules), `security-reviewer` (`security-review` on the committed diff), `benchmark` (allocations and rounds against `main`), `ci-watcher`, `merger`, and `reporter` never edit. The mechanical agents run on the cheapest tier; the contributor, the reviewers, the planner, and the retrospective on the session's model.
- Run state: `build/pipeline/<change>.json`, written only by `tools/run_state.sh`; stage logs in `build/stages/<change>/`. Metrics history: `docs/metrics.tsv`, one row per merged change, appended only by `tools/run_state.sh history` in the next change's package step, which also commits the planner's queue.
- Planning: the charter `docs/goals.md` and the ordered queue `docs/queue.md`; each change's brief is archived as `brief.md` in its OpenSpec change.
- Grouping: tasks of one domain may be grouped into one change when that makes sense, but each change stays balanced, one reviewable pull request; a contributor whose change grows past that proposes a split.

## Stack

Decided in `docs/architecture.md` sections 2 and 13, which give the reasons.

- Language: Ruby 4, compiled with Spinel, Matz's ahead-of-time Ruby-to-C compiler (language baseline CRuby 4.0), at the commit pinned as `SPINEL_REF` in the Makefile. No CRuby interpreter anywhere in the workflow, never Ruby 3, and none to build Spinel either (its one CRuby-generated header is vendored under `tools/spinel/`): a clone needs a C compiler, `make`, `git`, and `curl`. Every `make` target, the toolchain build included, and CI through it run with `tools/noruby/` first on the `PATH`, whose `ruby` refuses and exits 127.
- Toolchain: `spin`, Spinel's project tool, for building, running, testing, packaging, and installing, with `spinel` and `spinel-doctor`; `make toolchain` installs them under `tmp/.toolchain`, first on every target's `PATH`. The `Makefile` only maps targets to `spin` and OpenSpec commands. No Rakefile, no Bundler.
- Dependencies: none. Standard library only, and only what Spinel bundles: `io/console` in the terminal driver, and `pty` and `open3` in the smoke test only. JSON, for JSON-RPC, is the project's own `Carat::Json`; the configuration is not JSON. Tests use the project's own `Carat::Testing` with committed snapshots, are compiled together into one test runner, and load the library and the doubles through `carat/test_support.rb`; the production graph `carat.rb` contains no double.
- Terminal I/O: `io/console` and `IO.select`, no curses. Child processes: `Process.spawn` with `IO.pipe`, never `IO.popen`.
- Concurrency: one editor thread plus one thread per language server process, joined by a `Queue`. No Ractor.
- Configuration: `.caratrc` files of one `scope.name value` line each, read by the project's own byte-walking parser: `config/default.caratrc`, embedded in the binary, then `~/.config/carat/caratrc`, then the project's `.caratrc`, a later line winning, every problem reported as `file:line: message`. `config/plugins.caratrc` lists the compiled plugins.
- IDE services: `ruby-lsp` and RuboCop as subprocesses over JSON-RPC and stdio.

## Commands

Every command has a Makefile target, and `make help` prints each one's full description; keep this list current. `docs/architecture.md` section 10 explains the test, analysis, and diagnose machinery.

- `make doctor`: `spinel`, `spin`, a C compiler, and `node` on the path, and `ruby: refused (stub)`; fails when any other `ruby` would be reached. `make no-cruby`: proves the guard with `spin test` on a snapshot-less program in a temporary project outside the repository.
- `make toolchain`: fetch `SPINEL_REF` into `tmp/.spinel`, copy the vendored header in, build, and install `spinel`, `spin`, and `spinel-doctor` into `tmp/.toolchain`. Bump the pin in its own pull request after `make check` passes, regenerating the vendored header with Spinel's `tools/gen_respond_to_tables.rb` there. `make toolchain-clean` removes `tmp/`; `make spinel-rev` prints the pin, the CI cache key.
- `make build`: `spin build` of every `bin/*.rb` into `build/bin`, printing the alias line for a shell profile. `make dev-build`: `bin/carat.rb` with the development flags (`-O TEST_OPT --incremental`, cache in `SPINEL_CACHE_DIR`) into `build/dev/carat`, with the analysis budget checked on its own report. `make run FILE=path`.
- `make test`: `make build`, `make test-build` (every test in the runner `test/runner/run_all.rb`, compiled into `build/test/run_all` at `-O 0 --incremental`, the analysis budget checked on its report), and `make test-run` (each test, or those `TESTS` names, in its own process through `tools/run_tests.sh`, output compared byte for byte with its snapshot, exit status 0; the smoke test runs `CARAT_BIN`, default `build/bin/carat`). A test without a snapshot fails. Never call `spin test` directly.
- `make test-one T=test/NAME.rb`: one test compiled alone and run against its snapshot. `make lint`: `make test-one T=test/lint.rb`. `make types`: the signatures Spinel inferred, where they widened to `untyped`.
- `make diagnose`: `spinel-doctor` on every compile root; it must report clean. `make diagnose-one T=path`; `DIAGNOSE_SKIP` names the legs skipped (default `behavior`, which compares against a CRuby; `make check` also skips `build`, `inference`, and `advice`).
- `make bench`: `bench/keys.rb` at `-O 2` and its scenarios (all, or `SCENARIOS="lh j"`) through `bench/run.sh`, pinned to one core; the map lists the scenarios per area. `make bench-budget`: fails when one key of `lh` allocates `ALLOC_BUDGET` objects or more (default 100). `make profile`: the top functions of `j` and `lh` under `perf`, when it works.
- `make snapshots`: rewrite every `.expected` file from the runner's output; review the diff. `make gen-config`: regenerate the config mirror from `config/default.caratrc` and the plugin registry from `config/plugins.caratrc`. `make config-current`: fail when `make gen-config` rewrote either.
- `make analysis-budget`: compile `ANALYSIS_ROOTS` (default `bin/carat.rb` and the runner) to C and fail above `ANALYSIS_ROUNDS` re-narrowing rounds (default 2), warning above `ANALYSIS_MS`; `make dev-build` and `make test-build` already check both roots.
- `make check`: the canonical stage list `CHECK_STAGES` in order (doctor, build, dev-build, config-current, test-build, test-run, diagnose, no-cruby, bench-budget, metrics, tools-test, gates); run it before every push. `make stages` prints it, `make check-stage S=NAME` runs one stage, and the Makefile records why CI leaves out three. `make tools-test`: `tools/tools_test.sh`, the tests of `tools/ci_scope.sh`, `tools/metrics.sh`, the run state, and the gates. `make gates`: `tools/gates.sh static`.
- `make metrics`: `tools/metrics.sh measure` into `build/metrics/current.tsv`, the rounds and analysis time of both roots and allocations and time per key of eight scenarios, from the earlier stages' builds. `make metrics-compare`: compare it with `BASE_METRICS`, failing on more allocations or rounds and warning on time; CI compares a pull request with the last push to `main` through the Actions cache.
- `sh tools/run_state.sh`: a change's run state; `check CHANGE` runs the stages, resuming after the passed ones; `push CHANGE` pushes after the pre-push gates; `metric`, `metrics`, and `note` record figures and findings; `review-due`, `pending`, and `history` keep the history; `status` is `/status`.
- `make install`, `make pack`, `make clean` (never touches `tmp/`), and `make spec-list`, `make spec-validate`, `make spec-update`, the OpenSpec commands with usage statistics disabled.

## Layout

Defined in `docs/architecture.md`, section 11, in the shape `spin` expects. `docs/codebase-map.md` places every file of the source roots in its area; this list names the top level only.

- `spin.toml` (the manifest), `Makefile` (the command map), `README.md`, `.gitignore` (`build/`, `dist/`, `tmp/`), and `carat.rb`, the production require graph, innermost layer first, ending with the plugin registry, with no test double.
- `carat/`: the library: `plugin_api.rb` (the only file a plugin may require), the layers `domain/`, `ports/`, `use_cases/`, `adapters/`, and `drivers/`, the test doubles `doubles/` (required only by `carat/test_support.rb`), `plugins/` (the generated `registry.rb` and one directory per compiled plugin), `testing.rb`, `test_support.rb`, and `version.rb`.
- `bin/`: the compile roots, `carat.rb` (entry point and composition root, the only place drivers are constructed) and `carat-gen-config.rb`.
- `config/`: `default.caratrc` (every default option and key binding, mirrored by the generated `carat/domain/default_config.rb`) and `plugins.caratrc` (the compiled plugins in order).
- `test/`: one test module per file with its `.expected` snapshot, and `runner/run_all.rb`. `bench/`: the key benchmark, not compiled by `spin`. `tools/`: the `noruby/ruby` stub, the vendored Spinel header, and the scripts behind the make targets, CI, and the pipeline.
- `docs/`: `architecture.md`, `codebase-map.md`, `goals.md`, `queue.md`, `metrics.tsv` (the metrics history), `compatibility.md` (every Neovim command implemented, with its test), `actions.md` (every action name a keymap may use), `plugins.md` (how to write a compiled plugin), `backlog.md` (known items left for later, each with its location and fix outline).
- `openspec/` (specs and changes), `.claude/` (agents, the delivery workflow, `/deliver` and `/status`, settings, and the generated OpenSpec commands and skills), `.github/` (the workflow and the pull request template).
- Ignored by git: `build/` (`spin` output, development builds, the compile cache, `build/smoke/`, `build/stages/`, and `build/pipeline/`), `dist/`, and `tmp/` (`tmp/.spinel` and `tmp/.toolchain`, hidden because `spin` reads every visible directory as project source, and `tmp/scout/`, the scouts' packs).

## Coding conventions

- Prefer the simplest change that fully solves the task. Do not widen scope on your own.
- Match the existing style of the file you are editing.
- Ruby naming conventions, the mechanical ones enforced by `test/lint.rb`: one public class or module per file, named after the file in CamelCase (`ex_name.rb` declares `ExName`), in the namespace of its layer directory (`carat/domain/` is `Carat::Domain`; feature subdirectories such as `use_cases/windows/` add no namespace; `carat/plugins/<name>/` adds `Plugins::<Name>`; `carat/plugin_api.rb` and `Carat::Json` in `carat/domain/json.rb` are the recorded exceptions); CamelCase classes and modules; upper snake case constants; snake_case methods without unclear abbreviations (`char_class`, not `cls`); a predicate ends in `?` and returns `bool`, never `get_`, `is_`, or `has_`, and a method returning `bool` is a predicate unless it is a command listed in the lint table's `BOOL_COMMANDS` (`pump`, `handle`, `register`); `name!` only beside a safe `name`; a setter of one value is `name=`, while a request with several values keeps its name (`set_lines(from, to, lines)`, and the plugin API's request names); conversions are `to_s`, `to_a`, `to_h`; an alternate constructor is a `from_x` class method; subclasses of `ActionHandler` and `ExHandler` end in `Handler`, ports in `Port`, doubles start with `Fake`, `Memory`, `Manual`, or `Fixed` (`EditorHarness` is a harness, not a double), and concerns are adjectives or `-ing` words (`Guarded`, `Reporting`). By convention a use case is a verb phrase (`SplitWindow`) and a driver a concrete noun (`DiskFiles`).
- A use case is a verb phrase with one public method, `call`; everything else is private, and its constants are `private_constant`. How operations, variants (a symbol or flag for a name, a small `Data` request such as `FocusRequest` for a count), forwarding handlers, shared logic (into the domain unless it needs a port), and shared constants (`Domain::Messages`, `Domain::OperatorKind`) are split is `docs/architecture.md` section 5. The pinned Spinel enforces `private` but not `private_constant`, so `test/lint.rb` checks three rules: a plain class under `carat/use_cases/` has no public instance method but `initialize` and `call` and no public writer, `attr_reader` aside for the shared-instance test (left out: the handlers and their bases, `ActionTable`, `ExTable`, `CommandRunner`, `Outcome`, records, concerns, and the plugin host under `use_cases/plugins/`, whose request families keep one method per request until the plugin-side change in `docs/backlog.md`); every constant assigned under `carat/use_cases/` is listed in a `private_constant` there; and no file of the library, the executables, the tests, or the benchmark names `UseCase::CONSTANT` outside the use case's own file.
- Constructors of behavior classes take required keyword arguments, as `def initialize(actions:, files:)` with `#: (actions: ActionTable, files: Ports::FilePort) -> void`; Spinel types required keywords fully, also through `super(kind: kind)`. A default value such as `store: Store.new` is typed too, but Spinel evaluates it again on every call, so two objects built with the default do not share it (probed on the pinned compiler). Defaults are therefore allowed only for a collaborator that takes no arguments, keeps no state, and does no I/O; everything shared or needing input is a required keyword built once in the composition root, `EditorAssembly`, the only place that wires the core. The lint test applies the rule to every behavior class and every record's `initialize`, and `test/adapters_assembly.rb` checks that every holder of a shared object received the one the assembly built; a class that receives a shared object keeps a reader for it so the test can see it.
- Concerns follow `docs/architecture.md` section 5.4: a module under `carat/<layer>/concerns/` holding behavior only (no instance variables, constructor, collaborators, `extend`, `included` hook, or `define_method`), its methods marked `# @rbs skip`, named by an adjective or `-ing` word; the lint test enforces the mechanical rules. It lists the readers it depends on in a `Readers the including class provides:` comment at its top (or says none); a hot path keeps an explicit method, and a concern whose results widen in `make types` becomes a module function instead, as `Boundary.copied_lines` did. A list of objects of a program class is a class of its own with a pinned `Array[untyped]` and a typed reader, as `PluginEntries` is.
- Add or update tests alongside behavior changes.
- A test program passes typed values into the library, as `docs/architecture.md` section 10 explains: a table row's values, and anything read from an untyped array, are `untyped`, and an `untyped` argument widens the parameter it reaches for the whole runner, which the analysis pays for in re-narrowing rounds. Convert table values before the call with a typed helper (`strings`, `ints`, `.to_s`, `.to_i`), as `test/domain_edits.rb` and `test/domain_buffer.rb` do; a test that checks the refusal of a wrongly typed value, as the manifest rules do, is the exception. `make test-build` checks the rounds.
- A test file is a module named after the file with the suffix `Test` (`DomainBufferTest`), with its constants, classes, and helper methods (`def self.name`) in the module, its statements in `def self.main`, and the last line `NameTest.main if __FILE__ == $0`; a new test file gets a `require_relative` and a `when` line in `test/runner/run_all.rb`. A helper returning several values returns an object with typed readers, never an array to destructure (section 10).
- A finding that is not fixed in the current change, from a review or from work on something else, goes into `docs/backlog.md` with its location, why it matters, and a fix outline; the change that fixes it removes the entry.
- All production code follows the Spinel rules in `docs/architecture.md`, section 2.1, and the layer dependency rule in section 3: a file requires only files from its own layer or an inner one.
- Every method, attribute, and instance variable under `carat/` carries an inline RBS signature in Spinel's comment form (section 2.1): a `#: (params) -> return` line directly above each `def`, a `# @rbs @name: Type` block at the top of each class, and a trailing `#: Type` on each `attr_*`; the `lint` test fails on a missing one, and there are no sidecar `.rbs` files. Signatures describe what the program actually stores, `untyped` where a value is genuinely mixed, and parameters are required ones only. A method that a subclass overrides (every port method and its driver and double overrides) cannot have its return type applied, so give it `# @rbs name: Type` parameter lines, or `# @rbs skip` when it takes no parameters, and describe the return in prose; a `-> void` return is annotated normally. `make types` prints what Spinel inferred and where it widened to `untyped`.
- There is no RuboCop, because RuboCop needs a CRuby interpreter. Style and Spinel rules are enforced by the `lint` test program and by `make diagnose`, which runs `spinel-doctor`, Spinel's own checker.
- Domain classes come in two record kinds and one behavior kind, as `docs/architecture.md` section 2.1 describes: immutable values are `Data` subclasses (`class Position < Data.define(:row, :col)`), mutable records whose state is a set of fields with readers and writers (Buffer, Cursor, Window, Frame, Cell, Options, EditorState, BufferList, TabList, InputState, PluginUi, Keymap, KeymapNode) are `Struct` subclasses with `keyword_init: true`, both in the subclass form only, never a block form, because Spinel ignores inline RBS inside the block; behavior classes (use cases, adapters, drivers, ports, doubles, `Carat::Json`, `Carat::Testing`) are plain classes. A record's custom `initialize` takes required keyword parameters with a keyword signature (`#: (row: Integer, col: Integer) -> void`) and fills the rest through `super` with keywords. Every record is built with keyword arguments at every call site (a positional call of a `keyword_init` record raises `ArgumentError`), and the lint test checks it: every `Struct.new` under `carat/`, `bin/`, `test/`, and `bench/` carries `keyword_init: true`, and every `Name.new(` of a record class, or a bare `new(` in a record's own file, starts its arguments with a keyword.
- A `Struct` record's methods use the readers and the `self.member =` writers, never instance variables. Every member is pinned with a `# @rbs @member: Type` line in the block at the top of the class, which Spinel applies exactly as it does for a plain class's instance variable. An empty array literal is typed `Array[Integer]` by default and a pinned member of another element type does not coerce it inside a `super` call, so a record whose default is an empty, non-integer collection calls `super()` and stores the literal through the writer, as `Keymap` does. A keyword `super` of a `keyword_init` record must name every member (section 2.1), so a record that sets only some members in `super` calls `super()` and stores every member through its writer instead, as `Buffer`, `PluginEntry`, and `Registers` do.
- Spinel pins `Array[T]` and `Hash[K, V]` only with builtin element types, and `Symbol` is not among them: a signature naming `Array[Symbol]` is not applied, so such a parameter is typed `untyped` and checked with `is_a?`, and a `Hash[String, Symbol]` pin leaves the values `untyped`. `# @rbs @member` pins apply to a `Data` subclass as to a `Struct`, but only when the class body holds at least one statement, so give a pinned value at least one method; a pinned hash member refuses an empty hash literal passed to the constructor, so a member that callers may fill with `{}` stays unpinned. A `Hash` type pins only with `String` or `Symbol` keys, and a hash literal whose key is a constant reads as `Hash[untyped, untyped]`; write the key as a literal. `Buffer` stores its line array through the writer after `super()` like every other member, and `LineSplice` writes the array one element at a time.
- Key bindings are never hard-coded in Ruby. Add or change them as `keymap.<mode> <keys> <action>` lines in `config/default.caratrc` and regenerate the Ruby mirror with `make gen-config`. A plugin's default bindings live in its manifest and go into the keymap before the configuration's, so the configuration wins. Every action a binding names has a handler registered in the action table by its feature (`self.register(table, ...)` with keyword dependencies, called by `EditorAssembly`), and `docs/actions.md` lists it; a test compares the two. The command grammar reads an action by its handler's kind: `:motion` (the names in `Motions::NAMES`), `:find`, `:operator` (the five pending operators), `:text_object` (`TextObjects::NAMES`), `:register`, `:char`, or `:action`; `plugin.<name>.<action>` completes at once and is routed to its plugin through the namespace handler. A new ex command is an `ExHandler` registered in the ex table with its Vim name spec, in the order of `docs/compatibility.md`, which is its precedence. A new motion needs a binding in the `normal`, `operator_pending`, `visual`, `visual_line`, and `visual_block` maps. In the visual modes the five operators complete at once on the selection, and the keys whose meaning differs there are `visual.*` actions. An action name is one or more namespace segments and the action, joined by dots.
- Features beyond core modal editing are plugins, written as `docs/plugins.md` describes, under the rules of `docs/architecture.md` section 9. A plugin under `carat/plugins/<name>/` requires only `carat/plugin_api.rb` and files in its own directory and names none of `Domain::`, `UseCases::`, `Adapters::`, `Drivers::`, or `Doubles::`; the `lint` test enforces both. Buffers and windows are addressed by id across the API, enumerations are strings, every string crossing the boundary is copied, and every plugin call goes through the host's one guarded path, so a plugin that raises anything is disabled and cleaned up, never the editor. A new host request is a method on `PluginApi::Host`, an override in `PluginLink` (the `lint` test checks that every method has one), and a method on the request family that serves it, with a minor version bump. A new plugin is listed in `config/plugins.caratrc` as `plugin.<name> <path> <class>` with the registry regenerated by `make gen-config`, its `plugin.<name>.*` lines go into `config/default.caratrc`, its manifest gives its default bindings and option defaults as configuration lines, and its actions go into `docs/actions.md`. Icons are requested by name through the host, never by code point.
- Buffer text changes only through the `Buffer` primitives (`insert`, `delete`, `replace`, `set_lines`, `reload`); never assign `lines`, one of its elements, or call a mutating method on it outside `carat/domain/buffer.rb`, and never mutate a line string in place, because change records share the strings. The modified flag is derived: call `mark_saved` after a write and `mark_unsaved` when no saved text matches any more, never set it. A use case that groups edits opens a transaction with `begin_transaction` and closes it with `commit_transaction` only when the open returned true; today that is the dispatcher, `LeaveInsert`, and the plugin host's edit requests, and an edit outside them is its own transaction.
- Every Neovim command implemented gets a row in `docs/compatibility.md` and a table-driven test.
- Keep documentation in this file, the code map, and the README in sync with the code.
- Ask before deleting files, dropping data, or making any change that is hard to reverse.
