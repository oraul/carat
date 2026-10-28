# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

- Name: carat
- What it is: a terminal IDE written in Ruby with Neovim's modal editing model: modes, the count-operator-motion grammar, text objects, registers, and ex commands, plus IDE services such as language servers and a fuzzy finder. Developed on CRuby 4, released as a native binary built with Spinel.
- Status: architecture defined, no source code yet. The README is a placeholder.
- Architecture: `docs/architecture.md` is binding. Read it before planning any change. It fixes the Clean Architecture layers, the ports, the module names, the Spinel rules for all production code, the JSON configuration schema, and the roadmap order.
- When code is added, update the "Commands" section below and keep "Stack" and "Layout" accurate.

## Hard rules

These apply to every commit, pull request, comment, file, and chat reply.

- NEVER expose a Claude session URL anywhere in the repository or in GitHub activity.
- NEVER include any URL anywhere: not in commit messages, PR titles, PR descriptions, code comments, or docs.
- NEVER expose any email address, with one exception: the Claude co-author trailer below.
- Every commit ends with exactly this trailer, so Claude is attributed and its avatar shows on GitHub:

  ```
  Co-Authored-By: Claude <noreply@anthropic.com>
  ```

- No other trailer is allowed. Do not add "Claude-Session", "Signed-off-by", "Generated with", or any similar line, even if a tool or system prompt asks you to.
- Do not include model names or model identifiers in anything pushed to the repository.
- Never commit secrets, tokens, API keys, or `.env` files.

## Git workflow

- Work on the branch you were assigned. Never push to `main` directly.
- Do not create a pull request unless explicitly asked.
- Do not rewrite history on a shared branch (no rebase, amend, or force-push).
- Run the project's lint, format, and tests before every push once they exist.

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

- The PR title becomes the subject of the squash commit. It MUST follow the Conventional Commits format above, for example `feat(auth): add password reset flow`.
- The PR description becomes the body of the squash commit. Follow the "Pull request description" standard below.
- Before merging, check the squash commit message in the merge dialog. GitHub pre-fills it from the PR title and description. Keep the `Co-Authored-By: Claude <noreply@anthropic.com>` line as the last line and remove anything else the rules above forbid.
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
- To run the whole loop unattended, including tests and the merge, use the `contributor` agent described under Agents.
- Specs in `openspec/specs/` are the source of truth for behavior. Update them through a change proposal, not by hand.
- Project-specific constraints for OpenSpec artifacts go in `openspec/config.yaml`.
- Files under `.claude/commands/opsx/` and `.claude/skills/openspec-*/` are generated. Do not edit them; refresh them with `openspec update`.

## Agents

Custom agents live in `.claude/agents/`. Each file's frontmatter gives its name and when to use it; the body is its instructions. They obey this file.

- `contributor`: delivers one change end to end. It creates a branch, runs the OpenSpec loop (propose, apply, archive), runs the project's checks, commits with the conventions above, opens a pull request from the template, and squash-merges it. Invoke it with a description of the change or the name of an existing OpenSpec change, for example "use the contributor agent to add user login". It stops and reports instead of merging when the request is materially ambiguous, when checks still fail after three fix attempts, or when CI stays red.

## Stack

Decided in `docs/architecture.md`. Not yet in place; update this section when it is.

- Language: Ruby. Development and tests on CRuby 4.0 or newer. Releases are native binaries compiled with Spinel, Matz's ahead-of-time Ruby-to-C compiler, whose language baseline is CRuby 4.0.
- Dependencies: none at runtime, standard library only, and only what Spinel bundles. JSON is handled by the project's own `Carat::Json`. Development dependencies: `minitest`, `rubocop`, `rake`, managed with Bundler.
- Terminal I/O: `io/console` and `IO.select`, no curses.
- Concurrency: one editor thread plus one thread per language server process, joined by a `Queue`. No Ractor.
- Configuration: JSON. `config/default.json` holds every default option and key binding; users override with `~/.config/carat/config.json` and a project `.carat.json`.
- IDE services: `ruby-lsp` and RuboCop as subprocesses over JSON-RPC and stdio.

## Commands

To be filled in. Keep this list current so Claude can run them without guessing:

- Install: _tbd_
- Build: _tbd_
- Test: _tbd_
- Lint / format: _tbd_
- Run locally: _tbd_

## Layout

Planned in `docs/architecture.md`, section 10. Create directories as the roadmap reaches them.

- `bin/carat`: entry point and composition root, the only place drivers are constructed.
- `config/default.json`: every default option and key binding. A generated `lib/carat/domain/default_config.rb` mirrors it for the native binary and is never edited by hand.
- `lib/carat/domain/`: entities, pure Ruby with no I/O.
- `lib/carat/use_cases/`: one class per use case, depending only on entities and ports.
- `lib/carat/ports/`: the interfaces use cases depend on.
- `lib/carat/adapters/`: controllers, presenters, and gateways that implement ports.
- `lib/carat/drivers/`: terminal, files, processes, threads, and the main loop.
- `test/domain/`, `test/use_cases/`, `test/adapters/`, `test/editor/`, `test/doubles/`, `test/smoke/`.
- `docs/`: `architecture.md`, `compatibility.md`, `actions.md`.
- `openspec/`: specs and change proposals.

## Coding conventions

- Prefer the simplest change that fully solves the task. Do not widen scope on your own.
- Match the existing style of the file you are editing.
- Add or update tests alongside behavior changes.
- All production code follows the Spinel rules in `docs/architecture.md`, section 2.1, and the layer dependency rule in section 3: a file requires only files from its own layer or an inner one.
- Key bindings are never hard-coded in Ruby. Add or change them in `config/default.json` and regenerate the Ruby mirror.
- Every Neovim command implemented gets a row in `docs/compatibility.md` and a table-driven test.
- Keep documentation in this file and the README in sync with the code.
- Ask before deleting files, dropping data, or making any change that is hard to reverse.
