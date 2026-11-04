# Design

## Context

The scout pack `tmp/scout/build-and-ci-0b17324-20261104T024154Z.md` (Commit: 0b17324, `origin/main`, the branch's base) holds the facts used here, re-checked against `main`: the guard deletes quotes and backslashes and greps the text (`tools/agent_guard.sh` lines 91 to 92 and 98), its git rule names a list of refused verbs after a run of options (136 to 137), the profiles set a refused-verb list each (204 to 227), and the file-tool branch judges the path and its real path (231 to 256). Every finding of the pack still holds. The commands each agent runs are those its file under `.claude/agents/` names (the pack's Gaps list them by agent); the workflow script runs none itself. `settled_at` is at `tools/gates.sh` 75 to 79 and its diff has no `--no-renames`, unlike `tests_only_since` in `tools/run_state.sh`.

## Goals / Non-Goals

**Goals:**

- A command no profile lists is refused, so an unlisted form fails closed.
- The forms the guard cannot judge (expansions, substitutions, subshells, here-documents, globs) are refused before any form is matched.
- Each agent's normal commands, as its file names them, pass under its profile.
- A guard that is missing, edited on the branch, or failing refuses the call.
- A file moved into `openspec/` after a review unsettles the review.

**Non-Goals:**

- Containing a contributor that edits a script or a Makefile recipe and then runs it: the reviews, the records gate, and branch protection stand behind the contributor.
- The backup push of `workflow-cost` part (d).

## Decisions

### Reading a command as the shell does

`words` becomes a lexer that prints one line per token: `W` and a word with its quotes and escapes removed, `O` and an operator (`;`, `&&`, `||`, `|`, `&`), or `R` and a redirection operator followed by its target word. It refuses, for every profile: `$` outside single quotes (a variable, `$(...)`, `${...}`, `$'...'`, `$"..."`, `$[...]`), a backquote, `(` and `)` outside quotes (subshells, process substitution, extended globs), `<<` (here-documents and here-strings), unquoted `*`, `?`, `[`, `{`, and `}` (globs, brace expansion, groups), a `~` at the start of a word, and an unterminated quote. `field` marks an escaped newline with the character `\001`, and the lexer reads it as the shell reads a line break: a `;` between commands, a character of a quoted word, a line continuation dropped with the backslash before it outside single quotes, and the end of a comment, where a backslash continues nothing (joining the lines in `field` let `true # x \<newline>git push` hide the push in the comment). A `#` at the start of a word starts a comment that ends at the line break. Only a bare digit run right before a redirection, with no quote or backslash in it, is its descriptor (the shell reads `"1">x` as the word `1` and a redirection); `>&N`, `<&N`, and `>&-` duplicate a descriptor and have no target.

`field` decodes a `\u` escape of a printable ASCII character to that character, so an escaped `$` or quote reads as the shell will see it; any other `\u` escape stays `?`, which the lexer refuses outside quotes.

The guard reads the tokens through a command substitution and splits them at line breaks with globbing off, judges each redirection target as soon as it is read, collects each simple command into the positional parameters, and judges the command at each operator and at the end. Every word is checked once for the rules all forms share: no parent step (`..` as a path segment, so `a..b` and `origin/main...HEAD` pass) and no run state's directory (`build/pipeline` or `pipeline/`), the body file excepted where a form names it. This one parent-step check replaces the file-tool branch's two patterns.

### Forms by profile

A form is the command name, then what may follow. Names given by a path, and names no form lists, are refused. Leading assignments are refused unless the form lists their names; the values are checked against a character class.

All profiles (read-only tools): `ls`, `cat`, `head`, `tail`, `wc`, `grep`, `diff`, `cmp`, `sort`, `cut`, `tr`, `nl`, `comm`, `basename`, `dirname`, `realpath`, `readlink`, `stat`, `du`, `date`, `pwd`, `echo`, `true`; `printf` whose first argument is not an option (`printf -v 'a[$(CMD)]'` runs CMD when bash expands the subscript, and `-v PATH` redirects command lookup); `uniq` with at most one operand, `-` and the words after `--` counted (a second operand is the file uniq writes); `find` without `-exec`, `-execdir`, `-ok`, `-okdir`, `-delete`, `-fprint`, `-fprint0`, `-fprintf`, or `-fls`; `sed -n` with line-number print scripts only (`sed` can write and run commands); `sort` with the short options `b d f g h i M n R r s u V z c C m` and `-k` and `-t` with their values, no long option (GNU sort clusters short options, so `-uo FILE` writes, and takes a long option by any unambiguous prefix, so `--compress-prog=sh` runs a command); `cd` to the project or a worktree under `tmp/.`; and `git` with the read verbs `status`, `log`, `show`, `diff`, `rev-parse`, `merge-base`, `ls-files`, `ls-tree`, `cat-file`, `blame`, `describe`, `shortlog`, `rev-list`, `grep`, `show-ref`, `for-each-ref`, `name-rev`, `branch` with listing options only, `remote -v`, `remote get-url origin`, `remote set-head origin main`, `fetch` with `-q`, `--prune`, and `origin` only, `ls-remote origin` with listing options and branch names (a remote such as `ext::` runs a command), `worktree add|remove|list|prune` of a `tmp/.` worktree, and `checkout -q --detach` inside a `tmp/.` worktree (`-C`). The read verbs refuse the options that write or run a command, by any prefix, since git takes a long option by an unambiguous one: `--output`, `--ext-diff`, `--textconv`, `--filters`, `--upload-pack`, `--receive-pack`, `--exec`, and `git grep`'s `--open-files-in-pager` and any short option cluster holding `-O`. Git's global options are only `-C` (the project or a worktree under `tmp/.`, since a repository an agent wrote elsewhere brings a configuration whose commands git runs), `--no-pager`, and for the contributor `-c user.name=...` and `-c user.email=...`; any other `-c`, `--config-env`, `--git-dir`, `--work-tree`, `--exec-path`, or `--namespace` is refused.

`read` adds: `mkdir -p` and `rm` of paths under its DIR; `make` with `-s` and `-C tmp/.NAME`, the targets `dev-build`, `test-build`, `bench-budget`, `metrics`, `metrics-compare`, and `bench`, and the variables `PREFIX` (the project's `tmp/.toolchain`), `SPINEL_CACHE_DIR` (the project's `build/spinel-cache`), `BASE_METRICS` (a path), and `SCENARIOS` (scenario names); `sh tools/run_state.sh` with `show`, `status`, `pending`, `get`, `trusted`, `check`, `bench`, `metrics`, `metric`, `note`, `budget`, and `review-due`; `sh tools/gates.sh` with gate names, after an optional `BASE=REV`; and `sh tools/metrics.sh measure OUT [SCENARIO...]`, OUT only `build/metrics/current.tsv` of the project or of a worktree `tmp/.NAME` with no link on its way (checked in the project and every worktree when relative, since the guard does not follow `cd`), and `compare BASE CURRENT`, which only reads.

`merger` adds to the shared forms: `sh tools/run_state.sh` with `show`, `status`, `get`, `trusted`, `metric`, `set CHANGE ci "red|green HEX"`, and `set CHANGE merged HEX`; `CHANGE=NAME RECORDS="..." sh tools/gates.sh merge BODY`; `sh tools/ci_wait.sh N`; `git push origin --delete BRANCH` of a Conventional Branch; `git checkout -q main`; `git merge -q --ff-only origin/main`; and `git branch -D BRANCH` of a Conventional Branch.

`contributor` adds to the read tools: `git` `add`, `commit`, `mv`, `rm`, `restore`, and `merge` of `origin/main` with `-q`, `--no-edit`, `--no-ff`, `-m MESSAGE`, `--abort`, or `--continue`; `make` with `-s`, `-k`, any target name, and the variables `T`, `S`, `FILE`, `TESTS`, `SCENARIOS`, `BASE_METRICS`, `ALLOC_BUDGET`, `ANALYSIS_ROUNDS`, `DIAGNOSE_SKIP`, `CARAT_BIN`, `TEST_OPT`, `NAME`, `AREA`, `DIR`, `ACTION`, and `SPEC`, every value without a shell character, since recipes expand them; `openspec` and `npx [-y] @fission-ai/openspec@latest` with any arguments; `mkdir`, `rm`, `cp`, `mv`, `touch`, and `chmod`, every path argument a write target; `sh tools/run_state.sh` with `show`, `status`, `pending`, `get`, `budget`, `history`, `push CHANGE [--ci-fix]`, and `set CHANGE pr N`; and `sh tools/gates.sh` with gate names or `pr-body BODY`. `git push`, `gh`, and the run state's records stay out because no form lists them.

A script is named as `tools/NAME.sh`, `./tools/NAME.sh`, or by the project's absolute path, and run with `sh` alone, without options.

### Write targets

A redirection's target and each path argument of a writing command are write targets, judged by one function: `/dev/null` passes as a redirection target only, since as an operand of `rm`, `mv`, `cp`, `touch`, or `chmod` it would replace or alter the device node; a parent step is refused; the real path (as `real_path` computes it) must be inside the project's real path (never the project itself) and outside its `.git/` and `build/pipeline/`, and never `build/` itself, which holds the run state; for `read` it must also be under the real path of DIR or of `build/stages/`, the checker's log directory. A file tool's path is the same write target, with two differences: no `/dev/null` or `build/stages/` (the file tools write only DIR for `read` and nothing for the merger), and the contributor's body file `build/pipeline/NAME.body.md` passes when its path is exactly that and its real path equals it, so a body file that is a link is refused. This replaces `body_links` and `body_word`: Bash names the body file only as the argument of the body gate, a whole word by construction, so no link, move, or copy can reach it.

### Hooks fail closed and read main's guard

Each agent's hook line becomes `g=$(git -C "$CLAUDE_PROJECT_DIR" show origin/main:tools/agent_guard.sh) && sh -c "$g" agent_guard PROFILE [DIR] || exit 2`. Claude Code blocks a call only on exit 2; with `|| exit 2` every other failure (no guard on main, a syntax error, a failing tool) blocks too. Reading the guard from `origin/main` means an edit on the branch, by the contributor or by text that led it astray, takes effect only after its review and merge, and the profiles keep `origin/main` out of reach: no `update-ref`, no `fetch` refspec, no write under `.git/`.

### Rename detection in settled_at

`settled_at` passes `--no-renames` to `git diff --name-only`, as `tests_only_since` does, so a moved file lists its old path and a code file moved into `openspec/` is not settled.

## Risks / Trade-offs

- The allowlist refuses commands an agent used to run freely, such as a `for` loop, `awk`, or a heredoc commit message. The refusal names the reason and the guard's header names the forms; the dry-run cases pin each agent's documented commands.
- A guard change is live only after merge, so the change's own run is judged by `main`'s guard. The `tools/tools_test.sh` cases judge the branch's guard.
- `real_path` runs once per write target, a few small subshells per call.
