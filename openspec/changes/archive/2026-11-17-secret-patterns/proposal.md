# Proposal

## Why

`ASSIGN_RE` in `tools/rules.sh` refuses a secret assignment only when its value is a quoted literal, so `password = hunter2hunter2` in a YAML, TOML, shell, or `.caratrc` file passes the content gate and reaches the backup ref before the security review reads the diff. In those files an unquoted value is a literal, while in code it is a name (`token = next_token`), so the rule must hold for configuration files only. It is outside the roadmap of `docs/architecture.md` section 12: it is a merge-gate rules fix (T1 pipeline defect, security), delivered first and alone in Sprint 16.

## What Changes

- `tools/rules.sh` adds `CONFIG_PATH_RE`, the configuration-file paths (a file whose name ends in `caratrc`, and `.yml`, `.yaml`, `.toml`, `.sh`, `.bash` files), and `BARE_ASSIGN_RE`, a name ending in password, passwd, secret, token, or api_key assigned with `=`, `:`, or `=>` an unquoted literal of eight characters or more starting with a letter or digit and ending at a space or the line's end, with no quote, dollar sign, backquote, or parenthesis in it; or, for the `.caratrc` form `scope.name value`, a whole line whose dotted name ends in one of those words followed by such a value.
- `tools/scan_text.sh` exports `CONFIG_PATH_RE`, keeps the text of configuration-file rows in a fifth work file, and greps `BARE_ASSIGN_RE` without case over it beside the other secret patterns, so a hit is reported by label as `secret: [not shown]`.
- `tools/tools_test.sh` cases: the scanner refuses an unquoted assignment in a YAML, TOML, shell, and `.caratrc` file and a `.caratrc` setting, read from a diff and from a file; it passes `token = next_token` and an unquoted password name in a `.rb` file and a variable, a command substitution, or a call in a configuration file; the content gate refuses an unquoted assignment in a `.caratrc` file and passes `token = next_token` in a `.rb` file.
- The header comment of the secrets in `tools/rules.sh` and the `tools/rules.sh` and `tools/scan_text.sh` lines of `docs/codebase-map.md` name the new rule.

Out of scope: `TOKEN_RE` gains no shape, since every platform the project uses already has one (GitHub tokens of each prefix, npm, and the `sk-` keys); no other gate rule changes; `tools/scan_text.sh` changes only for the configuration-row check; `ASSIGN_RE` is not widened, since it applies to code too.

Assumptions:

- The four file kinds are recognized by path: `.yml`/`.yaml`, `.toml`, `.sh`/`.bash`, and a name ending in `caratrc` (`.caratrc`, `config/default.caratrc`, a user's `caratrc`). A row named by `--where` (a commit message, the pull request body) or read from standard input is not a configuration file.
- A placeholder such as `TOKEN=VALUE...` in a shell comment is refused too; a secret in a comment is still a secret, and such a line is rare.

## Capabilities

### New Capabilities

None: the change is delivery tooling and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `tools/rules.sh`, `tools/scan_text.sh`, `tools/tools_test.sh`, `docs/codebase-map.md`.
- CLAUDE.md: unchanged, its Hard rules name secrets without their patterns, and no command or process changes.
- README.md: unchanged, it names no secret pattern.
- docs/architecture.md: unchanged, section 10 names no secret pattern.
- docs/codebase-map.md: changed, the `tools/rules.sh` and `tools/scan_text.sh` lines name the rule; no file is added, moved, or removed.
