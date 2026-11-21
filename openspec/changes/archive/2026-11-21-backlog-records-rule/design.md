# Design

## Context

`RECORDS_RE` (`tools/rules.sh`) is an extended regular expression without anchors, read as `^(RECORDS_RE)` by `settled_at` in `tools/gates.sh`, by `TEST_ONLY` and `outside_records` in `tools/run_state.sh`, and by `documentation()` in `tools/rules.sh`. Its backlog alternative is `docs/(backlog|queue-feature|queue-backlog|goals)\.md$`.

## Decisions

- Add the alternative `docs/backlog/.+\.md$` after the existing `docs/(...)\.md$` group, in the style of `docs/findings/[a-z0-9-]+\.md$`. `.+` rather than a character class, because the backlog files are named after a repository path (`docs/backlog/carat/adapters/tab_bar.rb.md`), with slashes, dots, and underscores. The `$` anchor keeps `x.txt` out; the slash keeps `docs/backlogs.md` out.
- Keep `docs/backlog\.md$`: `backlog-per-file` removes the file and that alternative once the move lands.
- Tests: a `records_case WANT PATH` helper sources `tools/rules.sh` and matches the path as the readers do; behavior cases extend the existing fixtures of the security gate (`settled_at`), the check's carry (`TEST_ONLY`), `settled` (`outside_records`), and `ci_scope` (`documentation`).
- No delta specs: `skip_specs: true`, archived with `--skip-specs`.

## Risks

A file under `docs/backlog/` ending in `.md` is now settled across by the gates; any such file is a record by the backlog layout, and none is read by a test, build, or tool case.
