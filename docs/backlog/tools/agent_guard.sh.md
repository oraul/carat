# Backlog: tools/agent_guard.sh

## The guard does not judge input redirections

- Where: `redirect` in `tools/agent_guard.sh` (line 752), which checks only write targets. Security Low (5) of `guard-allowlist` at 31a93d257317.
- Why it matters: `< /dev/tcp/HOST/PORT` opens an outbound connection from any profile, a path for exfiltration through the hostname or DNS by an agent that text in the tree leads astray.
- Fix outline: refuse a read target under `/dev/tcp/` or `/dev/udp/` (or allow only targets in the project and `/dev/null`), with a `tools/tools_test.sh` case. Queued in `guard-lows`.
- Also: tools/tools_test.sh
- Category: security
- Added: 2026-11-04

## The guard judges relative words after a cd against the project

- Where: the `cd` form in `judge`, `tools/agent_guard.sh` (line 724). Quality advisory of `guard-allowlist` at a979633e8a4d and again at 31a93d257317.
- Why it matters: `cd tmp/.base && mkdir -p tmp/scout/x` passes with DIR `tmp/scout` and writes `tmp/.base/tmp/scout/x`; benign today, since only DIR- or `build/stages`-prefixed paths inside the worktree are reachable, but the guard no longer reads the command as the shell runs it.
- Fix outline: refuse a relative write target after a `cd` other than to the project, or resolve it against the `cd` target, with a `tools/tools_test.sh` case. Queued in `guard-lows`.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-04

## The guard admits date with any argument

- Where: the shared plain tools in `judge`, `tools/agent_guard.sh` (line 710). Quality advisory of `guard-allowlist` at 31a93d257317.
- Why it matters: `date -s 2001-01-01` passes every profile and, run as root, sets the system clock that git and the run state's timestamps read, against an allowlist of what each agent needs (the scout runs only `date -u +FORMAT`).
- Fix outline: admit `date` only with `-u` and a `+FORMAT` word, with a refusal case in `tools/tools_test.sh`. Queued in `guard-lows`.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-04

## The guard decodes the JSON escapes \b and \f to letters

- Where: `field` in `tools/agent_guard.sh` (line 114), whose else branch keeps the escaped character. Quality advisory of `guard-allowlist` at 5af7fd9d9784, 14b18734b96e, and 31a93d257317.
- Why it matters: the guard judges the word `lsb` where bash runs `ls` and a backspace, against the header's "any other one ?"; no blank or operator diverges, since bash reads backspace and form feed as word characters, but the guard should read the command as the shell does.
- Fix outline: decode `\b` and `\f` to `?` like `\u0008` and `\u000c`, with a `tools/tools_test.sh` case for `ls\b#; git push origin x`. Queued in `guard-lows`.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-04

## uniq -f 1 FILE is refused

- Where: `uniq_form` in `tools/agent_guard.sh` (line 668). Quality advisory of `guard-allowlist` at 3efc71ba34f8 and again at 31a93d257317.
- Why it matters: the value of `-f`, `-s`, or `-w` given as a separate word counts as an operand, so a normal read-only form is refused (it fails closed).
- Fix outline: skip the word after `-f`, `-s`, and `-w`, with a `tools/tools_test.sh` case. Queued in `guard-lows`.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-04

## The guard header lists printf without its restriction

- Where: the shared forms of the header of `tools/agent_guard.sh` (line 25). Quality advisory of `guard-allowlist` at 3efc71ba34f8 and again at 31a93d257317.
- Why it matters: `judge` refuses `printf` with a leading option, so the header no longer says what the code allows.
- Fix outline: write `printf (no leading option)` in the header's shared forms. Queued in `guard-lows`.
- Category: pipeline
- Added: 2026-11-04

## The guard skips a short cluster that names cp's target directory

- Where: `files_form` in `tools/agent_guard.sh` (line 625), which skips any letters-only short cluster. Periodic security Low (7) at 598cf1b.
- Why it matters: `cp -r -tbuild pipeline` passes the contributor profile and copies a project-root `pipeline` directory into `build/pipeline`, overwriting run state records (`stage.*`, `phase.check`, `pushed`) the guard refuses to write directly.
- Fix outline: refuse a cluster holding `t`, `T`, or `S` for `cp` and `mv`, or judge the attached value and every operand placed under it as a write target, with a `tools/tools_test.sh` case. Queued in `guard-lows`.
- Also: tools/tools_test.sh
- Category: security
- Added: 2026-11-04

## The guard does not read a tilde after = or : as bash expands it

- Where: the lexer of `tools/agent_guard.sh` (line 173), which refuses only a leading `~`. Periodic quality advisory at 598cf1b.
- Why it matters: `cat a=~/x` and `BASE=~ sh tools/gates.sh trailer` pass while bash runs them with the home directory expanded, against the header's claim that a command is read as the shell reads it; harmless today, since no form takes a path value with a tilde.
- Fix outline: refuse an unquoted `~` right after `=` or `:` in a word that starts with an identifier and `=`, with a `tools/tools_test.sh` case. Queued in `guard-lows`.
- Also: tools/gates.sh, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-04

## The guard reads the shown profile name from the environment

- Where: `refuse` and the profile `case` in `tools/agent_guard.sh` (line 101 in the reviewed commit), which set `shown` only for the `close` profile and print `${shown:-$profile}`. Quality advisory at e8c5b43 in `pipeline-speed-c`.
- Why it matters: an inherited `shown` variable misnames the profile in every refusal, so a refused agent is told the wrong profile's rules.
- Fix outline: initialize `shown=$profile` beside `closing=0` and print `$shown` in `refuse`. Queued in `guard-lows`.
- Category: pipeline
- Added: 2026-11-04

## The close profile records a phase for any change and commit

- Where: the `close` profile of `tools/agent_guard.sh` (line 538 at f31f4e8) and `phase` in `tools/run_state.sh`. Periodic security Low (3) at f31f4e8.
- Why it matters: the profile records phase plan, implement, package, ci, merge, retro, or report for any change name and commit, so a retrospective steered by text it reads could write `phase.implement` for another queued change and make that change's resumed run skip planning and implementation; no merge gate reads these phases.
- Fix outline: limit the closing records to the run's own change and merged commit, or refuse a plan or implement phase from the close path, with a `tools/tools_test.sh` case. Queued in `guard-lows`.
- Also: tools/run_state.sh, tools/tools_test.sh
- Category: security
- Added: 2026-11-04

## The pinned fetch is matched on the joined arguments

- Where: the `fetch` case of `tools/agent_guard.sh` line 456 at the `pinned-main` change; security Low (5) and a quality advisory of `pinned-main`.
- Why it matters: the rule compares the joined `$*`, so a quoted word can regroup the arguments: `git fetch -q --refmap= 'origin +refs/heads/main:refs/remotes/origin/main'` passes, and git reads the quoted word as a local-path repository and fetches from it, which `local_origin` misses since it checks only origin's URL. The impact is limited (only `FETCH_HEAD` is written, `origin/main` is not updated, and the planted directory must exist first). The rule also admits the fetch without `-q`, a second form the header at line 37 does not name.
- Fix outline: compare by count and position, admitting only the green line's four words: `[ $# -eq 4 ] && [ "$1" = -q ] && [ "$2" = --refmap= ] && [ "$3" = origin ] && [ "$4" = "$MAIN_REFSPEC" ]`, and add `tools/tools_test.sh` cases refusing the quoted regroupings and the form without `-q`.
- Also: tools/tools_test.sh
- Category: security
- Added: 2026-11-09

## The guard's worktree check resolves the common directory on every call

- Where: `worktree` in `tools/agent_guard.sh` line 381 at the `pinned-main` change, called once per `tmp` entry in `metrics_out`'s loop (line 633); quality advisory of `pinned-main`.
- Why it matters: each call spawns `git rev-parse` and a `cd`, so a guard run over many entries repeats the same lookup.
- Fix outline: resolve the common directory once beside `project_real` and reuse it in `worktree`.
- Category: pipeline
- Added: 2026-11-09

## The merger profile may set BASE before the merge gates

- Where: `tools/agent_guard.sh` line 610, at df4654c. Periodic security Low (6). Queue item `guard-lows`.
- Why it matters: `BASE=HEAD` skips the origin ref check and empties the trailer and content scans while the gate still records gated.
- Fix outline: admit `BASE` only for the read profile and have the merge group refuse a base other than `origin/main`, with a `tools/tools_test.sh` case.
- Also: tools/tools_test.sh
- Category: security
- Added: 2026-11-09

## The merge hook leaves the squash title and message unchecked

- Where: `merge_tool` in `tools/agent_guard.sh` line 875 at 3895e21. Periodic security Low (6). Queue item `merge-gate-tidy`.
- Why it matters: the hook checks the method and the expected head only, so a merger steered by branch-controlled CI log text can squash onto main a message holding a URL, a secret, or another trailer the body gate refused.
- Fix outline: refuse a merge whose message differs from the run's body file plus the trailer or whose title is not the pull request title with its number, with a `tools/tools_test.sh` case.
- Also: tools/tools_test.sh
- Category: security
- Added: 2026-11-09

## The contributor may rewrite the agent files later starts load

- Where: `tools/agent_guard.sh` line 330 at 2f54bb5: the contributor's guard allows writes under `.claude/agents`, `.claude/workflows`, and `.claude/settings.json`, which later starts load from the branch's working tree. Periodic security at 2f54bb5, Medium (4). Queued in `guard-lows`.
- Why it matters: a misled contributor could drop a later agent's guard hook for the rest of the run.
- Fix outline: refuse contributor writes there unless the plan names the file, or load agent hooks from main, with a refusal case in `tools/tools_test.sh`.
- Also: .claude/settings.json, tools/tools_test.sh
- Category: security
- Added: 2026-11-10

## A submodule's own git config runs a command past the guard

- Where: `tools/agent_guard.sh:854` and the origin gate `tools/gates.sh:136` read only the superproject's `.git/config` and hooks. Periodic security Medium (6) at d0d783c.
- Why it matters: a populated submodule's configuration under the common git directory's `modules` folder runs a command on `git status` (`core.fsmonitor`, verified with git 2.43).
- Fix outline: refuse while the `modules` folder holds anything, or scan every `modules/*/config` with `RISKY_CONFIG` and every `modules/*/hooks`, in both scripts, with `tools/tools_test.sh` cases. Queue item `guard-lows`.
- Also: tools/gates.sh, tools/tools_test.sh
- Category: security
- Added: 2026-11-11

## pr-by-tag quality advisory at tools/agent_guard.sh:588

- Where: `tools/agent_guard.sh:588`. Delivery review of `pr-by-tag` (quality advisory) at 742ba5f.
- Why it matters: the contributor keeps the permission tools/run_state.sh set CHANGE pr N (header line 66, test 'contributor pushes and opens the pull request'), though pr_tag.sh wait now records the number and the agent must never record a pull request another way.
- Fix outline: drop contributor:pr and the header's set CHANGE pr N, and the set from that guard test.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-11

### Contributor keeps a pull request number permission (late `pr-by-tag` quality advisory)

- Location: `tools/agent_guard.sh` contributor rule allowing `tools/run_state.sh set CHANGE pr N`, the `tools/run_state.sh` header line naming it, and the guard test "contributor pushes and opens the pull request".
- Why it matters: once the delivery records the number of the pull request GitHub Actions opened, a contributor that may still write `pr` can record a number of a pull request it did not open, and the merger would act on it.
- Fix outline: drop the contributor's `pr` permission and the header line once the wait step records the number, and turn the guard test into a refusal case; keep any bootstrap path the workflow itself needs.
- Also: tools/run_state.sh
- Category: pipeline
- Added: 2026-11-11

### RISKY_CONFIG omits pager keys (sprint-14 sweep security Low (3))

- Location: tools/agent_guard.sh:884.
- Why: a pager.CMD key runs a shell command whenever a git verb pages, and the guard does not refuse it.
- Fix outline: add pager keys to RISKY_CONFIG and its copy, with a tools-test case. Queued in `lane-guards`.
- Category: security
- Added: 2026-11-17

### moved writes the run state yet stays a read-profile verb for agents
- Location: tools/agent_guard.sh:612
- Why: security: moved now writes the run state (drop_key, write_key) and its record gates the review record the merge gate reads, yet the checker and reviewers may run it with any commit.
- Fix: in a follow-up (the guard runs from main), restrict moved's COMMIT for agents or move the record's write out of the agent-run command, and say in the guard header that moved writes.
- Category: pipeline
- Added: 2026-11-18

### The squash trailer repeats the gates' trailer
- Location: tools/agent_guard.sh:964 (SQUASH_TRAILER), tools/gates.sh:78 (TRAILER)
- Why: quality advisory, duplication: two copies of the trailer line that must stay equal, or the merge hook and the gates disagree on the squash message.
- Fix: a tools_test.sh case comparing the two lines, as "the guard's risky keys are the gates'" does for RISKY_CONFIG; this change's head already carries it as "guard: the squash trailer is the gates' trailer", so the grooming may close this entry once it confirms the case on main.
- Also: tools/gates.sh
- Category: pipeline
- Added: 2026-11-18

### Two JSON string decoders in the guard
- Location: tools/agent_guard.sh:970 (json_text), tools/agent_guard.sh:153 (field)
- Why: quality advisory, duplication: json_text repeats field's key match, escape loop, and hex decoding, two JSON string decoders to keep in step.
- Fix: have field decode through json_text and apply its folding of newlines and non-ASCII after.
- Category: pipeline
- Added: 2026-11-18

### Two lookups of the archived pr.md
- Location: tools/agent_guard.sh:1027 (merge hook lookup), tools/open_pr.sh:167
- Why: quality advisory, one clear way: the hook finds the archived pr.md by a non-recursive listing and a cat-file check while open_pr.sh still lists the whole archive with ls-tree -r, two lookups of the same file that grow apart.
- Fix: give open_pr.sh the same non-recursive listing of the archive's entries, or share one lookup.
- Also: tools/open_pr.sh
- Category: pipeline
- Added: 2026-11-18

### The squash-merge hook leaves the commit title unchecked (sprint-17 review security Low (4))

- Where: `squash_message` in `tools/agent_guard.sh` (line 950 at 522a0e1).
- Why it matters: the hook compares `commit_message` with the archived pr.md but never `commit_title`, so a misled merger start could squash with a subject carrying a URL or a model name, and the subject of the commit on main is never compared.
- Fix outline: read `commit_title` as `commit_message` is read and require line 1 of the archived pr.md followed by ` (#N)`, N the run state's pull request; a tools-test case for a changed title. Queued in `ci-trust-gaps-c`.
- Category: security
- Added: 2026-11-18

### The planner's guard refuses backlog-pick, which its sprint mode runs

- Location: tools/agent_guard.sh:613 (run_state_form, the read profile)
- Why: the planner's sprint mode (.claude/agents/planner.md step 2, sprint-planning.js line 222) runs `sh tools/run_state.sh backlog-pick docs/backlog.md docs/findings/*.md`, but the read profile lists only backlog-dups among the backlog commands, so the guard refuses it ("refused for the read profile: tools/run_state.sh backlog-pick") and the planner must pick the batches by hand; backlog-throughput added backlog-oldest to the profile but left backlog-pick out of scope.
- Fix: add `read:backlog-pick` to the read profile and its header comment, with a guard case beside "guard: the read profile lists backlog duplicates" in tools/tools_test.sh.
- Also: .claude/agents/planner.md, tools/run_state.sh, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-18

### The contributor guard still admits the bare openspec command outside the pin (`pr-trust-lows` security Low (3), two passes)
- Location: tools/agent_guard.sh:896 and :902, `judge`, the contributor's OpenSpec cases.
- Why: the bare `openspec` command resolves through PATH to whatever installation exists, so the version pin does not cover that path; it predates the change, and the design keeps it on purpose as an installation the user made.
- Fix: either check in the guard, or in a wrapper, that the PATH `openspec` reports the pinned version, or limit the contributor to the pinned npx (or vendored binary) form, with a tools-test case for the refusal.
- Category: security
- Added: 2026-11-20

### An agent's git fetch in the shared toolchain clone voids a lane's check
- Location: tools/agent_guard.sh (the hook's working directory is never read), and the agents' starting directory, the main checkout's tmp/.spinel, which every lane links as its tmp/.spinel.
- Why: the check of contributor-harness at 142649463415 passed every stage and was voided by writes to tmp/.spinel/.git (FETCH_HEAD, a pack, refs/remotes/origin/master), whose reflog records a plain `fetch -q origin` at 18:28:13 UTC, the form the reviewers' and planner's step 1 runs, made from the agents' starting directory while the stages ran; no stage and no line of this change fetches there, so a sound check counted as failed and cost a round.
- Fix: have tools/agent_guard.sh refuse a git call whose hook working directory is neither the project nor a tmp/.NAME worktree of it (or make the workflow start agents in the project), with a tools-test case for a fetch from tmp/.spinel.
- Category: pipeline
- Added: 2026-11-21

### The merger profile can run a lane worktree's copies of run_state.sh and ci_wait.sh
- Location: tools/agent_guard.sh:717 (script_form, merger profile)
- Why: security Low, confidence 6, predating this change: after `cd tmp/.lane-CHANGE` the merger profile still allows tools/run_state.sh and tools/ci_wait.sh, so a branch, or code its checks run, that rewrites either script in the lane worktree runs arbitrary code with the merger's GitHub merge rights, outside every guard form; task 7.1 of the change named this entry.
- Fix: in script_form, refuse every tools/*.sh form of the merger profile while cd_worktree is set, as the open_pr.sh message and lane_facts.sh cases already are, keeping MERGE_GATES exempt as main's copy in tmp/.merge-gates; add a tools_test case for each refusal.
none
- Also: tools/run_state.sh, tools/ci_wait.sh
- Category: security
- Added: 2026-11-21

### A dangling .claude link refuses every write with the dangling-path message
- Location: `tools/agent_guard.sh`, `write_target`, the loop over `LOCAL_FILES` after `real_path`.
- Why: each write resolves the real path of every local settings file; while `.claude` is a dangling link, `real_path` refuses every write as "a path through a dangling link: .claude/settings.local.json", which names neither the write nor the reason. The refusal is on the safe side, so only the message misleads (merge-path-lows quality review).
- Fix: resolve the local settings paths once at the guard's start, skipping a dangling one, and compare each write's real path with that list.
none
- Category: pipeline
- Added: 2026-11-22

### The runner profile records any phase or review (sprint-29 review security Low (5))

- Location: tools/agent_guard.sh:688
- Why: the runner profile accepts tools/run_state.sh phase, review, metric, and ci-stages with any arguments, and the resume start, which reads run-state note text through `trusted`, shares it; note text quoting reviewed code could steer the cheap-tier runner into recording a forged `review CHANGE security pass ... COMMIT`. The merge gate's RECORDS comparison and the workflow's rule of skipping a phase only on a pass recorded by this start limit the damage.
- Fix: check runner:review and runner:phase arguments against the forms the workflow queues (kinds, pass or blocked, a 7 to 40 hex commit, a summary of key=integer words), or split the profile so the resume start runs only show, get, trusted, plan-needed, lane-open, init, and make doctor or toolchain; accepted when a tools-test case of a forged review line from the resume start is refused.
- Also: tools/run_state.sh
- Category: security
- Added: 2026-11-22

### runner:note repeats read:note's refusal (sprint-29 review quality)

- Location: tools/agent_guard.sh:689 to :697 (runner:note), :718 to :730 (read:note)
- Why: the late, held, and unpushed finding refusal and the data_at=6 rule are copied, so a new close-only note kind added to one profile is missed by the other.
- Fix: one `read:note|runner:note` branch; accepted when the existing guard cases pass for both profiles.
- Category: pipeline
- Added: 2026-11-22

### base-figures save is allowed to every read-profile agent
- Location: tools/agent_guard.sh, the read profile's `base-figures` form
- Why: the form is shared by every agent of the read profile, though only the benchmark agent saves; save now builds and measures main's tracked tree itself, so a planted output no longer reaches the stored figures, but any read-profile agent can still trigger the build and the store.
- Fix: give the benchmark its own guard profile (or an `only_profiles` check on `save`) and add the guard cases for the other profiles refusing it.
none
- Category: pipeline
- Added: 2026-11-23

### RISKY_CONFIG omits pager keys (sprint-14 sweep security Low (3))
- Location: tools/agent_guard.sh RISKY_CONFIG, tools/rules.sh:60
- Why: the line must change in tools/rules.sh with the guard's copy (tools/tools_test.sh requires them equal), and the brief stops a change that edits tools/rules.sh; moved to risky-config-pager (Pool 1), not fixed here.
- Fix: add the pager keys to both lines in the one change that may edit tools/rules.sh.
- Also: tools/rules.sh, tools/tools_test.sh
- Category: security
- Added: 2026-11-23

### the runner profile admits run_state.sh review and phase with at tools/agent_guard.sh:707 (sprint-30 sweep security Low (4), note 1)

- Location: tools/agent_guard.sh:707
- Why: the runner profile admits run_state.sh review and phase with any arguments, and the delivery flush runs review records and note lines carrying up to 400 characters of reviewer text in one runner start on the smallest model, so text planted in reviewed code and quoted into a finding could steer the runner to record a security pass the merge gate reads
- Fix: restrict runner review and phase in the guard to a result, kind, and commit form the workflow fixes (or a per-run nonce), and run note lines in a start separate from review records
- Category: security
- Added: 2026-11-23

### and 100 the profile header lines run past the at tools/agent_guard.sh:77 (sprint-30 sweep quality, note 19)

- Location: tools/agent_guard.sh:77
- Why: and 100 the profile header lines run past the header wrap width the rest of the block keeps
- Fix: rewrap them
- Category: pipeline
- Added: 2026-11-23

### header comment lines of 102 to 119 columns (also at tools/agent_guard.sh:77 (sprint-30 sweep quality, note 60)

- Location: tools/agent_guard.sh:77
- Why: style: header comment lines of 102 to 119 columns (also tools/agent_guard.sh:48 and tools/ci_scope.sh:38) break the wrapping the rest of each header keeps
- Fix: rewrap them
- Also: tools/ci_scope.sh
- Category: pipeline
- Added: 2026-11-23

### merger:lane-close reads pushed from the run state with sed at tools/agent_guard.sh:690 (sprint-30 sweep quality, note 61)

- Location: tools/agent_guard.sh:690
- Why: order: merger:lane-close reads pushed from the run state with sed before it checks the file exists and is not a link
- Fix: test -f and ! -L first, then read the head (a possible security point, unexamined here)
- Category: pipeline
- Added: 2026-11-23
