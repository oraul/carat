# Backlog: tools/new.sh

## Nothing compiles the generators' output on every check

- Where: `tools/new.sh` and its tests in `tools/tools_test.sh`, which check the files each generator writes and the lines it inserts, not that they compile.
- Why it matters: a convention that changes (a base class's constructor, an anchor's neighbor, a lint rule) could leave a generator writing code that no longer compiles or lints, and nothing would say so until an author ran it. The `authoring-kit` change compiled, linted, and tested the output of all five generators by hand in a scratch worktree (59 tests, `spinel-doctor` clean).
- Fix outline: a `make generators-check` target that runs every generator in a temporary worktree, then `make gen-config`, `make lint`, `make test-build`, and `make test-run` there, run by the checker when `tools/new.sh`, `carat.rb`, `EditorAssembly`, the handler bases, or `test/lint.rb` change rather than on every check, since it costs a full analysis of the library. The same holds for `tools/spinel/gen_respond_to_tables.rb`, the Ruby 4 port of Spinel's header generator (quality advisory at spinel-bump): no check compiles it, so a later pin that breaks it is found only at the next bump; compile it in `make tools-test` or in the same target.
- Also: tools/tools_test.sh, carat.rb, test/lint.rb, tools/spinel/gen_respond_to_tables.rb
- Category: pipeline
- Added: 2026-11-03

## The generated action description passes the length check

- Where: `tools/new.sh` (line 221 at `leader-layout`) writes the placeholder description `TODO: short description`, 23 characters, which the 1-to-32-character check of `test/use_cases_actions.rb` accepts. Quality advisory of `leader-layout`.
- Why it matters: a forgotten description passes every check and ships to the key hints.
- Fix outline: have the test reject a description starting with `TODO`, or generate an empty one so the check fails until it is written.
- Also: test/use_cases_actions.rb
- Category: pipeline
- Added: 2026-11-05

### tools/new.sh:280 generated TODO description placeholder passes the description check (quality)

- Where: tools/new.sh:280 for an ex command, tools/new.sh:221 for an action, and the check at test/use_cases_actions.rb:190.
- Why: the generated placeholder TODO: short description is 23 characters, so the 1-to-32 length check passes an ex command or action that still ships the placeholder in the palette, weakening the rule that the test fails on an ex command without a description.
- Fix: make both description checks also reject text starting with TODO.
- Also: test/use_cases_actions.rb
- Category: pipeline
- Added: 2026-11-15

### tools/new.sh:275 hand-reflowed template comment (quality, style)

- Where: tools/new.sh:275.
- Why: the template comment was reflowed by hand, leaving the short line a handler that runs a use case takes it as a before a wrapped remainder.
- Fix: rewrap the three lines to the file's width.
- Category: pipeline
- Added: 2026-11-15

### A placeholder comment in the generator now matches the bare assignment pattern
- Location: tools/new.sh:133
- Why: correctness: the existing comment '# fill TOKEN=VALUE...:' matches BARE_ASSIGN_RE, so the next change that edits that line fails the content gate on a placeholder; this change edits only the gate rules, so the line was left as is.
- Fix: reword it to 'fill NAME=VALUE...', or skip shell comment lines in the configuration check.
- Category: pipeline
- Added: 2026-11-18

### Generator TODO placeholders can reach a merge (sprint-24 sweep quality)

- Location: `tools/new.sh:176`, `:231`
- Why: the generators write TODO placeholders into `docs/actions.md`, `docs/codebase-map.md`, and Ruby, and no check refuses one.
- Fix: a docs-lint or lint check failing on a left placeholder.
- Also: docs/actions.md, docs/codebase-map.md
- Category: pipeline
- Added: 2026-11-21
