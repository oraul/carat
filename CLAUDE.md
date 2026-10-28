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
- NEVER include any URL in commit messages, PR titles, PR descriptions, code comments, or docs.
- Do not add "Co-Authored-By", "Claude-Session", or similar attribution trailers to commit messages.
- Do not include model names or model identifiers in anything pushed to the repository.
- Never commit secrets, tokens, API keys, or `.env` files.

## Git workflow

- Work on the branch you were assigned. Never push to `main` directly.
- Keep commits small and focused. Use a short imperative subject line (for example `Add user model`).
- Do not create a pull request unless explicitly asked.
- Do not rewrite history on a shared branch (no rebase, amend, or force-push).
- Run the project's lint, format, and tests before every push once they exist.

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
