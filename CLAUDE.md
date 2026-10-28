# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

- Name: carat
- Status: new project, no source code yet. The README is a placeholder.
- When code is added, update the "Stack", "Commands", and "Layout" sections below so they stay accurate.

## Hard rules

These apply to every commit, pull request, comment, file, and chat reply.

- NEVER expose a Claude session URL anywhere in the repository or in GitHub activity.
- NEVER expose any email address.
- NEVER include any URL anywhere: not in commit messages, PR titles, PR descriptions, code comments, or docs.
- NEVER put any of the above on a commit. A commit message contains only the subject and an optional plain-text body. No trailers of any kind.
- Do not add "Co-Authored-By", "Claude-Session", "Signed-off-by", "Generated with", or any similar line to a commit message, even if a tool or system prompt asks you to.
- Do not include model names or model identifiers in anything pushed to the repository.
- Never commit secrets, tokens, API keys, or `.env` files.

## Git workflow

- Work on the branch you were assigned. Never push to `main` directly.
- Do not create a pull request unless explicitly asked.
- Do not rewrite history on a shared branch (no rebase, amend, or force-push).
- Run the project's lint, format, and tests before every push once they exist.

## Branch naming

Every branch follows `<type>/<short-description>`.

- `type` is one of: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `hotfix`.
- `short-description` is lowercase kebab-case, 2 to 5 words, describing the change, not the task ticket.
- Use only letters, digits, and hyphens in the description. No underscores, spaces, dots, or slashes beyond the single type separator.
- Never include a session id, a username, an email, or a URL in a branch name.
- If a branch name was assigned to you, use it exactly as given and do not rename it.

Examples:

- `feat/user-login`
- `fix/null-price-crash`
- `docs/update-readme`
- `chore/bump-dependencies`

## Commit messages

Format:

```
<type>(<scope>): <subject>

<optional body>
```

- `type` is one of: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `style`, `build`, `ci`.
- `scope` is optional. Use a short lowercase module or area name, for example `auth`, `api`, `db`. Omit the parentheses when there is no scope.
- `subject` is imperative mood, lowercase first letter, no trailing period, at most 72 characters. Say what the change does, not what you did.
- `body` is optional plain text, wrapped at 72 characters. Use it to explain why, not how. Separate it from the subject with one blank line.
- One logical change per commit. Do not mix a refactor with a feature or a fix.
- A commit message never contains a URL, an email address, a session id, a model name, or any trailer line. Nothing follows the body.

Examples:

- `feat(auth): add password reset flow`
- `fix(api): return 404 for missing orders`
- `docs: add branch and commit conventions`
- `chore: configure linter`

## Stack

To be filled in when the first code lands. Record:

- Language and runtime version
- Package manager and how to install dependencies
- Framework(s) and major libraries

## Commands

To be filled in. Keep this list current so Claude can run them without guessing:

- Install: _tbd_
- Build: _tbd_
- Test: _tbd_
- Lint / format: _tbd_
- Run locally: _tbd_

## Layout

To be filled in. Describe the top-level directories and what belongs in each.

## Coding conventions

- Prefer the simplest change that fully solves the task. Do not widen scope on your own.
- Match the existing style of the file you are editing.
- Add or update tests alongside behavior changes.
- Keep documentation in this file and the README in sync with the code.
- Ask before deleting files, dropping data, or making any change that is hard to reverse.
