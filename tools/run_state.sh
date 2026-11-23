#!/bin/sh
# The run state of one change in the delivery pipeline, and the one writer
# of it and of the stage logs (.claude/workflows/deliver-change.js).
#
# State: build/pipeline/CHANGE.json, one flat JSON object of string values,
# one key per line, rewritten through a temporary file and a rename:
#   change, branch   the change, its branch, and repo, the GitHub owner/name
#   phase.NAME       the commit the phase finished at
#   stage.NAME       "EXIT SECONDSs COMMIT UTC-TIME" of the last run at the
#                    commit it started on, with "carried-from-COMMIT" when
#                    check carried it (below), or "compiled-KEY" (twelve
#                    digits of the code key) when check skipped a compile
#                    stage on its code key; EXIT is "running" while it
#                    runs, "killed" when a signal ended it, "superseded"
#                    when HEAD moved while it ran, "escaped" when it passed
#                    in a check that files outside its clone voided
#   review.KIND      "RESULT COMMIT SUMMARY" (security, quality, bench, and
#                    periodic-security and periodic-quality after a merge)
#   at.review.periodic-security
#                    the UTC time the periodic security review was recorded
#   at.plan-needed   the UTC time plan-needed last read the review runs
#                    before the change's planner (merged_since)
#   pushes, ci_fixes the pushes made and the CI fixes they may answer
#   review_fixes     the review fix pushes made (at most one a run)
#   gates_failed     the push attempts the pre-push gates refused
#   gated            the full sha every merge gate passed at, which the
#                    merge tool's hook requires; "none" after a push
#   pushed, pr, ci   the full sha of the last pushed commit, which the
#                    merger passes as the expected head, the pull
#                    request number, and
#                    "green|red COMMIT"
#   merged           the squash commit on main
#   metric.NAME      one measurement or figure of the run: tools/metrics.sh
#                    names, rework, ci_min, estimate (the plan's size), critical (rule letter),
#                    escalated (1), quality_review (the contributor's quality
#                    review, ADDED/FIXED/RECORDED; quality_blocked, the
#                    blocking quality rounds, in older runs), phase.KEY
#                    ("TOKENS/CALLS" of a phase so far), first.GATE (0 or 1,
#                    its first verdict), extra (fix rounds granted beyond
#                    three), stop (rounds when a start stopped at the
#                    limit, else none), planned (0 when the planner was
#                    skipped), and calib.KIND ("TIER/EFFORT" of a kind of
#                    agent start), stored by the workflow, every figure in each
#                    metric line it runs; total_tokens and wall_min, summed
#                    over the starts by usage; ci.STEP (seconds of a CI
#                    step, ci-stages), ci_wait_calls (the merger's calls
#                    waiting on CI), start.N, weighted.KEY, weighted_tokens,
#                    and counted (tokens); older runs stored
#                    first_pass, out_tokens, tool_calls, phases
#   note.N           "KIND TEXT": a retrospective proposal or a finding
#   moved            "HEAD COMMIT": moved found the change the same at
#                    HEAD as at the reviewed COMMIT (full shas)
# Logs: build/stages/CHANGE/STAGE.log, ending in "EXIT n", "KILLED: ...",
# or "SUPERSEDED: ..."; check.log, the runner's output, ending in its
# verdict line, and check.pid, "PID COMMIT CLONE" while the runner runs.
# Compile passes: build/pipeline/compiled, "STAGE KEY SUM" per stage of
# COMPILE_STAGES, kept across changes.
# The check clone: a repository the runner makes outside the delivery
# clone for each check (TMPDIR) and removes on exit; every stage runs in
# it. build/stages/CHANGE/carry keeps its build/ between checks (without
# pipeline, stages, and plan) and METRICS_OUT gets its metrics. The clone
# holds its own copy of the toolchain and a copy of the plan's sprint
# marker and groom.txt (clone_plan), which the gates stage reads to prove a
# records carrier's groomed findings; files changed outside the clone
# while every stage exited 0 (escaped_paths) void the check: its passes
# are rewritten as not passing, the paths kept as a security-escape note,
# and its verdict reads escaped when every path lies under a path of the
# main checkout's build/ another lane writes (LANE_WRITTEN, none by
# default; lane_written), else failed.
#
# History: docs/metrics-feature.tsv and docs/metrics-backlog.tsv, one row
# per merged change in its lane's file (lane), appended by history
# from the run states that have none yet, so the next change carries the
# rows of the runs before it (columns in HEADER below). A row's estimate is
# metric.estimate, else the size word of the change's queue item, its
# actual the total_tokens and wall_min, with out_tokens beside them.
#
# Usage: sh tools/run_state.sh COMMAND ...
#   init CHANGE BRANCH          create the state unless it exists, then show it;
#                               on a BRANCH other than main, refuse a CHANGE
#                               the close recorded as merged (merged and
#                               phase.retro) or with a lane history row,
#                               which takes a unique name; a merged run with
#                               no phase.retro resumes
#   show CHANGE                 print the state
#   trusted CHANGE              print the state a resume may trust: without a
#                               phase.*, review.*, or merged record whose
#                               commit is an ancestor of neither HEAD nor BASE,
#                               or a line write_key would not write, those
#                               keys named in "untrusted"
#   get CHANGE KEY              print one value, empty when absent
#   gated CHANGE clear|pass     the merge gates' record: none (in every run
#                               state), or HEAD's full sha
#   set CHANGE KEY VALUE        write one value; refuses review.*, phase.*, note.*, gated,
#                               change, branch, and repo (init's, which open_pr wait checks the head by),
#                               stage.*, at.*, and moved, which their own commands write,
#                               a pushed value but a commit hash, a ci value
#                               but "red|green COMMIT" at the pushed head, and
#                               a merged value but the squash commit on main
#                               (once pr is recorded, the commit whose subject
#                               ends with " (#PR)") whose last line is exactly
#                               the co-author trailer, each refusal naming both
#   phase CHANGE NAME [COMMIT]  record the phase (one of PHASES) done at
#                               COMMIT, HEAD when omitted
#                               (ci only at the pushed head, merge only at
#                               the squash commit, as set checks them)
#   phase CHANGE NAME merged [REPORTED]
#                               record merge, retro, or report at the squash
#                               commit: once pr is recorded, the commit of
#                               main whose subject ends with " (#PR)", which a
#                               recorded merged must name, else the recorded
#                               merged; REPORTED, the commit an agent
#                               reported (merge only), when it is not that
#                               commit, adds a merge-disagreement note naming
#                               both; either form records merge with its
#                               merged commit, writing merged when none is
#                               recorded and refusing one naming another
#   review CHANGE KIND RESULT SUMMARY [COMMIT]
#                               record a review (KIND one of REVIEW_KINDS,
#                               RESULT pass or blocked, and for the periodic
#                               kinds also partial, some areas not reviewed,
#                               or not-run, no result) at COMMIT, HEAD when
#                               omitted, periodic-security its time as
#                               at.review.periodic-security; a pass also
#                               records phase.KIND
#                               (a SUMMARY with carried=1 only at the head
#                               of the moved record, its reviewed commit
#                               another, where review.KIND passed)
# The delivery workflow, not its agents, runs phase and review: it builds
# them from the results it received (tools/agent_guard.sh keeps the agents
# off them, and the merge gate compares them with RECORDS).
#   stage CHANGE NAME CMD...    run CMD with its log and record its result
#   check CHANGE [COMMIT]       refuse a dirty tracked tree or an untracked
#                               file under carat/ bin/ test/ bench/, then
#                               run the checker's stages (make -s stages,
#                               FAST_STAGES; origin/main's CHECK_STAGES while
#                               its Makefile has no FAST_STAGES, as its merge
#                               gates require) in
#                               the check clone (below), CHECK_JOBS at once
#                               (default 3) in the order STAGE_AFTER and
#                               STAGE_ALONE need, and stop at the first
#                               failure, its log's last lines printed and
#                               the stages still running recorded killed (the
#                               workflow records phase.check); a stage record
#                               counts only at COMMIT when it is the
#                               recorded phase.check, the last check the
#                               workflow passed, or HEAD (any other COMMIT
#                               backs nothing, noted on stderr, and every
#                               stage runs), or carried from it:
#                               skipped when COMMIT is HEAD, carried to HEAD
#                               for a
#                               stage outside TEST_STAGES when only tests
#                               changed since COMMIT; a stage of
#                               COMPILE_STAGES is skipped on the code key of
#                               its last pass with its outputs unchanged;
#                               a stage of RERUN_STAGES (diagnose, which CI
#                               leaves out) is skipped only when COMMIT is
#                               the recorded phase.check, and never on a
#                               code key.
#                               Whoever started it, the contributor (CHANGE
#                               alone, its own head) or the checker, a check
#                               writes its stage records from the runner,
#                               which no agent's set writes; the workflow
#                               accepts a pass only from those records: it
#                               backs the contributor's passing head as
#                               COMMIT unless the change touches the check's
#                               own machinery (tools/lane_facts.sh
#                               machinery), and records phase.check from the
#                               checker's verdict alone. The runner is the
#                               contributor's working tree's copy, so an
#                               uncommitted edit of it, restored before
#                               the commit, could write records at HEAD
#                               that machinery no does not see: a backed
#                               head trusts the contributor's session only
#                               where a later run checks it again; CI
#                               reruns docs-lint, the builds, test-run,
#                               bench-budget, metrics, and tools-test,
#                               main's merge gates rerun gates, and the
#                               checker's own check reruns diagnose
#                               (RERUN_STAGES). The runner refuses a dirty
#                               tracked tree at its own start too, so one
#                               started over an edit writes no record. The
#                               stages run in a runner (check-run, no agent's)
#                               detached from the caller, rejoined by a check
#                               at the same HEAD and stopped by one at another;
#                               check waits CHECK_WAIT seconds, prints its log,
#                               and exits 0 on a pass, 1 otherwise, 3 while it
#                               runs; the last line is the verdict: "check:
#                               every stage passed at C", "check: stage S
#                               failed|killed|superseded at C; read LOG" (S
#                               none before a stage), "check: stage none
#                               escaped at C; read LOG" when every stage
#                               exited 0 but files changed outside the clone,
#                               each under a LANE_WRITTEN path of the main
#                               checkout's build/ seen from a lane, none by
#                               default (rerun with no fix round; any
#                               other path reads "stage none failed"; both
#                               rewrite its records escaped and note the
#                               paths), or "check: still running"
#   scope CHANGE COMMIT [FILE...]
#                               print "fix: ..." and exit 0 when every path
#                               changed from COMMIT to HEAD is a FILE or
#                               matches TEST_ONLY, so the quality review of a
#                               fix reads only its diff; "branch: ..." and
#                               exit 1 otherwise or when nothing changed
#   settled CHANGE COMMIT       print "settled: only records changed from COMMIT
#                               to HEAD: ..." and exit 0 when COMMIT is an
#                               ancestor, the tree clean, and every changed
#                               path matches RECORDS_RE (docs/sprints.tsv
#                               and INSTRUCTION_RECORDS_RE never), so an
#                               advisory-only round stands on
#                               COMMIT's check and security review;
#                               "unsettled: ..." and exit 1 otherwise
#   moved CHANGE COMMIT         after merge-main took in a moved main (BASE,
#                               origin/main), print "moved: the change is the
#                               same ...", record moved ("HEAD COMMIT" in full),
#                               and exit 0 when no file of the change differs
#                               from COMMIT, the reviewed commit, to HEAD and
#                               HEAD matches BASE in every file the change
#                               never touched (both outside the records-only
#                               paths, an instruction record counted as a
#                               file, names compared as text), so its reviews
#                               stand; else, or when a git diff fails, print
#                               why and exit 1, no moved record left
#   bench CHANGE                record the metrics stage's measurement and
#                               compare it with main's through make
#                               metrics-compare: the newest merged change
#                               without a history row, else the last row;
#                               exit 0 when allocations and rounds equal
#                               them, 1 otherwise
#                               when figures of main measured at its current
#                               commit are stored (base-figures), they are the
#                               base instead: exit 0 unless more allocations
#                               or rounds, which exit 1 with no base to build
#   base-figures CHANGE [save]  exit 0 when main's measured figures for its
#                               current commit are stored, else say so and
#                               exit 1; save builds tmp/.base (outputs cleared first,
#                               an untracked makefile refused), measures it with its own
#                               tools/metrics.sh and stores that,
#                               refused unless that worktree is at main
#   carried CHANGE COMMIT       exit 0 and print "carried: every stage passed
#                               at HEAD" when COMMIT is HEAD and every stage
#                               holds a pass record at HEAD (diagnose only
#                               scoped out), then print the spent line and the
#                               bench result as the checker would; else print
#                               "carried: no: why" and exit 1, so the workflow
#                               starts no checker
#   push CHANGE [--ci-fix|--review-fix|--main-moved|--pr-text]
#                               run the pre-push gates, refuse a push beyond one
#                               plus one per CI fix (a CI fix needs ci red) plus
#                               one review fix a run (a resume past the push
#                               fixing a blocking review: a recorded push other
#                               than HEAD) plus one main-moved push a run (a
#                               merge refused because main moved: a recorded
#                               push other than HEAD that does not hold BASE,
#                               origin/main, and a HEAD that does) plus one
#                               pull request text push a run (a rewrite of
#                               pr.md the text review blocked: a recorded
#                               push other than HEAD), push the
#                               branch with upstream tracking, and count it
#   metric CHANGE NAME=VALUE... record metric.NAME; names are [a-z0-9_.-], values
#                               [A-Za-z0-9_.,:/=+-]
#   metrics CHANGE FILE         record each "name<TAB>value" line of a
#                               tools/metrics.sh measurement as metric.name,
#                               dropping one whose value is ? (not measured)
#   note CHANGE KIND TEXT       record note.N, the next number, as "KIND TEXT";
#                               a quality-advisory whose TEXT, without its
#                               leading commit, is already noted is not
#                               recorded again, nor a security note whose
#                               whole TEXT is; a late-finding is refused
#                               until merged names a commit on main and is
#                               stored as "late-finding MERGED TEXT"; a
#                               held-finding is refused without a pushed
#                               record or with a merged one, and an
#                               unpushed-finding once pushed is recorded
#                               (the workflow's close records, which the
#                               guard keeps to the close profile)
#   usage CHANGE TOKENS MINUTES add one start's total tokens (input plus
#                               output) and wall minutes, as the Workflow
#                               tool reported them, to metric.total_tokens
#                               and metric.wall_min, then print the budget
#   ci-stages CHANGE COMMIT     record the seconds of each step of the spin
#                               job of the newest ci run at COMMIT as
#                               metric.ci.STEP, read with gh; exits 0 when
#                               none could be read
#   tokens CHANGE DIR           record each agent start of the Workflow run
#                               whose transcripts DIR holds, its total
#                               tokens weighted by its tier (TIER_PRICES),
#                               per start and per phase; a DIR counts once
#   review-due                  print "due: sprint-N has N changes merged",
#                               the changes, its combined diff
#                               BASE..origin/main, and "sweep: yes" in an
#                               even sprint, and exit 0 when sprint_size
#                               changes counted merged since the last sprint
#                               of docs/sprints.tsv (SPRINTS_FILE): the
#                               queue's sprint items and their split parts,
#                               never a T0 item, one an exception line puts
#                               outside the 3, one beyond the sprint, or a
#                               pool item (queue_class);
#                               print "not due: ...", the changes left out
#                               named by reason, and exit 1 before that or
#                               while the sprint's plan waits in build/plan/
#                               after its security review, recorded pass or
#                               blocked in the run state sprint-N
#                               or while a run state records a merge phase
#                               without its merged commit, naming each
#   backlog-dups                print each location (file:line) that two or
#                               more backlog headings name, with the headings
#   backlog-move FILE           file every entry of FILE into BACKLOG_DIR
#                               (the backlog file of the first file it
#                               names, else _general.md, with "- Also:",
#                               "- Category:", and "- Added:" lines, dated
#                               by the git blame of its heading), prove the
#                               folder kept every heading and line of FILE
#                               beside its own, and remove FILE
#   backlog-pick PATH...        print the next PICK_BATCHES batches of the
#                               backlog entries ("## title" or deeper,
#                               "- Location:" or "- Where:", "- Why:" or
#                               "- Why it matters:") of the PATHs (a file,
#                               or a directory: each Markdown file under
#                               it), oldest "- Added:" first, which it
#                               requires (only the sprint planner names
#                               docs/backlog and docs/findings/*.md),
#                               each of one docs/codebase-map.md area: the
#                               areas of the entries naming security first,
#                               then by their oldest entry; PICK_MIN or more
#                               give at most PICK_MAX, security first, then
#                               oldest; fewer give their security entries
#                               alone, or none; an entry a queue file names,
#                               or whose whole heading line ends a line of
#                               PLAN_DIR/groom.txt, a gone line's before its
#                               " -- REASON", is skipped; one placed by
#                               the first path of its Location line the map
#                               holds (a bare backticked word only when the
#                               map names it and the tree holds it as a file
#                               or directory), or a directory holding one,
#                               else by its heading's path:line; one no
#                               mapped path holds printed "unmapped:"; exit
#                               1 when no batch
#   backlog-oldest PATH...      print the heading lines of the first
#                               PRUNE_COUNT entries of the PATHs (50), as
#                               backlog-pick reads them,
#                               which it requires (only the sprint planner names
#                               docs/backlog and docs/findings/*.md), in
#                               order, the oldest first: a "## " or "### "
#                               heading with a path:line in it or a
#                               "- Location:" or "- Where:" line, each
#                               once, one whose whole heading line ends a
#                               line of PLAN_DIR/groom.txt, a gone line's
#                               before its " -- REASON", left out; the
#                               entries the planner checks against HEAD
#                               for evidence (groom's fixed and gone)
#   groom [CHANGE]              nothing when CHANGE's run state sets
#                               records=skip (the planning records excluded),
#                               or, retiring the marker to sprint.applied,
#                               when the sprint it names has its row in
#                               BASE's sprints file (a row only in the
#                               working tree's, the carrier's, keeps it,
#                               so the other lane still reads the plan's
#                               queues); refuse a run with no CHANGE; a
#                               delivery's package step runs it
#                               (planner-loop), the first while a plan
#                               waits carrying it: nothing while
#                               PLAN_DIR/sprint.carrier names another
#                               change of the sprint, or while the plan
#                               is held (queue_hold: sprint-N or
#                               sprint-N-sweep records a blocking periodic
#                               security review no change planned after
#                               it merged since nor a later whole-tree
#                               pass superseded, or sprint-N records hold
#                               security-first and no such merge); else
#                               apply a waiting sprint plan (PLAN_DIR/sprint
#                               names the sprint in progress, which the
#                               sprints file lacks, and sprint-N records its
#                               security review pass or blocked; else the
#                               plan waits), writing sprint.carrier as
#                               "sprint-N CHANGE": check every line of
#                               groom.txt, "listed CHANGE HEADING" (CHANGE
#                               a change of the sprint whose queue item
#                               holds HEADING), "fixed COMMIT HEADING"
#                               (COMMIT in the sprint's range, after its
#                               base up to HEAD, changing a file the entry
#                               names), "gone HEADING -- REASON" (REASON,
#                               after the line's last " -- ", not blank,
#                               saying why the problem no longer applies,
#                               and every path the entry names that the
#                               history held, at least one, absent at
#                               HEAD), "merged KEPT <=
#                               HEADING" (KEPT another heading no line
#                               removes, HEADING removed by no other line;
#                               a security entry only into one), or
#                               "duplicate HEADING" ("gone" and
#                               "duplicate" never a security
#                               entry; an entry leaves only with evidence,
#                               never for its age, so a "stale" or
#                               "closed" line is refused
#                               (security_entry: security and a severity
#                               in any wording, such as security Low or
#                               a Low finding of the security review),
#                               HEADING a whole heading line
#                               of the backlog, and write nothing when one
#                               fails; then copy queue-feature.md and
#                               queue-backlog.md over their docs/ lane files,
#                               file each findings file's entries (FINDINGS_DIR)
#                               into the backlog file of its first named
#                               path (backlog-move's filing) and remove it,
#                               remove each entry, a merged one's lines
#                               appended under KEPT after a "- Merged:
#                               HEADING" line, across every backlog file, a
#                               file left with no entry removed, file
#                               groomed.md's entries the same way (merged
#                               entries and the sprint findings not queued),
#                               and append the sprint's row from its history
#                               rows, the marker kept until BASE holds it
#   sprint-row COMMIT [committed]  print the row groom appends for the sprint
#                               the marker names (PLAN_DIR/sprint, else
#                               sprint.applied), against the sprints file
#                               at COMMIT; refuse a marker naming another
#                               sprint than the one in progress there;
#                               committed reads the history rows from HEAD,
#                               not the working tree (the gates' form)
#   groom-proof COMMIT LINE     exit 0 when the groom line LINE ("listed CHANGE
#                               HEADING" or "fixed COMMIT HEADING") holds
#                               groom's proof against the sprint in progress
#                               at COMMIT, the removed entry's text on stdin
#                               (the findings gate's check of a plan line)
#   plan-needed CHANGE          print "needed: REASON" and exit 0 when the
#                               change is not item 1 of a lane queue,
#                               docs/queue-feature.md or docs/queue-backlog.md
#                               (the waiting sprint plan's), or a
#                               pending change holds a proposal or finding
#                               (PLAN_NOTES) to place that no sprint
#                               plan placed (placed_by_sprint), or
#                               the head item names no estimate, or a review run records
#                               a failing periodic security review with no
#                               change planned after it was recorded and
#                               merged since (merged_since) nor a later
#                               whole-tree periodic security review passed
#                               (passed_since); while the change's plan is
#                               ahead, record when it read them (at.plan-needed);
#                               print "not needed: ..." with the head item's size and exit 1
#   budget CHANGE               print "over:", "under:", "unmeasured:", or
#                               "no estimate:" with the change's estimate, its
#                               budget (TOKEN_BUDGETS, MINUTE_BUDGETS), its
#                               total tokens and wall minutes, and its output
#                               tokens
#   spent CHANGE                print "under:", "over:", or "no estimate:" with
#                               the output tokens spent so far against the
#                               output budget of the change's estimate
#                               (TOKEN_BUDGETS / OUTPUT_SHARE) and the total
#                               tokens earlier starts recorded against
#                               TOKEN_BUDGETS; a note after a passing check,
#                               always exit 0
#   reviewed-edits CHANGE       list the files changed since the commit
#                               the security review passed at (commits,
#                               working tree, untracked) outside the
#                               records-only paths (RECORDS_RE) or among
#                               INSTRUCTION_RECORDS_RE and exit 1
#                               when any is, or when no pass is recorded:
#                               the package step edits no reviewed file
#   pending                     the merged changes with no history row yet
#   history [CHANGE]            nothing when CHANGE's run state sets
#                               records=skip; else append a history row for
#                               each pending change of CHANGE's lane
#                               (lane_of; every lane with no CHANGE or one
#                               whose groom carries the waiting plan,
#                               carries), the other lane's
#                               left to its next package step, but one whose row BASE's
#                               history holds or whose run state records the
#                               branch it was appended on (row, written here);
#                               a gate without a stored first verdict is
#                               left out of its first passes; append each
#                               such run's late-finding notes to
#                               the change's findings file
#                               (FINDINGS_DIR/CHANGE.md) as one entry
#                               (late_findings: only a note stamped with its
#                               merged commit, in the workflow's note shape)
#   lane CHANGE                 print the change's lane, feature or backlog
#                               (lane_of), whose history file gets its row
#   plan-apply CHANGE           apply the delivery planner's PLAN_DIR/CHANGE/
#                               for the change's lane only: copy its
#                               queue-LANE.md over docs/queue-LANE.md, leaving
#                               the other lane's, goals.md over docs/goals.md,
#                               and append backlog.md to FINDINGS_DIR/CHANGE.md
#   status                      the queue, the running change, the last metrics
#                               row, and the first-pass rates of the history
#   lane-open CHANGE BRANCH     make the change's worktree tmp/.lane-CHANGE
#                               of the main checkout on BRANCH (the local
#                               branch, else origin's, else a new one from
#                               BASE), keep it on a resume, replace one on
#                               another branch (a replaced run), and link
#                               the main checkout's toolchain (tmp/.spinel,
#                               tmp/.toolchain), compile cache
#                               (build/spinel-cache), run states, stage
#                               logs, and plans (build/pipeline, build/stages,
#                               build/plan) into it, each target made first
#                               when missing, so a lane opened before make
#                               toolchain shares the one it installs; print
#                               its path; refuses, exit 1, a branch that
#                               tracks one of those paths, commits a tmp or
#                               build link, or a lane link to another target
#   lane-close CHANGE           remove the change's worktree, after its merge
#                               or when its run is replaced, never a link's
#                               target; nothing when none stands
#   merge-main CHANGE           in the worktree, fetch origin's main (BASE
#                               when set, unfetched) and merge it into the
#                               branch when it moved, never a rebase: the
#                               appended records (APPENDED_RECORDS) merge by
#                               union, both sides' rows kept; a conflict only
#                               in the lane queues keeps the branch's own
#                               lane queue (lane_of) and BASE's other; any
#                               other conflict aborts the merge and names
#                               its files, exit 1; only its fetch runs
#                               with no global or system configuration
#                               and no hook
# Every write refuses a key outside [a-z0-9_.-] and a key or value holding a
# control character (newline, carriage return, tab, or another), so no write
# adds a line of its own.
#
# Environment: BASE (origin/main), RUN_STATE_DIR (build/pipeline),
# STAGE_DIR (build/stages), STAGES (the stage list; make -s stages when
# unset), MAKE (make), METRICS_PREFIX (docs/metrics, the lane files
# PREFIX-feature.tsv and PREFIX-backlog.tsv), METRICS_OUT
# (build/metrics/current.tsv, under tmp/.lane-CHANGE/ when run from the
# main checkout while that lane exists), CHECK_WAIT (540, seconds check
# waits), LANE_WRITTEN (none, the paths under the main checkout's build/
# another lane writes, whose writes alone make a check read escaped),
# BACKLOG_DIR (docs/backlog), FINDINGS_DIR (docs/findings), TODAY (the
# date groom files a findings entry with, else the UTC day),
# SPRINTS_FILE (docs/sprints.tsv), PLAN_DIR (build/plan).
set -u

here=$(cd "$(dirname "$0")" && pwd)
. "$here/rules.sh"
state_dir=${RUN_STATE_DIR:-build/pipeline}
stage_dir=${STAGE_DIR:-build/stages}
make_cmd=${MAKE:-make}
lane_written_paths=${LANE_WRITTEN:-}
metrics_prefix=${METRICS_PREFIX:-docs/metrics}
metrics_files="$metrics_prefix-feature.tsv $metrics_prefix-backlog.tsv"
backlog_dir=${BACKLOG_DIR:-docs/backlog}
findings_dir=${FINDINGS_DIR:-docs/findings}
queue_files="docs/queue-feature.md docs/queue-backlog.md"
# The pick's batches (backlog-pick): the sprint's three backlog items, each
# of one area holding PICK_MIN entries, at most PICK_MAX of them.
PICK_BATCHES=3
PICK_MIN=5
PICK_MAX=10
# The entries the sprint planner checks against HEAD each sprint
# (backlog-oldest) for evidence that one left (groom's fixed and gone),
# never for its age (the user's rule of 2026-11-21): PRUNE_COUNT of them.
PRUNE_COUNT=50
metrics_out=${METRICS_OUT:-build/metrics/current.tsv}
# The stage records the check runner wrote (stage_record).
runner_records=''
PHASES="plan implement check quality security bench package ci merge retro report"
# The phases a workflow's close records, the phases of its CLOSABLE lines
# (.claude/workflows/deliver-change.js), which a rejoined check leaves out
# of its run-state comparison (state_view).
CLOSE_PHASES="plan implement package ci merge retro report"
# The stages that read what a test-only commit may change, which such a
# commit runs again: test-build and test-run compile and run the tests,
# diagnose runs spinel-doctor on the test runner, metrics reads the runner's
# rounds from test-build's report, docs-lint reads docs/*.md and the test
# paths the docs name, and gates reads the commit; check carries the others.
# TEST_ONLY: the paths such a commit may change, tests and their snapshots,
# and the records-only paths of tools/rules.sh (RECORDS_RE), which no
# carried stage reads.
TEST_STAGES="test-build test-run diagnose metrics docs-lint gates"
TEST_ONLY="^(test/|$RECORDS_RE|\$)"
# The records-only paths agents act on as instructions, which no pass is
# settled across (settled, reviewed-edits): the line of tools/gates.sh,
# which settled_at reads, kept equal by tools/tools_test.sh.
INSTRUCTION_RECORDS_RE='docs/goals\.md$'
# outside_records: the paths on stdin, one a line, that no pass is settled
# across: those outside the records-only paths (RECORDS_RE) and the
# instruction records (INSTRUCTION_RECORDS_RE); blank lines dropped.
outside_records() {
  outside_in=$(cat)
  printf '%s\n' "$outside_in" | grep -v -E -e "^($RECORDS_RE)" -e '^$'
  printf '%s\n' "$outside_in" | grep -E "^($INSTRUCTION_RECORDS_RE)"
  return 0
}
# The compile stages, skipped when the code they read is the code of their
# last pass and their outputs are the ones it left: the code key hashes
# every tracked path but NOT_COMPILED, which no compile stage reads, except
# BUILD_TOOLS, the scripts dev-build and test-build run: the analysis
# budget and the Spinel warning check, whose pattern decides a pass.
# COMPILED keeps each stage's last pass, "STAGE KEY SUM", across changes,
# in the run state's directory, which only this script writes.
COMPILE_STAGES="dev-build test-build"
# The stages CI leaves out of a pull request's checks and no later gate
# reruns (main's merge gates rerun the gates): diagnose. A pass of theirs
# is skipped at the head only when the backed commit is the recorded
# phase.check, which the workflow writes from the checker's verdict, never
# on a contributor's claimed head, whose records its working tree's
# runner wrote, and never on a compiled line, which any runner writes; so
# the checker runs them again wherever a contributor's runner could have
# written their pass.
RERUN_STAGES="diagnose"
NOT_COMPILED='^([.]claude/|[.]github/|docs/|openspec/|tools/[^/]+[.]sh$|[^/]+[.]md$)'
BUILD_TOOLS='^tools/(analysis_budget|spinel_warnings)[.]sh$'
# The path scope: the stages a change's paths need, from the paths changed
# since its merge base with main (BASE). ALWAYS_STAGES run on any change;
# tools-test runs when a changed path is one it reads (TOOLS_RE in
# tools/rules.sh); every other stage when a changed path is not
# documentation (tools/rules.sh), so a documentation-only change runs only
# ALWAYS_STAGES. A stage left out is recorded passed, with the note scoped.
ALWAYS_STAGES="docs-lint gates"
compiled_file=$state_dir/compiled
# The gates of a history row's first passes, in order, before gates.
GATES="check quality security bench ci"
REVIEW_KINDS="security quality bench periodic-security periodic-quality"
# The total-token budget (input plus output) of each size a queue item is
# estimated at, and the wall-minute budget of the sizes that have one, as
# docs/goals.md gives them.
TOKEN_BUDGETS="small=500000 medium=1200000 large=2500000"
MINUTE_BUDGETS="small=25"
# The total tokens per output token that a run's output budget assumes,
# for spent: the median of the history's rows with both figures was 5.5
# (4.1 to 9.1), rounded up so the note comes early rather than late.
OUTPUT_SHARE=6
# The price of each tier per million tokens, in tenths of a cent: input,
# cache write (the five-minute rate), cache read, output, from the current
# price list; tokens weighs a start by its tier, in session-tier input
# tokens, so the weighted figure stays near the raw totals and budgets.
TIER_PRICES="cheap=100/125/10/500 session=4000/5000/200/20000"
# The note kinds of a pending change that the planner places: retrospective
# proposals, overruns, and periodic review findings.
PLAN_NOTES='retro|overrun|security|quality'
# What makes a backlog entry a security entry for groom (security_entry,
# the one place that reads it, over the entry's lines joined, without
# case): the word security and a severity in any wording and order, as the
# security reviewer records it ("security Low (6)", "periodic security
# Medium", "security Lows"), the planner's "security disputed", or a note
# words it ("Low finding of the periodic security review"), or a severity
# and confidence pair ("High (8)", "Critical (9)"); a text that names
# security with no severity, such as a quoted section title, is not one.
SECURITY_SEVERITY='(critical|high|medium|low|disputed)s?'
SECURITY_MARK="(^|[^a-z])security[^a-z](.*[^a-z])?$SECURITY_SEVERITY([^a-z]|\$)|(^|[^a-z])$SECURITY_SEVERITY[^a-z](.*[^a-z])?security([^a-z]|\$)|(^|[^a-z])(critical|high|medium|low) \\([0-9]+\\)"
# The awk functions backlog-pick and backlog-oldest share: load_groomed
# fills groomed with every whole heading line a line of the plan's
# groom.txt ends in, a gone line cut at its last " -- " first, before its
# reason, and backlog_entry_head is true for a heading that
# makes an entry, one with a path:line in it or a "- Location:" or
# "- Where:" line (marked).
ENTRY_AWK='
    function load_groomed(file,   line, j, k) {
      while ((getline line < file) > 0) {
        if (line ~ /^gone /) {
          k = 0
          for (j = 1; j + 3 <= length(line); j++) if (substr(line, j, 4) == " -- ") k = j
          if (k) line = substr(line, 1, k - 1)
        }
        for (j = 1; j < length(line); j++) if (substr(line, j, 2) == " #") groomed[substr(line, j + 1)] = 1
      }
    }
    function backlog_entry_head(h, marked) {
      return marked || h ~ /[A-Za-z0-9_.\/-]+[.][A-Za-z]+:[0-9]+/
    }'
TAB=$(printf '\t')
# Columns 16 and 17 came after estimate, and 19 to 22 after calibration,
# so rates ($5, $6) read the same columns in every row; 23 and 24, the closing
# loop's advisories closed and left, follow weighted_phases, a row before them
# holding none.
HEADER="change${TAB}date${TAB}merged${TAB}pr${TAB}rework${TAB}first_pass${TAB}ci_min${TAB}rounds${TAB}allocs${TAB}us_per_key${TAB}out_tokens${TAB}tool_calls${TAB}phases${TAB}review${TAB}estimate${TAB}total_tokens${TAB}wall_min${TAB}calibration${TAB}ci_stages${TAB}ci_wait_calls${TAB}weighted_tokens${TAB}weighted_phases${TAB}advisories_closed${TAB}advisories_left"
# A sprint is sprint_size merged changes (sprint_state): SPRINT_SIZE, three
# features and three backlog changes, from sprint SPRINT_SIZE_FROM on, the
# user's decision of 2026-11-17, for now; SPRINT_SIZE_BEFORE, three and
# two, in an earlier sprint. sprint-planning reviews each sprint's combined
# diff, and the whole tree in every second sprint. One row per planned
# sprint in the sprints file, the first the seed sprint-0.
sprints_file=${SPRINTS_FILE:-docs/sprints.tsv}
plan_dir=${PLAN_DIR:-build/plan}
SPRINT_SIZE=6
SPRINT_SIZE_FROM=17
SPRINT_SIZE_BEFORE=5
# The run states of reviews, not changes, which a sprint never counts:
# /review's review-DATE and sprint-planning's sprint-N.
REVIEW_RUNS='^(review|sprint)-[0-9]'
# The review runs whose scope is a sprint's combined diff, sprint-N, its
# periodic security review never superseding another (passed_since); the
# rest, review-DATE and sprint-N-sweep, review the whole tree.
DIFF_REVIEW_RUN='sprint-[0-9]+'
# The words that mark a queue item, inside its first parenthesis, as a
# change the user approved beyond a sprint's size, which it does not count;
# distinct from "the user-approved exception" inside an item's parenthesis,
# which lifts only the one-pipeline limit (docs_lint.sh) and leaves the
# item counted.
BEYOND_SPRINT_MARK='beyond the sprint'
# The words of a paragraph starting "The user-approved exception" that put
# the changes it names before "run" or "runs" in the same clause outside a
# sprint's count (queue_class).
OUTSIDE_MARK='outside the 3'

die() {
  echo "run_state: $*" >&2
  exit 1
}

head_commit() {
  git rev-parse --short=12 HEAD
}

# The twelve-digit form of COMMIT, HEAD when empty; dies unless it names a
# commit.
commit_at() {
  [ -n "$1" ] || { head_commit; return; }
  valid '[0-9a-f]{7,40}' "$1" || die "not a commit: $1"
  git rev-parse --verify -q --short=12 "$1^{commit}" || die "not a commit: $1"
}

# The twelve-digit form of a check's COMMIT (contributor-self-check): only
# the recorded phase.check, the last check the workflow passed, or HEAD,
# where the stage records the check skips are the runner's at that very
# commit (the working tree's runner, so at HEAD they are only as trusted
# as the session that ran it, and RERUN_STAGES skip only on phase.check:
# the header's check entry). Any other commit
# backs nothing: its records are refused, a note says so on stderr, and
# the check runs every stage, since the workflow queues its phase.check
# record and writes it only after its rounds, so a fix round's check may
# name a pass the run state does not hold yet, which costs stage runs,
# never a refused check and a fix round.
backed_commit() {
  backed_at=$(commit_at "$1") || exit 1
  if [ "$backed_at" = "$(head_commit)" ]; then
    echo "$backed_at"
    return
  fi
  checked=$(recorded_check)
  if [ -n "$checked" ] && [ "$backed_at" = "$checked" ]; then
    echo "$backed_at"
    return
  fi
  echo "check: $backed_at is neither the recorded phase.check (${checked:-none}) nor HEAD $(head_commit): it backs nothing, every stage runs" >&2
}

# True when WORD is one of the words of LIST.
one_of() {
  case " $2 " in *" $1 "*) return 0 ;; esac
  return 1
}

state_file() {
  echo "$state_dir/$change.json"
}

# A value escaped for JSON; write_key and init refuse a control character
# first, so one key is one line.
escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Dies unless VALUE (named by WHAT) is free of control characters: a
# newline, carriage return, tab, escape, or any other would let a write add
# a line of its own, such as a forged review.* or phase.* record.
plain() {
  case "$1" in
    *[[:cntrl:]]*) die "refused: $2 holds a control character (newline, carriage return, tab, or another)" ;;
  esac
}

# Dies unless KEY is a run state key: lowercase letters, digits, _, ., -.
plain_key() {
  plain "$1" "the key"
  case "$1" in
    [a-z0-9]*) ;;
    *) die "refused: not a run state key: $1" ;;
  esac
  case "$1" in
    *[!a-z0-9_.-]*) die "refused: not a run state key: $1" ;;
  esac
}

read_key() {
  file=$(state_file)
  [ -f "$file" ] || return 0
  K="$1" awk '
    /^  "/ {
      key = $0; sub(/^  "/, "", key); sub(/".*/, "", key)
      if (key != ENVIRON["K"]) next
      value = $0; sub(/^  "[^"]*": "/, "", value); sub(/",?$/, "", value)
      gsub(/\\"/, "\"", value); gsub(/\\\\/, "\\", value)
      print value; exit
    }' "$file"
}

write_key() {
  file=$(state_file)
  [ -f "$file" ] || die "no run state for $change; run init first"
  plain_key "$1"
  plain "$2" "the value of $1"
  state_rewrite set "$1" "$2"
}

# Remove KEY from the run state; nothing happens when it is absent.
drop_key() {
  file=$(state_file)
  [ -f "$file" ] || die "no run state for $change; run init first"
  state_rewrite drop "$1"
}

# state_rewrite MODE KEY [VALUE]: the run state with KEY set to VALUE (MODE
# set, added at the end when absent) or without it (MODE drop), written
# through a temporary file and a rename: the one rewrite write_key and
# drop_key share.
state_rewrite() {
  K="$2" V=$(escape "${3:-}") MODE="$1" awk '
    /^  "/ {
      line = $0; sub(/,$/, "", line)
      key = line; sub(/^  "/, "", key); sub(/".*/, "", key)
      if (key == ENVIRON["K"]) {
        if (ENVIRON["MODE"] == "drop") next
        line = "  \"" key "\": \"" ENVIRON["V"] "\""; found = 1
      }
      lines[n++] = line
    }
    END {
      if (ENVIRON["MODE"] == "set" && !found) lines[n++] = "  \"" ENVIRON["K"] "\": \"" ENVIRON["V"] "\""
      print "{"
      for (i = 0; i < n; i++) print lines[i] (i < n - 1 ? "," : "")
      print "}"
    }' "$file" > "$file.tmp.$$" && mv "$file.tmp.$$" "$file"
}

utc_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

# run_stage NAME CMD...: run CMD with its log and record its result at the
# commit it started on. The record reads "running" while it runs; its first
# word is then the exit status, "killed" when a signal ended the command
# (KILLED_STATUSES: a hang-up, interrupt, kill, or terminate), or
# "superseded" when HEAD moved while it ran, and the log's last line says
# which. The stage command runs it; the check starts its stages as jobs
# (stage_launch) and ends each with stage_end, as this does. Sets
# stage_word to the record's first word; returns the status, 1 for a
# superseded stage that exited 0.
KILLED_STATUSES="129 130 137 143"
run_stage() {
  name=$1
  shift
  dir=$stage_dir/$change
  mkdir -p "$dir"
  log=$dir/$name.log
  at=$(head_commit)
  start=$(date +%s)
  write_key "stage.$name" "running 0s $at $(utc_now)"
  "$@" > "$log" 2>&1 < /dev/null &
  wait "$!"
  stage_end "$name" "$at" "$start" "$?"
}

# stage_end NAME AT START STATUS: the end of a stage started at commit AT
# and second START that exited with STATUS: appends its log's last line,
# writes its record, and prints it; sets stage_word and returns as
# run_stage does.
stage_end() {
  log=$stage_dir/$change/$1.log
  secs=$(( $(date +%s) - $3 ))
  now=$(head_commit)
  stage_word=$4
  if [ "$now" != "$2" ]; then
    stage_word=superseded
    echo "EXIT $4" >> "$log"
    echo "SUPERSEDED: HEAD moved from $2 to $now while the stage ran" >> "$log"
  elif one_of "$4" "$KILLED_STATUSES"; then
    stage_word=killed
    echo "KILLED: exit $4, a signal ended the stage" >> "$log"
  else
    echo "EXIT $4" >> "$log"
  fi
  stage_record "stage.$1" "$stage_word ${secs}s $2 $(utc_now)"
  if [ "$stage_word" = "$4" ]; then
    echo "stage $1: exit $4 in ${secs}s, log $log"
  else
    echo "stage $1: $stage_word (exit $4) in ${secs}s, log $log"
  fi
  [ "$stage_word" != superseded ] || [ "$4" -ne 0 ] || return 1
  return "$4"
}

# The order the stages need, "STAGE:BEFORE" pairs: STAGE starts only once
# BEFORE passed (skipped, carried, scoped, or compiled counts) when both
# are in the list. test-run runs test-build's runner and, in the smoke
# test, dev-build's binary; gates (its snapshots gate) runs test-build's
# runner on the changed snapshots and fails without it; metrics reads the
# reports of dev-build and test-build and measures bench-budget's binary.
# diagnose reads the runner's source, not the runner. Every other stage is
# free: each writes its own build path (build/dev, build/test,
# build/bench, build/diagnose, build/metrics), and the compile cache
# build/spinel-cache takes concurrent compilers, Spinel storing each
# object by renaming a whole file over it. STAGE_ALONE stages start only
# with no stage running and hold every other start while they run, so
# metrics measures time per key beside no compiler. CHECK_JOBS caps the
# stages running at once (default 3: 4 CPUs, two lanes checking at once).
STAGE_AFTER="test-run:test-build test-run:dev-build gates:test-build metrics:dev-build metrics:test-build metrics:bench-budget"
STAGE_ALONE="metrics"

# Prints why CHECK_JOBS is refused, nothing when it is a positive number.
jobs_refusal() {
  case "${CHECK_JOBS:-3}" in
    *[!0-9]*|'') echo "check: refused: CHECK_JOBS is ${CHECK_JOBS}, not a positive number" ;;
    *) [ "${CHECK_JOBS:-3}" -ge 1 ] || echo "check: refused: CHECK_JOBS is ${CHECK_JOBS}, not a positive number" ;;
  esac
}

# stage_record KEY VALUE: writes a stage record of the runner and keeps
# it in runner_records, "KEY VALUE" lines, so the runner knows the run
# state it expects (escaped_paths).
stage_record() {
  write_key "$1" "$2"
  runner_records="$runner_records$1 $2
"
}

# The stage records this runner wrote as passing (runner_records), each
# rewritten as escaped and its compile record cleared, so no later check
# reuses a pass that files changed outside the clone voided (compiled_same
# would skip a compile stage on it), whether the check reads escaped or
# failed (lane_written). Records of an earlier check stand.
escaped_records() {
  for key in $(printf '%s' "$runner_records" | awk '$2 == "0" { print $1 }' | sort -u); do
    s=${key#stage.}
    record=$(read_key "$key")
    case "$record" in
      "0 "*) stage_record "$key" "escaped $(echo "$record" | cut -d' ' -f2-4)"
        ! one_of "$s" "$COMPILE_STAGES" || compiled_set "$s" "" ;;
    esac
  done
}

# escaped_note PATHS: records the escaped paths, one per line, as a
# security-escape note of the run state, so they outlive the check log a
# rerun rewrites; every byte but a printable one is written "?", so no
# path a stage names can make write_key refuse the note and the check
# end with no verdict.
escaped_note() {
  add_note security-escape "escaped check at $head: $(printf '%s\n' "$1" | head -n 20 |
    LC_ALL=C tr -c '[:print:]\n' '?' | awk 'NR > 1 { printf "; " } { printf "%s", $0 }')"
}

# lane_written PATHS: true when every escaped path, one per line, is a
# path of LANE_WRITTEN under the main checkout seen from a lane, or lies
# under one, which another lane's tools are known to write, so the
# workflow reruns the check with no fix round. LANE_WRITTEN names none by
# default: tree_scan leaves out every build/ directory a lane links in
# (LANE_LINKS), and a lane keeps its metrics and bench logs under itself.
# A write anywhere else, the rest of the main checkout's build/ included
# (its release binary build/bin/carat, build/dev, build/test,
# build/spinel, build/bench, build/metrics), the shared toolchain or
# Spinel's checkout, the user's git configuration, the git directory, the
# main checkout's other files, the delivery clone, or its run state, fails
# the check, its fix round as before (lane-isolation). An entry outside
# build/ or naming a . or .. segment is ignored.
lane_written() {
  [ -n "$main_tree" ] && [ -n "$lane_written_paths" ] || return 1
  printf '%s\n' "$1" | MAIN="$main_tree/" OWNED="$lane_written_paths" awk '
    BEGIN { n = split(ENVIRON["OWNED"], owned, " ") }
    { ok = 0
      for (i = 1; i <= n; i++) {
        p = owned[i]
        if (p !~ /^build\/[A-Za-z0-9_.\/-]+$/ || p ~ /(^|\/)[.][.]?(\/|$)/) continue
        sub(/\/+$/, "", p)
        full = ENVIRON["MAIN"] p
        if ($0 == full || index($0, full "/") == 1) ok = 1
      }
      if (!ok) other = 1 }
    END { exit other }'
}

# stage_launch NAME CMD...: starts CMD as a job in the background, its
# record reading running, its log NAME.log, and "NAME PID SECONDS COMMIT"
# in the runner's job_table; the job ends with CMD's exit status, which the
# runner alone reads with wait, passing a terminate signal on to CMD and
# waiting for it again. No file carries a result, so no stage's code can
# write another's. Only the runner writes the run state.
stage_launch() {
  launch_name=$1
  shift
  launch_log=$stage_dir/$change/$launch_name.log
  launch_at=$(head_commit)
  launch_start=$(date +%s)
  stage_record "stage.$launch_name" "running 0s $launch_at $(utc_now)"
  (
    job_child=''
    trap '[ -z "$job_child" ] || kill -TERM "$job_child" 2> /dev/null' TERM
    "$@" > "$launch_log" 2>&1 < /dev/null &
    job_child=$!
    wait "$job_child"
    job_status=$?
    while kill -0 "$job_child" 2> /dev/null; do
      wait "$job_child"
      job_status=$?
    done
    exit "$job_status"
  ) &
  job_table="$job_table
$launch_name $! $launch_start $launch_at"
  running="$running $launch_name"
}

# job_load NAME: sets job_pid, job_start, and job_at from job_table, empty
# for an unknown job.
job_load() {
  # shellcheck disable=SC2046
  set -- $(printf '%s\n' "$job_table" | sed -n "s/^$1 //p" | tail -n 1)
  job_pid=${1:-}
  job_start=${2:-}
  job_at=${3:-}
}

# job_ended PID: true when the job is gone or ended and not yet waited for
# (kill -0 still succeeds on such a child, so the process table says).
job_ended() {
  job_state=$(ps -o stat= -p "$1" 2> /dev/null | tr -d ' ')
  case "$job_state" in ''|Z*) return 0 ;; esac
  return 1
}

# visible_text: stdin with a tab or NUL as a space and every other control
# byte as "?", so a log's escape sequence never reaches the terminal. The
# C1 controls go too, as the UTF-8 pair C2 80 to C2 9F and as a raw byte
# 80 to 9F, which a terminal acting on 8-bit controls runs as a CSI; the
# raw-byte pass also turns a UTF-8 continuation byte in that range into "?".
visible_text() {
  c1_lead=$(printf '\302')
  c1_low=$(printf '\200')
  c1_high=$(printf '\237')
  tr '\t\000' '  ' | LC_ALL=C sed -e 's/[[:cntrl:]]/?/g' \
    -e "s/${c1_lead}[${c1_low}-${c1_high}]/?/g" \
    -e "s/[${c1_low}-${c1_high}]/?/g"
}

# Starts the queued stages that are ready, in queue order, while fewer
# than CHECK_JOBS run and no STAGE_ALONE stage runs.
stages_start() {
  for s in $running; do
    ! one_of "$s" "$STAGE_ALONE" || return 0
  done
  for s in $queue; do
    # shellcheck disable=SC2086
    set -- $running
    [ $# -lt "${CHECK_JOBS:-3}" ] || return 0
    [ -z "$running" ] || ! one_of "$s" "$STAGE_ALONE" || continue
    ready=1
    for pair in $STAGE_AFTER; do
      [ "${pair%%:*}" = "$s" ] || continue
      ! one_of "${pair#*:}" "$queue $running" || ready=0
    done
    [ "$ready" = 1 ] || continue
    queue=$(echo " $queue " | sed "s/ $s / /; s/^ *//; s/ *\$//")
    # The clone has no release build (make stages leaves out build), so the
    # smoke test runs dev-build's binary, as CI does on a pull request.
    stage_launch "$s" sh -c "$CLONE_EXEC" in_clone "$check_root" "$make_cmd" --no-print-directory check-stage "S=$s" "CARAT_BIN=$CHECK_BIN"
    ! one_of "$s" "$STAGE_ALONE" || return 0
  done
}

# Waits until a running stage ended and records it; returns 1, its name in
# ended, when it did not pass. The status is the job's own exit status.
stages_reap() {
  while :; do
    for s in $running; do
      job_load "$s"
      job_ended "$job_pid" || continue
      wait "$job_pid"
      job_status=$?
      running=$(echo " $running " | sed "s/ $s / /; s/^ *//; s/ *\$//")
      ended=$s
      stage_end "$s" "$job_at" "$job_start" "$job_status" || return 1
      compile_passed "$s"
      return 0
    done
    pause
  done
}

# stages_stop LINE: stops every running stage, its job and command, and
# records it killed, or superseded when HEAD moved, LINE ending its log;
# a stage that ended meanwhile keeps its own record. The runner, detached
# by setsid, leads its process group, which it stops with them.
stages_stop() {
  stop_word=killed
  [ "$(head_commit)" = "$head" ] || stop_word=superseded
  stopped=''
  for s in $running; do
    job_load "$s"
    [ -n "$job_pid" ] || continue
    job_ended "$job_pid" || kill -TERM "$job_pid" 2> /dev/null
  done
  if [ "$(ps -o pgid= -p $$ 2>/dev/null | tr -d ' ')" = "$$" ]; then
    trap '' HUP INT TERM
    kill -TERM 0 2>/dev/null
  fi
  for s in $running; do
    job_load "$s"
    [ -n "$job_pid" ] || continue
    n=0
    while ! job_ended "$job_pid" && [ $n -lt 50 ]; do pause; n=$((n + 1)); done
    if job_ended "$job_pid"; then
      wait "$job_pid"
      job_status=$?
      if ! one_of "$job_status" "$KILLED_STATUSES"; then
        if stage_end "$s" "$job_at" "$job_start" "$job_status" && [ "$stage_word" = 0 ]; then compile_passed "$s"; fi
        continue
      fi
    fi
    echo "$1" >> "$stage_dir/$change/$s.log"
    stage_record "stage.$s" "$stop_word $(( $(date +%s) - job_start ))s $job_at $(utc_now)"
    stopped="$stopped $s"
    echo "stage $s: $stop_word in $(( $(date +%s) - job_start ))s, log $stage_dir/$change/$s.log"
  done
  running=''
}

# True when every path changed from COMMIT to HEAD matches TEST_ONLY; a
# rename counts both paths, so a file moved under test/ is no test-only change.
tests_only_since() {
  rest=$(git diff --no-renames --name-only "$1" HEAD 2>/dev/null) || return 1
  [ -z "$(printf '%s\n' "$rest" | grep -v -E "$TEST_ONLY")" ]
}

# The paths changed from the merge base with BASE to HEAD, a rename
# counting both; nothing when the merge base is unknown.
scope_paths() {
  scope_base=$(git merge-base "${BASE:-origin/main}" HEAD 2>/dev/null) || return 0
  git diff --no-renames --name-only "$scope_base" HEAD 2>/dev/null
}

# out_of_scope STAGE PATHS: true when no path of PATHS is one STAGE checks;
# false for no paths, so an unknown scope runs every stage.
out_of_scope() {
  [ -n "$2" ] && ! one_of "$1" "$ALWAYS_STAGES" || return 1
  if [ "$1" = tools-test ]; then
    ! printf '%s\n' "$2" | grep -q -E "$TOOLS_RE"
    return
  fi
  for scope_path in $2; do
    documentation "$scope_path" || return 1
  done
}

# The merge gates run origin/main's copy (BASE), which requires the stages
# of its Makefile: while that Makefile has CHECK_STAGES and no FAST_STAGES,
# main's CHECK_STAGES; otherwise nothing, and make stages decides.
main_stages() {
  file=$(git show "${BASE:-origin/main}:Makefile" 2> /dev/null) || return 0
  ! printf '%s\n' "$file" | grep -q '^FAST_STAGES := ' || return 0
  printf '%s\n' "$file" | sed -n 's/^CHECK_STAGES := //p'
}

# head_fast_stages: the FAST_STAGES line of the committed Makefile at HEAD,
# read as text; empty when the line is missing or names anything but words
# (a variable, a continuation), so the carry then asks the checker.
head_fast_stages() {
  line=$(git show HEAD:Makefile 2> /dev/null | sed -n 's/^FAST_STAGES := //p')
  case "$line" in
    *[!a-z0-9\ -]*) return 0 ;;
  esac
  printf '%s\n' "$line"
}

# The stages in order: a stage record counts only at BACKED, the last
# commit whose check the workflow recorded (empty: none), or carried from
# it, so a record at HEAD that no workflow record backs runs again. A stage
# passed at BACKED is skipped when BACKED is HEAD, and carried to HEAD when
# it reads no test program and only tests changed since BACKED.
# The runner (check-run) runs them detached from the waiter (check_wait),
# the ones not skipped at once (STAGE_AFTER); the first stage that does not
# pass ends the run with its verdict line.
check_stages() {
  stages=${STAGES:-$(main_stages)}
  [ -n "$stages" ] || stages=$(in_clone "$make_cmd" -s --no-print-directory stages)
  backed=$1
  paths=$(scope_paths)
  # The recorded phase.check, twelve digits, which alone backs a pass of
  # RERUN_STAGES at the head.
  phase_check=$(recorded_check)
  for s in $stages; do
    record=$(read_key "stage.$s")
    at=$(echo "$record" | cut -d' ' -f3)
    from=$(echo "$record" | sed -n 's/.* carried-from-\([0-9a-f]*\)$/\1/p')
    case "$record" in
      "0 "*)
        if one_of "$s" "$RERUN_STAGES" && { [ -z "$phase_check" ] || [ "$backed" != "$phase_check" ]; }; then
          [ -z "$backed" ] || [ "$at" != "$head" ] ||
            echo "stage $s: passed at $head, run again: CI leaves it out and only the recorded phase.check backs its pass"
        elif [ -n "$backed" ] && [ "$at" = "$backed" ] && [ "$at" = "$head" ]; then
          echo "stage $s: passed at $head, skipped"
          continue
        elif [ -n "$backed" ] && { [ "$at" = "$backed" ] || [ "$from" = "$backed" ]; } &&
            ! one_of "$s" "$TEST_STAGES" && tests_only_since "$backed"; then
          stage_record "stage.$s" "0 0s $head $(utc_now) carried-from-$backed"
          echo "stage $s: passed at $backed, carried to $head (only tests changed since)"
          continue
        fi ;;
    esac
    if out_of_scope "$s" "$paths"; then
      stage_record "stage.$s" "0 0s $head $(utc_now) scoped"
      echo "stage $s: no path changed since the merge base is one it checks, skipped"
      continue
    fi
    if one_of "$s" "$COMPILE_STAGES"; then
      key=$(stage_key "$s")
      if compiled_same "$s" "$key"; then
        stage_record "stage.$s" "0 0s $head $(utc_now) compiled-$(echo "$key" | cut -c1-12)"
        echo "stage $s: passed on the same code (key $(echo "$key" | cut -c1-12)) with its outputs unchanged, skipped"
        continue
      fi
      compiled_set "$s" ""
    fi
    queue="$queue $s"
  done
  refused=$(jobs_refusal)
  if [ -n "$refused" ]; then
    echo "$refused"
    verdict_failed
    exit 1
  fi
  # The stages left run at once (stages_start), each in its job; the runner
  # alone writes their records as they end (stages_reap).
  mkdir -p "$stage_dir/$change"
  while [ -n "$queue$running" ]; do
    stages_start
    if ! stages_reap; then
      case "$stage_word" in killed|superseded) word=$stage_word ;; *) word=failed ;; esac
      stages_stop "KILLED: the check stopped after stage $ended $word"
      echo "the last lines of the log of stage $ended:"
      tail -n 20 "$stage_dir/$change/$ended.log" | visible_text | sed 's/^/| /'
      echo "check: stage $ended $word at $head; read $stage_dir/$change/$ended.log"
      exit 1
    fi
  done
  escaped=$(escaped_paths)
  if [ -n "$escaped" ]; then
    echo "check: files outside its clone changed while every stage exited 0, so no pass counts (make toolchain reinstalls a changed toolchain):"
    printf '%s\n' "$escaped" | head -n 20 | sed 's/^/| /'
    escaped_note "$escaped"
    escaped_records
    if lane_written "$escaped"; then
      echo "check: stage none escaped at $head; read $(check_log)"
    else
      verdict_failed
    fi
    exit 1
  fi
  # The workflow records phase.check from the checker's result alone; a
  # check another start ran, the contributor's own included, backs a later
  # check only through these runner records at this very head.
  echo "check: every stage passed at $head; the workflow records the check"
}

# The check's files: the runner's pid file, "PID COMMIT CLONE", while it runs,
# and its output, which ends with its verdict line.
check_pid_file() {
  echo "$stage_dir/$change/check.pid"
}
check_log() {
  echo "$stage_dir/$change/check.log"
}

# True when PID is a live check runner (a reused pid is another program).
runner_alive() {
  [ -n "$1" ] && kill -0 "$1" 2>/dev/null &&
    ps -p "$1" -o args= 2>/dev/null | grep -q 'run_state[.]sh check-run'
}

# The tracked files that differ from HEAD, as status --porcelain lists
# them, read with no optional lock: what the waiter and the runner refuse.
dirty_tracked() {
  GIT_OPTIONAL_LOCKS=0 git status --porcelain --untracked-files=no
}

# The verdict line of a check that failed before any stage ran or after
# every one exited 0, at the runner's head (check_verdict reads it back).
verdict_failed() {
  echo "check: stage none failed at $head; read $(check_log)"
}

# The twelve-digit commit the recorded phase.check names, empty when none is
# recorded or git knows no such commit.
recorded_check() {
  checked=$(read_key phase.check)
  [ -z "$checked" ] || checked=$(git rev-parse --verify -q --short=12 "$checked^{commit}" 2>/dev/null) || checked=""
  printf '%s\n' "$checked"
}

# The verdict line ending the runner's output, empty while it has none:
# only the header's verdict forms, never another line the runner starts
# with "check: " (the escape scan's heading, a refusal, a backing note),
# so a waiter polling between such a line and the verdict keeps waiting.
check_verdict() {
  last=$(tail -1 "$(check_log)" 2>/dev/null)
  case "$last" in
    "check: every stage passed at "*|"check: stage "*" at "*"; read "*) echo "$last" ;;
  esac
}

# check-run BACKED: the runner, started detached by check_wait. It writes
# the pid file, removes it on exit while it still names it, and on a
# hang-up, interrupt, or terminate signal records its running stage as
# killed, or superseded when HEAD moved, and prints that verdict. The
# stages run in the check clone, which it makes first and drops on exit.
check_run() {
  head=$(head_commit)
  pid_file=$(check_pid_file)
  echo "$$ $head" > "$pid_file"
  queue=''
  running=''
  job_table=''
  check_root=''
  trap 'check_signalled HUP' HUP
  trap 'check_signalled INT' INT
  trap 'check_signalled TERM' TERM
  trap 'clone_drop; own=$(cut -d" " -f1 "$pid_file" 2>/dev/null); [ "$own" != "$$" ] || rm -f "$pid_file"' EXIT
  # The waiter's refusal again, at the runner's own start: a runner
  # started over an edited tree (after the waiter's check, or by hand)
  # writes no record, so its pass backs no head; an edit after this line
  # is voided by the escape scan.
  dirty=$(dirty_tracked)
  if [ -n "$dirty" ]; then
    echo "check: refused: tracked files differ from HEAD at the runner's start, so no stage record stands: $(printf '%s\n' "$dirty" | head -3 | tr '\n' ' ')"
    verdict_failed
    exit 1
  fi
  clone_make
  escape_mark
  check_stages "$1"
}

# What a stage could write outside its clone by an absolute path, noted
# before the branch's Makefile first runs (make stages): the time, kept in
# the runner's memory and compared with each file's status-change time,
# which touch cannot set back, taken once a new second began so nothing
# written before it counts; the main checkout when the delivery clone is a
# lane (main_tree, empty otherwise), its branch, HEAD, and state
# (main_view); the repository configuration, the lanes' branches, and the
# references; the staged entries of the delivery clone's index; the run
# state.
escape_mark() {
  escape_since=$(date '+%Y-%m-%d %H:%M:%S')
  while [ "$(date '+%Y-%m-%d %H:%M:%S')" = "$escape_since" ]; do pause; done
  escape_since=$(date '+%Y-%m-%d %H:%M:%S')
  git_dir=$(cd "$(git rev-parse --git-dir)" && pwd -P)
  common_dir=$(cd "$(git rev-parse --git-common-dir)" && pwd -P)
  main_tree=''
  [ "$(basename "$common_dir")" != .git ] || [ "${common_dir%/.git}" = "$top" ] || main_tree=${common_dir%/.git}
  main_branch=''
  escape_main_head=''
  escape_main=''
  if [ -n "$main_tree" ]; then
    main_branch=$(git -C "$main_tree" symbolic-ref -q HEAD)
    escape_main_head=$(git -C "$main_tree" rev-parse -q --verify HEAD)
    escape_main=$(main_view)
  fi
  escape_config=$(config_view)
  escape_lanes=$(lane_branches)
  escape_refs=$(refs_view)
  escape_index=$(index_view "$top")
  escape_state=$(state_view)
}

# The run state's lines, commas removed, of every record but those the
# runner's caller writes again while a rejoined check runs: the figures
# (metric.*) other than the measurements (allocs.*, rounds.*, us.*,
# analysis_ms.*), which only the metrics command imports, since the
# checker's line and /deliver's usage and tokens write figures; and the
# notes (note.*) and the phases a workflow's close records (CLOSE_PHASES),
# since a workflow that stops while its check runs closes.
state_view() {
  close_alternation=$(printf '%s' "$CLOSE_PHASES" | tr ' ' '|')
  sed 's/,$//' "$(state_file)" |
    awk -v closing="^  \"phase[.]($close_alternation)\"" '(!/^  "(metric|note)[.]/ && $0 !~ closing) ||
      /^  "metric[.](allocs|rounds|us|analysis_ms)[.]/'
}

# escape_scan PATH: the paths under PATH, its link followed, changed since
# escape_mark.
escape_scan() {
  [ ! -e "$1" ] || find -H "$1" -newerct "$escape_since" -print 2> /dev/null
}

# The common repository configuration, less the upstream a concurrent
# lane's push -u sets.
config_view() {
  git config --file "$common_dir/config" --list 2> /dev/null |
    grep -v -E '^branch[.].*[.](remote|merge)='
}

# The branches checked out in a linked worktree other than the delivery
# clone and the main checkout (the first one listed), which their own
# lanes commit to and the merger deletes once it removed their worktree.
lane_branches() {
  git -C "$top" worktree list --porcelain 2> /dev/null |
    OWN=$(git -C "$top" symbolic-ref -q HEAD) awk '/^worktree / { n++ } /^branch / && n > 1 && $2 != ENVIRON["OWN"] { print $2 }'
}

# The references of the common repository, name and object, less the
# remote-tracking refs, which a fetch or push of any lane rewrites and the
# next fetch restores, the lanes' branches at escape_mark or now
# (lane_branches), and from a lane the main checkout's branch, which the
# merger fast-forwards (main_moved).
refs_view() {
  git -C "$top" for-each-ref --format='%(refname) %(objectname)' 2> /dev/null |
    SKIP="$escape_lanes
$(lane_branches)
$main_branch" awk 'BEGIN { n = split(ENVIRON["SKIP"], l, "\n"); for (i = 1; i <= n; i++) if (l[i] != "") skip[l[i]] = 1 }
      $1 !~ /^refs\/remotes\// && !($1 in skip)'
}

# index_view DIR: the staged entries of DIR's index (mode, object, stage,
# path, and the assume-unchanged tag), read with no optional lock, so a
# stat refresh, which rewrites the file, leaves them.
index_view() {
  GIT_OPTIONAL_LOCKS=0 git -C "$1" ls-files --stage -v 2> /dev/null
}

# tree_scan DIR [TEST...]: the paths of the work tree DIR passing the find
# TESTs changed since escape_mark, without following links, but its git
# directory, tmp/ (the lanes and toolchain links), and the run
# states, stage logs, plans, and compile cache, which concurrent lanes and
# the runner write.
tree_scan() {
  scan_dir=$1
  shift
  tree_find "$scan_dir" -print "$@"
}

# tree_find DIR ACTION [TEST...]: tree_scan's find with ACTION (-print, or
# -print0 for names holding a newline) in place of -print.
tree_find() {
  scan_dir=$1
  scan_action=$2
  shift 2
  find "$scan_dir" \( -path "$scan_dir/.git" -type d -o -path "$scan_dir/tmp" -o -path "$scan_dir/build/pipeline" -o \
      -path "$scan_dir/build/stages" -o -path "$scan_dir/build/plan" -o -path "$scan_dir/build/spinel-cache" \) -prune -o \
    "$@" -newerct "$escape_since" "$scan_action" 2> /dev/null
}

# The main checkout's files changed since escape_mark (tree_scan) that it
# does not track, directories left out, and the logs of its build/ itself
# (build/NAME.log, which another lane's benchmark agent redirects its make
# output into and nothing runs), but not the files under build/bin, build/dev,
# or any other directory of it: the merger's fast-forward of its
# branch changes only tracked files, which main_view compares.
main_scan() {
  # Both lists NUL-separated, read by awk as records ended by a byte 1, so
  # a path holding a tab, newline, quote, or backslash, which git quotes
  # in its line form, still matches the one find prints.
  { git -C "$main_tree" ls-files -z 2> /dev/null | tr '\0' '\001' | MAIN="$main_tree" awk -v RS='\001' -v ORS='\001' '{ print "T " ENVIRON["MAIN"] "/" $0 }'
    tree_find "$main_tree" -print0 ! -type d ! '(' -path "$main_tree/build/*.log" ! -path "$main_tree/build/*/*" ')' | tr '\0' '\001' | awk -v RS='\001' -v ORS='\001' '{ print "F " $0 }'; } |
    awk -v RS='\001' -v ORS='\n' '/^T / { tracked[substr($0, 3)] = 1; next } !(substr($0, 3) in tracked) { print substr($0, 3) }'
}

# What the main checkout holds against its HEAD, which the merger's
# fast-forward leaves: its status (the index against HEAD, the work tree
# against the index, the files it neither tracks nor ignores) and the
# index entries a flag hides from it, read with no optional lock.
main_view() {
  GIT_OPTIONAL_LOCKS=0 git -C "$main_tree" status --porcelain --untracked-files=all 2> /dev/null
  GIT_OPTIONAL_LOCKS=0 git -C "$main_tree" ls-files -v 2> /dev/null | grep -v '^H '
}

# bounded COMMAND...: COMMAND with at most 60 seconds where timeout exists,
# so a stalled connection or a prompt cannot hold a check.
bounded() {
  if command -v timeout > /dev/null 2>&1; then timeout 60 "$@"; else "$@"; fi
}

# True when the main checkout's HEAD names another commit than at
# escape_mark and not the one origin's branch names, where the merger's
# fast-forward takes it, read from origin itself (ls-remote): a stage can
# write the remote-tracking ref, which refs_view leaves out, but not
# origin, whose address config_view compares. An unreachable origin or a
# detached main checkout, whose empty branch names no ref, counts as moved.
main_moved() {
  main_ref=$(git -C "$main_tree" symbolic-ref -q HEAD)
  [ "$main_ref" = "$main_branch" ] || return 0
  main_head=$(git -C "$main_tree" rev-parse -q --verify HEAD)
  [ "$main_head" != "$escape_main_head" ] || return 1
  origin_head=$(GIT_TERMINAL_PROMPT=0 bounded git -C "$main_tree" ls-remote origin "$main_branch" 2> /dev/null |
    REF="$main_branch" awk '$2 == ENVIRON["REF"] { print $1; exit }')
  [ -z "$origin_head" ] || [ "$main_head" != "$origin_head" ]
}

# The paths changed since escape_mark outside the clone, one per line: the
# delivery clone's files (tree_scan); a linked worktree's git directory but
# its own entry and its index, which any git status refreshes; the hooks,
# info/, and config.worktree of the common directory; the user's git
# configuration; the shared toolchain and Spinel's checkout; from a lane,
# the main checkout's untracked files (main_scan), its state when it
# differs (main_view), and its HEAD when it moved (main_moved); then the
# configuration file when the repository configuration differs
# (config_view), the references when they differ (refs_view), the index
# when its staged entries differ (index_view), and the run state file when
# it holds records the runner did not write (state_unexpected).
escaped_paths() {
  tree_scan "$top"
  [ "$git_dir" = "$common_dir" ] ||
    find -H "$git_dir" -mindepth 1 \( -path "$git_dir/index" -o -path "$git_dir/index.lock" \) -prune -o \
      -newerct "$escape_since" -print 2> /dev/null
  escape_scan "$common_dir/hooks"
  escape_scan "$common_dir/info"
  escape_scan "$common_dir/config.worktree"
  # The files the user's later sessions run or read: the global git
  # configuration (also under XDG_CONFIG_HOME and ~/.config/git), the shell
  # startup files, and the agent hooks' settings. Not ~/.claude as a whole,
  # which the session itself writes.
  if [ -n "${HOME:-}" ]; then
    for home_file in .gitconfig .config/git .profile .bash_profile .bash_login .bashrc .zprofile .zshenv .zshrc .claude/settings.json .claude/settings.local.json; do
      escape_scan "$HOME/$home_file"
    done
  fi
  [ -z "${XDG_CONFIG_HOME:-}" ] || [ "$XDG_CONFIG_HOME" = "${HOME:-}/.config" ] || escape_scan "$XDG_CONFIG_HOME/git"
  escape_scan "$top/tmp/.toolchain"
  escape_scan "$top/tmp/.spinel"
  if [ -n "$main_tree" ]; then
    main_scan
    [ "$(main_view)" = "$escape_main" ] || echo "$main_tree: the main checkout's files or staged files changed"
    ! main_moved || echo "$common_dir/HEAD: the main checkout moved"
  fi
  [ "$(config_view)" = "$escape_config" ] || echo "$common_dir/config: the configuration changed"
  [ "$(refs_view)" = "$escape_refs" ] || echo "$common_dir/refs: the references changed"
  [ "$(index_view "$top")" = "$escape_index" ] || echo "$git_dir/index: the staged files changed"
  state_unexpected
}

# The run state file when it differs from the one escape_mark noted with
# the stage records the runner wrote since put in (stage_record).
state_unexpected() {
  expected=$(printf '%s' "$runner_records" | SNAP="$escape_state" awk '
    NF { key = $1; rec[key] = substr($0, length(key) + 2) }
    END {
      n = split(ENVIRON["SNAP"], lines, "\n")
      for (i = 1; i <= n; i++) {
        line = lines[i]
        if (line ~ /^  "/) {
          key = line; sub(/^  "/, "", key); sub(/".*/, "", key)
          if (key in rec) continue
        }
        print line
      }
      for (key in rec) print "  \"" key "\": \"" rec[key] "\""
    }' | LC_ALL=C sort)
  [ "$(state_view | LC_ALL=C sort)" = "$expected" ] ||
    echo "$(state_file): records the runner did not write"
}

# The gates' git: no global or system configuration and no hook.
pinned_git() {
  GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -c core.hooksPath=/dev/null "$@"
}

# The check clone: a new repository under TMPDIR, outside the delivery
# clone, holding HEAD on the branch's name and origin/main by one fetch
# (objects copied into a pack: no hard link, no alternates, no remote, the
# sample hooks only), its own copy of the toolchain, and build/ from the
# carry.
# What a stage writes in its directory (hooks, configuration, refs,
# build/pipeline) stays in it and is removed with it.
clone_make() {
  top=$(pwd -P)
  check_root=$(mktemp -d "${TMPDIR:-/tmp}/carat-check.XXXXXX") ||
    clone_refused "mktemp failed"
  echo "$$ $head $check_root" > "$pid_file"
  branch=$(git symbolic-ref -q --short HEAD) || branch=check
  refs="+HEAD:refs/heads/$branch"
  ! git rev-parse -q --verify refs/remotes/origin/main > /dev/null ||
    refs="$refs +refs/remotes/origin/main:refs/remotes/origin/main"
  pinned_git init -q "$check_root/repo" > /dev/null 2>&1 || clone_refused "git init failed"
  check_root=$check_root/repo
  # shellcheck disable=SC2086
  pinned_git -C "$check_root" fetch -q --no-tags "$top" $refs 2>&1 || clone_refused "the fetch failed"
  [ "$(git -C "$check_root" rev-parse -q --verify --short=12 "refs/heads/$branch")" = "$head" ] ||
    clone_refused "HEAD moved from $head"
  pinned_git -C "$check_root" checkout -q "$branch" 2>&1 || clone_refused "the checkout failed"
  mkdir -p "$check_root/tmp" "$check_root/build"
  toolchain_copy
  carry=$stage_dir/$change/carry
  [ ! -d "$carry" ] || { cp -RP "$carry/." "$check_root/build/" && find "$check_root/build" -type l -exec rm -f {} +; }
  clone_plan
}

# The plan files the gates stage reads to prove a records carrier's groomed
# findings, the sprint marker and groom.txt, copied from the delivery
# clone's plan directory into the clone: read there, never written back (a
# regular file only, no link), the rest of the plan staying out.
clone_plan() {
  [ -d "$plan_dir" ] || return 0
  for plan_file in sprint sprint.applied groom.txt; do
    [ -f "$plan_dir/$plan_file" ] && [ ! -L "$plan_dir/$plan_file" ] || continue
    mkdir -p "$check_root/build/plan" && cp "$plan_dir/$plan_file" "$check_root/build/plan/$plan_file"
  done
}

# The clone's own copy of the shared toolchain, each absolute link into
# the shared one (Spinel installs bin/spinel as one) pointed at the same
# place in the copy, so a stage writing tmp/.toolchain changes only its
# copy. Spinel's checkout, tmp/.spinel, which no stage reads, stays out.
toolchain_copy() {
  [ -d "$top/tmp/.toolchain" ] || return 0
  shared=$(cd -P "$top/tmp/.toolchain" && pwd -P) || clone_refused "the toolchain could not be read"
  copy=$check_root/tmp/.toolchain
  { mkdir "$copy" && cp -RP "$shared/." "$copy/"; } 2>&1 || clone_refused "the toolchain copy failed"
  find "$copy" -type l | while IFS= read -r link; do
    target=$(readlink "$link")
    case "$target" in
      "$shared"/*) rel=${target#"$shared"} ;;
      "$top/tmp/.toolchain"/*) rel=${target#"$top/tmp/.toolchain"} ;;
      *) continue ;;
    esac
    rm -f "$link" && ln -s "$copy$rel" "$link"
  done
}

clone_refused() {
  echo "check: the check clone could not be made: $1"
  verdict_failed
  exit 1
}

# in_clone COMMAND...: runs COMMAND in the check clone, with no path to
# the delivery clone's run state, stages, or project in its environment and
# HOME a throwaway directory inside the clone (tmp/home) with no XDG
# configuration directory, so a stage that writes "~" writes the clone, not
# the profile, shell startup files, or git configuration of the user who ran
# the check; sh execs it, so a stage's parent stays the runner.
CLONE_EXEC='cd "$1" && shift && unset RUN_STATE_DIR STAGE_DIR METRICS_OUT CLAUDE_PROJECT_DIR XDG_CONFIG_HOME && HOME=$PWD/tmp/home && mkdir -p "$HOME" && export HOME && exec "$@"'
in_clone() {
  sh -c "$CLONE_EXEC" in_clone "$check_root" "$@"
}

# Removes the clone a runner gone past its trap left, named by its pid
# file, only when it is a check clone under TMPDIR.
clone_lost() {
  lost_root=$(cut -d' ' -f3 "$(check_pid_file)" 2> /dev/null)
  case "${lost_root#"${TMPDIR:-/tmp}/carat-check."}" in
    "$lost_root"|''|*[!A-Za-z0-9]*) return 0 ;;
  esac
  chmod -R u+w "$lost_root" 2> /dev/null
  rm -rf "$lost_root"
}

# Keeps the clone's build/ in the carry, without the records a stage could
# have planted, and its metrics in METRICS_OUT, then removes the clone.
clone_drop() {
  [ -n "$check_root" ] || return 0
  root=${check_root%/repo}
  check_root=''
  if [ -d "$root/repo/build" ]; then
    carry=$stage_dir/$change/carry
    rm -rf "$carry"
    mkdir -p "$carry" && cp -RP "$root/repo/build/." "$carry/" 2> /dev/null
    rm -rf "$carry/pipeline" "$carry/stages" "$carry/plan"
    # No link a stage planted in build/ reaches the carry and the next clone.
    find "$carry" -type l -exec rm -f {} + 2> /dev/null
    if [ -f "$root/repo/build/metrics/current.tsv" ]; then
      mkdir -p "$(dirname "$metrics_out")" && cp "$root/repo/build/metrics/current.tsv" "$metrics_out"
    fi
  fi
  chmod -R u+w "$root" 2> /dev/null
  rm -rf "$root"
}

check_signalled() {
  trap '' HUP INT TERM
  signal=$1
  word=killed
  [ "$(head_commit)" = "$head" ] || word=superseded
  # Every running stage stops and is recorded; the verdict names the first.
  first=''
  if [ -n "$running" ]; then
    stages_stop "KILLED: the check received SIG$signal during the stage"
    first=${stopped# }
    first=${first%% *}
  fi
  if [ -n "$first" ]; then
    echo "check: stage $first $word at $head; read $stage_dir/$change/$first.log"
  else
    [ "$(ps -o pgid= -p $$ 2>/dev/null | tr -d ' ')" != "$$" ] || kill -TERM 0 2>/dev/null
    echo "check: stage none $word at $head; read $(check_log)"
  fi
  exit 1
}

# A runner gone without a verdict (killed by a signal it cannot trap):
# its running stage, if any, is recorded as killed and its log says so;
# prints the verdict line and appends it to the runner's output.
check_lost() {
  at=$1
  clone_lost
  lost=$(keys_under stage. | sed -n 's/^\([^=]*\)=running \(.*\)$/\1 \2/p')
  # Every stage the runner left running is recorded killed; the verdict
  # names the first.
  first=''
  while read -r s rest; do
    [ -n "$s" ] || continue
    [ -n "$first" ] || first=$s
    echo "KILLED: the check ended without a verdict during the stage" >> "$stage_dir/$change/$s.log"
    write_key "stage.$s" "killed $rest"
  done <<LOST
$lost
LOST
  if [ -n "$first" ]; then
    line="check: stage $first killed at $at; read $stage_dir/$change/$first.log"
  else
    line="check: stage none killed at $at; read $(check_log)"
  fi
  echo "$line" >> "$(check_log)"
  echo "$line"
}

# check BACKED: refuse a dirty tree, then rejoin the runner running at
# HEAD, stop one at another commit (its verdict reads superseded), or
# start one detached from this shell (setsid), so the end of the caller's
# turn or tool call cannot kill the stages. Waits at most CHECK_WAIT
# seconds: prints the runner's output and exits 0 when every stage
# passed, 1 otherwise, and 3 while it still runs.
check_wait() {
  # No optional lock: a waiter rejoining a running check leaves the index,
  # which escaped_paths reads in a linked worktree's git directory.
  dirty=$(dirty_tracked)
  [ -z "$dirty" ] || die "check: refused: tracked files differ from HEAD; commit them first: $(printf '%s\n' "$dirty" | head -3 | tr '\n' ' ')"
  loose=$(git ls-files --others --exclude-standard -- carat bin test bench)
  [ -z "$loose" ] || die "check: refused: untracked files under carat/, bin/, test/, or bench/, which spin compiles: $(printf '%s\n' "$loose" | head -3 | tr '\n' ' ')"
  refused=$(jobs_refusal)
  [ -z "$refused" ] || die "$refused"
  [ -f "$(state_file)" ] || die "no run state for $change; run init first"
  mkdir -p "$stage_dir/$change"
  head=$(head_commit)
  pid_file=$(check_pid_file)
  pid=''
  at=''
  [ ! -f "$pid_file" ] || read -r pid at _ < "$pid_file"
  runner_finish "$pid"
  joined=0
  if runner_alive "$pid" && [ "$at" = "$head" ]; then
    echo "check: rejoining the check running at $head (pid $pid)"
    joined=1
  elif runner_alive "$pid"; then
    echo "check: the check running at $at is superseded by $head; stopping it"
    kill -TERM "$pid" 2>/dev/null
    runner_wait "$pid"
    echo "the superseded check: $(check_verdict)"
  elif [ -f "$pid_file" ]; then
    [ -n "$(check_verdict)" ] || echo "the last check: $(check_lost "$at")"
  fi
  if [ "$joined" = 0 ]; then
    rm -f "$pid_file"
    : > "$(check_log)"
    if command -v setsid > /dev/null 2>&1; then
      setsid -f sh "$here/run_state.sh" check-run "$change" ${1:+"$1"} > "$(check_log)" 2>&1 < /dev/null
    else
      (sh "$here/run_state.sh" check-run "$change" ${1:+"$1"} > "$(check_log)" 2>&1 < /dev/null &)
    fi
  fi
  begun=$(date +%s)
  limit=${CHECK_WAIT:-540}
  seen=$joined
  while :; do
    verdict=$(check_verdict)
    [ -z "$verdict" ] || break
    read_pid
    if runner_alive "$pid"; then
      seen=1
    elif [ -n "$pid" ] || [ "$seen" = 1 ] || [ $(( $(date +%s) - begun )) -ge 10 ]; then
      # Gone, or never started, without a verdict: the pid file holds
      # only the runner started or rejoined here.
      [ -n "$(check_verdict)" ] || check_lost "$head" > /dev/null
      rm -f "$pid_file"
      continue
    fi
    if [ $(( $(date +%s) - begun )) -ge "$limit" ]; then
      echo "check: still running at $head (pid $pid, $(( $(date +%s) - begun ))s waited); run the same command again to wait"
      exit 3
    fi
    pause
  done
  read_pid
  runner_finish "$pid"
  cat "$(check_log)"
  case "$verdict" in "check: every stage passed at "*) return 0 ;; esac
  return 1
}

# The pid file's runner and commit as pid and at, empty without one.
read_pid() {
  pid=''
  at=''
  [ ! -f "$pid_file" ] || read -r pid at _ 2>/dev/null < "$pid_file" || true
}

# runner_finish PID: a runner prints its verdict, then drops its clone and
# its pid file; waits, at most 30 seconds, for one that printed its verdict
# to exit, so a check returns with no runner behind it and the next check
# neither rejoins a finished runner nor shares the carry it still writes.
runner_finish() {
  runner_wait "$1" finished
}

# runner_wait PID [finished]: waits, at most 30 seconds by the clock, for
# the runner PID to exit; with "finished", only while its output already
# ends in its verdict. The one wait runner_finish and the superseding of a
# runner in check_wait share.
runner_wait() {
  began=$(date +%s)
  while runner_alive "$1" && { [ "${2:-}" != finished ] || [ -n "$(check_verdict)" ]; } && [ $(( $(date +%s) - began )) -lt 30 ]; do
    pause
  done
}

# A fifth of a second, or a second where sleep takes whole seconds only.
pause() {
  sleep 0.2 2>/dev/null || sleep 1
}

# The key of the code the compile stages read: the blobs of every tracked
# path at HEAD but those NOT_COMPILED names (BUILD_TOOLS excepted), hashed.
code_key() {
  skip=$NOT_COMPILED
  # dev-build compiles bin/carat.rb and what it requires, never a test or a
  # benchmark, so a commit to test/ or bench/ keeps its key.
  [ "${1:-}" != dev-build ] || skip="$NOT_COMPILED|^(test|bench)/"
  git ls-tree -r --full-tree HEAD |
    awk -F'\t' -v skip="$skip" -v keep="$BUILD_TOOLS" '$2 !~ skip || $2 ~ keep' |
    git hash-object --stdin
}

# stage_key STAGE: the key a pass of the compile stage STAGE is cached by,
# its code key and the make command that ran it, so a pass under another
# command (MAKE=true records a stage that never ran) skips no later run.
stage_key() {
  printf '%s\n%s\n' "$(code_key "$1")" "$make_cmd" | git hash-object --stdin
}

# compile_passed STAGE: records a passed compile stage on its key and its
# outputs (compiled_set), as the one place that reaps or stops it does; a
# stage outside COMPILE_STAGES is left alone.
compile_passed() {
  ! one_of "$1" "$COMPILE_STAGES" || compiled_set "$1" "$(stage_key "$1") $(outputs_sum "$1")"
}

# The editor binary every check stage gets as CARAT_BIN: the Makefile's
# DEV_BIN, the one source, which dev-build writes before test-run's smoke
# test runs it (tools/tools_test.sh fails when the two paths differ).
CHECK_BIN=build/dev/carat

# The outputs of a compile stage, which later stages read (test-run and
# metrics), as the Makefile names them (DEV_BIN, TEST_BIN).
compile_outputs() {
  case "$1" in
    dev-build) echo build/dev/carat build/dev/carat.timing ;;
    test-build) echo build/test/run_all build/test/run_all.timing ;;
  esac
}

# The checksum of a compile stage's outputs: "-" without outputs, "missing"
# when one is absent.
outputs_sum() {
  files=$(compile_outputs "$1")
  [ -n "$files" ] || { echo -; return; }
  for f in $files; do [ -f "${check_root:-.}/$f" ] || { echo missing; return; }; done
  # shellcheck disable=SC2086
  (cd "${check_root:-.}" && cat $files) | cksum | tr ' ' '-'
}

# True when the compile stage last passed on KEY and its outputs still have
# the checksum that pass left (COMPILED).
compiled_same() {
  [ -f "$compiled_file" ] || return 1
  sum=$(outputs_sum "$1")
  [ "$sum" != missing ] || return 1
  awk -v s="$1" -v k="$2 $sum" '$1 == s { found = (substr($0, length(s) + 2) == k) } END { exit !found }' "$compiled_file"
}

# compiled_set STAGE VALUE: the stage's line of COMPILED, "KEY SUM", or none
# when VALUE is empty.
compiled_set() {
  mkdir -p "$state_dir"
  touch "$compiled_file"
  awk -v s="$1" -v v="$2" '$1 != s { print } END { if (v != "") print s " " v }' "$compiled_file" > "$compiled_file.tmp.$$" &&
    mv "$compiled_file.tmp.$$" "$compiled_file"
}

# scope COMMIT [FILE...]: whether the fix since COMMIT stays within the
# files the blocking findings at COMMIT name, tests, and the OpenSpec and
# planning records (TEST_ONLY), so the next quality review may read only
# its diff; renames count both paths.
fix_scope() {
  since=$(commit_at "$1") || exit 1
  shift
  for f in "$@"; do
    valid '[A-Za-z0-9_][A-Za-z0-9_./-]*' "$f" && parent_free "$f" || die "scope: not a plain relative path: $f"
  done
  rest=$(git diff --no-renames --name-only "$since" HEAD) || die "scope: git diff failed"
  if [ -z "$rest" ]; then
    echo "branch: nothing changed since $since; review the whole branch diff"
    return 1
  fi
  other=$(printf '%s\n' "$rest" | while IFS= read -r path; do
    printf '%s\n' "$path" | grep -q -E "$TEST_ONLY" && continue
    named=0
    for f in "$@"; do [ "$f" != "$path" ] || named=1; done
    [ "$named" -eq 1 ] || { printf '%s\n' "$path"; break; }
  done)
  if [ -n "$other" ]; then
    echo "branch: $other changed since $since and no blocking finding names it; review the whole branch diff"
    return 1
  fi
  echo "fix: review only git diff $since HEAD against the findings and the rules"
}

# Whether an advisory-only fix round may stand on the check, security
# review, and benchmark of COMMIT, an ancestor of HEAD (review-lite): every
# path changed from COMMIT to HEAD matches RECORDS_RE, the paths main's
# merge gates settle a pass across (settled_at in tools/gates.sh), with
# docs/sprints.tsv refused outright, since the gates take only groom's row
# there, and an instruction record (INSTRUCTION_RECORDS_RE) too, since the
# gates settle no pass across it; the tracked tree clean. Exit 1 names what
# keeps the full round.
settled_round() {
  since=$(commit_at "$1") || exit 1
  now=$(git rev-parse --verify -q --short=12 HEAD) || die "settled: no HEAD"
  if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    echo "unsettled: tracked files differ from HEAD; run the full round"
    return 1
  fi
  if ! git merge-base --is-ancestor "$since" HEAD 2>/dev/null; then
    echo "unsettled: $since is not an ancestor of HEAD $now; run the full round"
    return 1
  fi
  rest=$(git diff --no-renames --name-only --end-of-options "$since" HEAD --) || die "settled: git diff failed"
  if [ -z "$rest" ]; then
    echo "unsettled: nothing changed since $since; run the full round"
    return 1
  fi
  other=$(printf '%s\n' "$rest" | outside_records | sort -u | tr '\n' ' ')
  printf '%s\n' "$rest" | grep -q -x -F docs/sprints.tsv && other="${other}docs/sprints.tsv "
  if [ -n "$other" ]; then
    echo "unsettled: ${other% } changed since $since outside the records a pass settles across; run the full round"
    return 1
  fi
  echo "settled: only records changed from $since to $now: $(printf '%s\n' "$rest" | tr '\n' ' ' | sed 's/ $//')"
}

# True when PATH has no parent step (..) as a segment.
parent_free() {
  case "/$1/" in */../*) return 1 ;; esac
}

count() {
  value=$(read_key "$1")
  echo "${value:-0}"
}

# The merge gates' first step: every run state under the run state's
# directory holding a gated value other than none, not only this change's,
# gets none, since the merge tool's hook reads them all and branch code run
# by the checks can plant one. A file that cannot be rewritten fails it.
gated_clear() {
  for other in "$state_dir"/*.json; do
    grep -s '"gated"' "$other" | grep -q -v -E '^  "gated": "none",?$' || continue
    (change=$(basename "$other" .json) && write_key gated none) || return 1
  done
  write_key gated none
}

push_branch() {
  pushes=$(count pushes)
  fixes=$(count ci_fixes)
  reviews=$(count review_fixes)
  moved=$(count main_moved)
  texts=$(count pr_text_fixes)
  case "${1:-}" in
    --ci-fix)
      case "$(read_key ci)" in
        red*) fixes=$((fixes + 1)) ;;
        *) die "push: refused: a CI fix push needs a red CI run recorded (ci)" ;;
      esac ;;
    --review-fix)
      [ "$reviews" -eq 0 ] || die "push: refused: $reviews review fix push(es) made; one is allowed a run"
      pushed=$(read_key pushed)
      [ -n "$pushed" ] && [ "$pushed" != "$(git rev-parse HEAD)" ] ||
        die "push: refused: a review fix push needs a recorded push other than HEAD (pushed)"
      reviews=1 ;;
    --main-moved)
      [ "$moved" -eq 0 ] || die "push: refused: $moved main-moved push(es) made; one is allowed a run"
      pushed=$(read_key pushed)
      [ -n "$pushed" ] && [ "$pushed" != "$(git rev-parse HEAD)" ] ||
        die "push: refused: a main-moved push needs a recorded push other than HEAD (pushed)"
      base=${BASE:-origin/main}
      git merge-base --is-ancestor "$base" HEAD && ! git merge-base --is-ancestor "$base" "$pushed" ||
        die "push: refused: a main-moved push needs a HEAD holding $base that the recorded push does not (run merge-main)"
      moved=1 ;;
    --pr-text)
      [ "$texts" -eq 0 ] || die "push: refused: $texts pull request text push(es) made; one is allowed a run"
      pushed=$(read_key pushed)
      [ -n "$pushed" ] && [ "$pushed" != "$(git rev-parse HEAD)" ] ||
        die "push: refused: a pull request text push needs a recorded push other than HEAD (pushed)"
      # It rewrites the archived pr.md and nothing else: the records paths
      # a review settles across hold specs and goals nobody reviewed again.
      text_paths=$(git diff --no-renames --name-only --end-of-options "$pushed" HEAD --) ||
        die "push: refused: git diff failed comparing the pushed head $pushed with HEAD"
      text_other=$(printf '%s\n' "$text_paths" | grep -v -x -E "openspec/changes/archive/[0-9]{4}-[0-9]{2}-[0-9]{2}-$change/pr[.]md" | grep . | head -n 3 | tr '\n' ' ') || true
      [ -z "$text_other" ] || die "push: refused: a pull request text push rewrites only the archived pr.md of $change, not ${text_other% }"
      texts=1 ;;
    "") ;;
    *) die "push: unknown push kind: $1 (--ci-fix, --review-fix, --main-moved, or --pr-text)" ;;
  esac
  if [ "$pushes" -ge $((1 + fixes + reviews + moved + texts)) ]; then
    die "push: refused: $pushes push(es) made; one is allowed, plus one per CI fix ($fixes), one review fix ($reviews), one main-moved push ($moved), and one pull request text push ($texts)"
  fi
  branch=$(git rev-parse --abbrev-ref HEAD)
  [ "$branch" != "main" ] || die "push: refused: never push main"
  over=$(queue_over)
  [ -z "$over" ] || die "push: refused: $over"
  if ! CHANGE=$change sh "$here/gates.sh" pre-push; then
    write_key gates_failed $(($(count gates_failed) + 1))
    die "push: refused: the pre-push gates failed"
  fi
  git push -u origin "$branch" || die "push: git push failed"
  write_key pushes $((pushes + 1))
  write_key ci_fixes "$fixes"
  [ "$reviews" -eq 0 ] || write_key review_fixes "$reviews"
  [ "$moved" -eq 0 ] || write_key main_moved "$moved"
  [ "$texts" -eq 0 ] || write_key pr_text_fixes "$texts"
  write_key pushed "$(git rev-parse HEAD)"
  # A new head needs the merge gates again, and a marker branch code
  # planted in this run state before the push is gone; the merge gates
  # clear every other run state's (gated_clear).
  write_key gated none
}

show_status() {
  for q in $queue_files; do
    if [ -f "$q" ]; then
      echo "== queue ($q)"
      cat "$q"
    else
      echo "queue: none ($q does not exist)"
    fi
  done
  running=""
  for file in $(ls -t "$state_dir"/*.json 2>/dev/null); do
    change=$(basename "$file" .json)
    if [ -z "$(read_key merged)" ]; then running=$change; break; fi
  done
  if [ -n "$running" ]; then
    change=$running
    done_list=""
    next=""
    for p in $PHASES; do
      if [ -n "$(read_key "phase.$p")" ]; then done_list="$done_list $p"
      elif [ -z "$next" ]; then next=$p; fi
    done
    echo "== running: $change on $(read_key branch)"
    echo "phases done:${done_list:- none}"
    echo "next phase: ${next:-none}"
    grep -E '"(stage|review)\.|"(pr|ci|pushes)"' "$(state_file)" | sed 's/^  /  /; s/,$//'
  else
    echo "running: none"
  fi
  history=$(history_rows)
  if [ "$(printf '%s\n' "$history" | wc -l)" -gt 1 ]; then
    echo "== last metrics row ($metrics_files)"
    printf '%s\n' "$history" | sed -n '1p;$p'
    printf '%s\n' "$history" | rates
  else
    echo "metrics: none ($metrics_files hold no row)"
  fi
}

# The first-pass rate of each gate and the rework rounds over the history.
rates() {
  awk -F'\t' '
    NR > 1 && $6 != "-" {
      rows++
      n = split($6, pairs, ",")
      for (i = 1; i <= n; i++) {
        split(pairs[i], kv, ":")
        if (!(kv[1] in tried)) order[++gates] = kv[1]
        tried[kv[1]]++
        if (kv[2] == "1") passed[kv[1]]++
      }
    }
    NR > 1 && $5 != "-" { rework += $5; changes++ }
    END {
      line = "first-pass rates over " rows + 0 " change(s):"
      for (i = 1; i <= gates; i++) line = line " " order[i] " " passed[order[i]] + 0 "/" tried[order[i]]
      print line
      print "rework rounds: " rework + 0 " over " changes + 0 " change(s)"
    }'
}

# True when VALUE matches PATTERN whole; a value holding a control
# character never does, since grep -x would match it one line at a time.
valid() {
  case "$2" in *[[:cntrl:]]*) return 1 ;; esac
  printf '%s' "$2" | grep -q -x -E "$1"
}

record_metric() {
  name=${1%%=*}
  value=${1#*=}
  case "$1" in *=*) ;; *) die "metric: $1 is not NAME=VALUE" ;; esac
  valid '[a-z0-9_.-]+' "$name" || die "metric: not a metric name: $name"
  valid '[A-Za-z0-9_.,:/=+-]*' "$value" || die "metric: $name: not a metric value: $value"
  write_key "metric.$name" "$value"
}

import_metrics() {
  [ -f "$1" ] || die "metrics: no measurement $1"
  recorded=0
  skipped=0
  while IFS="$TAB" read -r name value; do
    [ -n "$name" ] || continue
    # tools/metrics.sh writes ? for a value it could not measure; an
    # unmeasured value is not stored, and a figure an earlier import
    # recorded for it is removed so it does not pass for this one.
    if [ "$value" = "?" ]; then
      valid '[a-z0-9_.-]+' "$name" || die "metrics: not a metric name: $name"
      drop_key "metric.$name"
      skipped=$((skipped + 1))
      continue
    fi
    record_metric "$name=$value"
    recorded=$((recorded + 1))
  done < "$1"
  echo "metrics: recorded $recorded measurement(s) of $change, skipped $skipped unmeasured"
}

# The squash commit of the change, merged, when it is 7 to 40 hexadecimal
# digits; nothing otherwise, so no stored value reaches git as an option.
# Every git call on it also passes it after --end-of-options.
merged_commit() {
  merged=$(read_key merged)
  valid '[0-9a-f]{7,40}' "$merged" && echo "$merged"
  return 0
}

# The newest merged change without a history row, by its squash commit's
# time; nothing when none is pending.
newest_pending() {
  for name in $(pending_list); do
    merged=$(change=$name; merged_commit)
    printf '%s %s\n' "$(git log -1 --format=%ct --end-of-options "$merged" -- 2>/dev/null || echo 0)" "$name"
  done | sort -n -k1,1 | tail -1 | cut -d' ' -f2
}

# Main's measured figures, stored once per main commit (cache-reuse): a
# first line "main FULLSHA", then "name<TAB>value" lines, in the shared run
# state directory, which no lane's check scans for writes. Only
# base_figures save writes it, from the base worktree tmp/.base when that is
# at main, so a later bench compares with figures measured at main's
# current commit and builds nothing.
main_figures_file() {
  echo "$state_dir/main-figures.tsv"
}
main_ref_commit() {
  git rev-parse --verify -q --end-of-options "${BASE:-origin/main}^{commit}" 2>/dev/null
}

# stored_figures OUT: write the stored figures to OUT and succeed only when
# they were measured at main's current commit and hold allocations or rounds.
stored_figures() {
  file=$(main_figures_file)
  [ -f "$file" ] || return 1
  at=$(main_ref_commit) || return 1
  [ "$(sed -n 1p "$file")" = "main $at" ] || return 1
  sed '1d' "$file" > "$1.part"
  if grep -q -E '^(allocs|rounds)[.]' "$1.part"; then
    mv "$1.part" "$1"
    return 0
  fi
  rm -f "$1.part"
  return 1
}

# base-figures [save]: without an argument, say whether figures measured at
# main's current commit are stored (exit 0) or the base must be measured
# (exit 1); save builds tmp/.base, measures it with main's own script and
# stores it (no file is copied),
# refused unless that worktree is at main's current commit.
base_figures() {
  at=$(main_ref_commit) || die "base-figures: no ${BASE:-origin/main} to measure"
  short=$(printf '%s' "$at" | cut -c1-12)
  case "${1:-}" in
    "")
      probe=$(mktemp)
      if stored_figures "$probe"; then
        rm -f "$probe" "$probe.part"
        echo "base-figures: the figures of main $short are stored; build nothing"
        return 0
      fi
      rm -f "$probe" "$probe.part"
      echo "base-figures: none stored for main $short; build tmp/.base, measure it, then save"
      return 1 ;;
    save)
      [ "$(git -C tmp/.base rev-parse --verify -q HEAD 2>/dev/null)" = "$at" ] ||
        die "base-figures: refused: tmp/.base is not at ${BASE:-origin/main}, $short"
      # The measurement is taken here, by main's own script in tmp/.base from
      # builds made here from main's tracked tree, never copied from a file
      # anyone could have written; the tracked files of tmp/.base must be
      # main's, no makefile of its own may stand there (make reads
      # GNUmakefile and makefile before Makefile), and the outputs the
      # script reads are removed before the build, so a planted one is
      # never measured.
      [ -z "$(GIT_OPTIONAL_LOCKS=0 git -C tmp/.base status --porcelain --untracked-files=no)" ] ||
        die "base-figures: refused: tracked files of tmp/.base differ from ${BASE:-origin/main}"
      for planted in GNUmakefile makefile; do
        if [ -e "tmp/.base/$planted" ] || [ -L "tmp/.base/$planted" ]; then
          [ -n "$(git -C tmp/.base ls-files -- "$planted")" ] ||
            die "base-figures: refused: tmp/.base holds an untracked $planted, which make would read first"
        fi
      done
      untracked=$(git -C tmp/.base ls-files --others --exclude-standard 2>/dev/null | head -n 3 | tr '\n' ' ')
      [ -z "$untracked" ] || die "base-figures: refused: tmp/.base holds an untracked file, which the build would measure as main's: ${untracked% }"
      [ -f tmp/.base/tools/metrics.sh ] || die "base-figures: refused: tmp/.base has no tools/metrics.sh"
      measured=$(mktemp) || die "base-figures: no temporary file"
      rm -rf tmp/.base/build/dev/carat.timing tmp/.base/build/test/run_all.timing tmp/.base/build/bench/keys-budget tmp/.base/build/metrics
      lane_top=$(pwd -P)
      "$make_cmd" -C tmp/.base dev-build test-build bench-budget "PREFIX=$lane_top/tmp/.toolchain" "SPINEL_CACHE_DIR=$lane_top/build/spinel-cache" > /dev/null ||
        { rm -f "$measured"; die "base-figures: refused: main's build failed in tmp/.base"; }
      mkdir -p tmp/.base/build/metrics
      (cd tmp/.base && sh tools/metrics.sh measure "$measured") > /dev/null ||
        { rm -f "$measured"; die "base-figures: refused: main's measurement failed in tmp/.base"; }
      grep -q -E '^(allocs|rounds)[.]' "$measured" ||
        { rm -f "$measured"; die "base-figures: refused: no measurement with allocations or rounds"; }
      mkdir -p "$state_dir"
      { echo "main $at"; grep -v "$TAB[?]$" "$measured"; } > "$(main_figures_file).part"
      mv "$(main_figures_file).part" "$(main_figures_file)"
      rm -f "$measured"
      echo "base-figures: stored the figures of main $short" ;;
    *) usage ;;
  esac
}

# The carried check (cache-reuse): when the commit the workflow backs is
# HEAD and every stage of make stages holds a pass record at HEAD (the
# contributor's own check, which the backing trusts as check does), the
# stages a check would run are none, so say so and give the figures the
# checker would have: the spent line and bench's report. A stage of
# RERUN_STAGES counts only when scoped out of the change, as check
# re-runs it otherwise. Exit 0 carried, 1 not; runs and writes nothing
# but what spent and bench write.
carried_check() {
  head=$(head_commit)
  untracked=$(git ls-files --others --exclude-standard -- GNUmakefile makefile '*/GNUmakefile' '*/makefile' 2>/dev/null)
  [ -z "$untracked" ] || { echo "carried: no: an untracked makefile stands: $untracked"; return 1; }
  want=$(commit_at "$1") || exit 1
  [ "$want" = "$head" ] || { echo "carried: no: $want is not HEAD $head"; return 1; }
  dirty=$(dirty_tracked)
  [ -z "$dirty" ] || { echo "carried: no: tracked files differ from HEAD"; return 1; }
  # The stage list is read as check_stages and gates.sh read it, as text and
  # never by running make in the working tree: a planted untracked GNUmakefile
  # or makefile is read before the committed Makefile and could drop a stage.
  stages=${STAGES:-$(main_stages)}
  [ -n "$stages" ] || stages=$(head_fast_stages)
  [ -n "$stages" ] || { echo "carried: no: no stages"; return 1; }
  paths=$(scope_paths)
  for s in $stages; do
    record=$(read_key "stage.$s")
    case "$record" in "0 "*) ;; *) echo "carried: no: stage $s has no pass record"; return 1 ;; esac
    [ "$(echo "$record" | cut -d' ' -f3)" = "$head" ] || { echo "carried: no: stage $s passed at another commit"; return 1; }
    if one_of "$s" "$RERUN_STAGES"; then
      case "$record" in *" scoped") ;; *) echo "carried: no: stage $s runs again"; return 1 ;; esac
      out_of_scope "$s" "$paths" || { echo "carried: no: stage $s is in scope"; return 1; }
    fi
  done
  echo "carried: every stage passed at $head; no stage ran"
  echo "spent: $(spent_line)"
  if bench_compare; then echo "carried: bench same"; else echo "carried: bench differs"; fi
  return 0
}

# The bench command: the metrics stage's measurement against main's. The
# history row of a merged change is appended in the next change's package
# step, after this one, so main's figures are those of the newest merged
# change without a row (its run state's metric.rounds.*, allocs.*, us.*),
# and the last history row only when no merged change is pending.
# When the check scoped the metrics stage out, no measured path changed, so
# main's figures are carried as the change's own, which the next history
# row reads, and reported the same.
bench_compare() {
  record=$(read_key stage.metrics)
  case "$record" in
    "0 "*) [ "$(echo "$record" | cut -d' ' -f3)" = "$(head_commit)" ] ||
      die "bench: the metrics stage passed at another commit; run the checks first" ;;
    *) die "bench: the metrics stage has not passed at HEAD; run the checks first" ;;
  esac
  scoped=no
  case "$record" in *" scoped") scoped=yes ;; *) import_metrics "$metrics_out" ;; esac
  last=$(dirname "$metrics_out")/last.tsv
  mkdir -p "$(dirname "$last")"
  stored=no
  base=''
  if stored_figures "$last"; then
    stored=yes
    source="the figures of main stored at $(main_ref_commit | cut -c1-12)"
  else
    base=$(newest_pending)
  fi
  if [ "$stored" = yes ]; then
    :
  elif [ -n "$base" ]; then
    (change=$base; keys_under metric.) | awk '
      /^(rounds|allocs|us)[.][^=]*=/ { name = $0; sub(/=.*/, "", name); sub(/^[^=]*=/, ""); print name "\t" $0 }' > "$last"
    if ! grep -q -E '^(allocs|rounds)[.]' "$last"; then
      echo "bench: the newest merged change $base has no recorded allocations or rounds to compare with"
      return 1
    fi
    source="the run state of $base, merged without a history row yet"
  else
    newest=$(history_rows | sed -n '2,$p' | tail -1)
    if [ -z "$newest" ]; then
      echo "bench: no history row in $metrics_files to compare with"
      return 1
    fi
    printf '%s\n' "$newest" | awk -F'\t' '
      function out(kind, list,   n, i, p, kv) {
        if (list == "-" || list == "") return
        n = split(list, p, ",")
        for (i = 1; i <= n; i++) { split(p[i], kv, "="); printf "%s.%s\t%s\n", kind, kv[1], kv[2] }
      }
      { out("rounds", $8); out("allocs", $9); out("us", $10) }' > "$last"
    source="the history row of $(printf '%s\n' "$newest" | cut -f1)"
  fi
  if [ "$scoped" = yes ]; then
    mkdir -p "$(dirname "$metrics_out")" && cp "$last" "$metrics_out"
    import_metrics "$metrics_out"
    echo "bench: the check measured nothing, since no path it measures changed; carried the figures of $source"
    return 0
  fi
  echo "bench: comparing with $source"
  "$make_cmd" --no-print-directory metrics-compare "BASE_METRICS=$last" "METRICS_OUT=$metrics_out"
  compared=$?
  # Figures measured at main itself settle the comparison: a regression
  # (more allocations or rounds) is the only difference that needs the
  # benchmark agent, which then builds nothing; fewer or equal pass.
  if [ "$stored" = yes ]; then
    if [ "$compared" -eq 0 ]; then
      echo "bench: no regression against $source"
      return 0
    fi
    echo "bench: regression against $source"
    return 1
  fi
  differ=$(awk -F'\t' '
    NR == FNR { if ($1 ~ /^(allocs|rounds)[.]/) base[$1] = $2; next }
    $1 ~ /^(allocs|rounds)[.]/ {
      seen[$1] = 1
      if (!($1 in base) || $2 == "?" || base[$1] + 0 != $2 + 0) print $1 " " ($1 in base ? base[$1] : "none") " -> " $2
    }
    END { for (k in base) if (!(k in seen)) print k " " base[k] " -> none" }' "$last" "$metrics_out")
  if [ -n "$differ" ]; then
    echo "bench: differs from $source:"
    printf '%s\n' "$differ"
    return 1
  fi
  echo "bench: same allocations and rounds as $source"
}

add_note() {
  valid '[a-z-]+' "$1" || die "note: the kind is lowercase words joined by hyphens, not $1"
  # An advisory a later round repeats is one note: its text is compared
  # without the leading commit of the review that found it.
  # Both sides strip one pattern, a commit of 7 to 40 hexadecimal digits,
  # so a text starting with a word of hex letters (add, dead) is kept whole.
  if [ "$1" = quality-advisory ]; then
    if keys_under note. | T="$(escape "$2")" awk '
        function bare(s) { return match(s, /^[0-9a-f]+ /) && RLENGTH >= 8 && RLENGTH <= 41 ? substr(s, RLENGTH + 1) : s }
        { sub(/^[0-9]+=/, "") }
        sub(/^quality-advisory /, "") { if (bare($0) == bare(ENVIRON["T"])) found = 1 }
        END { exit !found }'; then
      echo "note: the advisory is already recorded; not recorded again"
      return 0
    fi
  fi
  # A security finding or a quality finding a /sprint rerun records again
  # (after a partial review) is one note: the whole text compared, since it
  # carries no leading commit, so a disputed note beside its finding is
  # still recorded (sprint-close-lows, sprint-guard-lows).
  if [ "$1" = security ] || [ "$1" = quality ]; then
    if keys_under note. | K="$1" T="$(escape "$2")" awk '
        { sub(/^[0-9]+=/, "") }
        index($0, ENVIRON["K"] " ") == 1 { if (substr($0, length(ENVIRON["K"]) + 2) == ENVIRON["T"]) found = 1 }
        END { exit !found }'; then
      echo "note: the $1 finding is already recorded; not recorded again"
      return 0
    fi
  fi
  # A late finding is the workflow's, written at the close after the
  # merge: stamped with the squash commit, which no note written before
  # the merge (branch code a check runs, an earlier start) can name.
  if [ "$1" = late-finding ]; then
    stamp=$(merged_commit)
    [ -n "$stamp" ] && merged_on_main "$stamp" ||
      die "note: a late finding is recorded only after the run merged; $change records no merged commit on main"
    set -- "$1" "$stamp $2"
  fi
  # The held and unpushed findings are the workflow's close records
  # (recordLate), each written in its phase of the run: a held finding
  # after the push and before the merge, an unpushed one before the push.
  case "$1" in
    held-finding)
      [ -n "$(read_key pushed)" ] && [ -z "$(read_key merged)" ] ||
        die "note: a held finding is recorded only after the push and before the merge" ;;
    unpushed-finding)
      [ -z "$(read_key pushed)" ] ||
        die "note: an unpushed finding is recorded only before the push; $change records a push" ;;
  esac
  n=$(($(grep -c '^  "note[.]' "$(state_file)") + 1))
  write_key "note.$n" "$1 $2"
}

has_row() {
  lane_rows | awk -F'\t' -v c="$1" '$1 == c { found = 1 } END { exit !found }'
}

# Both lanes' history rows, unsorted and without the header, for a lookup
# by name: from the working tree, or from the commit history_at names when
# it is set (sprint-row's committed form), where the branch's later edits
# of the files are the only ones counted.
lane_rows() {
  for lane_name in feature backlog; do
    f="$metrics_prefix-$lane_name.tsv"
    if [ -n "${history_at:-}" ]; then
      git show "$history_at:$f" 2>/dev/null | awk 'NR > 1 && NF'
    else
      [ ! -f "$f" ] || awk 'NR > 1 && NF' "$f"
    fi
  done
}

# The header, then both lanes' history rows oldest merge first: ordered by
# the place of each row's merged commit in the ancestry of HEAD and of BASE
# (origin/main) together, oldest first (rev-list --topo-order, which main's
# chain of squash commits orders whole, whatever their timestamps), so a
# change merged on main after HEAD's branch point, whose row history
# appends (merged_on_main), sorts after every row HEAD holds; a row whose
# commit neither holds sorts first, in its file's order. BASE is passed to
# git only as the commit it resolves to, and left out when it resolves to
# none.
history_rows() {
  printf '%s\n' "$HEADER"
  rows=$(lane_rows)
  [ -n "$rows" ] || return 0
  base_tip=$(git rev-parse --verify -q --end-of-options "${BASE:-origin/main}^{commit}" 2>/dev/null) || base_tip=""
  # shellcheck disable=SC2086 # base_tip is one hash or empty
  { git rev-list --reverse --topo-order HEAD $base_tip -- 2>/dev/null; echo --; printf '%s\n' "$rows"; } | awk -F'\t' '
    !body { if ($0 == "--") body = 1; else { n++; at[substr($0, 1, 12)] = n; full[n] = $0 }; next }
    {
      k = 0
      if ($3 ~ /^[0-9a-f]+$/ && length($3) >= 7) {
        if (length($3) >= 12) k = at[substr($3, 1, 12)] + 0
        else for (i = 1; i <= n; i++) if (index(full[i], $3) == 1) { k = i; break }
        if (k && index(full[k], $3) != 1) k = 0
      }
      printf "%d\t%d\t%s\n", k, NR, $0
    }' | sort -n -k1,1 -k2,2 | cut -f3-
}

# The lane of the change, feature or backlog: the lane queue naming its
# item ("N. `CHANGE` (") at the parent of its squash commit, else its
# squash subject's type (a Conventional Commits type other than feat the
# backlog lane), else feature, feat and a subject of no known type alike.
# Its history row goes to that lane's file, the record of the lane.
# A change not merged yet (the one a package step packages) takes the lane
# queue naming its item in the working tree, else at BASE, where it stood
# before its planner removed it, else its recorded branch's type: feature/
# the feature lane, any other type the backlog lane.
lane_of() {
  merged=$(merged_commit)
  lane=""
  if valid '[0-9a-f]{7,40}' "$merged"; then
    for l in feature backlog; do
      if git show --end-of-options "$merged^:docs/queue-$l.md" 2>/dev/null | item_named; then
        lane=$l
        break
      fi
    done
    if [ -z "$lane" ]; then
      case "$(git log -1 --format=%s --end-of-options "$merged" -- 2>/dev/null | sed -n 's/^\([a-z]*\)[(!:].*/\1/p')" in
        fix|chore|docs|refactor|test|perf|style|build|ci|revert) lane=backlog ;;
      esac
    fi
  else
    for l in feature backlog; do
      if { item_named < "docs/queue-$l.md"; } 2>/dev/null; then lane=$l; break; fi
    done
    for l in feature backlog; do
      [ -z "$lane" ] || break
      if git show --end-of-options "${BASE:-origin/main}:docs/queue-$l.md" 2>/dev/null | item_named; then lane=$l; fi
    done
    if [ -z "$lane" ]; then
      case "$(read_key branch)" in feature/*|"") ;; */*) lane=backlog ;; esac
    fi
  fi
  echo "${lane:-feature}"
}

# True when the queue on stdin holds an item naming the change
# ("N. `CHANGE`" and anything after), as estimate_of reads it.
item_named() {
  C="$change" awk '
    { item = $0; if (sub(/^[0-9]+[.] /, "", item) && index(item, "`" ENVIRON["C"] "`") == 1) f = 1 }
    END { exit !f }'
}

# True when CHANGE's package step carries the waiting sprint plan
# (planner-loop): a plan waits for the sprint in progress, its security
# review recorded, nothing holds it (queue_hold), and no other change
# carries it (PLAN_DIR/sprint.carrier). Its history then appends every
# lane's rows, which groom's sprint row counts; carried_by names a carrier.
carries() {
  [ -n "${1:-}" ] || return 1
  sprint_waiting || return 1
  sprint_state
  [ "$waiting" = "sprint-$sprint_n" ] && sprint_reviewed || return 1
  ! queue_hold > /dev/null || return 1
  carried_by=$(carrier_of)
  [ -z "$carried_by" ] || [ "$carried_by" = "$1" ]
}

# The change PLAN_DIR/sprint.carrier names for the waiting sprint, "sprint-N
# CHANGE", or nothing when it names none or another sprint.
carrier_of() {
  [ -f "$plan_dir/sprint.carrier" ] || return 0
  awk -v s="$waiting" '$1 == s && $2 ~ /^[a-z0-9][a-z0-9-]*$/ { print $2; exit }' "$plan_dir/sprint.carrier"
}

# Prints what holds the waiting plan of sprint-N (sprint_n) and returns 0,
# else returns 1: a blocking periodic security review of sprint-N or its
# sweep that no change planned after it merged since (merged_since) nor a
# later whole-tree pass superseded (passed_since), as plan-needed reads
# them, or sprint-N's hold security-first, which sprint-planning sets for
# the plan's security first before the review, until such a merge.
queue_hold() {
  for run in "sprint-$sprint_n" "sprint-$sprint_n-sweep"; do
    record=$(change=$run; read_key review.periodic-security)
    case "${record%% *}: $record" in
      blocked:*|*" blocking="[1-9]*) ;;
      *) continue ;;
    esac
    reviewed=${record#* }
    reviewed=${reviewed%% *}
    recorded=$(change=$run; read_key at.review.periodic-security)
    merged_since "$reviewed" "$recorded" && continue
    passed_since "$reviewed" "$recorded" && continue
    echo "a blocking security finding of $run"
    return 0
  done
  [ "$(change="sprint-$sprint_n"; read_key hold)" = security-first ] || return 1
  record=$(change="sprint-$sprint_n"; read_key review.periodic-security)
  reviewed=${record#* }
  reviewed=${reviewed%% *}
  merged_since "$reviewed" "$(change="sprint-$sprint_n"; read_key at.review.periodic-security)" && return 1
  echo "the plan's security first"
}

# Applies the delivery planner's directory, PLAN_DIR/CHANGE, for the
# change's lane (lane_of) only: its queue over that lane's docs/ queue,
# fitted within the lane's budget (queue_fit) or refused with the bytes
# over, the queue then left as it was; the other lane's queue file left
# and named, goals.md over docs/goals.md,
# and backlog.md appended to the change's findings file. Two lanes' package
# steps so write no common record.
plan_apply() {
  dir=$plan_dir/$change
  lane=$(lane_of)
  if [ ! -d "$dir" ]; then echo "plan-apply: no plan in $dir/; nothing applied"; return 0; fi
  if [ -f "$dir/queue-$lane.md" ]; then
    fit="docs/queue-$lane.md.fit"
    cp "$dir/queue-$lane.md" "$fit" || die "plan-apply: $fit not written"
    if ! queue_fit "$lane" "$fit"; then
      rm -f "$fit"
      die "plan-apply: refused: $dir/queue-$lane.md is $fit_bytes bytes with every Decisions line dropped, $((fit_bytes - fit_budget)) over the $lane lane's budget of $fit_budget (tools/docs_lint.sh); docs/queue-$lane.md left as it was"
    fi
    mv "$fit" "docs/queue-$lane.md" || die "plan-apply: docs/queue-$lane.md not written"
    echo "plan-apply: copied $dir/queue-$lane.md over docs/queue-$lane.md"
    [ "$fit_dropped" -eq 0 ] ||
      echo "plan-apply: dropped the last $fit_dropped Decisions line(s) of docs/queue-$lane.md to fit the $lane lane's budget of $fit_budget bytes"
  fi
  for l in feature backlog; do
    [ "$l" = "$lane" ] || [ ! -f "$dir/queue-$l.md" ] || echo "plan-apply: left $dir/queue-$l.md, of the $l lane, which $change's package step never applies"
  done
  if [ -f "$dir/goals.md" ]; then
    case "$(read_key review.security)" in
      pass\ *)
        # docs/goals.md is an instruction record: a security review that
        # passed already makes any later edit of it stale, which reviewed-edits
        # names for restoring, so the planned goals wait for their own delivery.
        echo "plan-apply: left $dir/goals.md: a security review passed for $change and docs/goals.md is an instruction record the gates settle no pass across; the goals change needs its own delivery" ;;
      *)
        cp "$dir/goals.md" docs/goals.md || die "plan-apply: docs/goals.md not written"
        echo "plan-apply: copied $dir/goals.md over docs/goals.md" ;;
    esac
  fi
  if [ -f "$dir/backlog.md" ]; then
    mkdir -p "$findings_dir" && touch "$findings_dir/$change.md" || die "plan-apply: $findings_dir/$change.md not appended"
    # Each entry once, whoever appended it first (the implement step too),
    # after a blank line, so a run's findings file holds no heading twice.
    fresh_entries=$(T="$findings_dir/$change.md" awk 'BEGIN { while ((getline line < ENVIRON["T"]) > 0) if (line ~ /^#+ /) have[line] = 1 } /^#+ / { skip = ($0 in have) } !skip' "$dir/backlog.md")
    if [ -z "$(printf '%s' "$fresh_entries" | tr -d ' \t\n')" ]; then
      echo "plan-apply: $dir/backlog.md is already in $findings_dir/$change.md; not appended again"
    else
      { [ ! -s "$findings_dir/$change.md" ] || [ -z "$(tail -n 1 "$findings_dir/$change.md")" ] || echo; printf '%s\n' "$fresh_entries"; } >> "$findings_dir/$change.md" ||
        die "plan-apply: $findings_dir/$change.md not appended"
      echo "plan-apply: appended $dir/backlog.md to $findings_dir/$change.md"
    fi
  fi
}

# queue_budget LANE: the lane queue's byte budget, QUEUE_BUDGET_FEATURE or
# QUEUE_BUDGET_BACKLOG of tools/docs_lint.sh, its one source.
queue_budget() {
  case "$1" in
    feature) sed -n 's/^QUEUE_BUDGET_FEATURE=\([0-9][0-9]*\)$/\1/p' "$here/docs_lint.sh" ;;
    backlog) sed -n 's/^QUEUE_BUDGET_BACKLOG=\([0-9][0-9]*\)$/\1/p' "$here/docs_lint.sh" ;;
  esac
}

# queue_fit LANE FILE: fits the lane queue FILE within its lane's budget
# before the push (lane-isolation), as the planner's trims do: drops the
# "- " bullets of its "## Decisions" section, each with its indented
# continuation lines, from the last up, never an item. Sets fit_budget,
# fit_bytes, and fit_dropped; false when dropping every one is not enough.
queue_fit() {
  fit_budget=$(queue_budget "$1")
  fit_dropped=0
  [ -n "$fit_budget" ] || die "queue: no budget for the $1 lane in $here/docs_lint.sh"
  fit_bytes=$(wc -c < "$2")
  while [ "$fit_bytes" -gt "$fit_budget" ]; do
    last=$(awk '/^## / { on = ($0 == "## Decisions"); next } on && /^- / { n = NR } END { print n + 0 }' "$2")
    [ "$last" -gt 0 ] || return 1
    awk -v n="$last" 'NR == n { drop = 1; next } drop && /^[ \t]+[^ \t]/ { next } { drop = 0; print }' "$2" > "$2.tmp" &&
      mv "$2.tmp" "$2" || die "queue: $2 not written"
    fit_dropped=$((fit_dropped + 1))
    fit_bytes=$(wc -c < "$2")
  done
}

# queue_over: why the lane queue committed at HEAD is over its budget,
# nothing when it fits, so a push never takes CI a queue its check did
# not see (an edit after plan-apply).
queue_over() {
  lane=$(lane_of)
  budget=$(queue_budget "$lane")
  bytes=$(git show "HEAD:docs/queue-$lane.md" 2> /dev/null | wc -c)
  [ -z "$budget" ] || [ "$bytes" -le "$budget" ] ||
    echo "docs/queue-$lane.md is $bytes bytes at HEAD, $((bytes - budget)) over the $lane lane's budget of $budget; shorten its Decisions"
}

# The queue at COMMIT: both lane queues, else, at a commit before the
# lanes, the one queue file it had, so the history before the split stays
# readable; the working tree's old queue is never read.
queue_at() {
  q=$(for l in feature backlog; do git show --end-of-options "$1:docs/queue-$l.md" 2>/dev/null; done)
  [ -n "$q" ] || q=$(git show --end-of-options "$1:docs/queue.md" 2>/dev/null)
  printf '%s\n' "$q"
}

# True when COMMIT names a commit git knows on HEAD or on BASE
# (origin/main): a merge, unlike a merged value naming no such commit.
merged_on_main() {
  full=$(git rev-parse --verify -q --end-of-options "$1^{commit}" 2>/dev/null) || return 1
  on_head_or_base "$full" "${BASE:-origin/main}"
}

# True when the full commit $1 is an ancestor of HEAD or of $2, a commit or
# ref ("" for none): merged_on_main and supported differ only in the base.
on_head_or_base() {
  git merge-base --is-ancestor "$1" HEAD 2>/dev/null && return 0
  [ -n "$2" ] && git merge-base --is-ancestor "$1" "$2" 2>/dev/null
}

# The twelve-digit pushed head when VALUE ($1) is 7 to 40 of its leading
# digits: a recorded CI head is the head the push recorded, never another
# an agent reported; dies naming both, as COMMAND ($2), otherwise.
pushed_at() {
  pushed=$(read_key pushed)
  valid '[0-9a-f]{40}' "$pushed" || die "$2: refused: no pushed head is recorded for $change, so no CI head $1"
  valid '[0-9a-f]{7,40}' "$1" && case "$pushed" in "$1"*) true ;; *) false ;; esac ||
    die "$2: refused: the CI head $1 is not the pushed head $pushed"
  printf '%s\n' "$pushed" | cut -c1-12
}

# The twelve-digit newest commit of BASE (origin/main) whose subject ends
# with " (#PR)", as the squash merge of pull request PR ($1) titles it;
# fails when none does. Never a commit of HEAD: a branch commit can carry
# that subject, and no branch commit is a merge.
squash_commit() {
  ref=${BASE:-origin/main}
  git rev-parse --verify -q --end-of-options "$ref^{commit}" > /dev/null 2>&1 || return 1
  found=$(git log --format='%H %s' --end-of-options "$ref" -- 2>/dev/null | S=" (#$1)" awk '
    { s = ENVIRON["S"]; n = length($0) - length(s); if (n > 40 && substr($0, n + 1) == s) { print $1; exit } }')
  [ -n "$found" ] || return 1
  git rev-parse --short=12 "$found"
}

# The twelve-digit squash commit when VALUE ($1) names it: a commit on main
# (merged_on_main) and, once the pull request is recorded, its squash
# commit (squash_commit); dies naming both, as COMMAND ($2), otherwise, so
# no pushed head or mistyped hash an agent reported is recorded as merged.
merged_at() {
  valid '[0-9a-f]{7,40}' "$1" || die "$2: refused: merged is a commit hash of 7 to 40 hexadecimal digits, not $1"
  at=$(git rev-parse --verify -q --short=12 --end-of-options "$1^{commit}" 2>/dev/null) || at=""
  pr=$(read_key pr)
  if valid '[0-9]+' "$pr"; then
    squash=$(squash_commit "$pr") || squash="none"
    [ -n "$at" ] && [ "$at" = "$squash" ] || die "$2: refused: $1 is not the squash commit of pull request #$pr on main, $squash"
  else
    # No pull request recorded: an ancestor of main itself, never of HEAD,
    # where a lane's pushed head is.
    [ -n "$at" ] && git merge-base --is-ancestor "$at" "${BASE:-origin/main}" 2>/dev/null || die "$2: refused: $1 is no commit on main"
  fi
  # The squash message ends with exactly the co-author trailer, trailing
  # blank lines aside: #307's squash commit ended with it and a stray
  # double quote, and nothing in the merge phase noticed (cheap-tier).
  # History on main is not rewritten; the merge phase reports it here.
  last=$(git log -1 --format=%B --end-of-options "$at" -- 2>/dev/null | awk 'NF { l = $0 } END { print l }')
  [ "$last" = "Co-Authored-By: Claude <noreply@anthropic.com>" ] ||
    die "$2: refused: the squash commit $at ends with \"$last\", not exactly the co-author trailer"
  printf '%s\n' "$at"
}

# The twelve-digit squash commit of the change, for the word merged in
# place of a commit (phase, as COMMAND $1): once the pull request is
# recorded, its squash commit on main (squash_commit), which a recorded
# merged value must name; before, the recorded merged value as set checks
# it (merged_at). Dies naming both values, or when neither is recorded, so
# the close records a phase at the squash commit and never at a sha an
# agent reported.
squash_of_change() {
  recorded=$(read_key merged)
  pr=$(read_key pr)
  if valid '[0-9]+' "$pr"; then
    squash=$(squash_commit "$pr") || die "$1: refused: pull request #$pr has no squash commit on main"
    [ -z "$recorded" ] || [ "$(git rev-parse --verify -q --short=12 --end-of-options "$recorded^{commit}" 2>/dev/null)" = "$squash" ] ||
      die "$1: refused: the recorded merged commit $recorded is not the squash commit of pull request #$pr on main, $squash"
    printf '%s\n' "$squash"
  elif [ -n "$recorded" ]; then
    merged_at "$recorded" "$1"
  else
    die "$1: refused: $change records neither a pull request nor a merged commit"
  fi
}

# The merged changes whose run state has no history row, one per line; a
# merged value that is not a commit hash, or names no commit on main
# (merged_on_main), is not a merge, so no history row, sprint, or bench
# base takes it.
pending_list() {
  merged_rows | awk '$3 == "on" { print $1 }'
}

# Each run state with a merged value and no history row, classified once as
# "NAME MERGED on" (a commit on main, merged_on_main) or "NAME MERGED off":
# the one loop pending_list and unmerged_list filter.
merged_rows() {
  for file in "$state_dir"/*.json; do
    [ -f "$file" ] || continue
    name=$(basename "$file" .json)
    merged=$(change=$name; merged_commit)
    [ -n "$merged" ] || continue
    has_row "$name" && continue
    if merged_on_main "$merged"; then echo "$name $merged on"; else echo "$name $merged off"; fi
  done
}

# The run states recording a merge phase but no merged commit
# (merged_commit), each as "NAME at COMMIT", one per line, a review run
# (REVIEW_RUNS, which no sprint counts) and a change with a history row
# left out: merges pending_list cannot see, so sprint_state cannot count
# them and review_due names them (a run state written before phase merge
# recorded merged, or edited by hand).
merge_unrecorded() {
  for file in "$state_dir"/*.json; do
    [ -f "$file" ] || continue
    name=$(basename "$file" .json)
    printf '%s\n' "$name" | grep -q -E "$REVIEW_RUNS" && continue
    phase_at=$(change=$name; read_key phase.merge)
    valid '[0-9a-f]{7,40}' "$phase_at" || continue
    [ -z "$(change=$name; merged_commit)" ] || continue
    has_row "$name" && continue
    echo "$name at $phase_at"
  done
}

# The files the package step may not edit: those changed since the commit
# of the security review's pass record, which the push gate settles at
# HEAD, in commits, the working tree, or untracked, outside the
# records-only paths (RECORDS_RE) or among the instruction records
# (INSTRUCTION_RECORDS_RE), which the push gate settles no pass across.
# Exit 1 names them, or the missing pass
# (package-advisory-edit); a reviewed file stays as reviewed and an
# advisory not fixed in review goes to the findings file.
reviewed_edits() {
  record=$(read_key review.security)
  case "$record" in
    pass\ *) ;;
    *) echo "reviewed-edits: no passing security review is recorded for $change: ${record:-none}"; return 1 ;;
  esac
  at=${record#pass }
  at=${at%% *}
  valid '[0-9a-f]{7,40}' "$at" && git rev-parse --verify -q --end-of-options "$at^{commit}" > /dev/null 2>&1 ||
    { echo "reviewed-edits: the security review's commit $at names no commit"; return 1; }
  # A git that fails here lists no edit, so it is no pass: each read is checked.
  changed_diff=$(git diff --no-renames --name-only --end-of-options "$at" -- 2>/dev/null) &&
    changed_new=$(git ls-files --others --exclude-standard 2>/dev/null) ||
    { echo "reviewed-edits: git failed listing the files changed since the security review at $at, so no edit can be ruled out"; return 1; }
  changed=$(printf '%s\n%s\n' "$changed_diff" "$changed_new")
  edited=$(printf '%s\n' "$changed" | outside_records | sort -u | tr '\n' ' ')
  if [ -n "$edited" ]; then
    echo "reviewed-edits: files changed since the security review at $at: ${edited% }; restore each with git restore --source=$at -- FILE and record the finding in docs/findings/$change.md instead"
    return 1
  fi
  echo "reviewed-edits: none since the security review at $at"
}

# The run states whose merged value is a commit hash naming no commit on
# main and that have no history row, as "NAME VALUE" lines: never merged.
unmerged_list() {
  merged_rows | awk '$3 == "off" { print $1, $2 }'
}

# The keys of the run state under PREFIX as "suffix=value" lines.
keys_under() {
  P="$1" awk '
    /^  "/ {
      key = $0; sub(/^  "/, "", key); sub(/".*/, "", key)
      if (index(key, ENVIRON["P"]) != 1) next
      value = $0; sub(/^  "[^"]*": "/, "", value); sub(/",?$/, "", value)
      print substr(key, length(ENVIRON["P"]) + 1) "=" value
    }' "$(state_file)"
}

# metric.PREFIX.* of the run state as "suffix=value,...", "-" when none.
group() {
  out=$(keys_under "metric.$1." | paste -s -d, -)
  echo "${out:--}"
}

value() {
  v=$(read_key "$1")
  echo "${v:--}"
}

# The first verdict of GATE, 1 or 0: metric.first.GATE as the workflow
# stored it, else the gate's entry of an older run's metric.first_pass;
# nothing when neither says. The stage.*, review.*, and ci lines hold each
# gate's last result, which for a merged change is a pass, so they say
# nothing about the first.
first_of() {
  v=$(read_key "metric.first.$1")
  [ -z "$v" ] || { echo "$v"; return; }
  read_key metric.first_pass | tr ',' '\n' | sed -n "s/^$1://p"
}

# The output tokens of the run: the sum of its metric.phase.* figures, else
# an older run's metric.out_tokens; "-" when neither was recorded.
out_tokens() {
  if [ "$(group phase)" = "-" ]; then
    value metric.out_tokens
  else
    keys_under metric.phase. | awk -F'[=/]' '{ n += $2 } END { print n + 0 }'
  fi
}

# The size the change was estimated at, small, medium, or large:
# metric.estimate, which the workflow stores from the plan, so it outlives
# the queue item; else, for a run that stored none, the "estimated SIZE" of
# its item ("N. `CHANGE` ...") in the lane queues (queue_at) at the parent of its squash
# commit, the queue it was delivered from; "-" when neither states a size.
estimate_of() {
  size=$(read_key metric.estimate)
  if valid '(small|medium|large)' "$size"; then
    echo "$size"
    return
  fi
  merged=$(merged_commit)
  [ -n "$merged" ] || { echo -; return; }
  size=$(queue_at "$merged^" | C="$change" awk '
    {
      item = $0
      if (!sub(/^[0-9]+[.] /, "", item) || index(item, "`" ENVIRON["C"] "`") != 1) next
      if (match(item, /estimated (small|medium|large)/)) print substr(item, RSTART + 10, RLENGTH - 10)
      exit
    }')
  echo "${size:--}"
}

# budget_of SIZE: the total-token budget of a size (TOKEN_BUDGETS).
budget_of() {
  printf '%s\n' $TOKEN_BUDGETS | sed -n "s/^$1=//p"
}

# The budget line: the run's total tokens and wall minutes against the
# budgets of its estimate (TOKEN_BUDGETS, MINUTE_BUDGETS), its output tokens
# beside them, for the retrospective to flag an overrun.
budget_line() {
  [ -f "$(state_file)" ] || die "no run state for $change"
  size=$(estimate_of)
  total=$(value metric.total_tokens)
  minutes=$(read_key metric.wall_min)
  actual="actual $total total tokens${minutes:+ in $minutes minutes}, $(out_tokens) output tokens"
  if [ "$size" = "-" ]; then
    echo "no estimate: neither the run state nor a queue item of $change states a size; $actual"
    return
  fi
  limit=$(budget_of "$size")
  time_limit=$(printf '%s\n' $MINUTE_BUDGETS | sed -n "s/^$size=//p")
  budget="budget $limit total tokens${time_limit:+ and $time_limit minutes}"
  if ! valid '[0-9]+' "$total"; then
    echo "unmeasured: estimated $size, $budget, no total tokens recorded"
  elif [ "$total" -gt "$limit" ] || { [ -n "$time_limit" ] && valid '[0-9]+([.][0-9]+)?' "$minutes" &&
      awk -v m="$minutes" -v l="$time_limit" 'BEGIN { exit !(m > l) }'; }; then
    echo "over: estimated $size, $budget, $actual"
  else
    echo "under: estimated $size, $budget, $actual"
  fi
}

# usage TOKENS MINUTES: add one start's total tokens and wall minutes to the
# run's sums, then print the budget line.
add_usage() {
  valid '[0-9]+' "$1" || die "usage: the total tokens are a whole number, not $1"
  valid '[0-9]+([.][0-9]+)?' "$2" || die "usage: the wall minutes are a number, not $2"
  [ -f "$(state_file)" ] || die "no run state for $change"
  tokens=$(read_key metric.total_tokens)
  minutes=$(read_key metric.wall_min)
  [ -z "$tokens" ] || valid '[0-9]+' "$tokens" || die "usage: the recorded total tokens are not a number: $tokens"
  [ -z "$minutes" ] || valid '[0-9]+([.][0-9]+)?' "$minutes" || die "usage: the recorded wall minutes are not a number: $minutes"
  write_key metric.total_tokens "$(awk -v a="${tokens:-0}" -v b="$1" 'BEGIN { printf "%.0f", a + b }')"
  write_key metric.wall_min "$(awk -v a="${minutes:-0}" -v b="$2" 'BEGIN { printf "%.1f", a + b }')"
  budget_line
}

# ci-stages COMMIT: the seconds of each step of the spin job of the newest
# run of the ci workflow at COMMIT, read with gh, its seconds computed by
# gh's jq with their fraction (the timestamp to the second through
# fromdateiso8601, plus the digits after its point), as metric.ci.STEP (the
# step's name in lowercase, every other character an underscore, cut at a
# word within 32 characters), rounded to a tenth and written without a
# point when whole, replacing the previous run's; a step rounding to 0 is
# left out. The record or closing start runs it once CI finished (the
# merger's lines never do), so it exits 0 when nothing could be read.
ci_stages() {
  valid '[0-9a-f]{40}' "$1" || die "ci-stages: not a full commit: $1"
  [ -f "$(state_file)" ] || die "no run state for $change"
  repo=$(read_key repo)
  valid '[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' "$repo" || { echo "ci-stages: no repository recorded"; return 0; }
  run=$(gh api "repos/$repo/actions/runs?head_sha=$1&per_page=20" --jq '[.workflow_runs[] | select(.name == "ci")][0].id // empty' 2>/dev/null || true)
  valid '[0-9]+' "$run" || { echo "ci-stages: no ci run found at $1"; return 0; }
  pairs=$(gh api "repos/$repo/actions/runs/$run/jobs?per_page=10" --jq 'def secs: (.[0:19] + "Z" | fromdateiso8601) + ((capture("^.{19}(?<f>[.][0-9]+)") | .f | tonumber) // 0); .jobs[] | select(.name == "spin") | .steps[] | select(.started_at != null and .completed_at != null) | "\((.completed_at | secs) - (.started_at | secs)) \(.name)"' 2>/dev/null | LC_ALL=C awk '
    function tenth(v,  r) { r = sprintf("%.1f", v); sub(/[.]0$/, "", r); return r }
    $1 ~ /^[0-9]+([.][0-9]+)?$/ {
      s = tenth($1) + 0; $1 = ""; name = tolower($0)
      gsub(/[^a-z0-9]+/, "_", name); sub(/^_+/, "", name); sub(/_+$/, "", name)
      if (length(name) > 32) { name = substr(name, 1, 33); sub(/_[^_]*$/, "", name); if (length(name) > 32) name = substr(name, 1, 32) }
      if (name != "" && s > 0) { if (!(name in t)) order[++n] = name; t[name] += s }
    }
    END { for (i = 1; i <= n; i++) print order[i] "=" tenth(t[order[i]]) }')
  [ -n "$pairs" ] || { echo "ci-stages: no step of run $run was read"; return 0; }
  for key in $(keys_under metric.ci. | sed 's/=.*//'); do drop_key "metric.ci.$key"; done
  for pair in $pairs; do write_key "metric.ci.${pair%%=*}" "${pair#*=}"; done
  echo "ci-stages: recorded $(printf '%s\n' $pairs | wc -l | tr -d ' ') steps of run $run"
}

# tokens DIR: each agent start of one Workflow run, from the transcripts
# the runtime wrote in DIR: agent-ID.jsonl, whose assistant lines carry the
# message's id, model, and usage (a message repeated on several lines
# counts once, its last line), and agent-ID.meta.json, its label and
# workflow phase. A start's key is its phase in lowercase, record for the
# record starts, sprint for sprint-planning's own (a label beginning
# "sprint:" or naming a sprint or periodic review); its tier is cheap when its model contains a tier alias of
# an agent file's model: line, else session. Records metric.start.N
# "KEY/TIER/TOTAL/WEIGHTED", adds to metric.weighted.KEY
# "TOTAL/WEIGHTED/STARTS" and metric.weighted_tokens, and appends DIR's
# name to metric.counted, so a directory counts once.
add_tokens() {
  dir=$1
  [ -d "$dir" ] || die "tokens: no directory $dir"
  name=$(basename "$dir")
  valid '[A-Za-z0-9_.-]+' "$name" || die "tokens: not a run directory name: $name"
  [ -f "$(state_file)" ] || die "no run state for $change"
  counted=$(read_key metric.counted)
  case " $counted " in *" $name "*) echo "tokens: $name is already counted"; return 0 ;; esac
  aliases=$(sed -n 's/^model: *\([a-z][a-z]*\).*/\1/p' .claude/agents/*.md 2>/dev/null | sort -u | paste -s -d' ' -)
  n=$(keys_under metric.start. | sed 's/=.*//' | grep -x '[0-9][0-9]*' | sort -n | tail -1)
  n=${n:-0}
  starts=0
  added=0
  for file in "$dir"/agent-*.jsonl; do
    [ -f "$file" ] || continue
    meta=${file%.jsonl}.meta.json
    label=$(sed -n 's/.*"description":"\([^"]*\)".*/\1/p' "$meta" 2>/dev/null | head -1)
    case $label in
      record) key=record ;;
      sprint:*|*': sprint'*|*periodic*) key=sprint ;;
      *) key=$(sed -n 's/.*"workflowPhase":"\([^"]*\)".*/\1/p' "$meta" 2>/dev/null | head -1 | tr 'A-Z' 'a-z' | tr -cd 'a-z0-9') ;;
    esac
    [ -n "$key" ] || key=other
    line=$(A="$aliases" P="$TIER_PRICES" awk '
      function num(s, field,   m) {
        if (!match(s, "\"" field "\":[0-9]+")) return 0
        m = substr(s, RSTART, RLENGTH); sub(/.*:/, "", m); return m + 0
      }
      index($0, "\"type\":\"assistant\"") {
        i = index($0, "\"usage\":{")
        if (!i || !match($0, /"model":"[^"<][^"]*"/)) next
        model = substr($0, RSTART + 9, RLENGTH - 10)
        id = "line" NR
        if (match($0, /"id":"msg_[A-Za-z0-9_]+"/)) id = substr($0, RSTART + 6, RLENGTH - 7)
        u = substr($0, i)
        tin[id] = num(u, "input_tokens"); tcw[id] = num(u, "cache_creation_input_tokens")
        tcr[id] = num(u, "cache_read_input_tokens"); tout[id] = num(u, "output_tokens")
      }
      END {
        if (model == "") exit
        tier = "session"
        k = split(ENVIRON["A"], a, " ")
        for (j = 1; j <= k; j++) if (index(model, a[j])) tier = "cheap"
        k = split(ENVIRON["P"], p, " ")
        for (j = 1; j <= k; j++) { split(p[j], kv, "="); split(kv[2], v, "/"); for (c = 1; c <= 4; c++) price[kv[1], c] = v[c] }
        for (id in tin) { si += tin[id]; scw += tcw[id]; scr += tcr[id]; sout += tout[id] }
        w = (si * price[tier, 1] + scw * price[tier, 2] + scr * price[tier, 3] + sout * price[tier, 4]) / price["session", 1]
        printf "%s %.0f %.0f\n", tier, si + scw + scr + sout, w
      }' "$file")
    [ -n "$line" ] || continue
    tier=${line%% *}
    rest=${line#* }
    total=${rest%% *}
    weighted=${rest#* }
    n=$((n + 1))
    starts=$((starts + 1))
    write_key "metric.start.$n" "$key/$tier/$total/$weighted"
    write_key "metric.weighted.$key" "$(read_key "metric.weighted.$key" | awk -F/ -v t="$total" -v w="$weighted" '{ printf "%.0f/%.0f/%d", $1 + t, $2 + w, $3 + 1 } END { if (!NR) printf "%.0f/%.0f/1", t, w }')"
    added=$(awk -v a="$added" -v b="$weighted" 'BEGIN { printf "%.0f", a + b }')
  done
  write_key metric.weighted_tokens "$(awk -v a="$(read_key metric.weighted_tokens)" -v b="$added" 'BEGIN { printf "%.0f", a + b }')"
  write_key metric.counted "${counted:+$counted }$name"
  echo "tokens: counted $starts starts of $name, $added weighted tokens; the run's $(read_key metric.weighted_tokens) in all"
}

# The tokens spent so far against the budget, which the checker prints
# after a passing check: the output tokens of the phases the metric line
# stored (every start's, this one's up to the check) against the size's
# output budget, its total-token budget divided by OUTPUT_SHARE, and the
# total tokens earlier starts recorded through usage against the total
# budget. A note for the workflow, never a stop: it exits 0.
spent_line() {
  [ -f "$(state_file)" ] || die "no run state for $change"
  size=$(estimate_of)
  out=$(out_tokens)
  valid '[0-9]+' "$out" || out=0
  total=$(read_key metric.total_tokens)
  valid '[0-9]+' "$total" || total=0
  earlier="$total total tokens recorded by earlier starts"
  if [ "$size" = "-" ]; then
    echo "no estimate: $out output tokens so far; $earlier; neither the run state nor a queue item of $change states a size"
    return
  fi
  limit=$(budget_of "$size")
  out_limit=$((limit / OUTPUT_SHARE))
  word=under
  if [ "$out" -gt "$out_limit" ] || [ "$total" -gt "$limit" ]; then word=over; fi
  echo "$word: $out output tokens so far, budget $out_limit output tokens for $size ($limit total tokens at $OUTPUT_SHARE per output token); $earlier, budget $limit"
}

history_row() {
  merged=$(merged_commit)
  date=""
  [ -z "$merged" ] || date=$(git log -1 --format=%cs --end-of-options "$merged" -- 2>/dev/null)
  first=""
  for g in $GATES; do
    v=$(first_of "$g")
    [ -z "$v" ] || first="${first:+$first,}$g:$v"
  done
  phases=$(group phase)
  tokens=$(out_tokens)
  if [ "$phases" = "-" ]; then
    phases=$(value metric.phases)
    calls=$(value metric.tool_calls)
  else
    calls=$(keys_under metric.phase. | awk -F'[=/]' '{ n += $3 } END { print n + 0 }')
  fi
  if [ "$(count pushes)" -gt 0 ]; then
    if [ "$(count gates_failed)" -eq 0 ]; then gates=1; else gates=0; fi
    first="${first:+$first,}gates:$gates"
  fi
  review="-"
  security=$(read_key review.periodic-security)
  quality=$(read_key review.periodic-quality)
  if [ -n "$security$quality" ]; then
    review="security=${security%% *} quality=${quality%% *}"
  fi
  printf '%s\t' "$change" "${date:--}" "${merged:--}" "$(value pr)" "$(value metric.rework)" "${first:--}" \
    "$(value metric.ci_min)" "$(group rounds)" "$(group allocs)" "$(group us)" \
    "$tokens" "$calls" "$phases" "$review" "$(estimate_of)" "$(value metric.total_tokens)"
  printf '%s\t' "$(value metric.wall_min)"
  printf '%s\t' "$(group calib)" "$(group ci)" "$(value metric.ci_wait_calls)" "$(value metric.weighted_tokens)"
  printf '%s\t' "$(group weighted)"
  printf '%s\t%s\n' "$(value metric.advisories_closed)" "$(value metric.advisories_left)"
}

# The findings a run's workflow recorded after its package step, as
# late-finding notes, one per line in the order recorded: only a note
# stamped with the run's merged commit (add_note) whose text has the shape
# the workflow's noteText writes (LATE_TEXT_RE, at most 400 characters);
# any other is named on stderr and left out of the findings file.
LATE_TEXT_RE="^[A-Za-z0-9 .,:;()/_+=#%'?*@-]{1,400}\$"
late_findings() {
  stamp=$(merged_commit)
  for key in $(sed -n 's/^  "\(note\.[0-9][0-9]*\)": "late-finding .*/\1/p' "$(state_file)"); do
    value=$(read_key "$key")
    text=${value#late-finding }
    if [ -n "$stamp" ] && [ "$text" != "${text#* }" ] && [ "${text%% *}" = "$stamp" ] && valid "$LATE_TEXT_RE" "${text#* }"; then
      printf '%s\n' "${text#* }"
    else
      echo "history: $change's $key is no late finding the workflow recorded after the merge; left out" >&2
    fi
  done
}

# Each merged run's row, and its late findings appended to the backlog in
# one entry (a run whose merged value names no commit on main is named and
# left out), so the next change's package step commits both and a run
# pushes no commit of records after its package step. A run gets its row
# once: none when BASE's history holds it, or when its run state records
# the branch a package step appended it on (row), since the run states are
# the clone's and the history file is each branch's. A lane file absent or
# empty gets HEADER first; one whose line 1 is not HEADER exactly, as both
# kept the 22-column header after closing-loop added two columns
# (metrics-header-fix), stops the command before any row is written: the
# change that alters HEADER rewrites line 1 and pads the older rows.
append_history() {
  unmerged_list | while read -r name merged; do
    echo "history: $name records merged $merged, no commit on main; not appended"
  done
  names=$(pending_list)
  [ -n "$names" ] || { echo "history: nothing pending"; return 0; }
  for lane_name in feature backlog; do
    lane_file="$metrics_prefix-$lane_name.tsv"
    [ -s "$lane_file" ] || continue
    [ "$(sed -n 1p "$lane_file")" = "$HEADER" ] ||
      die "history: $lane_file's line 1 differs from HEADER; rewrite it to HEADER and pad each older row with - for the columns it lacks; nothing appended"
  done
  # The lane whose rows a delivery's package step appends, the change's
  # own; one that carries the waiting sprint plan, or no change, appends
  # every lane's, which groom's sprint row counts.
  only=""
  if [ -n "${1:-}" ] && ! (carries "$1"); then only=$(change=$1; lane_of); fi
  # Each lane file's rows at BASE, its header stripped, so the second
  # file's header is never read as a row.
  base_history=$(for lane_name in feature backlog; do git show "${BASE:-origin/main}:$metrics_prefix-$lane_name.tsv" 2>/dev/null | awk 'NR > 1 && NF'; done)
  branch_now=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || branch_now=HEAD
  case "$branch_now" in ""|*[[:cntrl:]]*) branch_now=HEAD ;; esac
  for change in $names; do
    on=$(read_key row)
    if [ -n "$on" ]; then
      echo "history: $change already has its row, appended on $on; not appended again"
      continue
    fi
    if printf '%s\n' "$base_history" | awk -F'\t' -v c="$change" '$1 == c { found = 1 } END { exit !found }'; then
      echo "history: $change already has its row in ${BASE:-origin/main}'s history; not appended again"
      continue
    fi
    lane_now=$(lane_of)
    if [ -n "$only" ] && [ "$lane_now" != "$only" ]; then
      echo "history: $change is of the $lane_now lane; left to that lane's next package step"
      continue
    fi
    row_file=$metrics_prefix-$lane_now.tsv
    [ -s "$row_file" ] || printf '%s\n' "$HEADER" > "$row_file"
    history_row >> "$row_file"
    write_key row "$branch_now"
    echo "history: appended $change to $row_file"
    found=$(late_findings)
    [ -n "$found" ] || continue
    mkdir -p "$findings_dir" || die "history: no $findings_dir"
    { printf '\n## Findings of %s after its package step\n\n' "$change"; printf '%s\n' "$found" | sed 's/^/- /'; } >> "$findings_dir/$change.md"
    echo "history: appended the late findings of $change to $findings_dir/$change.md"
  done
}

# The sprint in progress: sprint_n, the number after the sprints file's
# last row; sprint_size, the counted merges that close it (SPRINT_SIZE from
# sprint SPRINT_SIZE_FROM on, else SPRINT_SIZE_BEFORE); sprint_base, the
# merged commit of that row's last change, where the combined diff starts;
# sprint_names, the changes merged since (the history rows after that
# change's row, then the merged changes without a row); sprint_uncounted,
# those of them a sprint does not count (queue_class: a T0 item, one an
# exception line puts outside the 3, one beyond the sprint, or a pool item
# that is no split part of a counted change, split_part), and
# sprint_left_out, the same named by reason for review_due's line; and
# sprint_count, the rest: the sprint items, their split parts, and the
# changes no queue names, counted as before.
sprint_state() {
  [ -f "$sprints_file" ] || die "no $sprints_file"
  last_row=$(awk -F'\t' 'NR > 1 && NF { row = $0 } END { print row }' "$sprints_file")
  prev=$(printf '%s\n' "$last_row" | cut -f1)
  valid 'sprint-[0-9]+' "$prev" || die "$sprints_file ends with no sprint row"
  sprint_n=$((${prev#sprint-} + 1))
  sprint_size=$SPRINT_SIZE
  [ "$sprint_n" -ge "$SPRINT_SIZE_FROM" ] || sprint_size=$SPRINT_SIZE_BEFORE
  prev_last=$(printf '%s\n' "$last_row" | cut -f2)
  history=$(history_rows)
  sprint_base=$(printf '%s\n' "$history" | awk -F'\t' -v c="$prev_last" '$1 == c { print $3 }' | tail -1)
  [ -n "$sprint_base" ] || die "the last change of $prev, $prev_last, has no row in $metrics_files"
  sprint_names=$({ printf '%s\n' "$history" | awk -F'\t' -v c="$prev_last" 'seen && NF { print $1 } $1 == c { seen = 1 }'; pending_list; } |
    awk -v r="$REVIEW_RUNS" 'NF && $0 !~ r && !seen[$0]++')
  classes=""
  counted=""
  for name in $sprint_names; do
    class=$(queue_class "$name" "$(merged_of "$name")")
    classes="$classes${class:-none} $name
"
    case "$class" in t0|outside|beyond|pool) ;; *) counted="$counted $name" ;; esac
  done
  # A pool item is a split part when its sibling counted; the first pass
  # found every counted change, so merge order does not matter.
  left=$(printf '%s' "$classes" | while read -r class name; do
    [ "$class" != pool ] || ! split_part "$name" "$counted" || class=sprint
    case "$class" in t0|outside|beyond|pool) echo "$class $name" ;; esac
  done)
  sprint_uncounted=$(printf '%s\n' "$left" | awk 'NF { printf "%s%s", (n++ ? " " : ""), $2 }')
  sprint_left_out=$(printf '%s\n' "$left" | awk '
    NF { names[$1] = names[$1] (names[$1] == "" ? "" : ", ") $2 }
    END {
      split("beyond outside t0 pool", order, " ")
      label["beyond"] = "beyond the sprint"; label["outside"] = "outside the 3"
      label["t0"] = "T0"; label["pool"] = "not a sprint item"
      for (i = 1; i <= 4; i++) if (order[i] in names) printf "; not counted, %s: %s", label[order[i]], names[order[i]]
    }')
  sprint_count=$(printf '%s\n' "$sprint_names" | X=" $sprint_uncounted " awk 'NF && !index(ENVIRON["X"], " " $0 " ")' | grep -c .)
}

# True when NAME, less one trailing "-x" letter, equals a name of the
# space-separated COUNTED or that name less its own letter: a split part
# (finder-grep-c beside finder-grep-b or finder-grep).
split_part() {
  stem=${1%-[a-z]}
  [ "$stem" != "$1" ] || return 1
  for c in $2; do
    if [ "$c" = "$stem" ] || [ "${c%-[a-z]}" = "$stem" ]; then return 0; fi
  done
  return 1
}

# The merged commit of NAME: its history row's, else its run state's.
merged_of() {
  m=$(lane_rows | awk -F'\t' -v c="$1" '$1 == c { m = $3 } END { print m }')
  valid '[0-9a-f]{7,40}' "$m" || m=$(change=$1; merged_commit)
  printf '%s\n' "$m"
}

# Prints each item of the queue on stdin as "item WHERE TEXT" and each
# paragraph starting "The user-approved exception" (not its item form) as
# "para WHERE TEXT", the one reader of the queue line form for queue_class
# and queue_items. An item is numbered, or the line "The user-approved
# exception: `NAME` (...)", its TEXT from the backticked name on; WHERE is
# sprint under a "## Sprint N" heading, else pool, only a "# " or "## "
# heading setting it, so a "###" sub-heading keeps its sprint's. An item's
# or paragraph's continuation lines are joined by a space, to a blank line,
# a heading, or the next item or paragraph.
queue_records() {
  awk '
    function finish() { if (kind != "") print kind, (sprint ? "sprint" : "pool"), text; kind = "" }
    {
      line = $0
      start = sub(/^[0-9]+[.] /, "", line) || sub(/^The user-approved exception: `/, "`", line)
    }
    start { finish(); kind = "item"; text = line; next }
    /^The user-approved exception/ { finish(); kind = "para"; text = $0; next }
    !NF || /^#/ { finish(); if (/^##? /) sprint = /^## Sprint [0-9]+/; next }
    kind != "" { l = $0; sub(/^[ \t]+/, "", l); text = text " " l }
    END { finish() }'
}

# Prints the class of NAME in the queue at the parent of COMMIT, the queue
# it was delivered from, and in the queue at COMMIT, whose package step may
# have applied the plan naming it (queue_records over each), the first
# that either holds of: t0, its item's first parenthesis starts with T0;
# outside, an exception paragraph names `NAME` in a clause between
# semicolons holding OUTSIDE_MARK, before that clause's first " run " or
# " runs " (so "`a` runs before `b`, outside the 3" puts out a, not b);
# beyond, its item's first parenthesis carries BEYOND_SPRINT_MARK; sprint, its
# item sits under a "## Sprint N" heading; pool, under any other. Nothing
# when neither queue names it or COMMIT is no hash.
queue_class() {
  valid '[0-9a-f]{7,40}' "$2" || return 0
  for at in "$2^" "$2"; do queue_at "$at" | queue_records; done |
    C="$1" M="$BEYOND_SPRINT_MARK" O="$OUTSIDE_MARK" awk '
    BEGIN { C = ENVIRON["C"] }
    { text = $0; sub(/^[a-z]+ [a-z]+ /, "", text) }
    $1 == "item" && index(text, "`" C "` (") == 1 {
      if (substr(text, length(C) + 5) ~ /^T0([^0-9]|$)/) t0 = 1
      if (index(substr(text, 1, index(text, ")")), ENVIRON["M"])) beyond = 1
      if ($2 == "sprint") sprint = 1; else pool = 1
    }
    $1 == "para" {
      n = split(text, part, ";")
      for (i = 1; i <= n; i++) {
        if (!index(part[i], ENVIRON["O"])) continue
        cut = match(part[i], / runs? /) ? substr(part[i], 1, RSTART) : part[i]
        if (index(cut, "`" C "`")) outside = 1
      }
    }
    END { print t0 ? "t0" : outside ? "outside" : beyond ? "beyond" : sprint ? "sprint" : pool ? "pool" : "" }'
}

# Prints the item naming NAME (queue_records, its TEXT) on one line, from
# the queue at the parent of COMMIT, the queue it was delivered from, or
# else from the queue at COMMIT, whose package step may have applied the
# plan naming it (item_lists); nothing when neither holds it or COMMIT is
# no hash.
queue_items() {
  valid '[0-9a-f]{7,40}' "$2" || return 0
  for at in "$2^" "$2"; do
    held=$(queue_at "$at" | queue_records | C="$1" awk '
      $1 == "item" { text = $0; sub(/^[a-z]+ [a-z]+ /, "", text) }
      $1 == "item" && index(text, "`" ENVIRON["C"] "` (") == 1 { print text; exit }')
    [ -z "$held" ] || { printf '%s\n' "$held"; return 0; }
  done
}

# True when a sprint plan waits in PLAN_DIR for a package step: its marker
# names a sprint (waiting) that the sprints file has no row for.
sprint_waiting() {
  [ -f "$plan_dir/sprint" ] && [ -f "$sprints_file" ] || return 1
  waiting=$(sed -n '1p' "$plan_dir/sprint")
  valid 'sprint-[0-9]+' "$waiting" || return 1
  ! awk -F'\t' -v s="$waiting" '$1 == s { found = 1 } END { exit !found }' "$sprints_file"
}

# True when the run state sprint-N of the sprint in progress records its
# security review pass or blocked (sprint_security, the result word): a
# plan written without it waits, review-due staying due, so /sprint again
# reviews the sprint anew instead of closing it unreviewed. An even
# sprint, the one review-due asks the sweep for, also needs the sweep's
# run state sprint-N-sweep to record its periodic security review pass,
# blocked, or partial (a whole-tree review at its cap leaves its missed
# areas there): none, a sweep that failed to start, or not-run holds it,
# sprint_security then reading "sweep WORD".
sprint_reviewed() {
  sprint_security=$(change="sprint-$sprint_n"; read_key review.periodic-security)
  sprint_security=${sprint_security%% *}
  case "$sprint_security" in pass|blocked) ;; *) return 1 ;; esac
  [ $((sprint_n % 2)) -eq 0 ] || return 0
  sweep_security=$(change="sprint-$sprint_n-sweep"; read_key review.periodic-security)
  sweep_security=${sweep_security%% *}
  case "$sweep_security" in pass|blocked|partial) return 0 ;; esac
  sprint_security="sweep ${sweep_security:-none}"
  return 1
}

review_due() {
  sprint_state
  list=$(printf '%s\n' "$sprint_names" | awk 'NF { printf "%s%s", (n++ ? ", " : ""), $0 }')
  if sprint_waiting && [ "$waiting" = "sprint-$sprint_n" ] && sprint_reviewed; then
    echo "not due: sprint-$sprint_n is planned; its plan waits in $plan_dir/ for the next delivery's package step (groom)"
    return 1
  fi
  uncounted=$(merge_unrecorded | awk 'NF { printf "%s%s", (n++ ? ", " : ""), $0 }')
  if [ -n "$uncounted" ]; then
    echo "not due: sprint-$sprint_n cannot count a merge phase recorded without its merged commit: $uncounted; record each with sh tools/run_state.sh set NAME merged COMMIT"
    return 1
  fi
  if [ "$sprint_count" -lt "$sprint_size" ]; then
    echo "not due: sprint-$sprint_n has $sprint_count of $sprint_size changes merged${list:+ ($list)}${sprint_left_out}"
    return 1
  fi
  sweep=no
  [ $((sprint_n % 2)) -ne 0 ] || sweep=yes
  echo "due: sprint-$sprint_n has $sprint_count changes merged ($list); combined diff $sprint_base..${BASE:-origin/main}; sweep: $sweep"
}

# The locations (a file:line with an extension) that two or more backlog
# headings name, each with those headings: the candidates of groom's
# duplicate lines, which the model decides.
backlog_dups() {
  [ -d "$backlog_dir" ] || die "no $backlog_dir"
  folded_backlog | awk '/^#+ / && match($0, /[A-Za-z0-9_.\/-]+[.][A-Za-z]+:[0-9]+/) {
      at = substr($0, RSTART, RLENGTH); n[at]++; h[at] = h[at] (n[at] > 1 ? " | " : "") $0 }
    END { for (at in n) if (n[at] > 1) print at ": " h[at] }' | sort
}

# The backlog files, every Markdown file under BACKLOG_DIR in name order,
# one per line.
backlog_files() {
  [ -d "$backlog_dir" ] || return 0
  find "$backlog_dir" -type f -name '*.md' | LC_ALL=C sort
}

# The files the FILE and DIRECTORY arguments name, a directory as each
# Markdown file under it in name order, printed one after another with a
# blank line after each; dies on a missing one before printing any.
backlog_cat() {
  for f in "$@"; do [ -e "$f" ] || die "no $f"; done
  for f in "$@"; do
    if [ -d "$f" ]; then find "$f" -type f -name '*.md' | LC_ALL=C sort; else printf '%s\n' "$f"; fi
  done | while IFS= read -r f; do cat "$f"; echo; done
}

# The entries of the FILE and DIRECTORY arguments (backlog_cat), each a
# "## " or deeper heading to the next heading, ordered by the date of
# their "- Added:" line, an undated one (a findings entry) last, the input
# order kept among equal dates: the oldest first across the backlog files,
# which backlog-pick and backlog-oldest read. A "# " title and the text
# before the first entry are left out.
backlog_stream() {
  backlog_cat "$@" | awk -v T="$TAB" '
    function flush(   i, d) {
      d = date == "" ? "9999-99-99" : date
      for (i = 1; i <= nl; i++) print d T n T i T line[i]
      nl = 0; date = ""
    }
    /^#+ / { flush(); on = /^##+ /; if (on) n++ }
    !on { next }
    date == "" && /^- Added: [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ { date = substr($0, 10, 10) }
    { line[++nl] = $0 }
    END { flush() }' | LC_ALL=C sort -t "$TAB" -k1,1 -k2,2n -k3,3n | cut -f4-
}

# The day groom files a findings entry with: TODAY, else the UTC date.
today_date() {
  printf '%s\n' "${TODAY:-$(date -u +%Y-%m-%d)}"
}

# Files every entry of standard input (a "## " or deeper heading to the
# next heading; a "# " title and the text before the first entry left out)
# into the backlog file of the first file it names, BACKLOG_DIR/PATH.md
# with a leading dot of each part of PATH written as "_" (.claude/x as
# _claude/x), else BACKLOG_DIR/_general.md, a new file starting with a
# "# Backlog:" title; it fails, writing nothing more, when BACKLOG_DIR, a
# directory under it on the way to that file, or the file is a symbolic
# link. A file it names is a token of its text, the heading first, that
# git ls-files lists, the backlog and findings files left out. The entry's
# lines go unchanged, its trailing blank lines cut, followed by "- Also:"
# (the other files it names, left out when none), "- Category:", and
# "- Added:" lines, unless it already holds a "- Category:" line. The
# category is security when the joined entry matches SECURITY_MARK, else
# by its first file, else by words of its text (design when none); the
# date is the one the file DATES ($1, "LINE DATE" lines, LINE the heading's
# line of the input) gives, else today_date. Prints "filed N".
file_entries() {
  listed=$(mktemp) || die "no temporary file"
  git ls-files > "$listed" 2>/dev/null
  mkdir -p "$backlog_dir" 2>/dev/null || { rm -f "$listed"; echo "run_state: no directory $backlog_dir" >&2; return 1; }
  BD="$backlog_dir" LISTED="$listed" DATES="${1:-}" DAY="$(today_date)" S="$SECURITY_MARK" awk '
    BEGIN {
      while ((getline l < ENVIRON["LISTED"]) > 0) if (l !~ /^docs\/(backlog\/|backlog[.]md$|findings\/)/) known[l] = 1
      if (ENVIRON["DATES"] != "") while ((getline l < ENVIRON["DATES"]) > 0) { split(l, p, " "); dated[p[1]] = p[2] }
    }
    function quoted(s) { gsub(/\047/, "\047\\\047\047", s); return "\047" s "\047" }
    # The backlog name of a tracked path: each part starting with a dot
    # written with an underscore instead, so no folder of the backlog is
    # named like a configuration folder of a tool (.claude, .github).
    function backlog_name(p,   n, part, i, out) {
      n = split(p, part, "/"); out = ""
      for (i = 1; i <= n; i++) { if (part[i] ~ /^[.]/) part[i] = "_" substr(part[i], 2); out = out (i > 1 ? "/" : "") part[i] }
      return out
    }
    # True when BACKLOG_DIR, a directory between it and FILE, or FILE is a
    # symbolic link, which a write would follow out of the folder.
    function linked(file,   rel, n, part, i, p, cmd) {
      rel = substr(file, length(ENVIRON["BD"]) + 2); p = ENVIRON["BD"]; cmd = "test -L " quoted(p)
      n = split(rel, part, "/")
      for (i = 1; i <= n; i++) { p = p "/" part[i]; cmd = cmd " || test -L " quoted(p) }
      return system(cmd) == 0
    }
    function category(text, first,   t) {
      t = tolower(text)
      if (t ~ ENVIRON["S"]) return "security"
      if (first != "") {
        if (first ~ /^(\.claude|\.github|tools|openspec)\// || first ~ /^(Makefile|CLAUDE[.]md)$/ || first ~ /^docs\/(queue-|metrics-|goals|sprints|contributor-notes)/) return "pipeline"
        if (first ~ /plugin/) return "plugins"
        if (first ~ /(language|lsp|json_rpc|diagnostic|completion|hover|rubocop)/) return "ide"
        if (first ~ /^(test|bench)\//) return "code-quality"
        if (first ~ /^docs\// || first == "README.md") return "design"
        return "editor"
      }
      if (t ~ /(workflow|agent|planner|contributor|checker|merger|sprint|pull request|gate|stage|run state|queue|scout|deliver)/) return "pipeline"
      if (t ~ /(language server|lsp|rubocop|diagnostic|completion|hover)/) return "ide"
      if (t ~ /plugin/) return "plugins"
      if (t ~ /(buffer|cursor|window|motion|operator|register|keymap|render|screen|insert mode|visual mode|ex command)/) return "editor"
      if (t ~ /(test|lint|snapshot|duplicat|refactor|naming|spinel)/) return "code-quality"
      return "design"
    }
    function flush(   i, text, s, t, np, also, file, d, filed) {
      if (!inside) return
      inside = 0
      while (nl > 0 && line[nl] !~ /[^ \t\r]/) nl--
      text = head; filed = 0; split("", got); np = 0
      for (i = 1; i <= nl; i++) {
        if (line[i] ~ /^- Category: /) filed = 1
        if (line[i] !~ /^- (Also|Category|Added): /) text = text " " line[i]
      }
      for (s = text; match(s, /[A-Za-z0-9_.\/-]+/); s = substr(s, RSTART + RLENGTH)) {
        t = substr(s, RSTART, RLENGTH); sub(/^[.]\//, "", t); sub(/[.]+$/, "", t)
        if ((t in known) && !(t in got)) { got[t] = 1; path[++np] = t }
      }
      also = ""
      for (i = 2; i <= np; i++) also = also (i > 2 ? ", " : "") path[i]
      file = ENVIRON["BD"] "/" (np ? backlog_name(path[1]) : "_general") ".md"
      if (!(file in seen)) {
        if (linked(file)) { print "run_state: a symbolic link on the way to " file ", nothing written to it" > "/dev/stderr"; bad = 1; exit 1 }
        d = file; sub(/\/[^\/]*$/, "", d)
        if (system("mkdir -p " quoted(d)) != 0) { print "no directory " d > "/dev/stderr"; bad = 1; exit 1 }
        seen[file] = (system("test -s " quoted(file)) == 0)
        if (!seen[file]) print "# Backlog: " (np ? path[1] : "entries naming no file") > file
      }
      print "" >> file
      print head >> file
      for (i = 1; i <= nl; i++) print line[i] >> file
      if (!filed) {
        if (also != "") print "- Also: " also >> file
        print "- Category: " category(text, np ? path[1] : "") >> file
        print "- Added: " ((at in dated) ? dated[at] : ENVIRON["DAY"]) >> file
      }
      close(file); seen[file] = 1; count++
    }
    /^#+ / { flush(); if (/^##+ /) { inside = 1; head = $0; at = NR; nl = 0 }; next }
    inside { line[++nl] = $0 }
    END { if (bad) exit 1; flush(); print "filed " count + 0 }'
  status=$?
  rm -f "$listed"
  return $status
}

# The lines of the entries of the FILEs that are not blank, headings
# included, an "- Also:", "- Category:", or "- Added:" line left out: what
# backlog-move compares before and after the move.
entry_lines() {
  [ $# -eq 0 ] || cat "$@" | awk '/^#+ / { on = /^##+ / } on && /[^ \t\r]/ && !/^- (Also|Category|Added): /'
}

# Moves every entry of FILE into the backlog folder (file_entries), each
# dated by the git blame of its heading line (today when FILE has none),
# proves that the folder's sorted entry lines (entry_lines, headings
# included) after the move equal those before plus FILE's, so the count
# and set of headings and every line are kept, and only then removes FILE;
# on a mismatch it keeps FILE and dies.
backlog_move() {
  src=$1
  [ -f "$src" ] || die "backlog-move: no $src"
  dates=$(mktemp) && before=$(mktemp) && after=$(mktemp) || die "backlog-move: no temporary file"
  git blame --date=short -- "$src" 2>/dev/null |
    awk 'match($0, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] +[0-9]+\)/) { s = substr($0, RSTART, RLENGTH - 1); split(s, p, / +/); print p[2], p[1] }' > "$dates"
  { entry_lines "$src"; backlog_files | while IFS= read -r f; do entry_lines "$f"; done; } | LC_ALL=C sort > "$before"
  file_entries "$dates" < "$src" > /dev/null || { rm -f "$dates" "$before" "$after"; die "backlog-move: $src not filed"; }
  backlog_files | while IFS= read -r f; do entry_lines "$f"; done | LC_ALL=C sort > "$after"
  headings=$(entry_lines "$src" | grep -c "^##")
  lines=$(entry_lines "$src" | grep -c .)
  if ! cmp -s "$before" "$after"; then
    rm -f "$dates" "$before" "$after"
    die "backlog-move: the folder's entries differ from those before plus $src's; $src kept"
  fi
  rm -f "$dates" "$before" "$after" "$src"
  echo "backlog-move: moved $src into $backlog_dir, $headings headings and $lines lines kept, $src removed"
}

# Standard input with every reference to a findings file, which groom
# removes once it folded it, written as the removed file, so docs-lint
# finds no path that is gone: `docs/findings/NAME.md` (a :LINE after it
# too) and the directory `docs/findings/`. A heading line is left as it is.
removed_refs() {
  sed -e '/^#/!s#`\{0,1\}docs/findings/\([A-Za-z0-9._-][A-Za-z0-9._-]*\)[.]md\(:[0-9][0-9]*\)\{0,1\}`\{0,1\}#the removed findings file of \1#g' \
    -e '/^#/!s#`docs/findings/\{0,1\}`#the removed findings directory#g'
}

# Standard input, a findings file's text, as groom folds it into the
# backlog: a placeholder line (none or None, a period allowed, alone on its
# line) dropped, and its references to findings files rewritten
# (removed_refs).
fold_clean() {
  awk '!/^[ \t]*[Nn]one[.]?[ \t]*$/' | removed_refs
}

# The backlog files, then each findings file of FINDINGS_DIR in name order
# after a blank line: the backlog as groom writes it, which the sprint
# planner grooms.
folded_backlog() {
  backlog_files | while IFS= read -r f; do cat "$f"; echo; done | removed_refs
  for f in "$findings_dir"/*.md; do
    [ -f "$f" ] || continue
    echo
    awk 'NF { on = 1 } on' "$f" | fold_clean
  done
}

# Every backlog entry under the heading line $1, printed whole: from the
# heading to the next heading of any level, as each entry stands alone.
backlog_entry() {
  folded_backlog | H="$1" awk '
    /^#+ / { on = ($0 == ENVIRON["H"]) }
    on { print }'
}

# True when the entry under the heading line $1 is a security entry: its
# lines joined, so a severity on another line than the word counts, match
# SECURITY_MARK; groom's one judgement of security.
security_entry() {
  backlog_entry "$1" | tr '\n' ' ' | grep -q -i -E "$SECURITY_MARK"
}

# The pick of the backlog lane: the entries (a "## " or deeper heading, to
# the next heading, with a "- Location:" or "- Where:" line or a path:line
# in the heading; any other heading a section) of the PATHs, files or
# directories, oldest first (backlog_stream), which
# it requires, never reading the backlog on its own, ranked into batches of
# one docs/codebase-map.md area each (backlog-pick in the header). The first
# token of a Location that the map places (its backticked tokens first, a
# bare word among them only when the map names it and the tree holds it as
# a file or directory, so an identifier such as `ensure` never places it;
# then each word holding a "." or "/" or a :line, its :line and punctuation
# dropped), else the heading's first path:line, matches a path the map
# names under a numbered area (a bullet's leading path first, then any
# backticked path of the area's lines), or lies under the longest one
# ending in "/", or is a directory holding one (the first in name order);
# an entry whose heading text a queue file holds, not as the start of a
# longer word, is queued, and one whose whole heading line ends a line of
# PLAN_DIR/groom.txt, a gone line's before its " -- REASON", is groomed:
# the closed sprint's removals, which stay in the backlog until the
# package step that carries the sprint's plan. Any entry naming security ranks first here,
# wider than groom's SECURITY_MARK on purpose: a wider ranking only orders
# the batches, while groom's guard decides what may leave.
backlog_pick() {
  for f in "$@"; do [ -e "$f" ] || die "no $f"; done
  backlog_stream "$@" |
    M=docs/codebase-map.md Q="$queue_files" G="$plan_dir/groom.txt" B=$PICK_BATCHES L=$PICK_MIN H=$PICK_MAX awk "$ENTRY_AWK"'
    BEGIN {
      while ((getline line < ENVIRON["M"]) > 0) {
        if (line ~ /^## [0-9]+[.] /) { area = substr(line, 4); continue }
        if (line ~ /^## /) { area = ""; continue }
        if (area == "") continue
        if (match(line, /^- `[^`]+`/)) own[substr(line, 4, RLENGTH - 4)] = area
        for (s = line; match(s, /`[^` ]+`/); s = substr(s, RSTART + RLENGTH)) {
          t = substr(s, RSTART + 1, RLENGTH - 2)
          if (t ~ /^[A-Za-z0-9_.\/-]+$/ && !(t in seen)) seen[t] = area
        }
      }
      nq = split(ENVIRON["Q"], qf, " ")
      for (i = 1; i <= nq; i++) while ((getline line < qf[i]) > 0) queued = queued "\n" line
      load_groomed(ENVIRON["G"])
    }
    /^##+ / { n++; head[n] = $0; on = 1; next }
    /^#+ / { on = 0; next }
    on && !(n in loc) && /^- (Location|Where):/ { loc[n] = $0 }
    on && /^- Why( it matters)?:/ { why[n] = $0 }
    function queued_at(t,   s, j) {
      for (s = queued; (j = index(s, t)) > 0; s = substr(s, j + 1))
        if (substr(s, j + length(t), 1) !~ /[A-Za-z0-9_]/) return 1
      return 0
    }
    function under(m, p,   k, best) {
      if (p in m) return m[p]
      best = ""
      for (k in m) if (k ~ /\/$/ && index(p, k) == 1 && length(k) > length(best)) best = k
      return best == "" ? "" : m[best]
    }
    function area_of(p,   a) {
      if (p == "") return ""
      a = under(own, p)
      return a != "" ? a : under(seen, p)
    }
    function dir_area(p,   d, k, best) {
      if (p !~ /\//) return ""
      d = p; if (d !~ /\/$/) d = d "/"
      best = ""
      for (k in own) if (index(k, d) == 1 && (best == "" || k < best)) best = k
      if (best != "") return own[best]
      for (k in seen) if (index(k, d) == 1 && (best == "" || k < best)) best = k
      return best == "" ? "" : seen[best]
    }
    function place(p,   a) {
      a = area_of(p)
      return a != "" ? a : dir_area(p)
    }
    function clean(t) {
      sub(/^[ \t]+/, "", t); sub(/[ \t].*$/, "", t); sub(/^[(\"]+/, "", t)
      if (t ~ /::/) return ""
      sub(/:.*$/, "", t); sub(/[).,;\"]+$/, "", t)
      return t ~ /^[A-Za-z0-9_.\/-]+$/ ? t : ""
    }
    function pathlike(raw, t) {
      return t != "" && (t ~ /[.\/]/ || raw ~ /^[A-Za-z0-9_.\/-]+:[0-9]/)
    }
    function named_file(t) {
      if (!((t in own) || (t in seen) || ((t "/") in own) || ((t "/") in seen))) return 0
      return system("test -e \"" t "\"") == 0
    }
    function candidates(s,   k, r, raw, t, nw, w, x) {
      k = 0
      for (r = s; match(r, /`[^`]+`/); r = substr(r, RSTART + RLENGTH)) {
        raw = substr(r, RSTART + 1, RLENGTH - 2); t = clean(raw)
        if (pathlike(raw, t)) cand[++k] = t
        else if (t != "" && t == raw && named_file(t)) cand[++k] = ((t in own) || (t in seen)) ? t : t "/"
      }
      gsub(/`/, "", s); nw = split(s, w, /[ \t]+/)
      for (x = 1; x <= nw; x++) if (pathlike(w[x], t = clean(w[x]))) cand[++k] = t
      return k
    }
    function head_path(h) {
      if (!match(h, /[A-Za-z0-9_.\/-]+[.][A-Za-z]+:[0-9]+/)) return ""
      h = substr(h, RSTART, RLENGTH); sub(/:[0-9]+$/, "", h); return h
    }
    END {
      for (i = 1; i <= n; i++) {
        hp = head_path(head[i])
        if (!backlog_entry_head(head[i], (i in loc))) continue
        t = head[i]; sub(/^#+ /, "", t)
        if (queued_at(t) || (head[i] in groomed)) continue
        s = loc[i]; sub(/^- (Location|Where):[ \t]*/, "", s)
        nc = candidates(s); a = ""; p = ""
        for (c = 1; c <= nc && a == ""; c++) if ((a = place(cand[c])) != "") p = cand[c]
        if (a == "" && (a = area_of(hp)) != "") p = hp
        if (p == "") p = nc ? cand[1] : hp
        if (a == "") { print "unmapped: " head[i] " (" p ")"; continue }
        at[i] = a; count[a]++
        if (tolower(head[i] " " why[i]) ~ /security/) { secure[i] = 1; nsec[a]++ }
      }
      for (pass = 1; pass <= 2; pass++)
        for (i = 1; i <= n; i++)
          if ((i in at) && !(at[i] in ranked) && (pass == 2 || (i in secure))) { ranked[at[i]] = 1; order[++m] = at[i] }
      for (r = 1; r <= m && b < ENVIRON["B"] + 0; r++) {
        a = order[r]; alone = count[a] < ENVIRON["L"] + 0
        if (alone && !nsec[a]) continue
        b++; k = 0; out = ""
        for (pass = 1; pass <= (alone ? 1 : 2); pass++)
          for (i = 1; i <= n && k < ENVIRON["H"] + 0; i++)
            if (at[i] == a && ((pass == 1) == (i in secure))) { k++; out = out "\n" head[i] }
        print "batch " b ": area " a ", " (alone ? "its " k " security entries alone of " count[a] : k " of " count[a] " entries") out
      }
      if (!b) { print "no batch: no area holds " ENVIRON["L"] " entries and none names security"; exit 1 }
    }'
}

# The sprint's row from its history rows up to the sprint_size-th counted
# one, where it ends, a later uncounted change's row (sprint_uncounted)
# left to the next sprint, whose combined diff starts there: the last
# change, the merges, the changes, the wall minutes and their mean per
# change, the total tokens, the runs over their size's
# budget (TOKEN_BUDGETS), and each gate's first passes.
sprint_row() {
  history_rows | awk -F'\t' -v c="$prev_last" -v budgets="$TOKEN_BUDGETS" -v s="sprint-$sprint_n" -v size="$sprint_size" -v r="$REVIEW_RUNS" -v x=" $sprint_uncounted " '
    BEGIN { n = split(budgets, b, " "); for (i = 1; i <= n; i++) { split(b[i], kv, "="); budget[kv[1]] = kv[2] } }
    seen && NF && !done && $1 !~ r {
      ex = index(x, " " $1 " ") > 0
      if (counted == size) { done = 1; next }
      if (!ex) counted++
      rows++; names = names (rows > 1 ? "," : "") $1; last = $1
      if ($17 ~ /^[0-9.]+$/) wall += $17
      if ($16 ~ /^[0-9]+$/) { tokens += $16; if (($15 in budget) && $16 + 0 > budget[$15] + 0) over++ }
      m = split($6, g, ",")
      for (i = 1; i <= m; i++) {
        if (split(g[i], gv, ":") != 2) continue
        if (!(gv[1] in total)) order[++k] = gv[1]
        total[gv[1]]++; if (gv[2] == 1) pass[gv[1]]++
      }
    }
    $1 == c { seen = 1 }
    END {
      for (i = 1; i <= k; i++) fp = fp (i > 1 ? "," : "") order[i] ":" (pass[order[i]] + 0) "/" total[order[i]]
      printf "%s\t%s\t%d\t%s\t%.1f\t%.1f\t%d\t%d\t%s\n", s, last, rows, names, wall, rows ? wall / rows : 0, tokens, over, fp == "" ? "-" : fp
    }'
}

# True when the item naming NAME (queue_items) in the queue at the parent
# of COMMIT, the queue it was delivered from, or else at COMMIT, holds the
# whole heading line HEADING, bounded: no "#" before it; quoted, as the
# planner writes it (Backlog: "### title"), the same quote or backtick
# after it; unquoted, the end of the item or a comma after it. So a
# shorter heading that prefixes a quoted longer one, even before a comma
# inside the quotes, is not listed. Groom's proof that a merged item
# listed it.
item_lists() {
  queue_items "$1" "$2" | H="$3" awk '
    {
      h = ENVIRON["H"]; o = 0
      while ((p = index(substr($0, o + 1), h)) > 0) {
        p += o; o = p
        before = p > 1 ? substr($0, p - 1, 1) : ""
        after = substr($0, p + length(h), 1)
        if (before == "\"" || before == "`") ok = after == before
        else ok = before != "#" && (after == "" || after == ",")
        if (ok) { found = 1; exit }
      }
    }
    END { exit !found }'
}

# True when COMMIT changes a file the entry under the heading line HEADING
# names, as a whole path token (a "./" prefix allowed, a "." after it only
# ending a sentence, so not tools/c.sh.bak for tools/c.sh): in the heading
# or its "- Location:" or "- Where:" lines, or anywhere in an entry with
# neither, such as a group of findings. A merge commit lists no file, so it
# proves nothing. Groom's proof that the commit fixed it.
touches_entry() {
  entry_naming "$2" | touches_named "$1"
}

# True when COMMIT ($1) changes a file the naming text on stdin names, as
# touches_entry says; the gates read the text of an entry groom removed.
touches_named() {
  files=$(git diff-tree --no-commit-id --name-only -r --root --end-of-options "$1" 2>/dev/null)
  [ -n "$files" ] || return 1
  F="$files" awk '
    { text = text "\n" $0 }
    END {
      n = split(ENVIRON["F"], f, "\n")
      for (i = 1; i <= n && !found; i++) {
        if (f[i] == "") continue
        rest = text; off = 0
        while (!found && (p = index(rest, f[i])) > 0) {
          before = substr(rest, p - 1, 1)
          if (before == "/" && substr(rest, p - 2, 1) == ".") before = substr(rest, p - 3, 1)
          after = substr(rest, p + length(f[i]), 1)
          if (after == ".") after = substr(rest, p + length(f[i]) + 1, 1)
          if (before !~ /[A-Za-z0-9_.\/-]/ && after !~ /[A-Za-z0-9_.\/-]/) found = 1
          rest = substr(rest, p + 1)
        }
      }
      exit !found
    }'
}

# The text naming the files of the entry under the heading line $1, the
# lines touches_entry and entry_paths read: the heading and its
# "- Location:" or "- Where:" lines, or the whole entry when neither.
entry_naming() {
  backlog_entry "$1" | naming_of
}

# The same for an entry printed whole on stdin, heading first.
naming_of() {
  awk '
    /^#+ / || /^- (Location|Where):/ { named = named "\n" $0; marked += !/^#+ / }
    { all = all "\n" $0 }
    END { s = marked ? named : all; if (s != "") print substr(s, 2) }'
}

# The paths the entry under the heading line $1 names, each once: the
# tokens of its naming text (entry_naming) holding a "/" or ending in an
# extension, a "./" prefix, a ":line", and closing dots dropped. Groom's
# gone line counts only those the history held.
entry_paths() {
  entry_naming "$1" | awk '
    { text = text "\n" $0 }
    END {
      n = split(text, w, /[^A-Za-z0-9_.\/:-]+/)
      for (i = 1; i <= n; i++) {
        t = w[i]; sub(/^[.]\//, "", t); sub(/:.*$/, "", t); sub(/[.]+$/, "", t)
        if (t !~ /^[.\/-]/ && (t ~ /\// || t ~ /[^.][.][A-Za-z0-9]+$/) && !(t in seen)) { seen[t] = 1; print t }
      }
    }'
}

# The heading lines of the first PRUNE_COUNT entries of the FILEs, in
# order (backlog-oldest in the header): the oldest, by their "- Added:"
# date (backlog_stream), the findings entries, undated, last. An entry is
# a "## " or "### " heading with a path:line in it or a "- Location:" or
# "- Where:" line; one whose whole heading line ends a line of
# PLAN_DIR/groom.txt is left out, as backlog-pick leaves it out.
backlog_oldest() {
  for f in "$@"; do [ -e "$f" ] || die "no $f"; done
  backlog_stream "$@" | G="$plan_dir/groom.txt" N=$PRUNE_COUNT awk "$ENTRY_AWK"'
    BEGIN { load_groomed(ENVIRON["G"]) }
    function close_entry() {
      if (h != "" && backlog_entry_head(h, marked) && !(h in groomed) && !(h in shown) && count < ENVIRON["N"] + 0) {
        print h; shown[h] = 1; count++
      }
      h = ""; marked = 0
    }
    /^#+ / { close_entry(); if (/^###? /) h = $0; next }
    /^- (Location|Where):/ { marked = 1 }
    END { close_entry() }'
}

# Applies a waiting sprint plan, every line of groom.txt checked before
# anything is written. A listed heading (its change one of the sprint's,
# whose queue item holds it, item_lists) or a fixed one (its commit in the
# sprint's range, sprint_base..HEAD, changing a file the entry names,
# touches_entry) loses every entry under it; a duplicate heading that
# stands more than once keeps its first entry, one that stands once needs
# another heading at its location (backlog-dups). A gone heading carries
# its reason after the line's last " -- ", why the problem no longer
# applies, and names at least one path the history held, none of them
# standing at HEAD (entry_paths). An entry leaves only with evidence,
# never for its age (the user's rule of 2026-11-21): a stale line (an
# entry old and unnamed) and a closed one (a later commit touching a file
# it names, fix or not) are refused. The intake: a merged heading's lines are appended
# under its kept heading after a "- Merged:" line, so both reasons and
# locations stay, each line passed on under its own prefix so no text in
# it redirects the rest; the kept heading must stand and no line may
# remove it.
# A security entry (security and a severity in any wording, security_entry,
# judged once per line before the proofs) leaves only by
# a merged item's listed heading or its fixing commit in the sprint
# (fixed), never gone or duplicate, and merges only into
# another security entry. A heading merges once: no other line may
# already remove it.
# A plan is applied once: the marker is the clone's and the sprints file
# each branch's, so applying it, or finding its row in the sprints file or
# BASE's, retires the marker to PLAN_DIR/sprint.applied.
groom() {
  if sprint_applied; then
    mv "$plan_dir/sprint" "$plan_dir/sprint.applied" || die "groom: $plan_dir/sprint not retired"
    rm -f "$plan_dir/sprint.carrier"
    echo "groom: $waiting already has its row in $applied_in; not applied again, its marker retired"
    return 0
  fi
  if ! sprint_waiting; then
    if [ -f "$plan_dir/sprint" ]; then
      echo "groom: $(sed -n 1p "$plan_dir/sprint") has its row in $sprints_file, carried by this branch; its marker stays until ${BASE:-origin/main} holds the row"
    else
      echo "groom: no sprint plan waits in $plan_dir/"
    fi
    return 0
  fi
  [ -n "${1:-}" ] || die "groom: the plan of $waiting is applied by a delivery's package step, groom CHANGE; not by a run with no change"
  sprint_state
  [ "$waiting" = "sprint-$sprint_n" ] || die "groom: the plan of $waiting is not the sprint in progress, sprint-$sprint_n"
  if ! sprint_reviewed; then
    echo "groom: the plan of sprint-$sprint_n waits for its security review (${sprint_security:-none}); run /sprint again"
    return 0
  fi
  carried_by=$(carrier_of)
  if [ -n "$carried_by" ] && [ "$carried_by" != "$1" ]; then
    echo "groom: the plan of sprint-$sprint_n is carried by $carried_by's package step; not applied again (remove $plan_dir/sprint.carrier only when $carried_by will not merge)"
    return 0
  fi
  if hold=$(queue_hold); then
    echo "groom: the plan of sprint-$sprint_n is held by $hold; the first delivery planned after the fix merged applies it"
    return 0
  fi
  rows=$(printf '%s\n' "$history" | awk -F'\t' -v c="$prev_last" -v r="$REVIEW_RUNS" -v x=" $sprint_uncounted " 'seen && NF && $1 !~ r && !index(x, " " $1 " ") { n++ } $1 == c { seen = 1 } END { print n + 0 }')
  [ "$rows" -ge "$sprint_size" ] || die "groom: sprint-$sprint_n has $rows of $sprint_size history rows; run history first"
  removals=""
  repeats=""
  merges=""
  kept=""
  base_ok=""
  if [ -f "$plan_dir/groom.txt" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      [ -n "$line" ] || continue
      kind=${line%% *}
      rest=${line#* }
      case "$kind" in
        listed|fixed) word=${rest%% *}; heading=${rest#* } ;;
        duplicate) word=""; heading=$rest ;;
        gone)
          word=""; heading=${rest% -- *}; reason=${rest##* -- }
          [ "$heading" != "$rest" ] && [ -n "$(printf '%s' "$reason" | tr -d ' \t')" ] ||
            die "groom: a gone line carries its reason, gone HEADING -- REASON, why the problem no longer applies: $line" ;;
        stale|closed)
          die "groom: an entry leaves only with evidence (listed, fixed, gone with its reason, merged, or duplicate), never for its age or a later commit touching its file, so no $kind line: $line" ;;
        merged)
          word=${rest%% <= *}; heading=${rest#* <= }
          [ "$word" != "$rest" ] || die "groom: not a merged line, merged KEPT <= HEADING: $line" ;;
        *) die "groom: not a groom line: $line" ;;
      esac
      stands=$(folded_backlog | grep -c -x -F -e "$heading")
      [ "$stands" -ge 1 ] && valid '#{2,3} .+' "$heading" || die "groom: not a heading line of $backlog_dir or a findings file: $heading"
      if security_entry "$heading"; then
        case "$kind" in
          gone|duplicate)
            die "groom: a security entry leaves only by a merged item's heading or its fixing commit in the sprint (listed or fixed), never $kind: $heading" ;;
          merged)
            security_entry "$word" || die "groom: a security entry merges only into another security entry: $line" ;;
        esac
      fi
      case "$kind" in
        listed)
          sprint_change "$word" ||
            die "groom: $word is not a change of sprint-$sprint_n: $line"
          item_lists "$word" "$(merged_of "$word")" "$heading" ||
            die "groom: the queue item of $word does not list the heading: $line" ;;
        fixed)
          valid '[0-9a-f]{7,40}' "$word" && git merge-base --is-ancestor "$word" HEAD 2>/dev/null ||
            die "groom: $word is not a commit of HEAD: $line"
          [ -n "$base_ok" ] || { valid '[0-9a-f]{7,40}' "$sprint_base" && git rev-parse -q --verify --end-of-options "$sprint_base^{commit}" > /dev/null ||
            die "groom: the base of sprint-$sprint_n, $sprint_base, names no commit, so no fix is in its range: $line"; base_ok=1; }
          ! git merge-base --is-ancestor "$word" "$sprint_base" 2>/dev/null ||
            die "groom: $word is outside the range of sprint-$sprint_n, $sprint_base..HEAD: $line"
          touches_entry "$word" "$heading" ||
            die "groom: $word changes no file the entry names: $line" ;;
        gone)
          held=""
          for p in $(entry_paths "$heading"); do
            [ -n "$(git log -1 --format=%H -- "$p" 2>/dev/null)" ] || continue
            ! git cat-file -e "HEAD:$p" 2>/dev/null || die "groom: $p, which the entry names, still stands at HEAD: $line"
            held=1
          done
          [ -n "$held" ] || die "groom: the entry names no path the history held, so nothing proves it gone: $line" ;;
        merged)
          folded_backlog | grep -q -x -F -e "$word" && valid '#{2,3} .+' "$word" ||
            die "groom: not a heading line of $backlog_dir or a findings file: $word"
          [ "$word" != "$heading" ] || die "groom: an entry merges into another, not into itself: $line"
          ! printf '%s' "$removals" | grep -q -x -F -e "$heading" ||
            die "groom: another line already removes $heading, so it merges once: $line"
          # Each line of merges carries its prefix: "@" before a kept
          # heading, "|" before a line to append under it, so no text of
          # a merged body redirects or drops the rest.
          body=$(backlog_entry "$heading" | awk '/^#+ / { next } /^- (Category|Added): / { next } NF { for (; held > 0; held--) print "|"; print "|" $0; on = 1; next } on { held++ }')
          merges="$merges@$word
|- Merged: $heading
${body:+$body
}"
          kept="$kept$word
" ;;
        duplicate)
          if [ "$stands" -gt 1 ]; then
            repeats="$repeats$heading
"
            continue
          fi
          at=$(printf '%s\n' "$heading" | grep -o -E '[A-Za-z0-9_./-]+[.][A-Za-z]+:[0-9]+' | head -1)
          [ -n "$at" ] && backlog_dups | grep -q -F -e "$at: " || die "groom: no other heading names the location of: $heading" ;;
      esac
      removals="$removals$heading
"
    done < "$plan_dir/groom.txt"
  fi
  while IFS= read -r k; do
    [ -z "$k" ] || ! printf '%s' "$removals" | grep -q -x -F -e "$k" ||
      die "groom: $k takes a merged entry, so no line may remove it"
  done <<EOF
$kept
EOF
  for l in feature backlog; do
    [ ! -f "$plan_dir/queue-$l.md" ] || cp "$plan_dir/queue-$l.md" "docs/queue-$l.md"
  done
  folded=$(ls "$findings_dir"/*.md 2>/dev/null | grep -c .)
  # The findings files are filed first, so the removals and merges below
  # reach their entries in the backlog files as well.
  if [ "$folded" -gt 0 ]; then
    for f in "$findings_dir"/*.md; do cat "$f"; echo; done | fold_clean | file_entries > /dev/null || die "groom: the findings files not filed into $backlog_dir"
  fi
  # One pass over every backlog file, each after a marker line naming it,
  # so a repeated heading keeps its first entry across the folder and a
  # merged entry reaches its kept heading in any file; each file's text
  # goes to FILE.groom, then over FILE, a file left with no entry removed.
  mark=$(printf '\001')
  backlog_files | while IFS= read -r f; do printf '%s%s\n' "$mark" "$f"; cat "$f"; done | removed_refs |
    M="$mark" R="$removals" D="$repeats" A="$merges" awk '
    BEGIN {
      n = split(ENVIRON["R"], r, "\n"); for (i = 1; i <= n; i++) if (r[i] != "") gone[r[i]] = 1
      n = split(ENVIRON["D"], d, "\n"); for (i = 1; i <= n; i++) if (d[i] != "") repeat[d[i]] = 1
      n = split(ENVIRON["A"], a, "\n"); if (n && a[n] == "") n--
      for (i = 1; i <= n; i++)
        if (substr(a[i], 1, 1) == "@") cur = substr(a[i], 2)
        else add[cur] = add[cur] substr(a[i], 2) "\n"
    }
    # A merged entry goes after the last line of its kept entry, before
    # the blank lines that end it.
    function flush() {
      if (into != "") printf "%s", add[into] > out
      into = ""
      for (; held > 0; held--) print "" > out
    }
    index($0, ENVIRON["M"]) == 1 {
      if (out != "") { flush(); close(out) }
      out = substr($0, length(ENVIRON["M"]) + 1) ".groom"; skip = 0
      printf "" > out
      next
    }
    /^#+ / {
      flush(); seen[$0]++; skip = ($0 in gone) || (($0 in repeat) && seen[$0] > 1)
      if (!skip && seen[$0] == 1 && ($0 in add)) into = $0
    }
    skip { next }
    into != "" && !NF { held++; next }
    { for (; held > 0; held--) print "" > out; print > out }
    END { if (out != "") { flush(); close(out) } }' || { find "$backlog_dir" -name '*.md.groom' -exec rm -f {} +; die "groom: $backlog_dir not rewritten"; }
  backlog_files | while IFS= read -r f; do
    if grep -q '^##' "$f.groom"; then mv "$f.groom" "$f"; else rm -f "$f.groom" "$f"; fi
  done
  [ "$folded" -eq 0 ] || rm -f "$findings_dir"/*.md
  [ ! -f "$plan_dir/groomed.md" ] || file_entries < "$plan_dir/groomed.md" > /dev/null || die "groom: $plan_dir/groomed.md not filed into $backlog_dir"
  sprint_row >> "$sprints_file"
  printf 'sprint-%s %s\n' "$sprint_n" "$1" > "$plan_dir/sprint.carrier" || die "groom: $plan_dir/sprint.carrier not written"
  echo "groom: applied sprint-$sprint_n: $(printf '%s' "$removals$repeats" | grep -c .) headings groomed, $folded findings file(s) folded, its row appended to $sprints_file, carried by $1"
}

# True when the marker names a sprint (waiting) whose row BASE's sprints
# file holds (applied_in): only then is the plan merged; a row only in the
# working tree is its carrier's, not yet on main.
sprint_applied() {
  [ -f "$plan_dir/sprint" ] || return 1
  waiting=$(sed -n '1p' "$plan_dir/sprint")
  valid 'sprint-[0-9]+' "$waiting" || return 1
  applied_in="${BASE:-origin/main}'s $sprints_file"
  git show "${BASE:-origin/main}:$sprints_file" 2>/dev/null |
    awk -F'\t' -v s="$waiting" '$1 == s { found = 1 } END { exit !found }'
}

# True when NAME is a change of the sprint in progress (sprint_names).
sprint_change() {
  valid '[a-z0-9][a-z0-9-]*' "$1" && printf '%s\n' "$sprint_names" | grep -q -x -F -e "$1"
}

# True when the groom line $2 ("listed CHANGE HEADING" or "fixed COMMIT
# HEADING") holds the proof groom applies to it, against the sprint in
# progress at COMMIT ($1) as sprint_row_at reads it, the text of the entry
# it removes on stdin, heading first, since the entry no longer stands: a
# listed change is one of the sprint's and its queue item lists the
# heading; a fixed commit is in the sprint's range, after its base, and
# changes a file the entry names. Silent: the gates (tools/gates.sh) ask it
# of a line of the local plan, which no step but the planner writes.
groom_proof() {
  kind=${2%% *}
  rest=${2#* }
  case "$kind" in listed|fixed) ;; *) return 1 ;; esac
  word=${rest%% *}
  heading=${rest#* }
  [ "$word" != "$rest" ] || return 1
  text=$(cat)
  at=$(commit_at "$1") || return 1
  rows=$(mktemp) || return 1
  git show "$at:$sprints_file" > "$rows" 2>/dev/null || { rm -f "$rows"; return 1; }
  (
    sprints_file=$rows
    sprint_state > /dev/null 2>&1 || exit 1
    case "$kind" in
      listed) sprint_change "$word" && item_lists "$word" "$(merged_of "$word")" "$heading" ;;
      fixed)
        valid '[0-9a-f]{7,40}' "$word" && valid '[0-9a-f]{7,40}' "$sprint_base" &&
          git merge-base --is-ancestor "$word" HEAD 2>/dev/null &&
          git rev-parse -q --verify --end-of-options "$sprint_base^{commit}" > /dev/null &&
          ! git merge-base --is-ancestor "$word" "$sprint_base" 2>/dev/null &&
          printf '%s\n' "$text" | naming_of | touches_named "$word" ;;
    esac
  ) > /dev/null 2>&1
  proof=$?
  rm -f "$rows"
  return $proof
}

# The row groom appends for the sprint the marker names (PLAN_DIR/sprint,
# else the sprint.applied groom retired it to), computed by sprint_row
# against the sprints file at COMMIT ($1) and the history rows of the
# working tree; dies when the marker names another sprint than the one in
# progress at COMMIT. The records-only gate (tools/gates.sh, groom_row)
# accepts no other appended row.
sprint_row_at() {
  marker=$plan_dir/sprint
  [ -f "$marker" ] || marker=$plan_dir/sprint.applied
  [ -f "$marker" ] || die "sprint-row: no sprint marker in $plan_dir/"
  named=$(sed -n '1p' "$marker")
  valid 'sprint-[0-9]+' "$named" || die "sprint-row: $marker names no sprint"
  at=$(commit_at "$1") || exit 1
  rows=$(mktemp) || die "sprint-row: no temporary file"
  git show "$at:$sprints_file" > "$rows" 2>/dev/null || { rm -f "$rows"; die "sprint-row: no $sprints_file at $at"; }
  row=$(
    sprints_file=$rows
    sprint_state
    [ "$named" = "sprint-$sprint_n" ] || die "sprint-row: $marker names $named, but the sprint in progress at $at is sprint-$sprint_n"
    sprint_row
  ) || { rm -f "$rows"; exit 1; }
  rm -f "$rows"
  printf '%s\n' "$row"
}

# True when CHANGE ($2, the change whose package step runs COMMAND $1) has
# its planning records excluded, records=skip in its run state, which the
# workflow sets from the brief or the planner; says so.
records_excluded() {
  [ -n "$2" ] || return 1
  case "$2" in */*|.*|*[[:cntrl:]]*) die "not a change name: $2" ;; esac
  [ "$(change=$2; read_key records)" = skip ] || return 1
  what="nothing appended"
  [ "$1" != groom ] || what="nothing applied"
  echo "$1: $2 excludes the planning records (records=skip); $what"
}

# True when a change planned and merged after a periodic review of COMMIT
# recorded at TIME ($2, its at.review.periodic-security): any history
# row's change merged after COMMIT (the rows read newest first, up to the
# first merged at or before it, since main is linear), or a pending one,
# whose merged commit and recorded phase.plan both descend from COMMIT and
# are not it, its planner not skipped (metric.planned is not 0), and
# whose at.plan-needed, the time plan-needed read the review runs before
# its planner, is strictly later than TIME.
# That planner saw the review: plan-needed names a failing review before
# any other reason and the workflow passes the review run to the planner,
# so its finding was delivered first or judged not blocking. A change
# planned before the review was recorded, whatever its commits descend
# from, or resumed past its plan after it, clears nothing, nor does any
# merge clear a review with no record time, such as one recorded before
# record times existed, which only a later whole-tree pass supersedes
# (passed_since). Later merges whose planner was skipped leave it cleared.
# A merge planned at or before COMMIT, or without its run state, clears
# nothing (review-coverage-b, periodic-clear-rules). A COMMIT git does
# not know is never merged since.
merged_since() {
  record_time "$2" || return 1
  since=$(full_commit "$1") || return 1
  rows=$(history_rows | awk -F'\t' 'NR > 1 && $3 ~ /^[0-9a-f]+$/ { r[++n] = $1 ":" $3 } END { for (i = n; i > 0; i--) print r[i] }')
  after=
  for row in $rows; do
    descends "$since" "${row#*:}" || break
    after="$after ${row%%:*}"
  done
  for ran in $after $(pending_list); do
    valid '[a-z0-9][a-z0-9-]*' "$ran" || continue
    commits=$(change=$ran; planned_commits)
    [ -n "$commits" ] || continue
    for m in $commits; do
      descends "$since" "$m" || continue 2
    done
    later_than "$(change=$ran; read_key at.plan-needed)" "$2" || continue
    return 0
  done
  return 1
}

# True when a whole-tree review run (REVIEW_RUNS but a sprint's diff
# review, sprint-N, whose scope covers no other review) records a passing
# periodic security review (pass, no blocking finding) at a commit that
# descends from COMMIT and is not it and, when TIME ($2, the failing
# review's at.review.periodic-security) is a record time, recorded
# strictly after TIME: a later whole-tree security review superseded the
# failing one at COMMIT (review-coverage-b, periodic-clear-rules).
passed_since() {
  since=$(full_commit "$1") || return 1
  for later in $(review_runs); do
    ! valid "$DIFF_REVIEW_RUN" "$later" || continue
    passed=$(change=$later; read_key review.periodic-security)
    case "$passed" in
      "pass "*) ;;
      *) continue ;;
    esac
    case "$passed " in *" blocking="[1-9]*) continue ;; esac
    at=${passed#pass }
    at=${at%% *}
    valid '[0-9a-f]{7,40}' "$at" || continue
    descends "$since" "$at" || continue
    if record_time "$2"; then
      later_than "$(change=$later; read_key at.review.periodic-security)" "$2" || continue
    fi
    return 0
  done
  return 1
}

# The names of the review runs (REVIEW_RUNS), one per line: the run states
# no sprint counts, listed as pending_list lists the others.
review_runs() {
  for review_file in "$state_dir"/*.json; do
    [ -f "$review_file" ] || continue
    review_name=$(basename "$review_file" .json)
    ! printf '%s\n' "$review_name" | grep -q -E "$REVIEW_RUNS" || echo "$review_name"
  done
}

# The full commit COMMIT names when it is 7 to 40 hexadecimal digits
# naming a commit; fails otherwise.
full_commit() {
  valid '[0-9a-f]{7,40}' "$1" || return 1
  git rev-parse --verify -q --end-of-options "$1^{commit}" 2>/dev/null
}

# True when TIME is a record time as utc_now writes it.
record_time() {
  valid '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' "$1"
}

# True when TIME and OTHER are record times and TIME is strictly later.
later_than() {
  record_time "$1" && record_time "$2" && [ "$(printf '%s\n%s\n' "$1" "$2" | LC_ALL=C sort | tail -1)" = "$1" ] && [ "$1" != "$2" ]
}

# The change's merged and phase.plan commits, on one line, when both are 7
# to 40 hexadecimal digits and its planner was not skipped (metric.planned
# is not 0); nothing otherwise.
planned_commits() {
  [ -f "$(state_file)" ] || return 0
  [ "$(read_key metric.planned)" != 0 ] || return 0
  planned_merged=$(read_key merged)
  planned_plan=$(read_key phase.plan)
  valid '[0-9a-f]{7,40}' "$planned_merged" && valid '[0-9a-f]{7,40}' "$planned_plan" || return 0
  echo "$planned_merged $planned_plan"
}

# True when COMMIT, a hexadecimal hash (planned_commits checked it), names
# a commit that descends from the full commit SINCE and is not it.
descends() {
  full=$(git rev-parse --verify -q --end-of-options "$2^{commit}" 2>/dev/null) || return 1
  [ "$full" != "$1" ] && git merge-base --is-ancestor "$1" "$full" 2>/dev/null
}

# Whether the queue needs the planner before the change starts: needed,
# first, when a review run (REVIEW_RUNS) records a failing periodic security
# review (blocked, or blocking findings counted) and no change planned after
# it was recorded merged since (merged_since) nor a later whole-tree one
# passed (passed_since), the line naming that run, which the workflow hands
# the planner so its security-first stop applies whatever else needs it;
# then when the change is not the first item of a lane queue
# (docs/queue-feature.md or docs/queue-backlog.md), or when another merged
# change without a history row holds a note of a PLAN_NOTES kind (a
# retrospective proposal, an overrun, a periodic finding) that only the
# planner places, unless a sprint plan placed it (placed_by_sprint), or when
# the head item names no estimate; otherwise the head item is taken as
# written, its size printed for the run's estimate. It prints one line: a
# run whose brief is only the change name has its agents read the item in
# its lane queue. Before it reads the review runs it records the time,
# at.plan-needed, in the change's run state while that holds no phase.plan,
# phase.implement, or merged record, the condition the workflow runs the
# planner under, so merged_since knows which reviews that planner was handed
# and a resume past the plan keeps the last time it read them before the
# plan.
plan_needed() {
  if [ -f "$(state_file)" ] && [ -z "$(read_key phase.plan)$(read_key phase.implement)$(read_key merged)" ]; then
    write_key at.plan-needed "$(utc_now)"
  fi
  queues=$queue_files
  ! sprint_waiting || queues="$plan_dir/queue-feature.md $plan_dir/queue-backlog.md"
  for run in $(review_runs); do
    record=$(change=$run; read_key review.periodic-security)
    case "${record%% *}: $record" in
      blocked:*|*" blocking="[1-9]*) ;;
      *) continue ;;
    esac
    reviewed=${record#* }
    reviewed=${reviewed%% *}
    recorded=$(change=$run; read_key at.review.periodic-security)
    merged_since "$reviewed" "$recorded" && continue
    passed_since "$reviewed" "$recorded" && continue
    echo "needed: $run records a failing periodic security review at $reviewed, and no change planned after it has merged since, nor has a later whole-tree security review passed"
    return 0
  done
  queue=""
  heads=""
  for q in $queues; do
    item=$(sed -n 's/^1[.] //p' "$q" 2>/dev/null | head -1)
    name=$(printf '%s\n' "$item" | sed -n 's/^`\([a-z0-9][a-z0-9-]*\)`.*/\1/p')
    heads="$heads${heads:+, }${name:-no named item}"
    [ -n "$queue" ] || [ "$name" != "$change" ] || { queue=$q; head_item=$item; }
  done
  if [ -z "$queue" ]; then
    echo "needed: $change is not the head of $queues ($heads)"
    return 0
  fi
  for other in $(pending_list); do
    [ "$other" != "$change" ] || continue
    ! placed_by_sprint "$(change=$other; merged_commit)" || continue
    n=$(change=$other; grep -c -E "^  \"note[.][0-9]+\": \"($PLAN_NOTES) " "$(state_file)")
    if [ "$n" -gt 0 ]; then
      echo "needed: $other holds $n proposal(s) or finding(s) to place"
      return 0
    fi
  done
  size=$(printf '%s\n' "$head_item" | awk 'match($0, /estimated (small|medium|large)/) { print substr($0, RSTART + 10, RLENGTH - 10) }')
  if [ -z "$size" ]; then
    echo "needed: $change heads $queue with no estimate"
    return 0
  fi
  echo "not needed: $change heads $queue, estimated $size, and no pending change holds a proposal or finding"
  return 1
}

# True when the merged commit MERGED is at or before the commit a sprint's
# security review read (sprint-N's review.periodic-security, pass or
# blocked) and that sprint's plan was written (PLAN_DIR/sprint or
# sprint.applied names it, or the sprints file holds its row): that
# sprint's planner read the notes of every change merged before its review
# and wrote the queue, so they wait for no delivery's planner
# (plan-skip-placed, planner-loop).
placed_by_sprint() {
  valid '[0-9a-f]{7,40}' "$1" || return 1
  placed_since=$(git rev-parse --verify -q --end-of-options "$1^{commit}" 2>/dev/null) || return 1
  for placed_file in "$state_dir"/sprint-*.json; do
    placed_run=$(basename "$placed_file" .json)
    valid "$DIFF_REVIEW_RUN" "$placed_run" || continue
    placed_review=$(change=$placed_run; read_key review.periodic-security)
    case "$placed_review" in "pass "*|"blocked "*) ;; *) continue ;; esac
    placed_at=${placed_review#* }
    placed_at=${placed_at%% *}
    valid '[0-9a-f]{7,40}' "$placed_at" || continue
    { [ "$(sed -n 1p "$plan_dir/sprint" 2>/dev/null)" = "$placed_run" ] || [ "$(sed -n 1p "$plan_dir/sprint.applied" 2>/dev/null)" = "$placed_run" ] ||
      awk -F'\t' -v s="$placed_run" '$1 == s { found = 1 } END { exit !found }' "$sprints_file" 2>/dev/null; } || continue
    git merge-base --is-ancestor "$placed_since" "$placed_at" 2>/dev/null && return 0
  done
  return 1
}

# True when COMMIT is 7 to 40 hexadecimal digits naming a commit that is
# an ancestor of HEAD, or of the base (BASE, origin/main), where the merged
# phases' squash commits are.
supported() {
  full=$(full_commit "$1") || return 1
  on_head_or_base "$full" "$base_commit"
}

# The state as a resume may trust it: one flat object of the lines
# write_key writes, leaving out each phase.*, review.*, and merged record
# whose commit git does not support, any line not in write_key's form (a
# control character, an escape other than \" and \\, a key outside
# [a-z0-9_.-]), and a key already seen, then "untrusted", the keys left out.
trusted_state() {
  file=$(state_file)
  [ -f "$file" ] || die "no run state for $change"
  base_commit=$(git rev-parse --verify -q --end-of-options "${BASE:-origin/main}^{commit}" 2>/dev/null)
  drop=" "
  names=""
  listing=$(C=" $(LC_ALL=C grep -n '[[:cntrl:]]' "$file" | cut -d: -f1 | tr '\n' ' ')" awk '
    $0 == "{" || $0 == "}" { next }
    {
      key = $0; sub(/^  "/, "", key); sub(/".*/, "", key); gsub(/[^a-z0-9_.-]/, "?", key)
      if (key == "") key = "?"
      if (index(ENVIRON["C"], " " NR " ")) { print NR, key, "bad", "-"; next }
      if ($0 !~ /^  "[a-z0-9][a-z0-9_.-]*": "([^"\\]|\\["\\])*",?$/) { print NR, key, "bad", "-"; next }
      if (seen[key]++) { print NR, key, "bad", "-"; next }
      if (key == "untrusted") { print NR, key, "skip", "-"; next }
      if (key !~ /^(phase|review)[.]/ && key != "merged") next
      value = $0; sub(/^  "[^"]*": "/, "", value); sub(/",?$/, "", value)
      if (key ~ /^review[.]/) { split(value, word, " "); value = word[2] }
      gsub(/[^0-9a-zA-Z]/, "?", value)
      print NR, key, "record", (value == "" ? "-" : value)
    }' "$file")
  while read -r n key kind commit; do
    case "$kind" in
      bad) drop="$drop$n "; names="${names:+$names }$key" ;;
      skip) drop="$drop$n " ;;
      record) supported "$commit" || { drop="$drop$n "; names="${names:+$names }$key"; } ;;
    esac
  done <<EOF_LIST
$listing
EOF_LIST
  D="$drop" U="$names" awk '
    $0 == "{" || $0 == "}" { next }
    index(ENVIRON["D"], " " NR " ") == 0 { line = $0; sub(/,$/, "", line); lines[n++] = line }
    END {
      if (ENVIRON["U"] != "") lines[n++] = "  \"untrusted\": \"" ENVIRON["U"] "\""
      print "{"
      for (i = 0; i < n; i++) print lines[i] (i < n - 1 ? "," : "")
      print "}"
    }' "$file"
}

usage() {
  sed -n '/^# Usage:/,/^# Environment:/p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

# The delivery worktrees (parallel-lanes-b): each delivery runs in its own
# git worktree of the main checkout, tmp/.lane-CHANGE, hidden since spin
# reads every visible directory as source, so a feature-lane and a
# backlog-lane delivery run at once. What the deliveries share stays the
# main checkout's, linked in: the one toolchain and compile cache, and the
# run states, stage logs, and plans this script and the workflow read
# there. A lane's merge gates and benchmark base are worktrees under its own
# tmp/, so two deliveries never share one.
LANE_LINKS="tmp/.spinel tmp/.toolchain build/spinel-cache build/pipeline build/stages build/plan"

# main_top: the main checkout's root, from a linked worktree too.
main_top() {
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || die "lane: not a git repository"
  [ "$(basename "$common")" = .git ] || die "lane: the main checkout has no .git directory: $common"
  dirname "$common"
}

# lane_remove DIR: removes a lane's worktree, its links first so no removal
# can reach what they point at: the one step lane_open and lane_close share.
lane_remove() {
  for l in $LANE_LINKS; do
    [ ! -L "$1/$l" ] || rm -f "$1/$l"
  done
  git worktree remove --force "$1"
}

lane_open() {
  branch=$1
  valid '(feature|bugfix|hotfix|release|chore)/[a-z0-9][a-z0-9-]*' "$branch" || die "lane-open: not a Conventional Branch: $branch"
  top=$(main_top) || exit 1
  cd "$top" || die "lane-open: cannot enter $top"
  dir=tmp/.lane-$change
  git worktree prune
  if [ -e "$dir" ] || [ -L "$dir" ]; then
    [ -d "$dir" ] && [ ! -L "$dir" ] && [ -f "$dir/.git" ] || die "lane-open: $dir stands and is not a worktree"
    if [ "$(git -C "$dir" symbolic-ref -q --short HEAD)" != "$branch" ]; then
      lane_remove "$dir" || die "lane-open: the replaced run's $dir could not be removed"
      echo "lane-open: removed the replaced run's $dir"
    fi
  fi
  # The remote-tracking refs a worktree starts from are read after origin's
  # own answer: its main fetched, and the ref of BRANCH fetched, or removed
  # when origin holds no such branch, so a ref a stage planted in an earlier
  # check seeds nothing. An unreachable origin leaves them, with a note.
  if [ -z "${BASE:-}" ] && git remote get-url origin > /dev/null 2>&1; then
    if remote_branch=$(GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 bounded git -c core.hooksPath=/dev/null ls-remote origin "refs/heads/$branch" 2>/dev/null) &&
        pinned_git fetch -q --no-tags --refmap= origin +refs/heads/main:refs/remotes/origin/main 2>/dev/null; then
      if [ -z "$remote_branch" ]; then
        git update-ref -d "refs/remotes/origin/$branch" 2>/dev/null || :
      else
        pinned_git fetch -q --no-tags --refmap= origin "+refs/heads/$branch:refs/remotes/origin/$branch" 2>/dev/null || :
      fi
    else
      echo "lane-open: origin could not be read; its remote-tracking refs are used as they stand" >&2
    fi
  fi
  if [ ! -e "$dir" ]; then
    mkdir -p tmp
    if git show-ref -q --verify "refs/heads/$branch"; then
      git worktree add -q "$dir" "$branch"
    elif git show-ref -q --verify "refs/remotes/origin/$branch"; then
      git worktree add -q --track -b "$branch" "$dir" "origin/$branch"
    else
      git worktree add -q --no-track -b "$branch" "$dir" "${BASE:-origin/main}"
    fi || die "lane-open: git worktree add of $branch at $dir failed (a branch checked out in the main checkout is checked out there first: check out main in it)"
  fi
  # Every target is made first, so a lane opened before make toolchain
  # still links the one toolchain the main checkout installs into later.
  # The branch's tree is not trusted: a link target the branch commits (a
  # tmp or build symlink out of the repository), or a path of the shared
  # state the branch tracks (a build/pipeline of its own, read as the run
  # state), would steer what the lane reads and writes, so it is refused.
  for l in $LANE_LINKS; do
    parent=$(dirname "$l")
    [ ! -L "$dir/$parent" ] || die "lane-open: $dir/$parent is a link: the branch commits it; the lane's links go only into a real directory"
    [ -z "$(git -C "$dir" ls-files -- "$l")" ] || die "lane-open: the branch tracks $l, a path of the shared state the lane links to the main checkout's"
    if [ -L "$dir/$l" ] && [ "$(readlink "$dir/$l")" != "$top/$l" ]; then
      die "lane-open: $dir/$l is a link to $(readlink "$dir/$l"), not to $top/$l"
    fi
  done
  for l in $LANE_LINKS; do
    mkdir -p "$l" || die "lane-open: cannot make $top/$l"
    mkdir -p "$dir/$(dirname "$l")"
    [ -e "$dir/$l" ] || [ -L "$dir/$l" ] || ln -s "$top/$l" "$dir/$l"
  done
  echo "lane: $dir on $branch"
}

lane_close() {
  top=$(main_top) || exit 1
  cd "$top" || die "lane-close: cannot enter $top"
  dir=tmp/.lane-$change
  if [ ! -e "$dir" ] && [ ! -L "$dir" ]; then
    git worktree prune
    echo "lane-close: no $dir"
    return 0
  fi
  [ -d "$dir" ] && [ ! -L "$dir" ] && [ -f "$dir/.git" ] || die "lane-close: $dir is not a worktree"
  lane_remove "$dir" || die "lane-close: git worktree remove of $dir failed"
  git worktree prune
  echo "lane-close: removed $dir"
}

# merge_main: main moved while the delivery ran; merge it in, never a
# rebase or a force-push. The appended records (each lane's metrics rows,
# the findings files, the sprint rows) merge by git's union driver, given
# by an attributes file of this merge alone, both sides' rows kept; a
# conflict only in the lane queues keeps the branch's own lane's and
# main's other; a conflict in anything else is the contributor's, by the
# conflict rules of its push mode.
APPENDED_RECORDS="docs/metrics-*.tsv docs/findings/*.md docs/sprints.tsv"
merge_main() {
  branch=$(pinned_git symbolic-ref -q --short HEAD) || die "merge-main: HEAD is not on a branch"
  [ "$branch" != main ] || die "merge-main: HEAD is main"
  [ -z "$(pinned_git status --porcelain --untracked-files=no)" ] || die "merge-main: the tracked tree is dirty"
  base=${BASE:-origin/main}
  if [ -z "${BASE:-}" ]; then
    pinned_git fetch -q --refmap= origin +refs/heads/main:refs/remotes/origin/main || die "merge-main: the fetch of origin's main failed"
  fi
  if pinned_git merge-base --is-ancestor "$base" HEAD; then
    echo "merge-main: $branch holds $base"
    return 0
  fi
  # The branch's lane, read before the merge leaves conflict markers in
  # the queues lane_of reads.
  own=$(lane_of 2>/dev/null) || own=""
  attrs=$(mktemp "${TMPDIR:-/tmp}/carat-union.XXXXXX") || die "merge-main: mktemp failed"
  (set -f; for p in $APPENDED_RECORDS; do echo "$p merge=union"; done) > "$attrs"
  if merge_out=$(pinned_git -c core.attributesFile="$attrs" -c user.name=Claude -c user.email=noreply@anthropic.com merge -q --no-ff --no-edit \
      -m "chore: merge main into the branch" -m "Co-Authored-By: Claude <noreply@anthropic.com>" "$base" 2>&1); then
    rm -f "$attrs"
    echo "merge-main: merged $base into $branch at $(pinned_git rev-parse --short=12 HEAD)"
    return 0
  fi
  rm -f "$attrs"
  files=$(pinned_git diff --name-only --diff-filter=U | tr '\n' ' ')
  # A merge that failed with no conflicted file (an untracked file it would
  # overwrite, a missing ref) shows git's own words, and aborts only a
  # merge in progress.
  if [ -z "$files" ]; then
    [ ! -f "$(pinned_git rev-parse --git-path MERGE_HEAD)" ] || pinned_git merge --abort 2>/dev/null
    echo "merge-main: the merge of $base failed with no conflicted file: $(printf '%s\n' "$merge_out" | head -n 5 | tr '\n' ' ')"
    exit 1
  fi
  # Each lane's package step edits only its own lane queue, and the one
  # that carries a sprint plan (groom) both: a conflict only in the lane
  # queues keeps the branch's own lane queue and main's other, so both
  # lanes' edits stand (planner-loop).
  others=$(pinned_git diff --name-only --diff-filter=U | grep -v -x -E 'docs/queue-(feature|backlog)[.]md')
  if [ -n "$files" ] && [ -z "$others" ] && { [ "$own" = feature ] || [ "$own" = backlog ]; }; then
    for l in feature backlog; do
      pinned_git diff --name-only --diff-filter=U | grep -q -x -F "docs/queue-$l.md" || continue
      side=--theirs
      [ "$l" != "$own" ] || side=--ours
      { pinned_git checkout "$side" -- "docs/queue-$l.md" && pinned_git add -- "docs/queue-$l.md"; } || { pinned_git merge --abort 2>/dev/null; die "merge-main: docs/queue-$l.md not resolved"; }
    done
    if pinned_git -c user.name=Claude -c user.email=noreply@anthropic.com commit -q --no-edit \
        -m "chore: merge main into the branch" -m "Co-Authored-By: Claude <noreply@anthropic.com>" > /dev/null 2>&1; then
      echo "merge-main: merged $base into $branch at $(pinned_git rev-parse --short=12 HEAD), the $own lane queue kept from $branch and the other from $base"
      return 0
    fi
  fi
  pinned_git merge --abort 2>/dev/null
  echo "merge-main: conflicts in ${files:-no file named}; merge $base by hand by the conflict rules and commit the merge"
  exit 1
}

# moved_change COMMIT: after merge_main took in a moved main, whether the
# change's reviews at COMMIT (the reviewed commit) stand at HEAD. The names
# of three diffs, each status checked: REVIEWED, the change at COMMIT
# against its merge base with BASE (origin/main); CURRENT, HEAD against
# its own; MOVED, COMMIT against HEAD. They stand only when no name of
# MOVED is in REVIEWED or CURRENT and every name of CURRENT is in
# REVIEWED, so HEAD matches the new main in every file the change never
# touched, outside the records-only paths (RECORDS_RE) in both, an
# instruction record (INSTRUCTION_RECORDS_RE) counted as a file. Names are
# compared as text (grep -F -x), never handed to git as pathspecs. Only
# that path records moved, "HEAD COMMIT" in full, which a carried review
# needs (review); it is dropped first, so a refusal leaves none and the
# reviews run again (merge-main-path, moved-review-carry).
moved_change() {
  [ ! -f "$(state_file)" ] || drop_key moved
  at=$(git rev-parse -q --verify --end-of-options "$1^{commit}") || die "moved: not a commit: $1"
  git merge-base --is-ancestor "$at" HEAD || die "moved: $1 is not an ancestor of HEAD"
  base=${BASE:-origin/main}
  old_base=$(git merge-base "$base" "$at") || die "moved: $1 shares no history with $base"
  new_base=$(git merge-base "$base" HEAD) || die "moved: HEAD shares no history with $base"
  head_full=$(git rev-parse HEAD) || die "moved: no HEAD"
  short_at=$(git rev-parse --short=12 "$at")
  short_head=$(git rev-parse --short=12 HEAD)
  reviewed=$(git diff --no-renames --name-only "$old_base" "$at") &&
    current=$(git diff --no-renames --name-only "$new_base" HEAD) &&
    moved_names=$(git diff --no-renames --name-only "$at" HEAD) &&
    base_names=$(git diff --no-renames --name-only "$old_base" "$new_base") || {
    echo "moved: git diff failed comparing $short_at, HEAD, and $base; the reviews run again at $short_head"
    exit 1
  }
  # A file main changed (base_names) that the change also holds is as
  # changed as one the merge moved, though a conflict kept the change's own
  # text there and left it out of moved_names: the main fix is gone from HEAD.
  files=$(printf '%s\n%s\n' "$reviewed" "$current" | outside_records | sort -u)
  changed=$( [ -z "$files" ] || printf '%s\n%s\n' "$moved_names" "$(printf '%s\n' "$base_names" | outside_records)" | grep -F -x -e "$files" | sort -u | tr '\n' ' ')
  if [ -n "$changed" ]; then
    echo "moved: the merge changed files of the change: ${changed% }; the reviews run again at $short_head"
    exit 1
  fi
  untouched=$(printf '%s\n' "$current" | outside_records |
    { if [ -n "$reviewed" ]; then grep -v -F -x -e "$reviewed"; else cat; fi; } | sort -u | tr '\n' ' ')
  if [ -n "$untouched" ]; then
    echo "moved: HEAD differs from $base in files the change never touched: ${untouched% }; the reviews run again at $short_head"
    exit 1
  fi
  write_key moved "$head_full $(git rev-parse "$at")"
  echo "moved: the change is the same at $short_head as at $short_at: the merge of $base changed no file of the change, so its reviews stand"
}

# carried_backed KIND COMMIT: true when the moved record, which only the
# exit-0 path of moved_change writes, names COMMIT as its head and, as its
# reviewed commit, another commit: the one the existing review.KIND record
# passed at (read before review overwrites it). So a review the workflow
# carries to COMMIT (summary carried=1) is recorded only from the commit it
# passed at, and moved run at the head against itself backs nothing; sets
# moved_record for the refusal.
carried_backed() {
  moved_record=$(read_key moved)
  [ -n "$moved_record" ] || return 1
  carried_head=${moved_record%% *}
  carried_from=${moved_record#* }
  carried_from=${carried_from%% *}
  [ "$carried_head" = "$(git rev-parse -q --verify "$2^{commit}")" ] || return 1
  [ "$carried_from" != "$carried_head" ] || return 1
  carried_prior=$(read_key "review.$1")
  [ "${carried_prior%% *}" = pass ] || return 1
  carried_prior=${carried_prior#pass }
  carried_prior=${carried_prior%% *}
  valid '[0-9a-f]{7,40}' "$carried_prior" || return 1
  [ "$carried_from" = "$(git rev-parse -q --verify "$carried_prior^{commit}")" ]
}

[ $# -ge 1 ] || usage
command=$1
shift
case "$command" in
  status) show_status; exit 0 ;;
  pending) pending_list; exit 0 ;;
  history) [ $# -le 1 ] || usage; records_excluded history "${1:-}" || append_history "${1:-}"; exit 0 ;;
  review-due) [ $# -eq 0 ] || usage; review_due; exit $? ;;
  backlog-dups) [ $# -eq 0 ] || usage; backlog_dups; exit $? ;;
  backlog-move) [ $# -eq 1 ] || usage; backlog_move "$1"; exit $? ;;
  backlog-pick) [ $# -ge 1 ] || usage; backlog_pick "$@"; exit $? ;;
  backlog-oldest) [ $# -ge 1 ] || usage; backlog_oldest "$@"; exit $? ;;
  groom) [ $# -le 1 ] || usage; ! records_excluded groom "${1:-}" || exit 0; groom "${1:-}"; exit $? ;;
  sprint-row)
    [ $# -eq 1 ] || { [ $# -eq 2 ] && [ "$2" = committed ]; } || usage
    [ $# -eq 1 ] || history_at=HEAD
    sprint_row_at "$1"; exit $? ;;
  groom-proof) [ $# -eq 2 ] || usage; groom_proof "$1" "$2"; exit $? ;;
esac
[ $# -ge 1 ] || usage
change=$1
shift
case "$change" in
  ""|*/*|.*|*[[:cntrl:]]*) die "not a change name: $change" ;;
esac
# A check's and bench's metrics stay in the change's lane (lane-isolation):
# run from the main checkout while tmp/.lane-CHANGE exists, under the
# lane's build/, never the main checkout's shared build/, which another
# lane's check scans for writes (main_scan). Inside the lane the relative
# default already is the lane's own.
[ -n "${METRICS_OUT:-}" ] || [ ! -d "tmp/.lane-$change" ] || metrics_out=tmp/.lane-$change/build/metrics/current.tsv

case "$command" in
  init)
    [ $# -eq 1 ] || usage
    mkdir -p "$state_dir"
    # A delivery never reuses a merged name: a recurring change takes a
    # unique one (spinel-bump-<7-char commit>). A merged run the close has
    # not closed (no phase.retro) resumes, so a restart after the merge
    # reaches its retrospective. The sprint and review run states, at main,
    # set merged after their init and resume by it.
    if [ "$1" != main ]; then
      done_at=$([ ! -f "$(state_file)" ] || [ -z "$(read_key phase.retro)" ] || merged_commit)
      [ -z "$done_at" ] || die "init: refused: $change merged as $done_at; take a unique name, such as $change-<7-char commit>"
      ! has_row "$change" || die "init: refused: $change has a lane history row, so it merged; take a unique name, such as $change-<7-char commit>"
    fi
    if [ -f "$(state_file)" ]; then
      echo "run_state: resuming $change" >&2
    else
      plain "$1" "the branch"
      repo=$(git remote get-url origin 2>/dev/null | sed -E 's#^.*[:/]([^/]+/[^/]+)$#\1#; s#\.git$##')
      plain "$repo" "the remote's name"
      printf '{\n  "change": "%s",\n  "branch": "%s",\n  "repo": "%s",\n  "pushes": "0",\n  "ci_fixes": "0"\n}\n' \
        "$(escape "$change")" "$(escape "$1")" "$(escape "$repo")" > "$(state_file)"
    fi
    cat "$(state_file)" ;;
  show)
    [ -f "$(state_file)" ] || die "no run state for $change"
    cat "$(state_file)" ;;
  trusted)
    [ $# -eq 0 ] || usage
    trusted_state ;;
  get)
    [ $# -eq 1 ] || usage
    read_key "$1" ;;
  set)
    [ $# -eq 2 ] || usage
    value=$2
    case "$1" in
      review.*|phase.*|stage.*|at.*|note.*|gated|moved) die "set: refused: $1 is written only by its own command (review, phase, stage, review and plan-needed, note, check, gated, moved)" ;;
      change|branch|repo) die "set: refused: $1 is written only by init, since open_pr wait and the merge read it" ;;
      pushed) valid '[0-9a-f]{7,40}' "$2" || die "set: refused: $1 is a commit hash of 7 to 40 hexadecimal digits, not $2" ;;
      hold) [ "$2" = security-first ] || die "set: refused: hold is security-first, the plan's security first sprint-planning records, not $2" ;;
      merged) value=$(merged_at "$2" set) || exit 1 ;;
      ci)
        valid '(red|green) [0-9a-f]{7,40}' "$2" || die "set: refused: ci is red or green and the pushed head, not $2"
        at=$(pushed_at "${2#* }" set) || exit 1
        value="${2%% *} $at" ;;
    esac
    write_key "$1" "$value" ;;
  phase)
    [ $# -eq 1 ] || [ $# -eq 2 ] || { [ $# -eq 3 ] && [ "$1" = merge ] && [ "$2" = merged ]; } || usage
    one_of "$1" "$PHASES" || die "phase: not a phase: $1 (one of $PHASES)"
    case "$1:${2:-}" in
      merge:merged|retro:merged|report:merged)
        at=$(squash_of_change phase) || exit 1
        if [ $# -eq 3 ] && ! { valid '[0-9a-f]{7,40}' "$3" &&
            [ "$(git rev-parse --verify -q --short=12 --end-of-options "$3^{commit}" 2>/dev/null)" = "$at" ]; }; then
          add_note merge-disagreement "the merged commit reported, $(printf '%s' "$3" | cut -c1-40), is not the squash commit on main, $at, recorded instead"
        fi ;;
      *:merged) die "phase: refused: only merge, retro, and report are recorded at the merged commit, not $1" ;;
      ci:*) at=$(pushed_at "${2:-$(head_commit)}" phase) || exit 1 ;;
      merge:*)
        at=$(merged_at "${2:-$(head_commit)}" phase) || exit 1
        # A recorded merged naming another commit refuses both values; the
        # word merged checks it in squash_of_change.
        recorded=$(read_key merged)
        [ -z "$recorded" ] || [ "$(git rev-parse --verify -q --short=12 --end-of-options "$recorded^{commit}" 2>/dev/null)" = "$at" ] ||
          die "phase: refused: the recorded merged commit $recorded is not the merge's commit $at" ;;
      *) at=$(commit_at "${2:-}") || exit 1 ;;
    esac
    # The merge phase records its merged commit first, the commit just
    # checked on main, so no run state holds a merge without the merged
    # value pending_list and review_due count it by.
    [ "$1" != merge ] || [ -n "$(read_key merged)" ] || write_key merged "$at"
    write_key "phase.$1" "$at" ;;
  review)
    [ $# -eq 3 ] || [ $# -eq 4 ] || usage
    one_of "$1" "$REVIEW_KINDS" || die "review: not a review kind: $1 (one of $REVIEW_KINDS)"
    case "$1:$2" in *:pass|*:blocked|periodic-*:partial|periodic-*:not-run) ;;
      periodic-*) die "review result is pass, blocked, partial, or not-run, not $2" ;;
      *) die "review result is pass or blocked, not $2" ;; esac
    at=$(commit_at "${4:-}") || exit 1
    case " $3 " in *" carried=1 "*) carried_backed "$1" "$at" || die "review: refused: a carried review at $at needs tools/run_state.sh moved to have exited 0 at that commit against the commit review.$1 passed at (the moved record: ${moved_record:-none})" ;; esac
    write_key "review.$1" "$2 $at $3"
    [ "$1" != periodic-security ] || write_key at.review.periodic-security "$(utc_now)"
    [ "$2" != pass ] || write_key "phase.$1" "$at" ;;
  stage)
    [ $# -ge 2 ] || usage
    plain_key "stage.$1"
    run_stage "$@" ;;
  scope)
    [ $# -ge 1 ] || usage
    fix_scope "$@" ;;
  settled)
    [ $# -eq 1 ] || usage
    settled_round "$1" ;;
  check)
    [ $# -le 1 ] || usage
    backed=""
    [ $# -eq 0 ] || backed=$(backed_commit "$1") || exit 1
    check_wait "$backed" ;;
  check-run)
    [ $# -le 1 ] || usage
    check_run "${1:-}" ;;
  bench)
    [ $# -eq 0 ] || usage
    bench_compare ;;
  base-figures)
    [ $# -le 1 ] || usage
    base_figures "${1:-}" ;;
  carried)
    [ $# -eq 1 ] || usage
    carried_check "$1" ;;
  gated)
    [ $# -eq 1 ] || usage
    case "$1" in
      clear) gated_clear ;;
      pass) write_key gated "$(git rev-parse HEAD)" ;;
      *) usage ;;
    esac ;;
  push)
    push_branch "${1:-}" ;;
  metric)
    [ $# -ge 1 ] || usage
    for pair in "$@"; do record_metric "$pair"; done ;;
  metrics)
    [ $# -eq 1 ] || usage
    import_metrics "$1" ;;
  note)
    [ $# -eq 2 ] || usage
    add_note "$1" "$2" ;;
  budget)
    [ $# -eq 0 ] || usage
    budget_line ;;
  spent)
    [ $# -eq 0 ] || usage
    spent_line ;;
  lane)
    [ $# -eq 0 ] || usage
    lane_of ;;
  plan-apply)
    [ $# -eq 0 ] || usage
    plan_apply ;;
  lane-open)
    [ $# -eq 1 ] || usage
    lane_open "$1" ;;
  lane-close)
    [ $# -eq 0 ] || usage
    lane_close ;;
  merge-main)
    [ $# -eq 0 ] || usage
    merge_main ;;
  moved)
    [ $# -eq 1 ] || usage
    moved_change "$1" ;;
  usage)
    [ $# -eq 2 ] || usage
    add_usage "$1" "$2" ;;
  ci-stages)
    [ $# -eq 1 ] || usage
    ci_stages "$1" ;;
  tokens)
    [ $# -eq 1 ] || usage
    add_tokens "$1" ;;
  plan-needed)
    [ $# -eq 0 ] || usage
    plan_needed ;;
  reviewed-edits)
    [ $# -eq 0 ] || usage
    reviewed_edits ;;
  *)
    usage ;;
esac
