# Backlog: tools/ci_scope.sh

## The CI scope script word-splits the changed paths

- Where: `tools/ci_scope.sh` (line 66, the unquoted `for path in $changed`, over `git diff --name-only`). Low (3) finding of the periodic security review at 6ea61b1, and Low (5) finding of the security review of `untrusted-config-limits`; queued in `pipeline-hardening`.
- Why it matters: the loop splits names on spaces and expands glob characters, so a pull request whose changed paths contain them, such as `a.md .claude/x`, can make a change to code read as documentation only and CI skips `spin check`.
- Fix outline: read `git diff --name-only -z` into a `while read` loop with `IFS` unset and `set -f`, quote `"$path"`, and add a `tools/tools_test.sh` case with a spaced path and one with a glob character.
- Also: tools/tools_test.sh
- Category: security
- Added: 2026-11-03

## The CI scope reads a moved code file by its new path

- Where: the documentation-only test of `tools/ci_scope.sh` (line 62), which uses `git diff --name-only` with rename detection on. Periodic security Low (5) at 8c340cd.
- Why it matters: a pull request that only moves code files to a Markdown or `openspec/` path is listed by the new paths, so CI skips `spin check`, and the push to `main` then skips it as a passed head.
- Fix outline: list the paths without rename detection, together with the fix of the entry "The CI scope script word-splits the changed paths", and add a `tools/tools_test.sh` case. Queued in `ci-hardening`.
- Also: tools/tools_test.sh
- Category: security
- Added: 2026-11-04

## The CI scope asks the same API twice

- Where: the push branch of `tools/ci_scope.sh` lines 47 and 48 at b0dd342. Periodic quality. Queued in `ci-hardening`. At 38628bb the header also omits `docs/metrics.tsv` (`tools/ci_scope.sh` lines 8 and 95, periodic quality), still at 7711421 (header lines 8 to 12, note 47).
- Why it matters: two calls for one commit's head and number double the rate-limited requests and can disagree.
- Fix outline: one call printing both fields, read once.
- Raised again as "ci_scope asks for the same pull request twice": Where: `tools/ci_scope.sh:50` and `:51`. Periodic quality. Raised again at be4b63a (owner `check-skip`). Why it matters: two calls for the head and the number can disagree. Fix outline: one call printing both fields. Queue item `ci-hardening`.
- Raised again as "The CI scope fetches one answer twice": Where: `tools/ci_scope.sh:50-51` (two calls fetch the same commit's pull request). Periodic quality at bd86828. Why it matters: CI time and API calls. Fix outline: one call read into both values. Queue item `ci-time`.
- Category: pipeline
- Added: 2026-11-07

### ci_scope.sh lost its executable bit (`ci-time` quality advisory)

- Location: `tools/ci_scope.sh:1`.
- Why it matters: the file mode goes from 100755 to 100644, which the change does not mention.
- Fix outline: restore the executable bit, or name the change in a proposal.
- Category: pipeline
- Added: 2026-11-11

### Redundant parameter defaults in ci_scope.sh (`ci-time` quality advisory)

- Location: `tools/ci_scope.sh:85` and `tools/ci_scope.sh:92`.
- Why it matters: the `${PR:-}` and `${HEAD_SHA:-}` defaults are redundant after the guard at line 82.
- Fix outline: use `$PR` and `$HEAD_SHA`.
- Category: pipeline
- Added: 2026-11-11

## records-once quality advisory at tools/ci_scope.sh:8

- Location: tools/ci_scope.sh:8 and line 46.
- Why: the header still describes skippable documentation as Markdown and openspec/.claude files, not the shared RECORDS_RE list (docs/metrics.tsv, docs/sprints.tsv), and line 46 writes the records test as a double negation (! grep || return 0).
- Fix outline: name RECORDS_RE in the header and write printf | grep -q -E ... && return 0.
- Also: docs/sprints.tsv
- Category: pipeline
- Added: 2026-11-12

### Stop glob expansion of changed paths in tools/ci_scope.sh:95

- Location: tools/ci_scope.sh:95 and tools/ci_scope.sh:119, the loops over `$changed` and `$since` (security Low, confidence 4, existing code).
- Why: the unquoted path lists get word splitting and wildcard expansion, so a fork pull request can add a code file named like a wildcard (for example `docs/[a-z]*`) that expands to existing documentation; the scope step then answers run=false and the required spin check passes without running the tests.
- Fix: run `set -f` before the loops (or read `git diff --name-only -z` and handle each NUL-separated path), and add a tools-test case with a wildcard path asserting run=true.
- Category: security
- Added: 2026-11-14

### Read changed paths without splitting in tools/ci_scope.sh:96

- Location: tools/ci_scope.sh:96, `for path in $changed` (quality advisory, pre-existing in the touched script).
- Why: a path with glob characters (`notes[.]md` beside `notes.md`) expands against the checkout and a path with spaces splits, which can count a code file as documentation and skip the tests.
- Fix: `set -f` before the loops, or read the paths with `while IFS= read -r path`.
- Category: pipeline
- Added: 2026-11-14

### Query the commit's pull request once in tools/ci_scope.sh:76

- Location: tools/ci_scope.sh:76 (quality advisory, duplication).
- Why: the same endpoint `repos/$REPO/commits/$SHA/pulls` is called twice for head.sha and number, doubling the request and letting the two answers disagree.
- Fix: one call with `--jq '.[0] | "\(.head.sha) \(.number)"'`, split and validated once.
- Category: pipeline
- Added: 2026-11-14

### Keep the case pattern for the sha test in tools/ci_scope.sh:107

- Location: tools/ci_scope.sh:107 (quality advisory, simplicity).
- Why: `[ -n "$(hex "$sha")" ]` replaces an in-process case test with a command substitution per listed sha only to test a pattern.
- Fix: keep the case pattern there, or give the filters a predicate form for checks that need no value.
- Category: pipeline
- Added: 2026-11-14

### ci_scope asks the same pull request query twice

- Location: tools/ci_scope.sh:78. Sprint-6 sweep, quality advisory. Queue item `ci-scope-quoting`.
- Why: two identical gh api calls read the head sha and the number.
- Fix outline: one call printing both, split with read.
- Category: pipeline
- Added: 2026-11-15

### ci_scope.sh answer comment overruns its wrap and omits the tools line

- Location: tools/ci_scope.sh:31
- Why: the answer comment line runs far past the file's 72-column wrap and the next line still says GITHUB_OUTPUT keeps one run= and one reason= line, not the new tools= line.
- Fix: rewrap it and name the three lines.
- Category: pipeline
- Added: 2026-11-16

### An orphan line in the ci_scope.sh Environment comment

- Location: tools/ci_scope.sh:31
- Why: the Environment comment leaves an orphan line '# a pull request' after the CACHED insertion (quality advisory, ci-time-tidy-b).
- Fix: reflow the paragraph.
- Category: pipeline
- Added: 2026-11-16

### ci_scope.sh splits path lists on blanks

- Location: tools/ci_scope.sh:99 and :123 (sprint-8 sweep, quality); queued in `ci-scope-quoting`.
- Why: `for path in $changed` splits and globs, so a path with a space is judged piece by piece and can skip the checks.
- Fix: read the lists line by line with `while IFS= read -r path`, or set -f and a newline IFS around the loops.
- Category: pipeline
- Added: 2026-11-16

### ci_scope.sh fetches one pull request twice

- Location: tools/ci_scope.sh:80 (sprint-8 sweep, quality); queued in `ci-scope-quoting`.
- Why: two identical gh api calls on the commit's pulls fetch the head sha and the number separately.
- Fix: one call whose jq prints both fields, split with read.
- Category: pipeline
- Added: 2026-11-16

### ci_scope.sh answer comment overruns its wrap

- Location: tools/ci_scope.sh:42 and :30 (sprint-8 review, quality); queued in `ci-scope-quoting`.
- Why: the answer line runs to 110 columns and the Environment comment breaks mid-sentence.
- Fix: rewrap both comment blocks.
- Category: pipeline
- Added: 2026-11-16

### ci_scope.sh splits changed paths at whitespace

- Location: tools/ci_scope.sh:98, :118 (sweep, quality).
- Why: for path in $changed and $since are unquoted, so a path is split and its globs expanded; a path whose pieces each look like documentation skips the CI checks (fails open).
- Fix outline: set -f and a newline IFS around both loops, or while IFS= read -r path.
- Category: pipeline
- Added: 2026-11-17

### ci_scope.sh repeats its API calls

- Location: tools/ci_scope.sh:80, :81, :84, :117 (sweep, quality).
- Why: the commits pulls call runs twice and the spin check-runs query twice.
- Fix outline: one call printing both fields and a spin_passed helper.
- Category: pipeline
- Added: 2026-11-17

### ci_scope.sh loops over unquoted paths and asks gh twice (sprint-16 sweep quality)

- Location: tools/ci_scope.sh:99 and :123 (for path in $changed, $since), :80 (two gh calls for repos/REPO/commits/SHA/pulls).
- Why: the unquoted loop splits on spaces and expands globs in changed paths, failing safe but in the shape the tools avoid; the push path pays two API calls for one answer.
- Fix outline: read the lines with while IFS= read -r, or set -f with a newline IFS as moved_change does; one gh call printing both fields. Pool item `ci-trust-gaps-b`.
- Category: pipeline
- Added: 2026-11-18

### tools/ci_scope.sh:80: duplication: two gh api calls to the same commits/SHA/pulls (sprint-22 sweep quality)

- Location: `tools/ci_scope.sh:80`
- Why: duplication: two gh api calls to the same commits/SHA/pulls endpoint for the head sha and the number
- Fix: one call whose jq prints both, split with read
- Category: pipeline
- Added: 2026-11-20

### ci_scope splits changed paths on whitespace and globs (sprint-24 sweep quality)

- Location: `tools/ci_scope.sh:99`, `:123`
- Why: `for path in $changed` splits on whitespace and expands globs without `set -f`, so a path is judged by its fragments.
- Fix: read the names line by line with `while IFS= read -r path`.
- Category: pipeline
- Added: 2026-11-21

### ci_scope calls the same pulls endpoint twice (sprint-24 sweep quality)

- Location: `tools/ci_scope.sh:80`
- Why: one call for the head sha and one for the number.
- Fix: one call whose jq prints both.
- Category: pipeline
- Added: 2026-11-21

### PR-controlled file names are word-split and glob-expanded in for at tools/ci_scope.sh:99 (sprint-26 sweep security Low (4), note 17)

- Location: tools/ci_scope.sh:99
- Why: PR-controlled file names are word-split and glob-expanded in for path in $changed (and $since at 123), so a path with spaces or glob characters is classified by fragments or by other files' names when deciding to skip the checks
- Fix: set -f and read the names line by line (while IFS= read -r path), or use git diff -z
- Category: security
- Added: 2026-11-22

### duplication: the push path calls gh api repos/REPO/commits/SHA/pulls twice at tools/ci_scope.sh:80 (sprint-26 sweep quality, note 46)

- Location: tools/ci_scope.sh:80
- Why: duplication: the push path calls gh api repos/REPO/commits/SHA/pulls twice, once for the head sha and once for the number
- Fix: one call with --jq on .[0] printing both values, split into head and number
- Category: pipeline
- Added: 2026-11-22
