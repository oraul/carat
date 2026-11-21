# Backlog: tools/rules.sh

## RISKY_CONFIG omits command-bearing keys

- Where: `tools/rules.sh:51` and its copy in the guard. Periodic security Low (4) at d0d783c.
- Why it matters: `submodule.NAME.update`, `submodule.recurse`, `pager.CMD`, and `trailer.TOKEN.cmd` or `command` can run a command and pass the check.
- Fix outline: add submodule, pager, and trailer key patterns to both copies, with a `tools/tools_test.sh` case per key. Queue item `guard-lows`.
- Also: tools/tools_test.sh
- Category: security
- Added: 2026-11-11

## Tooling headers and double negatives found at 8b9bf6a

- Where: `tools/rules.sh:1` header omits RECORDS_RE; `tools/ci_scope.sh:45` and the groom dispatch in `tools/run_state.sh:1691` write `! cmd || return`. Sprint-2 review and sweep.
- Why it matters: the header no longer names what three scripts source it for, and the double negatives read backwards.
- Fix outline: name RECORDS_RE in the header and write both as plain `if` tests.
- Also: tools/ci_scope.sh, tools/run_state.sh
- Category: pipeline
- Added: 2026-11-14

### rules.sh documentation() comment disagrees with TOOLS_RE on .claude/commands

- Location: tools/rules.sh:70 against :86 (sprint-8 review, quality); queued in `ci-scope-quoting`.
- Why: the comment says it is true only for paths no case reads, yet it is true for .claude/commands/*, which tools-test reads; only the separate TOOLS_RE check keeps tools-test running.
- Fix: return 1 for .claude/commands/* too, or say tools-test is decided by TOOLS_RE alone.
- Category: pipeline
- Added: 2026-11-16

### A docs/architecture.md-only change skips the tests that read it

- Location: tools/rules.sh:73, test/lint.rb:772 and :1285 (sprint-8 sweep, quality, correctness); queued in `ci-scope-quoting`.
- Why: documentation() counts docs/architecture.md as documentation, but lint compares its section 6 port table with the ports, so such a change skips the test stage in CI and the checker and can merge a table the next code change fails on.
- Fix: return 1 for docs/architecture.md beside docs/actions.md, with a tools-test expect case.
- Also: test/lint.rb, docs/architecture.md, docs/actions.md
- Category: pipeline
- Added: 2026-11-16

### rules.sh documentation comment misstates tools-test scope

- Location: tools/rules.sh:62, tools/ci_scope.sh:9 (sweep, quality).
- Why: documentation() is said to be read by no tool case, yet TOOLS_RE (:88) scopes tools-test on CLAUDE.md and .claude/commands.
- Fix outline: say no test or build reads them, tools-test scoped by TOOLS_RE.
- Also: tools/ci_scope.sh, CLAUDE.md
- Category: pipeline
- Added: 2026-11-17

### The configuration-file pattern of the secret check leaves out common formats
- Location: tools/rules.sh:37 (CONFIG_PATH_RE)
- Why: security Low (confidence 4): .json, .ini, .conf, .cfg, .properties, and .env.* variants are not matched, so an unquoted credential such as password=hunter2hunter2 committed in one of them passes the content gate and the pull request scan.
- Fix: add those extensions and a (^|/)\.env(\.[^/]*)?$ form to CONFIG_PATH_RE, each with a refusing expect case in tools/tools_test.sh.
- Also: tools/tools_test.sh
- Category: security
- Added: 2026-11-18

### The bare assignment pattern refuses a shell test comparison
- Location: tools/rules.sh:38 (BARE_ASSIGN_RE, separator form)
- Why: correctness: the optional quote lets the closing quote of an expansion stand before =, so [ "$token" = expected_value ] in a shell file is refused, a false positive the design's risks do not name.
- Fix: require the name not to follow a dollar sign or brace, for example (^|[^$A-Za-z0-9_{])[A-Za-z0-9_-]* before the secret word, with a pass case in tools/tools_test.sh.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-18

### tools/rules.sh:68: the documentation() comment says no tool case reads a (sprint-22 sweep quality)

- Location: `tools/rules.sh:68`
- Why: the documentation() comment says no tool case reads a .claude/ file but the agents, workflows, and settings.json, while TOOLS_RE (line 97) and tools_test.sh read .claude/commands/ and CLAUDE.md; the separate tools output keeps CI right, so only the comment drifts
- Fix: say documentation() decides the compile and test stages and TOOLS_RE the tools stage
- Also: CLAUDE.md
- Category: pipeline
- Added: 2026-11-20
