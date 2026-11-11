#!/bin/sh
# Tests the shell tools behind CI and the delivery pipeline, each in a
# temporary git repository or directory outside this one:
# tools/ci_scope.sh (which changes run the checks), tools/ci_wait.sh (the
# merger's wait), tools/metrics.sh (the measurement and the comparison with
# main), tools/run_state.sh (the run state, stages, resume, the push rule,
# the records only the workflow writes, the history, the budget, and the
# review areas), tools/agent_guard.sh (each profile's forms and refusals,
# and the agents' hook lines), tools/docs_lint.sh (budgets, content, wraps,
# paths, queue), tools/new.sh (every generator and its refusals),
# tools/spec_validate.sh (the archive preview, with a stub openspec), and
# every gate of tools/gates.sh, each passing and refusing.
# Prints "ok   NAME" or "FAIL NAME" and the output, then "P/T passed";
# exits 1 when any failed. Run by make tools-test.
#
# Forbidden text (addresses, links, model names) is assembled from pieces
# here, so this file does not trip the content gate it tests.
set -u

here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/carat-tools-test.XXXXXX")
trap 'rm -rf "$work"' EXIT
TRAILER='Co-Authored-By: Claude <noreply@anthropic.com>'
SCHEME="https:"
LINK="$SCHEME//example"".org/page"
MAIL="someone""@""example.org"
TIER="son""net"
passed=0
total=0

# expect NAME STATUS PATTERN COMMAND...: COMMAND exits with STATUS and its
# output matches the extended regular expression PATTERN.
expect() {
  name=$1 want=$2 pattern=$3
  shift 3
  total=$((total + 1))
  out=$("$@" 2>&1)
  got=$?
  if [ "$got" = "$want" ] && printf '%s\n' "$out" | grep -q -E -- "$pattern"; then
    passed=$((passed + 1))
    echo "ok   $name"
  else
    echo "FAIL $name (exit $got, wanted $want and /$pattern/)"
    printf '%s\n' "$out" | sed 's/^/  | /'
  fi
}

git_q() {
  git -c user.name=Claude -c user.email=noreply@anthropic.com -c init.defaultBranch=main "$@"
}

# commit MESSAGE: commit everything with MESSAGE and the trailer.
commit() {
  git_q add -A
  git_q commit -q -m "$1" -m "$TRAILER"
}

# fresh NAME: a repository with a base commit on main and a branch
# chore/NAME checked out; prints nothing, changes into it.
fresh() {
  cd "$work" || exit 1
  rm -rf "$1"
  git_q init -q "$1"
  cd "$1" || exit 1
  mkdir -p docs tools test
  printf '## build: compile\nbuild:\n\ttrue\n' > Makefile
  echo "# map" > docs/codebase-map.md
  echo "# rules" > CLAUDE.md
  echo "# readme" > README.md
  echo "echo base" > tools/base.sh
  echo build/ > .gitignore
  commit "chore: base"
  git_q checkout -q -b "chore/$1"
}

state() {
  sh "$here/run_state.sh" "$@"
}

gates() {
  BASE=main STAGES=lint sh "$here/gates.sh" "$@"
}

# ------------------------------------------------------------ ci_scope.sh

scope() {
  EVENT=$1 REPO=owner/carat SHA=$(git rev-parse HEAD) sh "$here/ci_scope.sh"
}

scope_case() {
  fresh scope
  mkdir -p "$(dirname "$2")"
  echo change >> "$2"
  commit "chore: change $2"
  expect "ci_scope: $2 on a pull request" 0 "^run=$1" scope pull_request
}

scope_case false docs/notes.md
scope_case false openspec/changes/x/proposal.md
scope_case false .claude/agents/x.md
scope_case false docs/metrics.tsv
scope_case true docs/codebase-map.md
scope_case true docs/actions.md
scope_case true tools/x.sh
expect "ci_scope: a run by hand always runs" 0 "^run=true" scope workflow_dispatch

# ------------------------------------------------------------ ci_wait.sh
expect "ci_wait: waits the given seconds" 0 "^ci_wait: waited 1 seconds$" sh "$here/ci_wait.sh" 1
expect "ci_wait: refuses zero" 2 "refused: 0 seconds" sh "$here/ci_wait.sh" 0
expect "ci_wait: refuses more than 540" 2 "refused: 541 seconds" sh "$here/ci_wait.sh" 541
expect "ci_wait: refuses a number past the shell's integer range" 2 "refused: 99999999999999999999999 seconds" sh "$here/ci_wait.sh" 99999999999999999999999
expect "ci_wait: refuses a value that is not a whole number" 2 "not a whole number" sh "$here/ci_wait.sh" '1; true'
expect "ci_wait: refuses no value" 2 "not a whole number" sh "$here/ci_wait.sh"
mkdir -p "$work/failing"
printf '#!/bin/sh\nexit 1\n' > "$work/failing/sleep"
chmod +x "$work/failing/sleep"
expect "ci_wait: fails when the sleep fails" 1 "^ci_wait: sleep failed" env PATH="$work/failing:$PATH" sh "$here/ci_wait.sh" 1

mkdir -p "$work/bin"
cat > "$work/bin/gh" <<'EOF'
#!/bin/sh
case "$*" in
  *head.sha*) echo "$FAKE_HEAD" ;;
  *number*) echo 7 ;;
  *tree.sha*) echo "$FAKE_TREE" ;;
  *check-runs*) echo "$FAKE_PASSED" ;;
esac
EOF
chmod +x "$work/bin/gh"
fresh push
echo code >> tools/x.sh
commit "chore: code"
tree=$(git rev-parse 'HEAD^{tree}')
expect "ci_scope: a push whose tree passed in its pull request skips" 0 "^run=false: the tree equals the head of pull request 7" \
  env PATH="$work/bin:$PATH" FAKE_HEAD=abc FAKE_TREE="$tree" FAKE_PASSED=1 EVENT=push REPO=owner/carat SHA=x sh "$here/ci_scope.sh"
expect "ci_scope: a push whose pull request did not pass runs" 0 "^run=true" \
  env PATH="$work/bin:$PATH" FAKE_HEAD=abc FAKE_TREE="$tree" FAKE_PASSED=0 EVENT=push REPO=owner/carat SHA=x sh "$here/ci_scope.sh"

# ------------------------------------------------------------- metrics.sh

mkdir -p "$work/metrics"
cd "$work/metrics" || exit 1
printf 'spinel-timing: phase=analysis ms=1000.0 x=1\nspinel-timing: phase=analysis_renarrow rounds=2\n' > carat.timing
printf 'spinel-timing: phase=analysis ms=2000.0 x=1\nspinel-timing: phase=analysis_renarrow rounds=3\n' > runner.timing
cat > "$work/bin/fake-bench" <<'EOF'
#!/bin/sh
for s in "$@"; do
  echo "$s lines=10 keys=10 handle=  1.0us render=  2.0us total=   50.0us worst= 9.0us@1 bytes=1 gc= 0.00% gc_runs=0 retained=0 open=1.0us tokenized=0.00 allocs=27.0 alloc_bytes=1616"
done
EOF
chmod +x "$work/bin/fake-bench"
measure() {
  env CARAT_TIMING=carat.timing RUNNER_TIMING=runner.timing BENCH_RUN="$work/bin/fake-bench" sh "$here/metrics.sh" measure "$@"
}
expect "metrics: measure writes allocations per key" 0 "^allocs[.]lh[[:space:]]27[.]0$" measure base.tsv lh j
expect "metrics: measure writes time per key" 0 "^us[.]j[[:space:]]50[.]0$" cat base.tsv
expect "metrics: measure writes the rounds of each root" 0 "^rounds[.]runner[[:space:]]3$" cat base.tsv
expect "metrics: measure writes the analysis time of each root" 0 "^analysis_ms[.]carat[[:space:]]1000[.]0$" cat base.tsv
expect "metrics: measure refuses without the build reports" 1 "missing; make dev-build" \
  env CARAT_TIMING=gone.timing sh "$here/metrics.sh" measure x.tsv lh
# compare SED-EXPRESSION [VAR=VALUE...]: base.tsv against a copy edited by it.
compare() {
  sed "$1" base.tsv > current.tsv
  shift
  env "$@" sh "$here/metrics.sh" compare base.tsv current.tsv
}
expect "metrics: compare passes the same measurement" 0 "no allocation or analysis-round regression" compare 's/^//'
expect "metrics: compare fails on more allocations per key" 1 "FAIL +allocs[.]lh +27[.]0 -> 27[.]5" compare 's/^allocs[.]lh\t27[.]0/allocs.lh\t27.5/'
expect "metrics: compare fails on more analysis rounds" 1 "FAIL +rounds[.]carat +2 -> 3" compare 's/^rounds[.]carat\t2/rounds.carat\t3/'
expect "metrics: compare fails on an unmeasured round count" 1 "not measured" compare 's/^rounds[.]carat\t2/rounds.carat\t?/'
expect "metrics: compare passes fewer allocations" 0 "ok +allocs[.]lh +27[.]0 -> 20[.]0" compare 's/^allocs[.]lh\t27[.]0/allocs.lh\t20.0/'
expect "metrics: compare only warns on slower time" 0 "warning +us[.]lh +50[.]0 -> 80[.]0: 60% slower" compare 's/^us[.]lh\t50[.]0/us.lh\t80.0/'
expect "metrics: compare annotates a warning on GitHub Actions" 0 "::warning::us[.]lh is 60% slower" compare 's/^us[.]lh\t50[.]0/us.lh\t80.0/' GITHUB_ACTIONS=true
expect "metrics: compare passes time within the tolerance" 0 "ok +us[.]lh +50[.]0 -> 55[.]0" compare 's/^us[.]lh\t50[.]0/us.lh\t55.0/'
expect "metrics: compare passes with a notice when there is no base" 0 "no base measurement" \
  sh "$here/metrics.sh" compare missing.tsv base.tsv

# ----------------------------------------------------------- run_state.sh

fresh state
expect "run_state: init writes the state" 0 '"branch": "chore/state"' state init state chore/state
expect "run_state: init again resumes" 0 "resuming state" state init state chore/state
state set state note 'a "quoted" \ value' > /dev/null
expect "run_state: a value round-trips through JSON escapes" 0 '^a "quoted" \\ value$' state get state note
expect "run_state: the file is one flat object" 0 '^  "note": "a \\"quoted\\" \\\\ value"$' cat build/pipeline/state.json
expect "run_state: a failing stage keeps its exit status" 3 "stage s: exit 3" state stage state s sh -c 'exit 3'
expect "run_state: the stage log ends with its status" 0 "^EXIT 3$" tail -1 build/stages/state/s.log
expect "run_state: a stage records exit, time, and commit" 0 "^3 [0-9]+s $(git rev-parse --short=12 HEAD) " state get state stage.s

cat > "$work/bin/fake-make" <<'EOF'
#!/bin/sh
for arg in "$@"; do
  case "$arg" in S=b) exit "${FAIL_B:-0}" ;; esac
done
exit 0
EOF
chmod +x "$work/bin/fake-make"
expect "run_state: check stops at the first failing stage" 1 "stage b failed" \
  env STAGES="a b" MAKE="$work/bin/fake-make" FAIL_B=2 sh "$here/run_state.sh" check state
# The merge gates run main's copy: while its Makefile has no FAST_STAGES, the
# check runs its CHECK_STAGES.
printf 'CHECK_STAGES := a b\n' >> Makefile
commit "chore: a full list"
expect "run_state: check runs main's full list while main has no fast list" 1 "stage b failed" \
  env BASE=HEAD MAKE="$work/bin/fake-make" FAIL_B=2 sh "$here/run_state.sh" check state
printf 'FAST_STAGES := a\n' >> Makefile
commit "chore: a fast list"
expect "run_state: check runs make stages once main has a fast list" 0 "every stage passed" \
  env BASE=HEAD MAKE="$work/bin/fake-make" FAIL_B=2 sh "$here/run_state.sh" check state
expect "make: every fast stage is a check stage" 0 "^none$" sh -c 'm="$1/../Makefile"; all=" $(sed -n "s/^CHECK_STAGES := //p" "$m") "; out=; for s in $(sed -n "s/^FAST_STAGES := //p" "$m"); do case "$all" in *" $s "*) ;; *) out="$out $s" ;; esac; done; [ -n "$(sed -n "s/^FAST_STAGES := //p" "$m")" ] && echo "${out:-none}"' _ "$here"
# A stage record counts only at the commit the workflow backs: one at HEAD
# without it, which any agent could have written, runs again.
expect "run_state: check runs a stage recorded at the head that no commit backs" 0 "^stage a: exit 0" \
  env STAGES="a b" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check state
expect "run_state: check leaves phase.check to the workflow" 0 "^$" state get state phase.check
expect "run_state: check skips the stages passed at the backed head" 0 "stage a: passed at .*, skipped" \
  env STAGES="a b" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check state "$(git rev-parse --short=12 HEAD)"
expect "run_state: check refuses a backed commit that is not one" 1 "not a commit: HEAD" \
  env STAGES="a b" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check state HEAD
# A commit that changes only tests reruns the test stages and carries the
# others from the backed commit; one that changes anything else reruns
# every stage.
env STAGES="a b test-run diagnose metrics docs-lint" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check state > /dev/null 2>&1
before_tests=$(git rev-parse --short=12 HEAD)
echo "check" > test/t.rb
commit "test: t"
env STAGES="a b test-run diagnose metrics docs-lint" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check state "$before_tests" > carry.out 2>&1
expect "run_state: check carries a stage after a test-only commit" 0 "^stage a: passed at $before_tests, carried to $(git rev-parse --short=12 HEAD)" cat carry.out
expect "run_state: check reruns the test stages" 0 "^stage test-run: exit 0" cat carry.out
expect "run_state: check reruns diagnose, which reads the test runner, after a test-only commit" 0 "^stage diagnose: exit 0" cat carry.out
expect "run_state: check reruns docs-lint, which reads the docs and the test paths they name, after a test-only commit" 0 "^stage docs-lint: exit 0" cat carry.out
expect "run_state: check reruns metrics, which reads the test runner's rounds, after a test-only commit" 0 "^stage metrics: exit 0" cat carry.out
expect "run_state: a carried stage names its commit" 0 "^0 0s $(git rev-parse --short=12 HEAD) .* carried-from-$before_tests$" state get state stage.b
rm carry.out
echo "check again" > test/t.rb
commit "test: t again"
expect "run_state: check carries a stage carried from the backed commit" 0 "stage a: passed at $before_tests, carried to $(git rev-parse --short=12 HEAD)" \
  env STAGES="a b test-run" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check state "$before_tests"
echo "check once more" > test/t.rb
commit "test: t once more"
expect "run_state: check carries nothing without a backed commit" 0 "^stage a: exit 0" \
  env STAGES="a b test-run" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check state
echo "check" > tools/t.sh
commit "chore: t"
expect "run_state: check reruns every stage after a change outside test/" 0 "^stage a: exit 0" \
  env STAGES="a b test-run" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check state
git_q mv tools/t.sh test/moved.sh
commit "chore: move t"
expect "run_state: check reruns every stage after a file moves under test/" 0 "^stage a: exit 0" \
  env STAGES="a b test-run" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check state
# The checks judge the commit: a modified tracked file or an untracked
# source spin would compile is refused before any stage runs.
echo dirty >> README.md
expect "run_state: check refuses modified tracked files" 1 "refused: tracked files differ from HEAD" \
  env STAGES="a" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check state
git_q checkout -q README.md
mkdir -p carat
echo loose > carat/loose.rb
expect "run_state: check refuses an untracked source" 1 "refused: untracked files under carat/, bin/, test/, or bench/" \
  env STAGES="a" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check state
rm -r carat
# The stages run in a throwaway clone outside the delivery clone: a stage
# that plants a hook, rewrites origin's url or fetch refspec, and writes a
# run state changes nothing the gates and the guard read here, and the
# clone is gone after the check.
fresh isolated
git_q remote add origin host:o/r.git
state init isolated chore/isolated > /dev/null
mkdir -p "$work/checks"
cat > "$work/bin/plant-make" <<'EOF'
#!/bin/sh
pwd -P > "$PLANT_OUT"
printf '#!/bin/sh\nexit 0\n' > .git/hooks/post-checkout && chmod +x .git/hooks/post-checkout
git config remote.origin.url "$PWD/fake.git"
git config remote.origin.fetch +refs/heads/forged:refs/remotes/origin/main
mkdir -p build/pipeline && printf '{\n  "review.security": "pass 0"\n}\n' > build/pipeline/isolated.json
exit 0
EOF
chmod +x "$work/bin/plant-make"
expect "run_state: check runs a stage that plants a hook, origin's url and refspec, and a run state" 0 "every stage passed" \
  env STAGES="plant" MAKE="$work/bin/plant-make" PLANT_OUT="$work/plant.out" TMPDIR="$work/checks" sh "$here/run_state.sh" check isolated
expect "run_state: a check stage runs in a clone outside the delivery clone" 0 "^$work/checks/carat-check[.][^/]+/repo$" cat "$work/plant.out"
expect "run_state: a hook a check stage plants leaves the origin gate passing" 0 "ok   origin: the configuration sets no risky key and no hook$" gates origin
expect "run_state: a check stage leaves origin's url" 0 "^host:o/r[.]git$" git config --get-all remote.origin.url
expect "run_state: a check stage leaves origin's fetch refspec" 0 "^[+]refs/heads/[*]:refs/remotes/origin/[*]$" git config --get-all remote.origin.fetch
expect "run_state: a run state a check stage writes is not the delivery clone's" 0 "^$" state get isolated review.security
expect "run_state: check removes its clone" 0 "^$" ls -A "$work/checks"
rm "$work/plant.out"
cd "$work/state" || exit 1
# A check that did not finish says so: a stage ended by a signal, its own
# or the runner's, is killed; one during which HEAD moved is superseded at
# the commit it ran on; a runner killed past its trap is reported by the
# next check. The runner is detached, so a check still running exits 3 and
# the next check at the same head rejoins it.
cat > "$work/bin/stop-make" <<'EOF'
#!/bin/sh
for arg in "$@"; do
  case "$arg" in
    S=own) kill -TERM $$ ;;
    S=runner) kill -TERM $PPID; sleep 5 ;;
    S=hard) kill -KILL $PPID ;;
    S=moves) git -C "$MOVE_IN" -c user.name=Claude -c user.email=noreply@anthropic.com commit -q --allow-empty -m "chore: moved" -m "Co-Authored-By: Claude <noreply@anthropic.com>" ;;
    S=slow) sleep "${SLOW:-0}" ;;
  esac
done
exit 0
EOF
chmod +x "$work/bin/stop-make"
stop_check() {
  env STAGES="$1" MAKE="$work/bin/stop-make" MOVE_IN="$work/state" TMPDIR="$work/checks" sh "$here/run_state.sh" check state
}
at=$(git rev-parse --short=12 HEAD)
expect "run_state: a stage killed by a signal is recorded as killed" 143 "^stage c: killed [(]exit 143[)]" state stage state c sh -c 'kill -TERM $$'
expect "run_state: a killed stage's log says so" 0 "^KILLED: exit 143" tail -1 build/stages/state/c.log
expect "run_state: a check whose stage a signal ended names it killed" 1 "^check: stage own killed at $at; read build/stages/state/own[.]log$" stop_check "a own b"
expect "run_state: a check killed by a signal names its stage and log" 1 "^check: stage runner killed at $at; read build/stages/state/runner[.]log$" stop_check "a runner b"
expect "run_state: a killed check records its stage as killed" 0 "^killed [0-9]+s $at " state get state stage.runner
expect "run_state: a killed check's log says so" 0 "^KILLED: the check received SIGTERM" tail -1 build/stages/state/runner.log
expect "run_state: a hard-killed check is reported killed by the next check" 1 "^check: stage hard killed at $at; read build/stages/state/hard[.]log$" stop_check "a hard b"
expect "run_state: a hard-killed check's stage is recorded as killed" 0 "^killed 0s $at " state get state stage.hard
expect "run_state: a hard-killed check's clone is removed" 0 "^$" ls -A "$work/checks"
expect "run_state: a check leaves no runner behind" 1 "" test -e build/stages/state/check.pid
expect "run_state: a stage during which HEAD moved is superseded at the commit it ran on" 1 "^check: stage moves superseded at $at; read" stop_check "a moves b"
expect "run_state: a superseded stage is recorded at its own commit" 0 "^superseded [0-9]+s $at " state get state stage.moves
at=$(git rev-parse --short=12 HEAD)
expect "run_state: a check still running exits 3" 3 "^check: still running at $at" \
  env SLOW=3 CHECK_WAIT=1 STAGES=slow MAKE="$work/bin/stop-make" sh "$here/run_state.sh" check state
expect "run_state: a second check at the same head rejoins the running one" 0 "^check: rejoining the check running at $at.*" stop_check "slow"
expect "run_state: a rejoined check ends with the runner's verdict" 0 "^check: every stage passed at $at" tail -1 build/stages/state/check.log
env SLOW=5 CHECK_WAIT=1 STAGES=slow MAKE="$work/bin/stop-make" sh "$here/run_state.sh" check state > /dev/null 2>&1
# HEAD moves only once the runner is in its stage: a commit while it still
# makes its clone refuses the clone, and nothing is left to supersede.
n=0
until state get state stage.slow 2>/dev/null | grep -q '^running ' || [ $n -ge 20 ]; do sleep 1; n=$((n + 1)); done
git_q commit -q --allow-empty -m "chore: newer" -m "$TRAILER"
expect "run_state: a check at a newer head supersedes the running one" 0 "the superseded check: check: stage slow superseded at $at" stop_check "slow"
expect "run_state: the newer check runs at the newer head" 0 "^check: every stage passed at $(git rev-parse --short=12 HEAD)" tail -1 build/stages/state/check.log
# A runner prints its verdict before it drops its clone and pid file: a
# check started meanwhile at the same head waits for it to exit and runs,
# rather than rejoining a finished check.
at=$(git rev-parse --short=12 HEAD)
sh -c 'sleep 2; :' "run_state.sh check-run" > /dev/null 2>&1 &
echo "$! $at" > build/stages/state/check.pid
echo "check: every stage passed at $at" > build/stages/state/check.log
expect "run_state: a check waits for a runner past its verdict instead of rejoining it" 0 "^stage settle: exit 0" stop_check "settle"
expect "run_state: the check after a finishing runner leaves no runner behind" 1 "" test -e build/stages/state/check.pid
# The workflow reruns a check whose verdict says it did not finish, and
# sends only a failure to a fix round: its RERUN_WORDS are this script's.
rerun=$(grep -E '^const RERUN_WORDS = ' "$here/../.claude/workflows/deliver-change.js")
for word in killed superseded running none; do
  expect "run_state: the workflow reruns a $word check with no fix round" 0 "[(|]$word[|)]" echo "$rerun"
done
expect "run_state: the workflow sends only a failed check to a fix round" 1 "^0$" sh -c 'printf "%s\n" "$1" | grep -c -E "failed|passed"' _ "$rerun"
state phase state report > /dev/null
expect "run_state: phase accepts report" 0 "^$(git rev-parse --short=12 HEAD)$" state get state phase.report
expect "run_state: status names the running change and its next phase" 0 "next phase: plan" state status
expect "run_state: set refuses a review record" 1 "refused: review.security" state set state review.security "pass abc"
expect "run_state: set refuses a phase record" 1 "refused: phase.plan" state set state phase.plan abc
expect "run_state: set refuses a stage record" 1 "refused: stage.lint" state set state stage.lint "0 1s abc now"
# A newline, carriage return, or other control character in a key or value
# would write a line of its own: every command refuses it, and no forged
# review.security or phase.merge line reaches the file.
nl='
'
cr=$(printf '\r')
at_head=$(git rev-parse --short=12 HEAD)
forged_review="x\": \"y\",$nl  \"review.security\": \"pass $at_head"
forged_phase="y\",$nl  \"phase.merge\": \"$at_head"
expect "run_state: set refuses a forged review line in its key" 1 "the key holds a control character" state set state "$forged_review" v
expect "run_state: set refuses a forged phase line in its value" 1 "the value of note holds a control character" state set state note "$forged_phase"
expect "run_state: set refuses a carriage return" 1 "the value of note holds a control character" state set state note "a${cr}b"
expect "run_state: set refuses a key that is not a run state key" 1 "not a run state key: Review" state set state 'Review' v
expect "run_state: metric refuses a forged line in its name" 1 "not a metric name" state metric state "x$nl  \"review.security\"=1"
expect "run_state: metric refuses a forged line in its value" 1 "not a metric value" state metric state "rework=1${nl}phase.merge=2"
expect "run_state: note refuses a forged line in its kind" 1 "the kind is lowercase" state note state "retro${nl}x" text
expect "run_state: note refuses a forged line in its text" 1 "the value of note[.]1 holds a control character" state note state retro "$forged_phase"
expect "run_state: review refuses a forged line in its summary" 1 "the value of review[.]quality holds a control character" state review state quality pass "$forged_review"
expect "run_state: stage refuses a forged line in its name" 1 "the key holds a control character" state stage state "s$nl  \"phase.merge\": \"x" true
expect "run_state: init refuses a forged line in its branch" 1 "the branch holds a control character" state init forged "chore/forged$nl  \"review.security\": \"pass"
expect "run_state: init refuses a control character in the change name" 1 "not a change name" state init "forged${cr}" chore/forged
expect "run_state: no forged line reached the file" 0 "^0$" sh -c "grep -c -E '^  \"(review[.]security|phase[.]merge)\"' build/pipeline/state.json; true"
expect "run_state: a refused init writes no state" 1 "" test -e build/pipeline/forged.json
expect "run_state: phase refuses a name not in the list" 1 "not a phase: deploy" state phase state deploy
expect "run_state: phase refuses a commit that is not hexadecimal" 1 "not a commit: HEAD" state phase state plan HEAD
expect "run_state: phase refuses a commit that does not exist" 1 "not a commit: 0000000" state phase state plan 0000000
base_commit=$(git rev-parse --short=12 HEAD)
echo more >> README.md
commit "chore: more"
state phase state plan "$(git rev-parse --short=7 HEAD~1)" > /dev/null
expect "run_state: phase records the given commit at twelve digits" 0 "^$base_commit$" state get state phase.plan
expect "run_state: review refuses an unknown kind" 1 "not a review kind: style" state review state style pass "x"
state review state quality blocked "blocking=1" > /dev/null
expect "run_state: a blocked review records no phase" 0 "^$" state get state phase.quality
state review state quality pass "blocking=0 advisory=2" "$base_commit" > /dev/null
expect "run_state: review records the given commit" 0 "^pass $base_commit blocking=0 advisory=2$" state get state review.quality
expect "run_state: a passed review records its phase at that commit" 0 "^$base_commit$" state get state phase.quality
expect "run_state: a diff review refuses a not-run result" 1 "pass or blocked, not not-run" state review state security not-run "no result"
state review state periodic-security not-run "no result after the retry" > /dev/null
expect "run_state: a periodic security review without a result is recorded as not run" 0 "^not-run [0-9a-f]* no result after the retry$" state get state review.periodic-security
expect "run_state: a periodic review not run records no phase" 0 "^$" state get state phase.periodic-security
state review state periodic-quality partial "blocking=0 advisory=1 not_reviewed=13,14" "$base_commit" > /dev/null
expect "run_state: a partial periodic review names what it did not review" 0 "^partial $base_commit blocking=0 advisory=1 not_reviewed=13,14$" state get state review.periodic-quality
expect "run_state: a partial periodic review records no phase" 0 "^$" state get state phase.periodic-quality
expect "run_state: a periodic review refuses another result" 1 "pass, blocked, partial, or not-run, not skipped" state review state periodic-security skipped "x"
# The scope of a fix round's quality review: the fix since the reviewed
# commit stays within the files the findings name, tests, and records.
reviewed_at=$(git rev-parse --short=12 HEAD)
echo fix >> tools/base.sh
echo fix > test/fix.rb
mkdir -p openspec/changes/c
echo "- [x] 1.1" > openspec/changes/c/tasks.md
commit "fix: a named file"
expect "run_state: scope allows a fix of the named files and tests" 0 "^fix: review only git diff $reviewed_at HEAD" state scope state "$reviewed_at" README.md tools/base.sh
expect "run_state: scope falls back for a file the findings do not name" 1 "^branch: tools/base.sh changed since $reviewed_at" state scope state "$reviewed_at" README.md
expect "run_state: scope falls back without named files" 1 "^branch: tools/base.sh" state scope state "$reviewed_at"
expect "run_state: scope falls back when nothing changed" 1 "^branch: nothing changed" state scope state "$(git rev-parse --short=12 HEAD)" tools/base.sh
expect "run_state: scope refuses a commit that is not one" 1 "not a commit: HEAD" state scope state HEAD tools/base.sh
expect "run_state: scope refuses a path with a parent step" 1 "not a plain relative path: tools/[.][.]/x" state scope state "$reviewed_at" tools/../x
git_q mv tools/base.sh test/base.sh
commit "chore: move a named file under test"
expect "run_state: scope counts both paths of a rename" 0 "^fix: " state scope state "$reviewed_at" tools/base.sh
expect "run_state: scope falls back for a rename the findings do not name" 1 "^branch: tools/base.sh" state scope state "$reviewed_at" README.md
git_q mv test/base.sh tools/base.sh
commit "chore: move it back"
# An advisory a later round repeats is noted once.
state note state quality-advisory "abc1234def01 tools/x.sh:3 a \"quoted\" reason; fix: an outline" > /dev/null
expect "run_state: note keeps one advisory across commits" 0 "already recorded" state note state quality-advisory "0123456789ab tools/x.sh:3 a \"quoted\" reason; fix: an outline"
expect "run_state: one note holds the repeated advisory" 0 "^1$" sh -c "grep -c 'tools/x.sh:3 a' build/pipeline/state.json"
state note state quality-advisory "0123456789ab tools/x.sh:4 another reason; fix: an outline" > /dev/null
expect "run_state: note records another advisory" 0 "^1$" sh -c "grep -c 'tools/x.sh:4 another' build/pipeline/state.json"
state note state quality-blocking "0123456789ab tools/x.sh:3 a reason; fix: an outline" > /dev/null
state note state quality-blocking "abc1234def01 tools/x.sh:3 a reason; fix: an outline" > /dev/null
expect "run_state: note keeps a blocking finding at each commit" 0 "^2$" sh -c "grep -c 'quality-blocking [0-9a-f]* tools/x.sh:3' build/pipeline/state.json"
# A text whose first word is made of hex letters is no commit on either side.
state note state quality-advisory "add a reason; fix: an outline" > /dev/null
expect "run_state: note keeps one advisory starting with a hex word" 0 "already recorded" state note state quality-advisory "add a reason; fix: an outline"
expect "run_state: note matches a hex word after a commit" 0 "already recorded" state note state quality-advisory "0123456789ab add a reason; fix: an outline"

# The compile stages skip the code they last passed while their outputs
# are the ones that pass left; a change to the code they read, to their
# outputs, or a failure runs them again.
fresh compiled
mkdir -p carat
echo code > carat/x.rb
echo budget > tools/analysis_budget.sh
commit "feat: code"
state init compiled chore/compiled > /dev/null
cat > "$work/bin/build-make" <<'EOF'
#!/bin/sh
for arg in "$@"; do
  case "$arg" in
    S=dev-build) mkdir -p build/dev && echo editor > build/dev/carat && echo report > build/dev/carat.timing ;;
    S=test-build) mkdir -p build/test && echo runner > build/test/run_all && echo report > build/test/run_all.timing; exit "${FAIL_TB:-0}" ;;
  esac
done
exit 0
EOF
chmod +x "$work/bin/build-make"
compile_check() {
  env STAGES="a dev-build test-build diagnose" MAKE="$work/bin/build-make" "$@" sh "$here/run_state.sh" check compiled
}
compile_check > "$work/compiled.out" 2>&1
expect "run_state: check runs the compile stages on code it never passed" 0 "^stage dev-build: exit 0" cat "$work/compiled.out"
echo tooling >> tools/base.sh
echo notes > docs/notes.md
commit "chore: tooling"
compile_check > "$work/compiled.out" 2>&1
expect "run_state: check skips a compile stage on the code it passed" 0 "^stage dev-build: passed on the same code .* skipped" cat "$work/compiled.out"
expect "run_state: a tooling commit keeps the code key" 0 "^stage diagnose: passed on the same code .* skipped" cat "$work/compiled.out"
expect "run_state: check runs the other stages on a tooling commit" 0 "^stage a: exit 0" cat "$work/compiled.out"
expect "run_state: a skipped compile stage passes at the head" 0 "^0 0s $(git rev-parse --short=12 HEAD) [^ ]+ compiled-[0-9a-f]{12}$" state get compiled stage.test-build
expect "run_state: check carries the compile outputs out of its clone" 0 "^runner$" cat build/stages/compiled/carry/test/run_all
echo rebuilt > build/stages/compiled/carry/test/run_all
compile_check > "$work/compiled.out" 2>&1
expect "run_state: check runs a compile stage whose outputs changed" 0 "^stage test-build: exit 0" cat "$work/compiled.out"
expect "run_state: check keeps the skip of a stage whose outputs did not change" 0 "^stage dev-build: passed on the same code" cat "$work/compiled.out"
echo more code > carat/x.rb
commit "feat: more code"
compile_check > "$work/compiled.out" 2>&1
expect "run_state: check runs a compile stage after a code change" 0 "^stage diagnose: exit 0" cat "$work/compiled.out"
echo even more code > carat/x.rb
commit "feat: even more code"
expect "run_state: a compile stage can fail" 1 "stage test-build failed" compile_check FAIL_TB=1
compile_check > "$work/compiled.out" 2>&1
expect "run_state: a failed compile stage keeps no pass" 0 "^stage test-build: exit 0" cat "$work/compiled.out"
expect "run_state: the stage before the failure keeps its pass" 0 "^stage dev-build: passed on the same code" cat "$work/compiled.out"
echo budget again > tools/analysis_budget.sh
commit "chore: the analysis budget"
compile_check > "$work/compiled.out" 2>&1
expect "run_state: check runs a compile stage after a change to the script it runs" 0 "^stage dev-build: exit 0" cat "$work/compiled.out"
# The metrics stage writes its figures in the clone, where METRICS_OUT is
# unset; the check copies them to the delivery clone's METRICS_OUT, which
# bench and the benchmark read.
cat > "$work/bin/metrics-make" <<'EOF'
#!/bin/sh
for arg in "$@"; do
  case "$arg" in
    S=metrics) [ -z "$METRICS_OUT" ] || exit 3; mkdir -p build/metrics && printf 'rounds\t7\n' > build/metrics/current.tsv ;;
  esac
done
exit 0
EOF
chmod +x "$work/bin/metrics-make"
env STAGES="metrics" MAKE="$work/bin/metrics-make" METRICS_OUT="$work/metrics/out.tsv" sh "$here/run_state.sh" check compiled > "$work/compiled.out" 2>&1
expect "run_state: check runs the metrics stage in its clone without METRICS_OUT" 0 "^stage metrics: exit 0" cat "$work/compiled.out"
expect "run_state: check copies the clone's metrics to METRICS_OUT" 0 "^rounds	7$" cat "$work/metrics/out.tsv"
rm -rf "$work/compiled.out" "$work/metrics"

fresh pushing
git_q init -q --bare "$work/origin.git"
git_q remote add origin "$work/origin.git"
git_q push -q origin main 2>/dev/null
state init pushing chore/pushing > /dev/null
echo more >> README.md
commit "chore: more"
# A run keeps its unpushed commits on its local branch; no backup ref is
# pushed before the branch.
expect "run_state: backup is no longer a command" 2 "" state backup pushing
expect "run_state: restore is no longer a command" 2 "" state restore pushing
expect "run_state: push refuses before the checks and the review" 1 "pre-push gates failed" \
  env BASE=main STAGES=lint sh "$here/run_state.sh" push pushing
expect "run_state: a refused push counts a gate failure" 0 "^1$" state get pushing gates_failed
sh "$here/run_state.sh" gated pushing pass > /dev/null
state stage pushing lint true > /dev/null
state phase pushing check > /dev/null
state review pushing security pass "no finding" > /dev/null
expect "run_state: push passes the gates and pushes" 0 "ok   security" \
  env BASE=main STAGES=lint sh "$here/run_state.sh" push pushing
expect "run_state: a push is counted" 0 "^1$" state get pushing pushes
expect "run_state: push clears a gated marker recorded before it" 0 "^none$" state get pushing gated
expect "run_state: push records the full sha as pushed" 0 "^full$" \
  sh -c 'p=$(sh "$1/run_state.sh" get pushing pushed) && [ "$p" = "$(git rev-parse HEAD)" ] && [ ${#p} -eq 40 ] && echo full' _ "$here"
expect "run_state: a second push is refused" 1 "refused: 1 push" \
  env BASE=main STAGES=lint sh "$here/run_state.sh" push pushing
expect "run_state: a CI fix push needs a red CI run" 1 "needs a red CI run" \
  env BASE=main STAGES=lint sh "$here/run_state.sh" push pushing --ci-fix
state set pushing ci "red abc" > /dev/null
expect "run_state: a CI fix allows one more push" 0 "ok   pushes|ok   stages" \
  env BASE=main STAGES=lint sh "$here/run_state.sh" push pushing --ci-fix

expect "run_state: abandon is no longer a command" 2 "" state abandon pushing

fresh history
state init history chore/history > /dev/null
state metric history rework=1 first_pass=check:1,quality:0,security:1 ci_min=2.5 out_tokens=1200 tool_calls=40 phases=implement=1000/30,check=200/10 calib.scout=cheap/low calib.security=session/session > /dev/null
expect "run_state: metric records a value" 0 "^check:1,quality:0,security:1$" state get history metric.first_pass
expect "run_state: metric refuses a value with a space" 1 "not a metric value" state metric history 'rework=1 2'
expect "run_state: metric refuses a value with a shell character" 1 "not a metric value" state metric history 'rework=$(x)'
expect "run_state: metric refuses a pair without a value" 1 "is not NAME=VALUE" state metric history rework
printf 'rounds.carat\t2\nallocs.lh\t27.0\nus.lh\t50.0\nallocs.j\t28.0\n' > m.tsv
expect "run_state: metrics records a measurement" 0 "recorded 4 measurement" state metrics history m.tsv
expect "run_state: a measurement is a metric" 0 "^28[.]0$" state get history metric.allocs.j
state init unmeasured chore/unmeasured > /dev/null
state metrics unmeasured m.tsv > /dev/null
printf 'us.lh\t?\nallocs.k\t30.0\nanalysis_ms.carat\t?\n' > q.tsv
expect "run_state: metrics skips an unmeasured value" 0 "recorded 1 measurement.*skipped 2 unmeasured" state metrics unmeasured q.tsv
expect "run_state: metrics records the measured values beside it" 0 "^30[.]0$" state get unmeasured metric.allocs.k
expect "run_state: metrics leaves an unmeasured value unrecorded" 0 "^$" state get unmeasured metric.analysis_ms.carat
expect "run_state: metrics drops an earlier figure now unmeasured" 0 "^$" state get unmeasured metric.us.lh
expect "run_state: metrics keeps the other earlier figures" 0 "^27[.]0$" state get unmeasured metric.allocs.lh
state note history retro "drop a step; evidence: 9000 tokens" > /dev/null
state note history security "Medium (6) tools/x.sh:3 quoting" > /dev/null
expect "run_state: note numbers the notes" 0 "^security Medium [(]6[)]" state get history note.2
expect "run_state: note refuses a kind that is not a word" 1 "the kind is lowercase" state note history 'Retro x' text
expect "run_state: pending skips a change that is not merged" 0 "^$" state pending
state set history merged "$(git rev-parse --short=12 HEAD)" > /dev/null
state note history late-finding "security Low (5) tools/x.sh:3 a thing; fix: y" > /dev/null
state note history overrun "not a finding" > /dev/null
state set history pr 9 > /dev/null
state set history pushes 1 > /dev/null
state set history gates_failed 1 > /dev/null
expect "run_state: pending names a merged change without a row" 0 "^history$" state pending
expect "run_state: history appends the row" 0 "appended history" state history
expect "run_state: history appends a merged run's late findings to the backlog" 0 "^- security Low [(]5[)] tools/x[.]sh:3 a thing; fix: y$" tail -1 docs/backlog.md
expect "run_state: history heads the late findings with their run, no other note" 0 "^## Findings of history after its package step 1$" sh -c 'echo "$(grep "^## " docs/backlog.md) $(grep -c "^- " docs/backlog.md)"'
expect "run_state: the history starts with its header" 0 "^change[[:space:]]date[[:space:]]merged" head -1 docs/metrics.tsv
expect "run_state: the row groups the measurements and the first passes" 0 \
  "^carat=2 lh=27[.]0,j=28[.]0 lh=50[.]0 check:1,quality:0,security:1,gates:0 implement=1000/30,check=200/10 -$" \
  awk -F'\t' 'NR == 2 { print $8, $9, $10, $6, $13, $14 }' docs/metrics.tsv
expect "run_state: history records the profiles" 0 "^scout=cheap/low,security=session/session$" awk -F'\t' 'NR == 2 { print $18 }' docs/metrics.tsv
expect "run_state: history appends a change once" 0 "nothing pending" state history
expect "run_state: status prints the first-pass rates" 0 "first-pass rates over 1 change.s.: check 1/1 quality 0/1 security 1/1 gates 0/1" state status

# A run state whose first passes the workflow stored only in part: the
# stage, review, and ci lines hold each gate's last result, not its first,
# so the history leaves a gate without a stored verdict out.
fresh derived
state init derived chore/derived > /dev/null
state stage derived a true > /dev/null
state stage derived b true > /dev/null
state review derived quality blocked "blocking=1" > /dev/null
state review derived security pass "high=0" > /dev/null
state set derived ci "green abc" > /dev/null
state metric derived first_pass=ci:0 first.bench=0 phase.implement=1000/30 phase.check=200/10 rework=1 > /dev/null
expect "run_state: usage adds a start's totals" 0 "^no estimate: .*actual 5000 total tokens in 3[.]5 minutes, 1200 output tokens$" state usage derived 5000 3.5
expect "run_state: usage adds the starts' totals" 0 "actual 7500 total tokens in 4[.]5 minutes" state usage derived 2500 1
expect "run_state: usage refuses minutes that are not a number" 1 "the wall minutes are a number, not x" state usage derived 100 'x'
expect "run_state: usage refuses a token count that is not whole" 1 "a whole number" state usage derived 1.5 2
state set derived merged "$(git rev-parse --short=12 HEAD)" > /dev/null
state set derived pushes 1 > /dev/null
state history > /dev/null
expect "run_state: history takes only the stored first verdicts" 0 "^bench:0,ci:0,gates:1$" \
  awk -F'\t' 'NR == 2 { print $6 }' docs/metrics.tsv
expect "run_state: history groups the phase figures" 0 "^implement=1000/30,check=200/10$" awk -F'\t' 'NR == 2 { print $13 }' docs/metrics.tsv
expect "run_state: history sums the phase figures" 0 "^1200 40$" awk -F'\t' 'NR == 2 { print $11, $12 }' docs/metrics.tsv
expect "run_state: history records no estimate without a queue item" 0 "^-$" awk -F'\t' 'NR == 2 { print $15 }' docs/metrics.tsv
expect "run_state: history records the totals after the estimate" 0 "^7500 4[.]5$" awk -F'\t' 'NR == 2 { print $16, $17 }' docs/metrics.tsv

# The estimate: the size word of the change's item in the queue at the
# parent of its squash commit, against the run's total tokens and wall
# minutes (usage), with its output tokens beside them.
fresh estimate
printf '# Queue\n\n1. `sized` (T2, estimated small): one.\n2. `unsized` (T5): two, after `sized`.\n3. `large` (T4, estimated large): three.\n4. `quiet` (T6, estimated medium): four.\n5. `unmerged` (T6, estimated small): five.\n' > docs/queue.md
commit "docs: the queue"
echo squash >> README.md
commit "feat: the squash commit"
squash=$(git rev-parse --short=12 HEAD)
for name in sized unsized large quiet unmerged; do
  state init "$name" "chore/$name" > /dev/null
  [ "$name" = unmerged ] || state set "$name" merged "$squash" > /dev/null
done
state metric sized phase.implement=250000/30 phase.check=60000/10 > /dev/null
state metric large phase.implement=900000/30 > /dev/null
state usage sized 610000 20 > /dev/null
state usage large 2000000 50 > /dev/null
expect "run_state: budget names an overrun of total tokens" 0 "^over: estimated small, budget 500000 total tokens and 25 minutes, actual 610000 total tokens in 20[.]0 minutes, 310000 output tokens$" state budget sized
expect "run_state: budget passes a run under its budget" 0 "^under: estimated large, budget 2500000 total tokens, actual 2000000 total tokens in 50[.]0 minutes, 900000 output tokens$" state budget large
expect "run_state: budget says when no estimate was made" 0 "^no estimate: neither the run state nor a queue item of unsized states a size" state budget unsized
expect "run_state: budget says when no total tokens were recorded" 0 "^unmeasured: estimated medium, budget 1200000 total tokens, no total tokens recorded$" state budget quiet
expect "run_state: budget reads no estimate of an unmerged change" 0 "^no estimate: " state budget unmerged
# The plan's estimate, stored as metric.estimate, outlives the queue item:
# planned is in no queue, early is not merged, and a stored size wins
# over the queue's.
state init planned chore/planned > /dev/null
state set planned merged "$squash" > /dev/null
state metric planned estimate=medium phase.implement=200000/20 > /dev/null
state metric large estimate=medium > /dev/null
state init early chore/early > /dev/null
state metric early estimate=small phase.implement=1000/2 > /dev/null
state metric quiet estimate=huge > /dev/null
state usage planned 700000 10 > /dev/null
state usage early 400000 20 > /dev/null
expect "run_state: budget reads the stored estimate of a change with no queue item" 0 "^under: estimated medium, budget 1200000 total tokens, actual 700000 total tokens in 10[.]0 minutes, 200000 output tokens$" state budget planned
expect "run_state: the stored estimate wins over the queue item" 0 "^over: estimated medium, budget 1200000 total tokens, actual 2000000 total tokens" state budget large
expect "run_state: budget reads the stored estimate before the merge" 0 "^under: estimated small, budget 500000 total tokens and 25 minutes, actual 400000 total tokens in 20[.]0 minutes, 1000 output tokens$" state budget early
expect "run_state: budget names an overrun of wall minutes" 0 "^over: estimated small, budget 500000 total tokens and 25 minutes, actual 400001 total tokens in 30[.]0 minutes" state usage early 1 10
expect "run_state: a stored word that is not a size leaves the queue item's" 0 "^unmeasured: estimated medium" state budget quiet
state init minuteless chore/minuteless > /dev/null
state metric minuteless estimate=small total_tokens=1000 > /dev/null
expect "run_state: budget names no minutes when none were recorded" 0 "^under: estimated small, budget 500000 total tokens and 25 minutes, actual 1000 total tokens, " state budget minuteless
rm build/pipeline/minuteless.json
# spent, which the checker prints after a passing check: the output tokens
# so far against the output budget (TOKEN_BUDGETS / OUTPUT_SHARE) and the
# earlier starts' total tokens against the total budget, never a stop.
state init spending chore/spending > /dev/null
state metric spending estimate=medium phase.plan=20000/10 phase.implement=150000/60 > /dev/null
expect "run_state: spent passes a run under its budget" 0 "^under: 170000 output tokens so far, budget 200000 output tokens for medium [(]1200000 total tokens at 6 per output token[)]; 0 total tokens recorded by earlier starts, budget 1200000$" state spent spending
state metric spending phase.check=40000/12 > /dev/null
expect "run_state: spent names output tokens over the budget" 0 "^over: 210000 output tokens so far, budget 200000 output tokens for medium" state spent spending
state metric spending estimate=large > /dev/null
state usage spending 2600000 40 > /dev/null
expect "run_state: spent names earlier starts over the total budget" 0 "^over: 210000 output tokens so far, budget 416666 output tokens for large .*; 2600000 total tokens recorded by earlier starts, budget 2500000$" state spent spending
state init sizeless chore/sizeless > /dev/null
expect "run_state: spent says when no estimate was made" 0 "^no estimate: 0 output tokens so far; 0 total tokens recorded by earlier starts; neither the run state nor a queue item of sizeless states a size$" state spent sizeless
expect "run_state: spent never stops a run" 0 "^over: " state spent spending
expect "run_state: spent refuses a change with no run state" 1 "no run state for absent" state spent absent
# The workflow takes the line only in the shape it parses (SPENT_LINE,
# NO_ESTIMATE_LINE), written so grep -E reads it alike.
spent_re=$(sed -n 's/^const SPENT_LINE = \/\(.*\)\/$/\1/p' "$here/../.claude/workflows/deliver-change.js")
expect "run_state: the workflow reads the spent line" 0 "${spent_re:-no SPENT_LINE in the workflow}" state spent spending
none_re=$(sed -n 's/^const NO_ESTIMATE_LINE = \/\(.*\)\/$/\1/p' "$here/../.claude/workflows/deliver-change.js")
expect "run_state: the workflow reads the spent line without an estimate" 0 "${none_re:-no NO_ESTIMATE_LINE in the workflow}" state spent sizeless
rm build/pipeline/spending.json build/pipeline/sizeless.json
# A merged value that is not a commit hash never reaches git, where
# --output=FILE would write FILE: set refuses it, and one written by hand is
# no merge.
expect "run_state: set refuses an option-shaped merged value" 1 "merged is a commit hash" state set unmerged merged '--output=clobbered'
expect "run_state: set refuses an option-shaped pushed value" 1 "pushed is a commit hash" state set unmerged pushed '--output=clobbered'
awk '{ print } $0 == "  \"change\": \"unmerged\"," { print "  \"merged\": \"--output=clobbered\"," }' build/pipeline/unmerged.json > unmerged.json
mv unmerged.json build/pipeline/unmerged.json
expect "run_state: budget passes git only a commit hash as the merged value" 0 "^no estimate: " state budget unmerged
expect "run_state: pending skips an option-shaped merged value" 0 "^$" sh -c "sh '$here/run_state.sh' pending | grep -x unmerged; true"
expect "run_state: review-due refuses an option-shaped merged value" 1 "unmerged is not merged" state review-due unmerged
expect "run_state: budget refuses a change without a run state" 1 "no run state for nothing" state budget nothing
state history > /dev/null
expect "run_state: history never passes the merged value to git as an option" 1 "" test -e clobbered
rm build/pipeline/unmerged.json
expect "run_state: history records the estimate" 0 "^medium small - medium$" \
  sh -c "awk -F'\t' '\$1 == \"large\" { l = \$15 } \$1 == \"sized\" { s = \$15 } \$1 == \"unsized\" { u = \$15 } \$1 == \"planned\" { p = \$15 } END { print l, s, u, p }' docs/metrics.tsv"
expect "run_state: every history row has the header's columns" 0 "^18$" sh -c "awk -F'\t' '{ print NF }' docs/metrics.tsv | sort -u"

# The benchmark from the check: the metrics stage's measurement against the
# last history row.
fresh bench
state init bench chore/bench > /dev/null
cat > "$work/bin/echo-make" <<'EOF'
#!/bin/sh
echo "make $*"
EOF
chmod +x "$work/bin/echo-make"
bench() {
  env MAKE="$work/bin/echo-make" sh "$here/run_state.sh" bench bench
}
expect "run_state: bench needs the metrics stage at HEAD" 1 "the metrics stage has not passed" bench
state stage bench metrics true > /dev/null
mkdir -p build/metrics
printf 'rounds.carat\t2\nallocs.lh\t27.0\nus.lh\t60.0\n' > build/metrics/current.tsv
{ printf 'header\n'; printf 'prev\t-\t-\t-\t-\t-\t-\tcarat=2\tlh=27\tlh=50.0\t-\t-\t-\t-\n'; } > docs/metrics.tsv
expect "run_state: bench passes the same figures" 0 "same allocations and rounds" bench
expect "run_state: bench compares through make metrics-compare" 0 "^make --no-print-directory metrics-compare BASE_METRICS=build/metrics/last[.]tsv$" bench
expect "run_state: bench writes the last row as a base" 0 "^allocs[.]lh[[:space:]]27$" cat build/metrics/last.tsv
expect "run_state: bench records the measurement" 0 "^60[.]0$" state get bench metric.us.lh
printf 'rounds.carat\t2\nallocs.lh\t28.0\n' > build/metrics/current.tsv
expect "run_state: bench names a differing figure" 1 "^allocs[.]lh 27 -> 28[.]0$" bench
# A merged change without a history row yet is main's, not the last row.
state init merged-first chore/merged-first > /dev/null
state set merged-first merged "$(git rev-parse --short=12 HEAD)" > /dev/null
state metric merged-first rounds.carat=2 allocs.lh=28.0 us.lh=61.0 > /dev/null
expect "run_state: bench compares with the merged change that has no history row" 0 "^bench: same allocations and rounds as the run state of merged-first" bench
expect "run_state: bench writes the pending change's figures as a base" 0 "^allocs[.]lh[[:space:]]28[.]0$" cat build/metrics/last.tsv
printf 'rounds.carat\t2\nallocs.lh\t27.0\n' > build/metrics/current.tsv
expect "run_state: bench names a figure that differs from the pending change's" 1 "^allocs[.]lh 28[.]0 -> 27[.]0$" bench
rm build/pipeline/merged-first.json
state init merged-bare chore/merged-bare > /dev/null
state set merged-bare merged "$(git rev-parse --short=12 HEAD)" > /dev/null
expect "run_state: bench does not compare with a pending change without figures" 1 "has no recorded allocations or rounds" \
  env MAKE="$work/bin/echo-make" sh "$here/run_state.sh" bench bench
rm build/pipeline/merged-bare.json
echo more >> README.md
commit "docs: more"
expect "run_state: bench refuses a measurement of another commit" 1 "passed at another commit" bench

# row CHANGE REVIEW: a history row with only a change and a review column.
row() {
  printf '%s\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t%s\n' "$1" "$2"
}
fresh due
state init due chore/due > /dev/null
mkdir -p carat
echo api > carat/plugin_api.rb
commit "feat: api"
state set due merged "$(git rev-parse --short=12 HEAD)" > /dev/null
expect "run_state: review-due names a sensitive area" 0 "^due: the change touched plugin boundaries [(]carat/plugin_api[.]rb[)]" state review-due due
mkdir -p carat/domain
echo decoder > carat/domain/utf8.rb
commit "fix: decoder"
state set due merged "$(git rev-parse --short=12 HEAD)" > /dev/null
expect "run_state: review-due names the decoder as terminal output" 0 "^due: the change touched terminal output [(]carat/domain/utf8[.]rb[)]" state review-due due
echo more >> README.md
commit "docs: readme"
state set due merged "$(git rev-parse --short=12 HEAD)" > /dev/null
expect "run_state: review-due is not due after one quiet change" 1 "^not due: 1 of 5" state review-due due
{ printf 'header\n'; row a "security=pass quality=pass"; row b -; row c -; row d -; row e -; } > docs/metrics.tsv
expect "run_state: review-due is due five changes after the last review" 0 "^due: 5 changes merged" state review-due due
{ printf 'header\n'; row a "security=pass quality=pass"; row b -; row c -; row d -; row e "security=not-run quality=pass"; } > docs/metrics.tsv
expect "run_state: review-due does not count a periodic review not run" 0 "^due: 5 changes merged" state review-due due
{ printf 'header\n'; row a "security=pass quality=pass"; row b -; row c -; row d -; row e "security=partial quality=pass"; } > docs/metrics.tsv
expect "run_state: review-due does not count a partial periodic review" 0 "^due: 5 changes merged" state review-due due
row f "security=pass quality=pass" >> docs/metrics.tsv
expect "run_state: a periodic review restarts the count" 1 "^not due: 1 of 5" state review-due due
{ printf 'header\n'; row a "security=pass quality=pass"; row b -; row c -; row d -; row e -; } > docs/metrics.tsv
state review due periodic-security not-run "no result after the retry" > /dev/null
expect "run_state: review-due does not count a pending periodic review not run" 0 "^due: 5 changes merged" state review-due due
state review due periodic-security blocked "high=1 medium=0 low=0 blocking=1" > /dev/null
expect "run_state: review-due counts a pending blocked periodic review" 1 "^not due: 0 of 5" state review-due due
# merge_touch MESSAGE PATH...: append a line to each PATH, commit, and
# record the commit as the merged commit of the change areas.
merge_touch() {
  message=$1
  shift
  for f in "$@"; do
    mkdir -p "$(dirname "$f")"
    echo "# touched" >> "$f"
  done
  commit "$message"
  state set areas merged "$(git rev-parse --short=12 HEAD)" > /dev/null
}
fresh areas
state init areas chore/areas > /dev/null
merge_touch "feat: entry" bin/carat.rb
expect "run_state: review-due names the entry point" 0 "^due: the change touched entry point [(]bin/carat[.]rb[)]" state review-due areas
merge_touch "chore: tool" tools/x.sh
expect "run_state: review-due skips another tool" 1 "^not due" state review-due areas
merge_touch "chore: guard" tools/agent_guard.sh
expect "run_state: review-due names the guard" 0 "^due: the change touched guard and gates [(]tools/agent_guard[.]sh[)]" state review-due areas
merge_touch "chore: gates" tools/gates.sh
expect "run_state: review-due names the gates" 0 "^due: the change touched guard and gates [(]tools/gates[.]sh[)]" state review-due areas
merge_touch "chore: settings" .claude/settings.json
expect "run_state: review-due names the settings" 0 "^due: the change touched guard and gates [(][.]claude/settings[.]json[)]" state review-due areas
merge_touch "chore: agent" .claude/agents/x.md
expect "run_state: review-due skips an agent's prose" 1 "^not due" state review-due areas
printf -- '---\nname: x\ntools: Bash, Read\n---\n\nProse.\n' > .claude/agents/x.md
merge_touch "chore: agent tools" README.md
expect "run_state: review-due names an agent's tools" 0 "^due: the change touched guard and gates [(][.]claude/agents/x[.]md, its tools or hooks[)]" state review-due areas
printf '    - matcher: "Bash"\n' >> .claude/agents/x.md
merge_touch "chore: agent hook" README.md
expect "run_state: review-due names an agent's hook" 0 "its tools or hooks" state review-due areas
merge_touch "docs: notes" docs/x.md
expect "run_state: review-due skips a docs-only change" 1 "^not due" state review-due areas
merge_touch "ci: workflow" .github/workflows/ci.yml
expect "run_state: review-due names the CI workflow" 0 "^due: the change touched guard and gates [(][.]github/workflows/ci[.]yml[)]" state review-due areas
merge_touch "chore: scanner" tools/scan_text.sh
expect "run_state: review-due names the scanner" 0 "^due: the change touched guard and gates [(]tools/scan_text[.]sh[)]" state review-due areas
merge_touch "chore: hooks" .githooks/pre-commit
expect "run_state: review-due names the commit hooks" 0 "^due: the change touched guard and gates [(][.]githooks/pre-commit[)]" state review-due areas
mkdir -p config carat/domain
printf '# Options.\noption.tabstop 2\nkeymap.normal j cursor.down\n' > config/default.caratrc
echo 'mirror' > carat/domain/default_config.rb
merge_touch "feat: config" README.md
{ sed 's/^keymap.normal j .*/keymap.normal j cursor.up/' config/default.caratrc; printf '\n# Window keys.\nkeymap.normal <C-w><C-j> window.down\n'; } > rc.tmp
mv rc.tmp config/default.caratrc
merge_touch "feat: keys" carat/domain/default_config.rb
expect "run_state: review-due skips a keymap-only change" 1 "^not due" state review-due areas
echo 'option.tabstop 4' >> config/default.caratrc
merge_touch "feat: tabstop" README.md
expect "run_state: review-due names a changed option" 0 "^due: the change touched config loading [(]config/default[.]caratrc[)]" state review-due areas
merge_touch "fix: mirror" carat/domain/default_config.rb
expect "run_state: review-due names the mirror changed alone" 0 "^due: the change touched config loading [(]carat/domain/default_config[.]rb[)]" state review-due areas
echo 'keymap.normal k cursor.up' >> config/default.caratrc
merge_touch "fix: loader" carat/adapters/rc_config_gateway.rb
expect "run_state: review-due names a loader" 0 "^due: the change touched config loading [(]carat/adapters/rc_config_gateway[.]rb[)]" state review-due areas
echo 'keymap.normal l cursor.right' >> config/default.caratrc
merge_touch "fix: generator" bin/carat-gen-config.rb
expect "run_state: review-due names the generator" 0 "^due: the change touched config loading [(]bin/carat-gen-config[.]rb[)]" state review-due areas

# The planner runs only when the queue needs a decision: the change is not
# the queue's head, or a merged change without a history row holds a
# proposal or finding to place.
fresh plan
printf '# Queue\n\n1. `next` (T1, estimated small): one, estimated large later.\n2. `later` (T5, estimated medium): two.\n' > docs/queue.md
commit "docs: the queue"
state init next chore/next > /dev/null
expect "run_state: plan-needed takes the queue head as written" 1 "^not needed: next heads docs/queue[.]md, estimated small," state plan-needed next
expect "run_state: plan-needed names a change that is not the head" 0 "^needed: later is not the head of docs/queue[.]md [(]next[)]" state plan-needed later
# plan_lines CHANGE: plan-needed's exit, then the count of its lines.
plan_lines() {
  out=$(state plan-needed "$1")
  got=$?
  echo "exit $got lines $(printf '%s\n' "$out" | grep -c .)"
}
expect "run_state: plan-needed prints one line for the head" 0 "^exit 1 lines 1\$" plan_lines next
expect "run_state: plan-needed prints one line for a change that is not the head" 0 "^exit 0 lines 1\$" plan_lines later
state init prev chore/prev > /dev/null
state set prev merged "$(git rev-parse --short=12 HEAD)" > /dev/null
state note prev quality-advisory "abc1234 a name" > /dev/null
state note prev quality-blocking "abc1234 a bug" > /dev/null
expect "run_state: plan-needed ignores a delivery's advisories" 1 "^not needed" state plan-needed next
state note prev retro "drop a step; evidence: 9000 tokens" > /dev/null
expect "run_state: plan-needed names a pending proposal" 0 "^needed: prev holds 1 proposal" state plan-needed next
expect "run_state: plan-needed prints one line beside a pending proposal" 0 "^exit 0 lines 1\$" plan_lines next
state history > /dev/null
expect "run_state: plan-needed leaves a change with a history row" 1 "^not needed" state plan-needed next
printf '# Queue\n\n1. UI track: themes (T5, estimated medium).\n' > docs/queue.md
expect "run_state: plan-needed names a head without a change name" 0 "^needed: next is not the head of docs/queue[.]md [(]no named item[)]" state plan-needed next

# forge CHANGE LINE: append LINE to the run state as a hand edit would.
forge() {
  { sed '$d' "build/pipeline/$1.json" | sed '$s/$/,/'; printf '%s\n}\n' "$2"; } > forged.json
  mv forged.json "build/pipeline/$1.json"
}
# A resume trusts a phase or review record only at a commit git supports:
# an ancestor of HEAD, or of main, where the squash commit is.
fresh trust
state init trust chore/trust > /dev/null
echo work >> README.md
commit "feat: work"
worked=$(git rev-parse --short=12 HEAD)
state phase trust implement > /dev/null
state review trust security pass "high=0" > /dev/null
git_q checkout -q main
echo squash >> README.md
commit "feat: the squash commit"
squashed=$(git rev-parse --short=12 HEAD)
git_q checkout -q -b chore/other
echo other >> README.md
commit "feat: other"
other=$(git rev-parse --short=12 HEAD)
git_q checkout -q chore/trust
state phase trust merge "$squashed" > /dev/null
state set trust merged "$squashed" > /dev/null
state phase trust package "$other" > /dev/null
forge trust '  "phase.check": "0000000000"'
forge trust '  "phase.plan": "HEAD"'
forge trust "  \"phase.implement\": \"$other\""
forge trust '  "phase.retr\u006f": "x"'
env BASE=main sh "$here/run_state.sh" trusted trust > trusted.out
expect "run_state: trusted keeps a record at an ancestor of HEAD" 0 "^  \"phase.implement\": \"$worked\",$" cat trusted.out
expect "run_state: trusted keeps a review at an ancestor of HEAD" 0 "^  \"review.security\": \"pass $worked high=0\",$" cat trusted.out
expect "run_state: trusted keeps a record at a commit of main" 0 "^  \"phase.merge\": \"$squashed\",$" cat trusted.out
expect "run_state: trusted keeps the merged commit on main" 0 "^  \"merged\": \"$squashed\",$" cat trusted.out
expect "run_state: trusted leaves out a record at a commit off the branch" 1 "" grep -q '"phase.package"' trusted.out
expect "run_state: trusted names what it left out" 0 "^  \"untrusted\": \"phase.package phase.check phase.plan phase.implement phase[.]retr[?]u006f\"$" cat trusted.out
expect "run_state: trusted prints one flat object" 0 "^ok$" \
  awk '{ l[NR] = $0 } END { ok = l[1] == "{" && l[NR] == "}" && l[NR - 1] !~ /,$/; for (i = 2; i < NR - 1; i++) if (l[i] !~ /^  "[a-z0-9_.-]+": ".*",$/) ok = 0; print ok ? "ok" : "bad" }' trusted.out
expect "run_state: trusted leaves the file as it was" 0 '"phase.package"' cat build/pipeline/trust.json
expect "run_state: trusted without the base still trusts the ancestors of HEAD" 0 "\"untrusted\": \"phase.merge merged phase.package" \
  env BASE=nothing sh "$here/run_state.sh" trusted trust

# --------------------------------------------------------- agent_guard.sh

# guard PROFILE COMMAND [DIR]: the guard's answer to a Bash call of
# COMMAND, given already escaped for JSON, in the project PROJECT (default
# /w).
guard() {
  printf '{"session_id":"s","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"%s","description":"d"}}' "$2" |
    CLAUDE_PROJECT_DIR=${PROJECT:-/w} sh "$here/agent_guard.sh" "$1" ${3:+"$3"}
}

# guard_edit PROFILE TOOL PATH [DIR]: the guard's answer to an edit of
# PATH in the project PROJECT (default /w), whose text names a refused
# command.
guard_edit() {
  printf '{"tool_name":"%s","tool_input":{"file_path":"%s","old_string":"a","new_string":"\\"command\\": \\"git push\\""}}' "$2" "$3" |
    CLAUDE_PROJECT_DIR=${PROJECT:-/w} sh "$here/agent_guard.sh" "$1" ${4:+"$4"}
}

# Every profile refuses the forms it cannot read and the commands it does
# not list, however they are written.
for p in read merger contributor; do
  expect "guard: $p allows a git read" 0 "^$" guard $p 'git --no-pager log --oneline -5 && git diff origin/main...HEAD | head -40'
  expect "guard: $p refuses git push" 2 "refused for the $p profile: git push" guard $p 'git push origin chore/x'
  expect "guard: $p refuses a quoted verb" 2 "git push" guard $p "git 'push' origin x"
  expect "guard: $p refuses a quoted name" 2 "git push" guard $p '\"git\" push origin x'
  expect "guard: $p refuses an escaped name" 2 "git push" guard $p 'g\\it pu\\sh origin x'
  expect "guard: $p refuses a split verb" 2 "git push" guard $p "git pu''sh origin x"
  expect "guard: $p refuses ANSI-C quoting" 2 "a [$] expansion" guard $p "git \$'\\\\x70ush' origin x"
  expect "guard: $p refuses locale quoting" 2 "a [$] expansion" guard $p 'git $\"push\" origin x'
  expect "guard: $p refuses a parent step" 2 "a parent step" guard $p 'cat docs/../README.md'
  expect "guard: $p refuses a variable" 2 "a [$] expansion" guard $p 'git $V origin x'
  expect "guard: $p refuses a variable in double quotes" 2 "inside double quotes" guard $p 'sh \"$PWD/tools/run_state.sh\" show c'
  expect "guard: $p refuses a subshell" 2 "a subshell" guard $p '(git push origin x)'
  expect "guard: $p refuses a command substitution" 2 "a [$] expansion" guard $p 'echo $(git push origin x)'
  expect "guard: $p refuses a backquote substitution" 2 "a command substitution" guard $p 'echo `git push origin x`'
  expect "guard: $p refuses env" 2 "env is not a command" guard $p 'env git push origin x'
  expect "guard: $p refuses an environment assignment" 2 "an assignment of GIT_DIR" guard $p 'GIT_DIR=x git status'
  expect "guard: $p refuses a fake make for the checks" 2 "an assignment of MAKE" guard $p 'MAKE=true STAGES=lint sh tools/run_state.sh check c'
  expect "guard: $p refuses xargs" 2 "xargs is not a command" guard $p 'echo push | xargs git'
  expect "guard: $p refuses sh -c" 2 "a shell option: sh -c" guard $p 'sh -c \"git push origin x\"'
  expect "guard: $p refuses bash -c" 2 "bash is not a command" guard $p 'bash -c \"git push origin x\"'
  expect "guard: $p refuses eval" 2 "eval is not a command" guard $p 'eval git push origin x'
  expect "guard: $p refuses awk" 2 "awk is not a command" guard $p 'awk \"BEGIN { system(1) }\"'
  expect "guard: $p refuses a glob" 2 "glob or brace character" guard $p 'git pu? origin x'
  expect "guard: $p refuses brace expansion" 2 "glob or brace character" guard $p 'git {push,origin}'
  expect "guard: $p refuses a here-document" 2 "a here-document" guard $p 'cat <<EOF\ngit push\nEOF'
  expect "guard: $p refuses a command named by a path" 2 "a command named by a path" guard $p '/usr/bin/git push origin x'
  expect "guard: $p refuses a script outside its forms" 2 "the script tmp/x.sh is not one" guard $p 'sh tmp/x.sh'
  expect "guard: $p refuses gh" 2 "gh is not a command" guard $p 'gh pr merge 5 --squash'
  expect "guard: $p refuses a command on a later line" 2 "git push" guard $p 'git status\ngit push origin x'
  expect "guard: $p refuses a command after a comment" 2 "git push" guard $p 'ls # a note\ngit push origin x'
  expect "guard: $p refuses a carriage return before a comment" 2 "glob or brace character" guard $p 'ls\r#; git push origin x'
  expect "guard: $p refuses an escaped carriage return before a comment" 2 "glob or brace character" guard $p 'ls\u000d#; git push origin x'
  expect "guard: $p refuses git push over a line continuation" 2 "git push" guard $p 'git \\\npush origin x'
  expect "guard: $p refuses a push on the line after an escaped backslash" 2 "git push" guard $p 'echo x\\\\\ngit push'
  expect "guard: $p refuses a git alias" 2 "a git configuration override" guard $p 'git -c alias.p=push p origin x'
  expect "guard: $p refuses a git option it does not list" 2 "the git option --git-dir" guard $p 'git --git-dir=.git log'
  expect "guard: $p refuses update-ref" 2 "git update-ref is not" guard $p 'git update-ref refs/heads/main HEAD'
  expect "guard: $p refuses send-pack" 2 "git send-pack is not" guard $p 'git send-pack origin HEAD:main'
  expect "guard: $p refuses git config" 2 "git config is not" guard $p 'git config core.hooksPath tmp'
  expect "guard: $p refuses a forced branch" 2 "git branch other than a listing" guard $p 'git branch -f main HEAD'
  expect "guard: $p refuses a checkout of the tree" 2 "git checkout outside a worktree" guard $p 'git checkout -- .'
  expect "guard: $p refuses a git read that writes a file" 2 "git diff --output=x" guard $p 'git diff --output=x'
  expect "guard: $p refuses a fetch with a refspec" 2 "git fetch other than" guard $p 'git fetch origin x:refs/remotes/origin/main'
  expect "guard: $p refuses a remote that runs a command" 2 "git ls-remote of other than origin" guard $p 'git ls-remote --heads \"ext::sh -c x\" main'
  expect "guard: $p refuses a -C path outside the project's worktrees" 2 "git -C other than the project or a worktree" guard $p 'git -C \"my dir\" push origin x'
  expect "guard: $p refuses a repository of its own by -C" 2 "git -C other than the project or a worktree" guard $p 'git -C tmp/scout/ev fetch -q origin' tmp/scout
  expect "guard: $p allows -C of the project and of a worktree" 0 "^$" guard $p 'git -C /w log -1 && git -C . status && git -C tmp/.base log -1'
  expect "guard: $p refuses a line continuation inside a comment" 2 "git push" guard $p 'true # x \\\ngit push origin HEAD'
  expect "guard: $p reads a comment to its line break only" 0 "^$" guard $p 'ls # a; git push \\\ngit status'
  expect "guard: $p refuses a review record" 2 "tools/run_state.sh review" guard $p 'sh tools/run_state.sh review c security pass x HEAD'
  expect "guard: $p refuses a quoted review record" 2 "tools/run_state.sh review" guard $p "sh tools/run_state.sh re''view c security pass x"
  expect "guard: $p refuses a phase record" 2 "tools/run_state.sh phase" guard $p 'sh tools/run_state.sh phase c plan'
  expect "guard: $p refuses a stage record" 2 "tools/run_state.sh stage" guard $p 'sh tools/run_state.sh stage c lint 0'
  expect "guard: $p refuses an init" 2 "tools/run_state.sh init" guard $p 'sh tools/run_state.sh init c chore/c'
  expect "guard: $p refuses a push count" 2 "tools/run_state.sh set" guard $p 'sh tools/run_state.sh set c pushes 0'
  expect "guard: $p refuses the run state file" 2 "naming the run state's directory" guard $p 'cat build/pipeline/c.json'
  expect "guard: $p refuses a quoted run state path" 2 "naming the run state's directory" guard $p 'cat build/\"pipe\"line/c.json'
  expect "guard: $p refuses an unterminated quote" 2 "an unterminated quote" guard $p "echo 'x"
  expect "guard: $p reads a JSON escape as its character" 2 "inside double quotes" guard $p 'echo \"$(git push origin x)\"'
  expect "guard: $p reads an escaped quote as a quote" 2 "git push" guard $p 'echo 'x'; git push origin x'
  expect "guard: $p refuses a write outside the project" 2 "a write outside the project" guard $p 'echo x > /tmp/x'
  expect "guard: $p refuses a write under .git" 2 "a write under .git" guard $p 'echo x > .git/hooks/pre-commit'
  expect "guard: $p refuses a tool it does not judge" 2 "which this guard does not judge" guard_edit $p Read /w/README.md
done
expect "guard: an unknown profile refuses" 2 "no such profile" guard writer 'ls'
# A dry run of each agent's commands as its file under .claude/agents/
# names them, under its profile.
expect "guard: scout runs its steps" 0 "^$" guard read 'git rev-parse HEAD && git rev-parse --short HEAD && git merge-base --is-ancestor HEAD origin/main && date -u +%Y%m%dT%H%M%SZ' tmp/scout
expect "guard: scout prunes and writes its directory" 0 "^$" guard read 'mkdir -p tmp/scout && rm tmp/scout/edit-path-abc1234-x.md' tmp/scout
expect "guard: scout reads the tree" 0 "^$" guard read 'git diff --quiet abc1234 HEAD -- tools/x.sh docs/y.md; git ls-files tools | wc -l; ls tools; grep -n \"def name\" carat/x.rb; git show --stat HEAD' tmp/scout
expect "guard: planner reads the run states" 0 "^$" guard read 'sh tools/run_state.sh status && sh tools/run_state.sh pending && sh tools/run_state.sh show c' build/plan
expect "guard: planner prepares its directory" 0 "^$" guard read 'mkdir -p build/plan && rm -f build/plan/goals.md' build/plan
expect "guard: checker runs the checks" 0 "^$" guard read 'sh tools/run_state.sh check c abc1234; sh tools/run_state.sh check c'
expect "guard: checker never starts the runner" 2 "tools/run_state.sh check-run" guard read 'sh tools/run_state.sh check-run c'
expect "guard: contributor refuses the removed backup command" 2 "tools/run_state.sh backup, which the workflow or another agent runs" guard contributor 'sh tools/run_state.sh backup c'
expect "guard: contributor never abandons a run" 2 "run_state.sh abandon" guard contributor 'sh tools/run_state.sh abandon c'
expect "guard: merger never abandons a run" 2 "run_state.sh abandon" guard merger 'sh tools/run_state.sh abandon c'
expect "guard: read refuses a backup" 2 "tools/run_state.sh backup" guard read 'sh tools/run_state.sh backup c'
expect "guard: checker records the figures first" 0 "^$" guard read 'sh tools/run_state.sh metric c phase.check=1200/5 first.check=0 rework=2 extra=1 stop=none estimate=small planned=0'
expect "guard: retrospective budgets the last row's change" 0 "^$" guard close 'tail -1 docs/metrics.tsv | cut -f1; sh tools/run_state.sh budget prev && sh tools/run_state.sh note c overrun \"prev: over: estimated small\"'
expect "guard: retrospective checks the squash commit" 0 "^$" guard close 'sh tools/run_state.sh show c && git show --stat abc1234 && BASE=abc1234~1 sh tools/gates.sh trailer && BASE=abc1234~1 sh tools/gates.sh content docs'
expect "guard: retrospective records its notes" 0 "^$" guard close 'sh tools/run_state.sh note c retro \"x; evidence: 3\" && sh tools/run_state.sh budget c && sh tools/run_state.sh review-due c && sh tools/run_state.sh status'
# The closing start runs the run's last records: the phases no merge gate
# reads, notes, and the figures, never a review or a gated phase.
expect "guard: close records a closing phase" 0 "^$" guard close 'sh tools/run_state.sh phase c package abc1234 && sh tools/run_state.sh phase c ci abc1234 && sh tools/run_state.sh phase c merge abc1234 && sh tools/run_state.sh phase c retro abc1234 && sh tools/run_state.sh phase c report abc1234 && sh tools/run_state.sh note c extra-round \"why\" && sh tools/run_state.sh metric c phase.check=1200/5 first.check=1 rework=0 stop=none'
for gated in check quality security bench; do
  expect "guard: close refuses a $gated phase" 2 "the close profile records only" guard close "sh tools/run_state.sh phase c $gated abc1234"
done
expect "guard: close refuses a phase without its commit" 2 "the close profile records only" guard close 'sh tools/run_state.sh phase c report'
expect "guard: close refuses a phase at a word that is not a commit" 2 "the close profile records only" guard close 'sh tools/run_state.sh phase c report HEAD'
expect "guard: close refuses a review record" 2 "tools/run_state.sh review" guard close 'sh tools/run_state.sh review c security pass x abc1234'
expect "guard: close refuses a push" 2 "git push" guard close 'git push origin x'
expect "guard: close names its profile" 2 "refused for the close profile" guard close 'sh tools/run_state.sh set c pushes 0'
expect "guard: read refuses a closing phase" 2 "the close profile records only" guard read 'sh tools/run_state.sh phase c report abc1234'
expect "guard: checker reads a failing log and compares" 0 "^$" guard read 'tail -60 build/stages/c/lint.log; grep -n -m 20 -E \"FAIL|rror|KILLED\" build/stages/c/lint.log; sh tools/run_state.sh bench c; sh tools/run_state.sh show c'
expect "guard: checker notes the tokens spent" 0 "^$" guard read 'sh tools/run_state.sh spent c && sh tools/run_state.sh bench c'
expect "guard: merger refuses spent" 2 "tools/run_state.sh spent" guard merger 'sh tools/run_state.sh spent c'
expect "guard: benchmark prepares the base" 0 "^$" guard read 'git worktree add --detach tmp/.base origin/main || git -C tmp/.base checkout -q --detach origin/main'
expect "guard: benchmark builds the base" 0 "^$" guard read 'make -C tmp/.base dev-build test-build bench-budget PREFIX=/w/tmp/.toolchain SPINEL_CACHE_DIR=/w/build/spinel-cache'
expect "guard: benchmark measures the base with the change's script" 0 "^$" guard read 'cd tmp/.base && sh /w/tools/metrics.sh measure build/metrics/current.tsv'
expect "guard: benchmark compares and records" 0 "^$" guard read 'make metrics && make metrics-compare BASE_METRICS=tmp/.base/build/metrics/current.tsv && make bench SCENARIOS=\"lh j\" && sh tools/run_state.sh metrics c build/metrics/current.tsv && git worktree remove --force tmp/.base'
expect "guard: quality reviewer reads the diff and notes" 0 "^$" guard read 'git diff origin/main...HEAD && git diff --name-only abc1234 HEAD && git rev-parse --short=12 HEAD && sh tools/run_state.sh note c quality-advisory \"abc1234 tools/x.sh:3 a reason; fix: an outline\"'
expect "guard: quality reviewer scopes a fix round" 0 "^$" guard read 'sh tools/run_state.sh scope c abc1234 tools/x.sh carat/domain/buffer.rb && git diff abc1234 HEAD'
expect "guard: quality reviewer runs the periodic mode" 0 "^$" guard read 'git fetch -q origin && git worktree add --detach tmp/.review-quality origin/main && git log --name-only -5 origin/main && git worktree remove --force tmp/.review-quality'
expect "guard: security reviewer runs its steps" 0 "^$" guard read 'git status --porcelain --untracked-files=no && git remote set-head origin main && git fetch -q origin && git -C tmp/.review-security checkout -q --detach origin/main && sh tools/run_state.sh note c security \"Low (3) tools/x.sh:1 a title; fix: an outline\"'
expect "guard: merger waits and records CI" 0 "^$" guard merger 'sh tools/run_state.sh metric c rework=0 && sh tools/run_state.sh show c && sh tools/ci_wait.sh 30 && sh tools/run_state.sh set c ci \"green abc1234\"'
expect "guard: merger runs main's merge gates" 0 "^$" guard merger 'git worktree remove --force tmp/.merge-gates; git worktree add -q --detach tmp/.merge-gates origin/main && CHANGE=c RECORDS=\"security:pass:abc1234 quality:pass:abc1234 check:pass:abc1234\" sh tmp/.merge-gates/tools/gates.sh merge build/pipeline/c.body.md'
expect "guard: merger refuses the branch's merge gates" 2 "the branch's tools/gates.sh merge" guard merger 'CHANGE=c RECORDS=\"security:pass:abc1234\" sh tools/gates.sh merge build/pipeline/c.body.md'
expect "guard: merger refuses another gate of main's copy" 2 "other than merge BODY" guard merger 'sh tmp/.merge-gates/tools/gates.sh records'
expect "guard: merger refuses another script under the worktree" 2 "the script tmp/.merge-gates/tools/run_state.sh is not one" guard merger 'sh tmp/.merge-gates/tools/run_state.sh show c'
expect "guard: contributor refuses main's merge gates" 2 "is not a command of this profile" guard contributor 'sh tmp/.merge-gates/tools/gates.sh merge build/pipeline/c.body.md'
expect "guard: merger verifies and records the merge" 0 "^$" guard merger 'git fetch -q --prune origin && git log -1 --format=%B origin/main && sh tools/run_state.sh set c merged abc1234 && git ls-remote --heads origin chore/x'
expect "guard: merger deletes the branch and fast-forwards main" 0 "^$" guard merger 'git push origin --delete chore/x; git checkout -q main && git merge -q --ff-only origin/main && git branch -D chore/x'
# The merger's first green: the green and red lines as the workflow builds
# them (mergeLines), and its two closing calls, each one call the guard
# admits.
expect "guard: merger runs the green line" 0 "^$" guard merger 'git worktree prune; git worktree remove --force tmp/.merge-gates; sh tools/run_state.sh metric c phase.check=1200/5 rework=0 stop=none estimate=medium && sh tools/run_state.sh set c ci \"green abc1234\" && GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -c core.hooksPath=/dev/null remote get-url origin | tr -d '\''\\n'\'' | grep -q -x -E '\''(https[:]//([^/@]+@)?github[.]com/|(ssh[:]//)?git@github[.]com[:/])o/r([.]git)?/?'\'' && GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -c core.hooksPath=/dev/null fetch -q --refmap= origin +refs/heads/main:refs/remotes/origin/main && GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -c core.hooksPath=/dev/null worktree add -q --detach tmp/.merge-gates origin/main && CHANGE=c RECORDS=\"security:pass:abc1234 quality:pass:abc1234 bench:pass:abc1234 check:pass:abc1234\" sh tmp/.merge-gates/tools/gates.sh merge build/pipeline/c.body.md'
expect "guard: merger refuses another global configuration before git" 2 "a GIT_CONFIG_GLOBAL other than /dev/null" guard merger 'GIT_CONFIG_GLOBAL=tmp/g git fetch -q --prune origin'
expect "guard: merger refuses a pinned configuration before another command" 2 "an assignment before ls" guard merger 'GIT_CONFIG_NOSYSTEM=1 ls'
expect "guard: merger refuses another assignment before git" 2 "an assignment of BASE before git" guard merger 'BASE=main git fetch -q --prune origin'
expect "guard: merger records red CI" 0 "^$" guard merger 'sh tools/run_state.sh metric c rework=1 && sh tools/run_state.sh set c ci \"red abc1234\"'
expect "guard: merger waits as its file says" 0 "^$" guard merger 'sh tools/ci_wait.sh 180 && sh tools/ci_wait.sh 240 && sh tools/ci_wait.sh 300'
expect "guard: merger verifies the merge" 0 "^$" guard merger 'git fetch -q --prune origin && git log -1 --format=%H%n%B origin/main'
expect "guard: merger records the merge and cleans up" 0 "^$" guard merger 'sh tools/run_state.sh set c merged abc1234 && git ls-remote --heads origin chore/x && git checkout -q main && git merge -q --ff-only origin/main && git branch -D chore/x'
expect "guard: contributor proposes and validates" 0 "^$" guard contributor 'npx -y @fission-ai/openspec@latest new change c && npx @fission-ai/openspec@latest validate \"c\" --strict --no-interactive && openspec status --change c --json'
expect "guard: contributor generates and checks" 0 "^$" guard contributor 'make new-ex-command NAME=sort SPEC=\"sor[t]\" AREA=12 && make test-one T=test/domain_buffer.rb && make diagnose-one T=carat/domain/buffer.rb && make -s lint docs-lint gates && make snapshots && make spec-validate'
expect "guard: contributor commits" 0 "^$" guard contributor 'git add -A && git -c user.name=\"Claude\" -c user.email=\"noreply@anthropic.com\" commit -q -m \"feat: x\" -m \"Co-Authored-By: Claude <noreply@anthropic.com>\" && git commit -q -F tmp/message.txt'
expect "guard: contributor records the plan" 0 "^$" guard contributor 'cp build/plan/queue.md docs/queue.md && cp build/plan/goals.md docs/goals.md && sh tools/run_state.sh history'
expect "guard: contributor archives" 0 "^$" guard contributor 'npx @fission-ai/openspec@latest archive c -y --skip-specs && npx @fission-ai/openspec@latest validate --all --strict --no-interactive'
expect "guard: contributor pushes and opens the pull request" 0 "^$" guard contributor 'sh tools/run_state.sh push c && sh tools/gates.sh pr-body build/pipeline/c.body.md && sh tools/run_state.sh set c pr 47 && sh tools/run_state.sh show c'
expect "guard: contributor pushes a CI fix" 0 "^$" guard contributor 'sh tools/run_state.sh push c --ci-fix'
expect "guard: contributor merges main" 0 "^$" guard contributor 'git fetch -q origin && git merge --no-edit origin/main'
expect "guard: contributor moves and removes files" 0 "^$" guard contributor 'mkdir -p tools/x && git mv a.sh tools/x/a.sh && rm -f tmp/x && chmod +x tools/x/a.sh && touch tmp/y'
expect "guard: contributor reads lines and the tree" 0 "^$" guard contributor 'cd /w && sed -n 1,70p tools/x.sh; sed -n \"300,\\$p\" docs/backlog.md; find tools -name x.sh; git status --short | head'

# Each profile's own refusals.
expect "guard: read refuses a contributor command" 2 "cp is not a command" guard read 'cp a b'
expect "guard: read refuses a commit" 2 "git commit is not" guard read 'git commit -m x'
expect "guard: read refuses a set" 2 "tools/run_state.sh set" guard read 'sh tools/run_state.sh set c ci \"green abc1234\"'
expect "guard: read refuses a push through the run state" 2 "tools/run_state.sh push" guard read 'sh tools/run_state.sh push c'
expect "guard: read refuses a make target it does not list" 2 "the make target check" guard read 'make check'
expect "guard: read refuses a command in a make variable" 2 "a shell character in the make variable SCENARIOS" guard read 'make bench SCENARIOS=\"lh; git push\"'
expect "guard: read refuses a toolchain elsewhere" 2 "PREFIX other than" guard read 'make -C tmp/.base dev-build PREFIX=/tmp/evil'
expect "guard: read refuses a make outside a worktree" 2 "make -C outside a worktree" guard read 'make -C tmp/.toolchain dev-build'
expect "guard: read refuses a cd elsewhere" 2 "cd other than" guard read 'cd build && cat pipeline/c.json'
expect "guard: read refuses a write outside its directory" 2 "a write outside tmp/scout" guard read 'echo x > tools/x.sh' tmp/scout
expect "guard: read refuses a removal outside its directory" 2 "a write outside tmp/scout" guard read 'rm tools/x.sh' tmp/scout
expect "guard: read refuses a removal without a directory" 2 "a write by an agent that writes no file" guard read 'rm tmp/x'
expect "guard: read refuses sed that writes" 2 "sed other than" guard read 'sed -i s/a/b/ x'
expect "guard: read refuses sed that runs a command" 2 "sed other than" guard read 'sed -n \"1e git push\" x'
expect "guard: read refuses find that runs a command" 2 "find -exec" guard read 'find . -exec git push \\;'
expect "guard: read refuses sort that writes" 2 "the sort option -o" guard read 'sort -o tools/x.sh x'
expect "guard: read refuses sort -o in a cluster" 2 "the sort option -o in -uo" guard read 'sort -uo .git/config x' tmp/scout
expect "guard: read refuses a long sort option by its prefix" 2 "the sort option --outp=.git/config" guard read 'sort --outp=.git/config x' tmp/scout
expect "guard: read refuses a sort compress program" 2 "the sort option -S" guard read 'sort -S 1 --compress-prog=sh x'
expect "guard: read refuses a long sort option after its operands" 2 "the sort option --compress-prog=sh" guard read 'sort x --compress-prog=sh'
expect "guard: read allows sort with its listed options" 0 "^$" guard read 'sort -u -k2,2 -t: -rn -k 3 x | sort -to -- -o'
expect "guard: read refuses uniq writing from stdin" 2 "uniq with a second operand" guard read 'printf x | uniq - .git/config' tmp/scout
expect "guard: read refuses uniq with an output file" 2 "uniq with a second operand" guard read 'uniq a b'
expect "guard: read refuses uniq's output file after --" 2 "uniq with a second operand" guard read 'uniq -c -- -a Makefile'
expect "guard: read allows uniq with one input" 0 "^$" guard read 'uniq -c a && sort a | uniq -u && uniq -d -'
for p in read merger contributor; do
  expect "guard: $p refuses printf -v with a subscript" 2 "printf with the option -v" guard $p "printf -v 'a[\$(id)]' x"
  expect "guard: $p refuses printf -v PATH" 2 "printf with the option -v" guard $p 'printf -v PATH x'
  expect "guard: $p refuses printf --" 2 "printf with the option --" guard $p 'printf -- -v x'
done
expect "guard: read allows printf with a format" 0 "^$" guard read "printf '%s\\\\n' a b"
expect "guard: read refuses git grep -O in a cluster" 2 "git grep -nOCMD, whose -O runs a command" guard read 'git grep -nOCMD x'
expect "guard: read refuses git grep's pager by a prefix" 2 "a prefix of --open-files-in-pager" guard read 'git grep --open=sh x'
expect "guard: read refuses textconv by a prefix" 2 "a prefix of --textconv" guard read 'git cat-file --textc HEAD:a'
expect "guard: read allows a git read with a long option" 0 "^$" guard read 'git log --no-ext-diff --exit-code --oneline -1 && git diff -O tmp/order --stat'
expect "guard: read refuses a quoted digit before a redirection" 2 "a write outside tmp/scout, links followed: 1" guard read 'rm -rf \"1\">/dev/null' tmp/scout
expect "guard: read refuses an escaped digit before a redirection" 2 "a write outside tmp/scout, links followed: 1" guard read 'rm -rf \\1>/dev/null' tmp/scout
expect "guard: read takes a bare digit before a redirection as a descriptor" 0 "^$" guard read 'rm -f tmp/scout/x 2>/dev/null' tmp/scout
expect "guard: read refuses a removal of /dev/null" 2 "a write outside the project: /dev/null" guard read 'rm -f /dev/null; echo x > /dev/null'
expect "guard: read refuses a removal of /dev/null in its directory" 2 "a write outside the project: /dev/null" guard read 'rm /dev/null' tmp/scout
expect "guard: read refuses a metrics script of another form" 2 "tools/metrics.sh other than" guard read 'sh tools/metrics.sh shell'
expect "guard: read refuses a measurement into .git" 2 "tools/metrics.sh measure into other than build/metrics/current.tsv" guard read 'sh tools/metrics.sh measure .git/config'
expect "guard: read refuses a measurement outside the project" 2 "tools/metrics.sh measure into other than build/metrics/current.tsv" guard read 'sh tools/metrics.sh measure /tmp/x'
expect "guard: read refuses a measurement into another project file" 2 "tools/metrics.sh measure into other than build/metrics/current.tsv" guard read 'sh tools/metrics.sh measure /w/.claude/settings.json'
expect "guard: read refuses a measurement into the toolchain" 2 "tools/metrics.sh measure into other than a worktree" guard read 'sh tools/metrics.sh measure tmp/.toolchain/build/metrics/current.tsv'
expect "guard: read refuses a measurement with other than scenario names" 2 "tools/metrics.sh measure with other than scenario names: /tmp/x" guard read 'sh tools/metrics.sh measure build/metrics/current.tsv lh /tmp/x'
expect "guard: read refuses a measurement without OUT" 2 "tools/metrics.sh measure without OUT" guard read 'sh tools/metrics.sh measure'
expect "guard: read refuses a comparison of another form" 2 "tools/metrics.sh compare other than BASE CURRENT" guard read 'sh tools/metrics.sh compare a b c'
expect "guard: read measures into the project or a worktree and compares" 0 "^$" guard read 'sh tools/metrics.sh measure build/metrics/current.tsv lh dot-ciw && sh tools/metrics.sh measure /w/build/metrics/current.tsv && sh tools/metrics.sh measure /w/tmp/.base/build/metrics/current.tsv && sh tools/metrics.sh compare a.tsv b.tsv'
expect "guard: read refuses the merge gate" 2 "tools/gates.sh with other than gate names" guard read 'sh tools/gates.sh merge build/pipeline/c.body.md'
expect "guard: read refuses an assignment before another script" 2 "an assignment before tools/run_state.sh" guard read 'BASE=x sh tools/run_state.sh show c'
expect "guard: merger refuses the deletion of main" 2 "git push other than" guard merger 'git push origin --delete main'
expect "guard: merger refuses a second ref after the branch" 2 "git push other than" guard merger 'git push origin --delete chore/x main'
expect "guard: merger refuses another push" 2 "git push other than" guard merger 'git push origin HEAD:main'
expect "guard: merger refuses the deletion of main locally" 2 "git branch other than" guard merger 'git branch -D main'
expect "guard: merger refuses another merge" 2 "git merge other than" guard merger 'git merge origin/chore/x'
expect "guard: merger refuses a pull request record" 2 "tools/run_state.sh set of pr" guard merger 'sh tools/run_state.sh set c pr 5'
expect "guard: merger refuses a forged CI record" 2 "a CI record other than" guard merger 'sh tools/run_state.sh set c ci green'
expect "guard: merger refuses make" 2 "make is not a command" guard merger 'make metrics'
expect "guard: merger refuses another body" 2 "not a pull request body file" guard merger 'CHANGE=c sh tmp/.merge-gates/tools/gates.sh merge README.md'
expect "guard: contributor refuses git push" 2 "git push is not" guard contributor 'git push -u origin chore/x'
expect "guard: contributor refuses a push of another form" 2 "tools/run_state.sh push other than" guard contributor 'sh tools/run_state.sh push c --force'
# The contributor pushes only through tools/run_state.sh push: every git
# push it could run itself is refused, a push to a backup ref included.
for c in 'git push -q --atomic origin HEAD:refs/backup/chore/x main:refs/backup-base/chore/x' 'git push origin HEAD:refs/backup/chore/x' 'git -C . push origin HEAD:refs/backup/chore/x' 'git -c core.hooksPath=/dev/null push origin chore/x' 'GIT_CONFIG_NOSYSTEM=1 git --no-pager push origin chore/x' 'git push origin --delete chore/x'; do
  expect "guard: contributor refuses $c" 2 "git push is not a command of this profile" guard contributor "$c"
done
expect "guard: contributor pushes through tools/run_state.sh" 0 "^$" guard contributor 'sh tools/run_state.sh push c'
expect "guard: contributor refuses a CI record" 2 "tools/run_state.sh set of ci" guard contributor 'sh tools/run_state.sh set c ci \"green abc1234\"'
expect "guard: contributor refuses a reset" 2 "git reset is not" guard contributor 'git reset --hard HEAD~1'
expect "guard: contributor refuses another git configuration" 2 "a git configuration override: -c core.hooksPath=tmp" guard contributor 'git -c core.hooksPath=tmp commit -m x'
expect "guard: contributor refuses a merge of another branch" 2 "git merge other than of origin/main" guard contributor 'git merge origin/chore/x'
expect "guard: contributor refuses a make option that runs text" 2 "the make option --eval" guard contributor 'make --eval=x lint'
expect "guard: contributor refuses a make variable it does not list" 2 "the make variable SPIN" guard contributor 'make lint SPIN=x'
expect "guard: contributor refuses a command in a make variable" 2 "a shell character in the make variable T" guard contributor 'make test-one T=\"x; git push\"'
expect "guard: contributor refuses npx of another package" 2 "npx of other than" guard contributor 'npx cowsay x'
expect "guard: contributor refuses a script by a path" 2 "a command named by a path" guard contributor './tools/run_state.sh push c'
expect "guard: contributor refuses a link" 2 "ln is not a command" guard contributor 'ln -s c.json build/x'
expect "guard: contributor refuses a copy into .git" 2 "a write under .git" guard contributor 'cp x .git/hooks/pre-commit'
expect "guard: contributor refuses a removal of the run state's parent" 2 "the directory that holds the run state's" guard contributor 'rm -rf build'
expect "guard: contributor refuses a removal of the project" 2 "a write outside the project" guard contributor 'rm -rf .'
expect "guard: contributor refuses a move onto /dev/null" 2 "a write outside the project: /dev/null" guard contributor 'mv x /dev/null'
expect "guard: contributor refuses a copy onto /dev/null" 2 "a write outside the project: /dev/null" guard contributor 'cp x /dev/null'
expect "guard: contributor allows a redirection to /dev/null" 0 "^$" guard contributor 'ls 2>/dev/null >/dev/null'
expect "guard: contributor refuses a long option of a writing command" 2 "the cp option --target-directory=/tmp" guard contributor 'cp --target-directory=/tmp x'
expect "guard: contributor refuses a move onto the body file" 2 "a write to the run state's directory" guard contributor 'mv tmp/x build/pipeline/c.body.md'
expect "guard: contributor refuses the run state file beside the body file" 2 "naming the run state's directory" guard contributor 'cat build/pipeline/c.body.md build/pipeline/c.json'
expect "guard: contributor refuses a body gate on another file" 2 "not a pull request body file" guard contributor 'sh tools/gates.sh pr-body build/pipeline/c.json'
expect "guard: contributor refuses a step inside the quoted body file" 2 "not a pull request body file" guard contributor 'sh tools/gates.sh pr-body \"build/pipeline/x.body.md /y\"'
expect "guard: contributor refuses a quoted blank and a parent step after the body file" 2 "a parent step" guard contributor 'printf x > \"build/pipeline/x.body.md /../x.json\"'
expect "guard: contributor allows the body gate by its absolute path" 0 "^$" guard contributor 'sh /w/tools/gates.sh pr-body /w/build/pipeline/c.body.md'

# File tools: a write target judged by its path and its real path.
expect "guard: contributor refuses an edit of the run state" 2 "a write to the run state's directory" guard_edit contributor Edit /w/build/pipeline/c.json
expect "guard: contributor allows an edit elsewhere, whatever its text" 0 "^$" guard_edit contributor Write /w/tools/x.sh
expect "guard: contributor refuses an edit outside the project" 2 "a write outside the project" guard_edit contributor Write /etc/x
expect "guard: contributor refuses an edit of the git configuration" 2 "a write under .git" guard_edit contributor Edit /w/.git/config
expect "guard: contributor writes the body file" 0 "^$" guard_edit contributor Write /w/build/pipeline/c.body.md
expect "guard: contributor refuses a path through the body file" 2 "a parent step" guard_edit contributor Write /w/build/pipeline/c.body.md/../c.json
expect "guard: read refuses a file edit without a directory" 2 "a write by an agent that writes no file" guard_edit read Write /w/tools/x.sh
expect "guard: read allows a pack in its directory, whatever its text" 0 "^$" guard_edit read Write /w/tmp/scout/area.md tmp/scout
expect "guard: read allows a relative path in its directory" 0 "^$" guard_edit read Write build/plan/queue.md build/plan
expect "guard: read refuses a file outside its directory" 2 "a write outside tmp/scout" guard_edit read Write /w/tools/x.sh tmp/scout
expect "guard: read refuses a parent step out of its directory" 2 "a parent step" guard_edit read Write /w/tmp/scout/../../tools/x.sh tmp/scout
expect "guard: merger refuses every file edit" 2 "a write by an agent that writes no file" guard_edit merger Write /w/tmp/x.md
expect "guard: merger refuses the body file" 2 "a write to the run state's directory" guard_edit merger Write /w/build/pipeline/c.body.md

# A real tree: a body file that is a link to the run state, a directory
# linked to the run state's, and a link out of the scout's directory.
proj="$work/proj"
mkdir -p "$proj/build/pipeline" "$proj/tmp/scout" "$proj/tools"
echo '{}' > "$proj/build/pipeline/c.json"
ln -s c.json "$proj/build/pipeline/d.body.md"
ln -s ../build/pipeline "$proj/tmp/run"
ln -s ../../tools "$proj/tmp/scout/out"
ln -s missing "$proj/tmp/gone"
ln -s nope/../run/c.json "$proj/tmp/hop"
ln -s ../build/pipeline/c.body.md "$proj/tmp/body"
PROJECT=$proj
expect "guard: contributor refuses the body gate on a linked body file" 2 "a pull request body file that is a link" guard contributor 'sh tools/gates.sh pr-body build/pipeline/d.body.md'
expect "guard: merger refuses the merge gate on a linked body file" 2 "a pull request body file that is a link" guard merger 'sh tmp/.merge-gates/tools/gates.sh merge build/pipeline/d.body.md'
expect "guard: contributor refuses a write to a linked body file" 2 "a pull request body file that is a link" guard_edit contributor Write "$proj/build/pipeline/d.body.md"
expect "guard: contributor refuses a write through a link to the body file" 2 "a write to the run state's directory" guard_edit contributor Write "$proj/tmp/body"
expect "guard: contributor refuses a linked directory into the run state" 2 "a write to the run state's directory" guard_edit contributor Write "$proj/tmp/run/c.json"
expect "guard: contributor refuses a redirection through a linked directory" 2 "a write to the run state's directory" guard contributor 'cat x > tmp/run/c.json'
expect "guard: contributor refuses a copy through a linked directory" 2 "a write to the run state's directory" guard contributor 'cp x tmp/run/'
expect "guard: contributor refuses a path through a dangling link" 2 "a dangling link" guard_edit contributor Write "$proj/tmp/gone/x/c.json"
expect "guard: contributor refuses a parent step after a missing directory" 2 "a parent step" guard_edit contributor Write "$proj/tmp/nope/../run/c.json"
expect "guard: contributor refuses a relative parent step" 2 "a parent step" guard_edit contributor Write "tmp/nope/../run/c.json"
expect "guard: contributor refuses a link whose target steps back" 2 "a parent step after a missing directory" guard_edit contributor Write "$proj/tmp/hop"
expect "guard: contributor allows a name with two dots" 0 "^$" guard_edit contributor Write "$proj/tmp/a..b.md"
expect "guard: read allows a name with two dots in its directory" 0 "^$" guard_edit read Write "$proj/tmp/scout/a..b.md" tmp/scout
expect "guard: read refuses a link out of its directory" 2 "a write outside tmp/scout, links followed" guard_edit read Write "$proj/tmp/scout/out/x.sh" tmp/scout
expect "guard: read refuses a redirection through a link out of its directory" 2 "a write outside tmp/scout, links followed" guard read 'echo x > tmp/scout/out/x.sh' tmp/scout
expect "guard: read allows a pack in its real directory" 0 "^$" guard_edit read Write "$proj/tmp/scout/area.md" tmp/scout
expect "guard: contributor writes the body file in a real tree" 0 "^$" guard_edit contributor Write "$proj/build/pipeline/c.body.md"
expect "guard: contributor allows the body gate in a real tree" 0 "^$" guard contributor 'sh tools/gates.sh pr-body build/pipeline/c.body.md'
# A measurement through a link into .git, in a worktree and in the project.
git_q init -q "$proj"
git_q -C "$proj" commit -q --allow-empty -m "chore: base" -m "$TRAILER"
git_q -C "$proj" worktree add -q --detach tmp/.base
ln -s ../../.git "$proj/tmp/.base/build"
expect "guard: read refuses a measurement through a link in a worktree" 2 "a path through a link: build/metrics" guard read 'cd tmp/.base && sh tools/metrics.sh measure build/metrics/current.tsv'
expect "guard: read refuses a measurement into a linked worktree path" 2 "a path through a link" guard read "sh tools/metrics.sh measure $proj/tmp/.base/build/metrics/current.tsv"
expect "guard: read measures into the project in a real tree" 0 "^$" guard read "sh tools/metrics.sh measure $proj/build/metrics/current.tsv"
ln -s ../.git "$proj/build/metrics"
expect "guard: read refuses a measurement through a link in the project" 2 "a path through a link" guard read "sh tools/metrics.sh measure $proj/build/metrics/current.tsv"
# Git and make run only in a worktree of the project's own repository: a
# repository planted at tmp/.NAME, a link to a worktree, and a worktree
# of another repository are refused; a worktree not there yet is admitted
# for the call that adds it, and add and remove go by the name.
git_q init -q "$work/elsewhere"
git_q -C "$work/elsewhere" commit -q --allow-empty -m "chore: base" -m "$TRAILER"
git_q -C "$work/elsewhere" worktree add -q --detach "$proj/tmp/.forged"
git_q init -q "$proj/tmp/.planted"
ln -s .base "$proj/tmp/.linked"
expect "guard: read allows git, cd, and make in a worktree of the project" 0 "^$" guard read 'git -C tmp/.base log -1 && cd tmp/.base && make -C tmp/.base dev-build'
for w in planted linked forged; do
  expect "guard: read refuses git in the $w tmp/.$w" 2 "git -C other than the project or a worktree" guard read "git -C tmp/.$w log -1"
  expect "guard: read refuses cd into the $w tmp/.$w" 2 "cd other than to the project or a worktree" guard read "cd tmp/.$w"
  expect "guard: read refuses make in the $w tmp/.$w" 2 "make -C outside a worktree" guard read "make -C tmp/.$w dev-build"
done
expect "guard: merger refuses a checkout in a planted repository" 2 "git -C other than" guard merger 'git -C tmp/.planted checkout -q --detach origin/main'
expect "guard: read adds a worktree not there yet and uses it" 0 "^$" guard read 'git worktree add --detach tmp/.new origin/main || git -C tmp/.new checkout -q --detach origin/main'
expect "guard: read removes a worktree by its name" 0 "^$" guard read 'git worktree remove --force tmp/.planted'
printf 'gitdir: %s\n' "$(cat "$proj/tmp/.base/.git" | sed 's/^gitdir: //')" > "$proj/tmp/.planted/.gitfile"
rm -rf "$proj/tmp/.planted/.git"
mv "$proj/tmp/.planted/.gitfile" "$proj/tmp/.planted/.git"
expect "guard: read refuses a .git file naming another worktree's record" 2 "git -C other than" guard read 'git -C tmp/.planted status'
PROJECT=/w

# The hook line of every agent file runs the guard of origin/main and
# refuses on any status but 0: a missing or failing guard refuses, and an
# edit on the branch has no effect until it is merged.
# hook FILE COMMAND: FILE's hook line on a Bash call of COMMAND in $hooks.
hook() {
  line=$(sed -n "s/^ *command: '\\(.*\\)'\$/\\1/p" "$1" | sed -n 1p)
  [ -n "$line" ] || { echo "no hook line in $1"; return 9; }
  printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$2" | CLAUDE_PROJECT_DIR=$hooks sh -c "$line"
}
fresh hooks
hooks=$PWD
cp "$here/agent_guard.sh" tools/agent_guard.sh
commit "chore: the guard"
git_q update-ref refs/remotes/origin/main HEAD
echo 'exit 0' > tools/agent_guard.sh
for f in "$here"/../.claude/agents/*.md; do
  a=$(basename "$f" .md)
  expect "guard: the $a hook allows a git read" 0 "^$" hook "$f" 'git log --oneline -1'
  expect "guard: the $a hook refuses with main's guard, not the branch's" 2 "git push" hook "$f" 'git push origin x'
done
expect "guard: the contributor hook refuses a direct push to the backup refs" 2 "git push is not a command of this profile" \
  hook "$here/../.claude/agents/contributor.md" 'git push -q --atomic origin HEAD:refs/backup/chore/x main:refs/backup-base/chore/x'
f="$here/../.claude/agents/checker.md"
echo 'exit 1' > tools/agent_guard.sh
commit "chore: a failing guard"
git_q update-ref refs/remotes/origin/main HEAD
expect "guard: a hook refuses when the guard fails" 2 "" hook "$f" 'ls'
git_q rm -q tools/agent_guard.sh
commit "chore: no guard"
git_q update-ref refs/remotes/origin/main HEAD
expect "guard: a hook refuses when main has no guard" 2 "" hook "$f" 'ls'
cd "$work" || exit 1

# The merge tool's hook: main's guard admits only the merger's squash at a
# head a run state records both as pushed and as gated, while origin/main
# is origin's main; and every call is refused while the configuration sets
# a risky key.
merge_call() {
  printf '{"tool_name":"mcp__github__merge_pull_request","tool_input":{"owner":"o","repo":"r","pullNumber":7,"merge_method":"%s","sha":"%s"}}' "$3" "$2" |
    CLAUDE_PROJECT_DIR=$PWD sh "$here/agent_guard.sh" "$1"
}
merge_hook() {
  line=$(sed -n "s/^ *command: '\\(.*\\)'\$/\\1/p" "$here/../.claude/agents/merger.md" | sed -n 2p)
  printf '{"tool_name":"mcp__github__merge_pull_request","tool_input":{"merge_method":"squash","sha":"%s"}}' "$1" |
    CLAUDE_PROJECT_DIR=$PWD sh -c "$line"
}
fresh mtool
git_q init -q --bare "$work/mtool.git"
git_q remote add origin "$work/mtool.git"
git_q push -q origin main 2>/dev/null
git_q fetch -q origin
echo code > tools/code.sh
commit "feat: code"
sha=$(git rev-parse HEAD)
state init mtool chore/mtool > /dev/null
state set mtool pushed "$sha" > /dev/null
expect "guard: the merge tool refuses another profile" 2 "refused for the contributor profile: the merge tool" merge_call contributor "$sha" squash
expect "guard: the merge tool refuses a merge other than a squash" 2 "a merge other than a squash" merge_call merger "$sha" merge
expect "guard: the merge tool refuses a short expected head" 2 "without the pushed head" merge_call merger "$(git rev-parse --short=12 HEAD)" squash
expect "guard: the merge tool refuses a head the merge gates did not pass" 2 "no run state records both the push and the merge gates' pass" merge_call merger "$sha" squash
sh "$here/run_state.sh" gated mtool pass > /dev/null
expect "guard: the merge tool allows the gated pushed head" 0 "^$" merge_call merger "$sha" squash
# A run state branch code planted naming the head too: the hook refuses
# while two run states name it, and the merge gates' clear resets every
# run state's gated, the planted one's included.
printf '{\n  "pushed": "%s",\n  "gated": "%s"\n}\n' "$sha" "$sha" > build/pipeline/planted.json
expect "guard: the merge tool refuses a head two run states name" 2 "which 2 run states name" merge_call merger "$sha" squash
sh "$here/run_state.sh" gated mtool clear > /dev/null
expect "run_state: gated clear resets a planted run state's gated" 0 "^none$" state get planted gated
expect "run_state: gated clear resets the change's own gated" 0 "^none$" state get mtool gated
rm -f build/pipeline/planted.json
sh "$here/run_state.sh" gated mtool pass > /dev/null
expect "guard: the merge tool allows the gated head again" 0 "^$" merge_call merger "$sha" squash
expect "guard: the merge tool refuses another head than the gated one" 2 "no run state records" merge_call merger "$(git rev-parse HEAD~1)" squash
git_q update-ref refs/remotes/origin/main HEAD
expect "guard: the merge tool refuses a rewritten origin/main" 2 "fetch, or the ref was rewritten" merge_call merger "$sha" squash
git_q fetch -q origin
expect "run_state: set refuses gated" 1 "gated is written only by its own command" state set mtool gated "$sha"
expect "guard: no profile records gated" 2 "gated" guard merger 'sh tools/run_state.sh gated c pass'
expect "guard: the contributor does not record gated" 2 "gated" guard contributor 'sh tools/run_state.sh gated c pass'
expect "guard: the merger hook matches the merge tool" 0 'matcher: "mcp__github__merge_pull_request"' grep -F 'matcher: "mcp__github__merge_pull_request"' "$here/../.claude/agents/merger.md"
cp "$here/agent_guard.sh" tools/agent_guard.sh
commit "chore: main's guard"
git_q push -q origin HEAD:main 2>/dev/null
git_q fetch -q origin
expect "guard: the merge hook refuses with main's guard" 2 "no run state records" merge_hook "$(git rev-parse HEAD)"
# A guard on main that does not name the merge tool, or none, refuses the
# merge rather than letting it run unguarded.
echo 'exit 0' > tools/agent_guard.sh
commit "chore: a guard without the merge tool"
git_q push -q origin HEAD:main 2>/dev/null
git_q fetch -q origin
expect "guard: the merge hook refuses when main's guard lacks the merge tool" 2 "^$" merge_hook "$sha"
: > tools/agent_guard.sh
commit "chore: an empty guard"
git_q push -q origin HEAD:main 2>/dev/null
git_q fetch -q origin
expect "guard: the merge hook refuses when main's guard is empty" 2 "^$" merge_hook "$sha"
git_q config core.hooksPath "$work"
expect "guard: a risky configuration key refuses every call" 2 "every call while the repository configuration sets core.hookspath" \
  env PROJECT="$PWD" sh -c 'printf "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"ls\"}}" | CLAUDE_PROJECT_DIR=$PROJECT sh "$1/agent_guard.sh" read' _ "$here"
git_q config --unset core.hooksPath
expect "guard: the guard's risky keys are the gates'" 0 "^same$" \
  sh -c '[ "$(grep "^RISKY_CONFIG=" "$1/agent_guard.sh")" = "$(grep "^RISKY_CONFIG=" "$1/rules.sh")" ] && echo same' _ "$here"
cd "$work" || exit 1

# ---------------------------------------------------------- docs_lint.sh

# docs NAME: a tree of the documents docs_lint.sh reads, all passing;
# changes into it.
docs() {
  cd "$work" || exit 1
  rm -rf "$1"
  mkdir -p "$1/docs" "$1/.claude/agents" "$1/.github" "$1/tools"
  cd "$1" || exit 1
  printf '# Rules\n\nSee `tools/x.sh`, `test/NAME.rb`, and `carat/<layer>/`.\n\n%s\n\n### Example\n\n```\n## Summary\n\nOne line.\n\n---\n\n- A bullet\n- Another\n```\n' "$TRAILER" > CLAUDE.md
  echo "# readme" > README.md
  echo "echo x" > tools/x.sh
  printf -- '---\nname: x\nmodel: %s\n---\n\nAn agent.\n' "$TIER" > .claude/agents/x.md
  printf '## Summary\n\n<!-- Guidance. -->\n\n---\n\n## Changes\n\n- \n' > .github/pull_request_template.md
}

doclint() {
  sh "$here/docs_lint.sh" .
}

docs clean
expect "docs_lint: passes a clean tree, the trailer, a tier alias in frontmatter, and placeholders" 0 "ok   paths: 1 path" doclint
docs budget
head -c 30721 /dev/zero | tr '\0' x >> CLAUDE.md
expect "docs_lint: refuses CLAUDE.md over its budget" 1 "FAIL budgets: CLAUDE.md is [0-9]+ bytes, over its budget of 30720" doclint
docs agent
head -c 8193 /dev/zero | tr '\0' x >> .claude/agents/x.md
expect "docs_lint: refuses an agent file over its budget" 1 "FAIL budgets: .claude/agents/x.md" doclint
docs queuesize
printf '# Queue\n\n1. `a` (T2, estimated small): one.\n' > docs/queue.md
head -c 17369 /dev/zero | tr '\0' x | head -c "$((17369 - $(wc -c < docs/queue.md)))" >> docs/queue.md
expect "docs_lint: passes a queue at its budget" 0 "ok   budgets: 3 file" doclint
echo x >> docs/queue.md
expect "docs_lint: refuses a queue over its budget" 1 "FAIL budgets: docs/queue.md is 17371 bytes, over its budget of 17369" doclint
docs link
echo "See $LINK." >> docs/notes.md
expect "docs_lint: refuses a URL in a document" 1 "FAIL content: docs/notes[.]md:[0-9]+: url: " doclint
docs mail
echo "Write to $MAIL." >> README.md
expect "docs_lint: refuses an email address" 1 "FAIL content: README[.]md:[0-9]+: email: " doclint
docs model
echo "Run it on $TIER." >> .claude/agents/x.md
expect "docs_lint: refuses a model name outside the frontmatter" 1 "FAIL content: [.]claude/agents/x[.]md:[0-9]+: model name: " doclint
docs wrap
printf 'A paragraph\nwrapped by hand.\n' >> .github/pull_request_template.md
expect "docs_lint: refuses a hard-wrapped template line" 1 "pull_request_template.md:[0-9]+: wrapped by hand" doclint
docs example
sed 's/^One line\.$/One line\nwrapped./' CLAUDE.md > c && mv c CLAUDE.md
expect "docs_lint: refuses a hard-wrapped line in the example body" 1 "CLAUDE.md example:[0-9]+: wrapped" doclint
docs dead
echo 'See `tools/gone.sh` and `docs/x.md:12`.' >> docs/notes.md
expect "docs_lint: refuses a dead path and names it" 1 "docs/notes.md:1:tools/gone.sh" doclint
docs line
echo 'See `tools/x.sh:3-9`.' >> docs/notes.md
expect "docs_lint: reads a path with a line suffix" 0 "ok   paths: 2 path" doclint
docs queue
printf '# Queue\n\n1. `a` (T2 user request, estimated small): one.\n2. `b` (T3 with T6 folded, estimated large): two.\n\n- An idea, not an item.\n' > docs/queue.md
expect "docs_lint: passes a queue whose items carry a tier and a size" 0 "ok   queue: 2 item" doclint
docs untiered
printf '1. `a` (T2, estimated small): one.\n2. `b` (tier T, estimated medium): two.\n' > docs/queue.md
expect "docs_lint: refuses a queue item without a tier and names it" 1 "^2:2[.] .b. [(]tier T, estimated medium[)]" doclint
docs unsized
printf '1. `a` (T2, estimated small): one.\n2. `b` (T5, large): two.\n' > docs/queue.md
expect "docs_lint: refuses a queue item without a size" 1 "FAIL queue: a queue item without .estimated small" doclint

# ----------------------------------------------------------------- new.sh

# kit NAME: a copy of the files tools/new.sh writes into, from this
# repository's working tree; changes into it.
kit() {
  cd "$work" || exit 1
  rm -rf "$1"
  mkdir -p "$1"
  (cd "$here/.." && tar -cf - carat.rb carat/adapters/editor_assembly.rb docs/codebase-map.md \
    docs/actions.md docs/compatibility.md test/runner/run_all.rb test/lint.rb \
    config/plugins.caratrc config/default.caratrc) | (cd "$1" && tar -xf -)
  cd "$1" || exit 1
}

new() {
  NEW_ROOT=. sh "$here/new.sh" "$@"
}

# has FILE TEXT: FILE holds a line equal to TEXT.
has() {
  grep -q -x -F -- "$2" "$1" && echo "has $2"
}

kit use
expect "new: use-case writes the class with its signature" 0 "wrote carat/use_cases/windows/scroll_view.rb" new use-case scroll_view 11 windows
expect "new: use-case signs call" 0 "has " has carat/use_cases/windows/scroll_view.rb "      #: (Domain::EditorState, Domain::Command) -> Outcome"
expect "new: use-case requires it in carat.rb" 0 "has " has carat.rb 'require_relative "carat/use_cases/windows/scroll_view"'
expect "new: use-case lists it in the map" 0 "has " has docs/codebase-map.md '- `carat/use_cases/windows/scroll_view.rb`: `ScrollView#call`; TODO: one line on what it does.'
expect "new: refuses a NAME that exists" 2 "scroll_view.rb exists" new use-case scroll_view 11 windows
expect "new: refuses a NAME that is not snake_case" 2 "NAME must be snake_case" new use-case ScrollView 11
expect "new: refuses an area the map lacks" 2 "has no area 99" new use-case scroll_more 99

kit action
expect "new: action writes the handler" 0 "wrote carat/use_cases/actions/scroll_handler.rb" new action scroll scroll.down
expect "new: action registers it" 0 "has " has carat/adapters/editor_assembly.rb "        UseCases::ScrollHandler.register(@actions)"
expect "new: action registers it before the plugin namespace handler" 0 "ScrollHandler" sh -c "grep -E 'ScrollHandler.register|PluginActionHandler.register' carat/adapters/editor_assembly.rb | head -1"
expect "new: action documents it" 0 "has " has docs/actions.md '| `scroll.down` | normal | TODO: the effect |'
expect "new: refuses an action already documented" 2 "already lists tab.next" new action tabs tab.next
expect "new: refuses a plugin action" 2 "declared in its manifest" new action tabs plugin.x.go

kit ex
expect "new: ex-command writes the handler" 0 "wrote carat/use_cases/ex/sort_command_handler.rb" new ex-command sort 'sor[t]'
expect "new: ex-command registers its Vim name" 0 "has " has carat/use_cases/ex/sort_command_handler.rb '        table.register(SortCommandHandler.new(spec: "sor[t]"))'
expect "new: ex-command adds its row before unknown" 0 "^unknown" sh -c "grep -A1 -F '| \`:sor[t]\` |' docs/compatibility.md | tail -1 | cut -c3-9"
expect "new: refuses a documented ex command" 2 "already lists :new" new ex-command fresh new

kit test
expect "new: test writes the program and a snapshot of its output" 0 "wrote test/domain_widget.rb and its snapshot" new test domain_widget 6
expect "new: test snapshot ends with the summary" 0 "has " has test/domain_widget.rb.expected "domain_widget: 2 passed, 0 failed"
expect "new: test requires it in sorted order" 0 "domain_undo_tree.*domain_widget.*drivers_main_loop" sh -c "grep '^require_relative' test/runner/run_all.rb | tr '\n' ' '"
expect "new: test runs it by name" 0 "has " has test/runner/run_all.rb 'when "domain_widget" then DomainWidgetTest.main'
expect "new: test lists it on the area's Tests line" 0 '`test/domain_widget.rb`\.$' grep '^Tests: ' docs/codebase-map.md
expect "new: refuses a test that exists" 2 "test/lint.rb exists" new test lint 18

kit plugin
expect "new: plugin writes the plugin" 0 "wrote carat/plugins/greeter/plugin.rb" new plugin greeter
expect "new: plugin lists it for the registry" 0 "has " has config/plugins.caratrc "plugin.greeter greeter/plugin Carat::Plugins::Greeter::Plugin"
expect "new: plugin enables it" 0 "has " has config/default.caratrc "plugin.greeter.enabled true"
expect "new: plugin documents its action" 0 "has " has docs/actions.md '| `plugin.greeter.run` | `greeter` | none | TODO: the effect |'

kit anchor
grep -v -F 'carat/use_cases/actions/action_handler"' carat.rb > c && mv c carat.rb
before=$(cat carat.rb docs/codebase-map.md | cksum)
expect "new: refuses when an anchor line is gone" 2 "has no line containing" new use-case count_words 8
expect "new: a refusal writes nothing" 0 "^same$" sh -c "[ ! -e carat/use_cases/count_words.rb ] && [ \"\$(cat carat.rb docs/codebase-map.md | cksum)\" = '$before' ] && echo same"

# ------------------------------------------------------- spec_validate.sh

# A stub openspec: archive merges the change's specs into openspec/specs and
# moves the change under archive; validate fails on a spec holding TOO LONG,
# which only the merge brings into openspec/specs.
cd "$work" || exit 1
rm -rf specv
mkdir -p specv/openspec/specs/a specv/openspec/changes/good specv/openspec/changes/long/specs/a
cat > stub_openspec <<'EOF'
echo "$*" >> "$STUB_LOG"
case "$1" in
  archive)
    [ ! -d "openspec/changes/$2/specs" ] || cp -R "openspec/changes/$2/specs/." openspec/specs/
    mkdir -p openspec/changes/archive
    mv "openspec/changes/$2" "openspec/changes/archive/x-$2" ;;
  validate) ! grep -r -q "TOO LONG" openspec/specs ;;
esac
EOF
echo short > specv/openspec/specs/a/spec.md
echo "skip_specs: true" > specv/openspec/changes/good/.openspec.yaml
echo "TOO LONG" > specv/openspec/changes/long/specs/a/spec.md
specv() {
  (cd "$work/specv" && STUB_LOG="$work/specv.log" OPENSPEC_CMD="sh $work/stub_openspec" sh "$here/spec_validate.sh")
}
: > specv.log
expect "spec_validate: refuses a change whose archive leaves an invalid spec" 1 "archiving long leaves fail strict validation" specv
expect "spec_validate: passes a change whose archive leaves valid specs" 1 "good as archived passes strict validation" specv
expect "spec_validate: archives a change without specs with --skip-specs" 0 "^archive good -y --skip-specs$" cat specv.log
expect "spec_validate: leaves the real tree as it was" 0 "^short$" sh -c "[ -d specv/openspec/changes/long ] && [ ! -d specv/openspec/changes/archive ] && cat specv/openspec/specs/a/spec.md"
rm -rf specv/openspec/changes/long
expect "spec_validate: passes when every change as archived is valid" 0 "good as archived passes strict validation" specv

# ---------------------------------------------------------------- gates.sh

fresh trailer
echo x >> README.md
commit "chore: good"
expect "gates: trailer passes" 0 "ok   trailer: 1 commit" gates trailer
echo y >> README.md
git_q add -A
git_q commit -q -m "chore: no trailer"
expect "gates: trailer refuses a commit without it" 1 "the last line is not the co-author trailer" gates trailer
fresh trailer2
echo x >> README.md
git_q add -A
git_q commit -q -m "chore: two" -m "Signed-off-by: someone" -m "$TRAILER"
expect "gates: trailer refuses another trailer" 1 "another trailer" gates trailer

fresh content
printf 'git -C x remote add origin "%s"\n' "$LINK" >> Makefile
echo "$TRAILER" >> README.md
mkdir -p .claude/agents
printf -- '---\nmodel: %s\n---\n' "$TIER" > .claude/agents/a.md
commit "chore: allowed"
expect "gates: content allows the clone address, the trailer, and a tier alias in frontmatter" 0 "ok   content" gates content
for bad in "see $LINK" "write to $MAIL" "session""_ABCDEFGHIJKLMNOPQRS" "run on $TIER" "notes: model: $TIER"; do
  fresh content2
  echo "$bad" >> README.md
  commit "chore: add a line"
  expect "gates: content refuses: $bad" 1 "FAIL content" gates content
done
fresh content3
echo x >> README.md
commit "chore: written on $TIER"
expect "gates: content refuses a model name in a commit message" 1 "commit [0-9a-f]+.*$TIER" gates content
expect "gates: backup is no longer a gate" 2 "unknown gate backup" gates backup

fresh cases
echo "echo changed" >> tools/base.sh
commit "chore: change a tool"
expect "gates: cases refuses a changed tool without a case" 1 "FAIL cases: tools/base.sh changed code" gates cases
expect "gates: static runs cases" 1 "FAIL cases: tools/base.sh" gates static
printf 'expect "x" 0 "y" true\n' > tools/tools_test.sh
commit "test: add a case"
expect "gates: cases passes a changed tool with a case" 0 "ok   cases: tools/base.sh$" gates cases
fresh cases2
printf '\n# a note\n  # indented\n' >> tools/base.sh
commit "docs: comment a tool"
expect "gates: cases passes a comment-only tool change" 0 "ok   cases: no tool changed$" gates cases
fresh cases3
echo x >> README.md
commit "chore: no tool"
expect "gates: cases leaves a branch without tools alone" 0 "ok   cases: no tool changed$" gates cases
fresh cases4
echo "echo new" > tools/new.sh
mkdir -p tools/spinel
echo "int x;" > tools/spinel/x.h
printf '# a comment only\n' > tools/tools_test.sh
commit "chore: add a tool"
expect "gates: cases reads shell scripts only and wants an expect line" 1 "FAIL cases: tools/new.sh changed code but" gates cases
# Secrets, each assembled from pieces like the forbidden text above.
KEY_LINE="-----BEGIN ""RSA PRIVATE KEY-----"
AWS_KEY="AK""IAABCDEFGHIJKLMNOP"
for kind in "key:$KEY_LINE" "aws:aws_id = $AWS_KEY" "github:GH=gh""p_abcdefghijklmnopqrstuvwxyz0123456789" \
    "slack:hook xo""xb-1234567890-abcdef" "sk:export KEY=s""k-abcdefghijklmnopqrstuvwx" \
    "password:db_pass""word = \"hunter2hunter2\"" "secret:client_sec""ret: 'abcdefghijkl'" \
    "token:\"to""ken\": \"0123456789abcdef\"" "api_key:API_""KEY => 'abcdefgh12345678'"; do
  fresh secret
  echo "${kind#*:}" >> README.md
  commit "chore: add a line"
  expect "gates: content refuses a secret: ${kind%%:*}" 1 "FAIL content: README[.]md:[0-9]+: secret: \[not shown\]" gates content
done
expect "gates: content does not print the secret" 0 "^0$" sh -c 'BASE=main STAGES=lint sh "$1/gates.sh" content | grep -c -F "$2"; true' _ "$here" "abcdefgh12345678"
fresh secret2
printf '%s\n' 'token = ENV.fetch("CARAT_TOKEN")' 'password = read_password(prompt)' 'export SECRET=$secret_value' >> README.md
commit "chore: read a token"
expect "gates: content allows a token read from a variable" 0 "ok   content" gates content
fresh secret3
echo "aws_id = $AWS_KEY" >> README.md
commit "chore: add a key"
git_q show HEAD~1:README.md > README.md
commit "chore: remove the key"
expect "gates: content refuses a secret a later commit removed" 1 "FAIL content: README[.]md:[0-9]+: secret: \[not shown\]" gates content
fresh dotenv
echo "X=1" > .env
commit "chore: add an env file"
expect "gates: content refuses an added .env file" 1 "FAIL content: an added .env file" gates content
fresh dotenv2
mkdir -p config
echo "X=1" > config/.env.local
commit "chore: add an env file"
expect "gates: content refuses an added .env.local in a directory" 1 "config/\.env\.local" gates content
expect "repository: .gitignore ignores .env files" 0 "config/\.env\.local" sh -c 'cd "$1/.." && git check-ignore .env config/.env.local' _ "$here"

fresh dotenv3
dir=$(printf 'caf\303\251')
mkdir "$dir"
echo "X=1" > "$dir/.env"
commit "chore: add an env file"
expect "gates: content refuses an added .env under a path git quotes" 1 "FAIL content: an added .env file" gates content
fresh plusline
echo "++ see $LINK" >> README.md
commit "chore: add a line"
expect "gates: content scans an added line starting with ++" 1 "FAIL content: README[.]md:[0-9]+: url: " gates content
fresh binary
printf 'see %s\000\n' "$LINK" > data.bin
commit "chore: add a binary file"
expect "gates: content notes a binary file and does not read it" 0 "note: data[.]bin: a binary file, not scanned" gates content

# ------------------------------------------------------------ scan_text.sh
# The one scanner: each URL form, an address, a session id, the two
# exceptions, a split URL, a quoted string, a ++ line, a binary file, and
# a secret masked. Each host is split before its dot, like the text above.

scantext() {
  printf '%s\n' "$1" | sh "$here/scan_text.sh"
}

# onediff PATH LINE: a diff adding LINE as line 2 of PATH, scanned.
onediff() {
  printf 'diff --git a/%s b/%s\n--- a/%s\n+++ b/%s\n@@ -1,0 +2 @@\n+%s\n' "$1" "$1" "$1" "$1" "$2" |
    sh "$here/scan_text.sh" --diff
}

HOST="example"".org"
for form in "scheme:see $LINK" "www host:go to w""ww.$HOST" "bare host and path:the $HOST/page" \
    "code host:git""hub"".com/owner/repo" "session link:claude"".ai/code/x"; do
  expect "scan_text: refuses a URL: ${form%%:*}" 1 "^stdin:1: url: " scantext "${form#*:}"
done
expect "scan_text: prints the URL, not the line" 1 "^stdin:1: url: https:[/][/]example[.]org/page$" scantext "the page ($LINK) is gone"
expect "scan_text: refuses an email address" 1 "^stdin:1: email: someone@example[.]org$" scantext "write to $MAIL"
expect "scan_text: refuses a session id" 1 "^stdin:1: session id: session_[A-Z]+$" scantext "id session""_ABCDEFGHIJKLMNOPQRS"
expect "scan_text: allows the co-author trailer" 0 "^$" scantext "$TRAILER"
expect "scan_text: refuses the trailer with another address" 1 "^stdin:1: email: someone@" scantext "Co-Authored-By: Claude <$MAIL>"
expect "scan_text: allows the clone address on the Makefile's remote add line" 0 "^$" onediff Makefile "	git -C x remote add origin \"$LINK\""
expect "scan_text: refuses the clone line outside the Makefile" 1 "^README[.]md:2: url: " onediff README.md "	git -C x remote add origin \"$LINK\""
expect "scan_text: refuses a URL split where a line wraps" 1 "^stdin:1: url: example[.]org/page$" \
  sh -c 'printf "see example.\norg/page\n" | sh "$1/scan_text.sh"' _ "$here"
expect "scan_text: leaves a sentence ending a line alone" 0 "^$" sh -c 'printf "The end.\nNext line here.\n" | sh "$1/scan_text.sh"' _ "$here"
expect "scan_text: refuses a URL in a quoted string" 1 "^stdin:1: url: https:[/][/]example[.]org/page$" scantext "url = \"$LINK\""
expect "scan_text: scans an added line starting with ++" 1 "^README[.]md:2: url: " onediff README.md "++ see $LINK"
printf 'see %s\000\n' "$LINK" > "$work/data.bin"
expect "scan_text: notes a binary file and does not read it" 0 "^note: .*data[.]bin: a binary file, not scanned$" sh "$here/scan_text.sh" "$work/data.bin"
expect "scan_text: notes a binary file in a diff" 0 "^note: data[.]bin: a binary file, not scanned$" \
  sh -c 'printf "diff --git a/data.bin b/data.bin\nBinary files a/data.bin and b/data.bin differ\n" | sh "$1/scan_text.sh" --diff' _ "$here"
TOKEN_URL="$SCHEME//user:gh""p_abcdefghijklmnopqrstuvwxyz0123456789@$HOST/x"
expect "scan_text: masks a URL's user and password" 1 "^stdin:1: url: https:[/][/]\[hidden\]@example[.]org/x$" scantext "see $TOKEN_URL"
expect "scan_text: never prints a token inside a URL" 0 "^0$" sh -c 'printf "see %s\n" "$2" | sh "$1/scan_text.sh" | grep -c abcdefghijklmnop; true' _ "$here" "$TOKEN_URL"
expect "scan_text: names the model name and the secret by label" 1 "^stdin:2: secret: \[not shown\]$" scantext "run on $TIER
aws_id = $AWS_KEY"
expect "scan_text: refuses an unknown option" 2 "Usage: sh tools/scan_text.sh" sh "$here/scan_text.sh" --nope

# ------------------------------------------------- make toolchain, pr_scan.sh
# make toolchain installs no commit hooks: in a clone, with a local stand-in
# for the Spinel sources, it leaves core.hooksPath unset, and the Makefile
# has no hooks target and sets core.hooksPath nowhere.
cd "$work" || exit 1
rm -rf fakespinel
git_q init -q fakespinel
mkdir -p fakespinel/lib
: > fakespinel/lib/.keep
printf 'all:\n\t@true\ndeps:\n\t@true\ninstall:\n\t@true\n' > fakespinel/Makefile
git_q -C fakespinel add -A
git_q -C fakespinel commit -q -m "chore: a stand-in" -m "$TRAILER"
fresh tooled
mkdir -p tools/spinel
: > tools/spinel/spinel_rt_responds_generated.h
commit "chore: the vendored header"
git_q clone -q "$work/tooled" "$work/tooled-clone"
git_q -C "$work/tooled-clone" checkout -q chore/tooled
git_q init -q "$work/tooled-src"
git_q -C "$work/tooled-src" remote add origin "$work/fakespinel"
expect "toolchain: a clone after make toolchain has no core.hooksPath" 0 "^unset$" \
  sh -c 'cd "$2" && make -s -f "$1/../Makefile" toolchain SPINEL_SRC="$3" SPINEL_REF=main PREFIX="$4" >/dev/null 2>&1 &&
    { git config --get-all core.hooksPath || echo unset; }' _ "$here" "$work/tooled-clone" "$work/tooled-src" "$work/tooled-prefix"
expect "toolchain: the Makefile has no hooks target and sets no core.hooksPath" 0 "^none$" \
  sh -c '! grep -q -E "^hooks:|hooksPath" "$1/../Makefile" && ! [ -e "$1/../.githooks" ] && echo none' _ "$here"

# The pull request scan of .github/workflows/scan.yml, with a sample title,
# body, and branch, and no network.
prscan() {
  BASE_SHA=$(git rev-parse main) HEAD_SHA=$(git rev-parse HEAD) PR_TITLE=$1 PR_BODY=$2 sh "$here/pr_scan.sh"
}
fresh prscan
echo x >> README.md
commit "chore: a clean line"
expect "pr_scan: passes a clean title, body, commit, and diff" 0 "^ok   scan: the title, the body, 1 commit message" prscan "chore: clean" "## Summary"
FOOTER="Generated by a tool, claude"".ai/code/session""_ABCDEFGHIJKLMNOPQRS"
expect "pr_scan: refuses a footer with a session link in the body" 1 "^body:3: url: claude[.]ai/code/session_" prscan "chore: clean" "$(printf '## Summary\r\n\r\n%s\r\n' "$FOOTER")"
expect "pr_scan: refuses a URL in the title" 1 "^title:1: url: " prscan "chore: see $LINK" "## Summary"
expect "pr_scan: never runs the title's or body's text" 0 "^absent$" \
  sh -c 'PR_TITLE="\$(touch injected)" PR_BODY="\`touch injected\`" BASE_SHA=$(git rev-parse main) HEAD_SHA=$(git rev-parse HEAD) sh "$1/pr_scan.sh" >/dev/null; [ -e injected ] || echo absent' _ "$here"
expect "pr_scan: refuses a base that is not a commit" 2 "BASE_SHA and HEAD_SHA must name commits" env BASE_SHA=--all HEAD_SHA=x sh "$here/pr_scan.sh"
fresh prscan2
echo "write to $MAIL" >> README.md
commit "chore: see $LINK"
expect "pr_scan: refuses a URL in a commit message" 1 "^commit [0-9a-f]+:1: url: " prscan "chore: clean" "## Summary"
expect "pr_scan: refuses an address in an added line" 1 "^README[.]md:[0-9]+: email: " prscan "chore: clean" "## Summary"
expect "repository: the scan workflow runs on every pull request edit with read-only contents and no interpolated run line" 0 "^good$" \
  sh -c 'f="$1/../.github/workflows/scan.yml"
    grep -q -x "    types: \[opened, edited, reopened, synchronize\]" "$f" && grep -q -x "  contents: read" "$f" &&
    ! grep -q -E "^ *pull_request_target:|: write" "$f" && ! grep -q -E "^ *run:.*[$][{][{]" "$f" &&
    grep -q -x "        run: sh ../base/tools/pr_scan.sh" "$f" && echo good' _ "$here"
# The scan runs the base commit's scanner, checked out to its own path
# without credentials, over the head's repository, so a pull request that
# makes its own scanner pass everything is still read by the base's.
fresh prscan3
printf '#!/bin/sh\ncat >/dev/null\nexit 0\n' > tools/scan_text.sh
cp tools/scan_text.sh tools/pr_scan.sh
echo "see $LINK" >> README.md
commit "chore: a scanner that passes everything"
expect "pr_scan: the base's scanner reads a head that replaces the scanner" 1 "^README[.]md:[0-9]+: url: " prscan "chore: clean" "## Summary"
expect "repository: the scan workflow checks out the base's scanner to its own path, without credentials, and runs it in the head" 0 "^good$" \
  sh -c 'f="$1/../.github/workflows/scan.yml"
    awk "/^      - name:/ { step = \$0 } /ref: [$][{][{] github.event.pull_request.base.sha [}][}]\$/ { print step }" "$f" | grep -q "the base" &&
    awk "/^      - name:/ { n++ } n == 1" "$f" | grep -q -x "          path: base" &&
    awk "/^      - name:/ { n++ } n == 1" "$f" | grep -q -x "          persist-credentials: false" &&
    awk "/^      - name:/ { n++ } n == 2" "$f" | grep -q -x "          path: head" &&
    awk "/^      - name:/ { n++ } n == 3" "$f" | grep -q -x "        working-directory: head" && echo good' _ "$here"

fresh docs
echo new > tools/new.sh
commit "chore: tool"
expect "gates: docs refuses a new tool without the map" 1 "docs/codebase-map.md did not change" gates docs
echo "- tools/new.sh" >> docs/codebase-map.md
commit "docs: map"
expect "gates: docs passes with the map" 0 "ok   docs" gates docs
mkdir -p .claude/agents
echo agent > .claude/agents/new.md
commit "chore: agent"
expect "gates: docs refuses a new agent without CLAUDE.md" 1 "CLAUDE.md did not change" gates docs
expect "gates: docs refuses a process change without README.md" 1 "README.md did not" gates docs
printf '## lint: check\n' >> Makefile
echo agents >> CLAUDE.md
echo agents >> README.md
commit "docs: rules"
expect "gates: docs passes with CLAUDE.md and README.md" 0 "ok   docs" gates docs

# A spec change touches README.md and docs/architecture.md, a process
# change CLAUDE.md, or the proposal says why each stays.
spec_file() {
  mkdir -p "$1"
  printf '## ADDED Requirements\n\n### Requirement: Ghosts\n\n#### Scenario: Lint refuses a ghost\n\n#### Scenario: Tab completes a word\n\n## REMOVED Requirements\n\n### Requirement: Old\n\n#### Scenario: An old thing\n' > "$1/spec.md"
}
fresh docspec
spec_file openspec/changes/c/specs/a
echo "# Proposal" > openspec/changes/c/proposal.md
commit "feat: spec"
expect "gates: docs refuses a spec change without README.md" 1 "a spec changed, but README.md did not" gates docs
expect "gates: docs refuses a spec change without docs/architecture.md" 1 "a spec changed, but docs/architecture.md did not" gates docs
printf -- '- README.md: unchanged,\n' >> openspec/changes/c/proposal.md
commit "docs: no reason"
expect "gates: docs refuses an unchanged line without a reason" 1 "a spec changed, but README.md did not" gates docs
printf -- '- README.md: unchanged, no key changes\n- `docs/architecture.md`: unchanged, no layer changes\n' >> openspec/changes/c/proposal.md
commit "docs: say why"
expect "gates: docs passes a spec change whose proposal says why each doc stays" 0 "ok   docs" gates docs
fresh docspec2
spec_file openspec/changes/archive/2026-01-01-c/specs/a
echo x >> README.md
echo x > docs/architecture.md
commit "feat: archived spec with docs"
expect "gates: docs passes an archived spec change with README.md and docs/architecture.md" 0 "ok   docs" gates docs
fresh docproc
echo "# a note" >> Makefile
commit "build: note"
expect "gates: docs refuses a process file change without CLAUDE.md" 1 "a process file changed, but CLAUDE.md did not" gates docs
mkdir -p openspec/changes/c
printf '# Proposal\n\n- CLAUDE.md: unchanged, a comment only\n' > openspec/changes/c/proposal.md
commit "docs: say why"
expect "gates: docs passes a process file change whose proposal says why CLAUDE.md stays" 0 "ok   docs" gates docs

fresh scenarios
spec_file openspec/changes/c/specs/a
echo 't.assert_equal(1, 1, "lint refuses a ghost")' > test/a.rb
commit "feat: spec"
expect "gates: scenarios refuses a scenario no test names and names it" 1 'scenario "Tab completes a word" is named by no test' gates scenarios
echo "# Scenario: Tab completes a word" >> tools/tools_test.sh
commit "test: name it"
expect "gates: scenarios passes when tests name each added scenario, a removed one left out" 0 "ok   scenarios: 2 scenarios named by tests" gates scenarios
fresh scenarios2
spec_file openspec/changes/archive/2026-01-01-c/specs/a
commit "feat: archived spec"
expect "gates: scenarios reads an archived delta spec" 1 'scenario "Lint refuses a ghost" is named by no test' gates scenarios

fresh snapshots
echo out > test/gone.rb.expected
commit "test: snapshot"
expect "gates: snapshots refuses a snapshot without its test" 1 "has no test test/gone.rb" gates snapshots
echo "puts 1" > test/gone.rb
commit "test: test"
expect "gates: snapshots refuses without the runner" 1 "build/test/run_all is missing" gates snapshots

fresh security
state init security chore/security > /dev/null
expect "gates: security refuses when no review is recorded" 1 "no security review is recorded" gates security
state review security security blocked "one high" > /dev/null
expect "gates: security refuses a blocked review" 1 "did not pass" gates security
state review security security pass "no finding" > /dev/null
expect "gates: security passes at HEAD" 0 "ok   security: pass" gates security
reviewed=$(git rev-parse --short=12 HEAD)
expect "gates: records passes the workflow's results" 0 "ok   records: the run state holds the workflow's 1 record" \
  env RECORDS="security:pass:$reviewed" BASE=main sh "$here/gates.sh" records
expect "gates: records compares the full commit" 0 "ok   records" \
  env RECORDS="security:pass:$(git rev-parse HEAD)" BASE=main sh "$here/gates.sh" records
expect "gates: records refuses another result" 1 "review.security is \"pass $reviewed no finding\", but the workflow received blocked" \
  env RECORDS="security:blocked:$reviewed" BASE=main sh "$here/gates.sh" records
expect "gates: records refuses a review the run state lacks" 1 "review.quality is \"\"" \
  env RECORDS="security:pass:$reviewed quality:pass:$reviewed" BASE=main sh "$here/gates.sh" records
expect "gates: records refuses a malformed record" 1 "not a KIND:RESULT:COMMIT record: security:pass:[*]" \
  env RECORDS="security:pass:*" BASE=main sh "$here/gates.sh" records
expect "gates: records refuses when no records are given" 1 "FAIL records: no workflow records given" gates records
expect "gates: records refuses without a security record" 1 "no security record given" \
  env RECORDS="quality:pass:$reviewed" BASE=main sh "$here/gates.sh" records
expect "gates: records refuses a check record the run state lacks" 1 "phase.check is \"\", but the workflow received pass" \
  env RECORDS="security:pass:$reviewed check:pass:$reviewed" BASE=main sh "$here/gates.sh" records
state phase security check > /dev/null
expect "gates: records compares the check record" 0 "ok   records: the run state holds the workflow's 2 record" \
  env RECORDS="security:pass:$reviewed check:pass:$reviewed" BASE=main sh "$here/gates.sh" records
expect "gates: records refuses a check record other than the workflow's" 1 "phase.check is \"pass $reviewed\", but the workflow received blocked" \
  env RECORDS="security:pass:$reviewed check:blocked:$reviewed" BASE=main sh "$here/gates.sh" records
mkdir -p openspec/changes/archive/x
echo archived > openspec/changes/archive/x/tasks.md
commit "chore: archive"
expect "gates: security passes after an archive only" 0 "ok   security: pass" gates security
echo "1. next" > docs/queue.md
echo change > docs/metrics.tsv
commit "docs: record the queue and the metrics"
expect "gates: security passes after the planning records only" 0 "ok   security: pass" gates security
mkdir -p openspec/moved
git_q mv tools/base.sh openspec/moved/base.sh
commit "chore: move a tool"
expect "gates: security refuses a code file moved into openspec" 1 "code changed since" gates security
git_q mv openspec/moved/base.sh tools/base.sh
commit "chore: move the tool back"
echo code > tools/fix.sh
commit "fix: code"
expect "gates: security refuses after code changed" 1 "code changed since" gates security
expect "gates: stages refuses a check before a code change" 1 "the check passed at [0-9a-f]+, but code changed since" gates stages
expect "gates: stages refuses a stage that has not run" 1 "lint has not run" gates stages
state set security pushes 3 > /dev/null
expect "gates: pushes refuses more than one push per CI fix" 1 "3 pushes for 0 CI fix" gates pushes

# The merge needs the check's and the three reviews' pass records at the
# pushed head.
fresh passed
state init passed chore/passed > /dev/null
echo code > tools/code.sh
commit "feat: code"
expect "gates: passed refuses a merge given no records" 1 "FAIL passed: check has no pass record" gates passed
expect "gates: passed refuses a merge without a recorded push" 1 "FAIL passed: no push is recorded for passed" gates passed
expect "gates: merge refuses a merge given no records" 1 "FAIL passed: quality has no pass record" gates merge body.md
state set passed pushed "$(git rev-parse --short=12 HEAD)" > /dev/null
state phase passed check > /dev/null
state review passed quality pass "blocking=0" > /dev/null
state review passed security pass "high=0" > /dev/null
state review passed bench blocked "blocking=1" > /dev/null
expect "gates: passed refuses a blocked review" 1 "FAIL passed: bench has no pass record: blocked" gates passed
state review passed bench pass "blocking=0" > /dev/null
expect "gates: passed passes the four records at the pushed head" 0 "ok   passed: check, quality, security, and bench passed at the pushed head" gates passed
mkdir -p openspec/changes/archive/x
echo archived > openspec/changes/archive/x/tasks.md
echo "1. next" > docs/queue.md
commit "docs: archive and record the queue"
expect "gates: passed refuses when HEAD is not the pushed head" 1 "is not the pushed head" gates passed
state set passed pushed "$(git rev-parse --short=12 HEAD)" > /dev/null
expect "gates: passed passes after the planning records" 0 "ok   passed" gates passed
echo more >> tools/code.sh
commit "fix: more code"
state set passed pushed "$(git rev-parse --short=12 HEAD)" > /dev/null
expect "gates: passed refuses a record before a code change" 1 "FAIL passed: check passed at [0-9a-f]+, but code changed since" gates passed
state phase passed check > /dev/null
state review passed quality pass "blocking=0" > /dev/null
state review passed security pass "high=0" > /dev/null
state review passed bench pass "blocking=0" > /dev/null
echo dirty >> tools/code.sh
expect "gates: passed refuses a dirty tree" 1 "FAIL passed: tracked files differ from HEAD:  M tools/code.sh" gates passed
git_q checkout -q -- tools/code.sh
expect "gates: passed passes a clean tree" 0 "ok   passed" gates passed

# The stages gate counts a stage only at the check the workflow recorded,
# and the merge runs a copy of main's gates against the branch.
fresh staged
state init staged chore/staged > /dev/null
expect "gates: stages refuses without a check record" 1 "no check is recorded for staged" gates stages
state stage staged lint true > /dev/null
echo code > tools/code.sh
commit "feat: code"
state phase staged check > /dev/null
expect "gates: stages refuses a stage at a commit the check record does not name" 1 "FAIL stages: lint passed at [0-9a-f]+, not at the recorded check" gates stages
state stage staged lint true > /dev/null
expect "gates: stages passes every stage at the recorded check" 0 "ok   stages: every stage passed at the recorded check" gates stages
mkdir -p "$work/copy/tools"
cp "$here/gates.sh" "$here/rules.sh" "$here/run_state.sh" "$work/copy/tools/"
printf 'CHECK_STAGES := lint other\n' > "$work/copy/Makefile"
expect "gates: stages reads the stage list beside the script" 1 "FAIL stages: other has not run" \
  env BASE=main CHANGE=staged sh "$work/copy/tools/gates.sh" stages
printf 'CHECK_STAGES := lint\n' > "$work/copy/Makefile"
state set staged pushed "$(git rev-parse --short=12 HEAD)" > /dev/null
state review staged quality pass "blocking=0" > /dev/null
state review staged security pass "high=0" > /dev/null
state review staged bench pass "blocking=0" > /dev/null
at=$(git rev-parse --short=12 HEAD)
printf '## Summary\n\nDoes a thing.\n\n---\n\n## Changes\n\n- Add a thing\n\n---\n\n## Testing\n\n- Run the security review, no finding\n\n---\n\n## Notes\n\nNone\n' > body.md
expect "gates: merge runs from a copy of main against the branch" 0 "ok   records" \
  env BASE=main CHANGE=staged RECORDS="security:pass:$at quality:pass:$at bench:pass:$at check:pass:$at" sh "$work/copy/tools/gates.sh" merge body.md
expect "gates: merge records the head it passed at as gated" 0 "^$(git rev-parse HEAD)$" state get staged gated
echo more >> tools/code.sh
commit "fix: more code"
state set staged pushed "$(git rev-parse --short=12 HEAD)" > /dev/null
expect "gates: merge refuses a head other than the one the security review passed" 1 "FAIL security: the review passed at $at, but code changed since" \
  env BASE=main CHANGE=staged RECORDS="security:pass:$at quality:pass:$at bench:pass:$at check:pass:$at" sh "$work/copy/tools/gates.sh" merge body.md
expect "gates: a failed merge leaves gated cleared" 0 "^none$" state get staged gated

# The origin gate: no configuration key that runs a command or redirects
# origin, and an origin/ base equal to origin's branch, from a hosted origin
# with the default fetch refspec.
fresh origined
expect "gates: origin passes a clean configuration with a local base" 0 "ok   origin: the configuration sets no risky key and no hook$" gates origin
printf '#!/bin/sh\ntouch planted\n' > .git/hooks/post-checkout
expect "gates: origin refuses a hook in the hooks directory" 1 "FAIL origin: the hooks directory holds post-checkout" gates origin
expect "guard: a planted hook refuses every call" 2 "every call while the hooks directory holds post-checkout" \
  env PROJECT="$PWD" sh -c 'printf "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"ls\"}}" | CLAUDE_PROJECT_DIR=$PROJECT sh "$1/agent_guard.sh" read' _ "$here"
rm .git/hooks/post-checkout
git_q config core.fsmonitor "touch planted"
expect "gates: origin refuses a key that runs a command" 1 "FAIL origin: the repository configuration sets core.fsmonitor" gates origin
expect "gates: pre-push runs the origin gate" 1 "FAIL origin: the repository configuration sets core.fsmonitor" gates pre-push
git_q config --unset core.fsmonitor
# Any core.hooksPath is refused, the absolute path of a tracked .githooks
# included, so git runs no hook that a checkout of a branch can write.
mkdir -p .githooks
printf '#!/bin/sh\ntouch planted\n' > .githooks/post-checkout
git_q config core.hooksPath "$PWD/.githooks"
expect "gates: origin refuses any core.hooksPath, a tracked .githooks included" 1 "FAIL origin: the repository configuration sets core.hookspath" gates origin
expect "guard: any core.hooksPath, a tracked .githooks included, refuses every call" 2 "every call while the repository configuration sets core.hookspath" \
  env PROJECT="$PWD" sh -c 'printf "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"ls\"}}" | CLAUDE_PROJECT_DIR=$PROJECT sh "$1/agent_guard.sh" read' _ "$here"
git_q config core.hooksPath .githooks
expect "gates: origin refuses the relative core.hooksPath .githooks" 1 "FAIL origin: the repository configuration sets core.hookspath" gates origin
expect "guard: the relative core.hooksPath .githooks refuses every call" 2 "every call while the repository configuration sets core.hookspath" \
  env PROJECT="$PWD" sh -c 'printf "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"ls\"}}" | CLAUDE_PROJECT_DIR=$PROJECT sh "$1/agent_guard.sh" read' _ "$here"
rm -rf .githooks
git_q config --unset core.hooksPath
git_q config "url.$work/fake.git.insteadOf" "$work/origined.git"
expect "gates: origin refuses a rewritten origin address" 1 "FAIL origin: the repository configuration sets url[.].*[.]insteadof" gates origin
git_q config --remove-section "url.$work/fake.git"
git_q init -q --bare "$work/origined.git"
git_q remote add origin "$work/origined.git"
git_q push -q origin main 2>/dev/null
git_q fetch -q origin
echo more >> README.md
commit "chore: more"
git_q update-ref refs/remotes/origin/main HEAD
expect "gates: origin refuses an origin/main other than origin's main" 1 "FAIL origin: origin/main is [0-9a-f]{40}, but origin's main is [0-9a-f]{40}: fetch, or the ref was rewritten" \
  env BASE=origin/main sh "$here/gates.sh" origin
git_q fetch -q origin
expect "gates: a fetch restores origin/main" 0 "^0$" sh -c 'BASE=origin/main sh "$1/gates.sh" origin | grep -c rewritten; true' _ "$here"
# A global insteadOf, which branch code can write to ~/.gitconfig, does
# not let a fake origin answer for the real one: the gates read no global
# configuration.
git_q init -q --bare "$work/fake.git"
git_q push -q "$work/fake.git" HEAD:refs/heads/main 2>/dev/null
printf '[url "%s"]\n\tinsteadOf = %s\n' "$work/fake.git" "$work/origined.git" > "$work/global.gitconfig"
git_q update-ref refs/remotes/origin/main HEAD
expect "gates: origin ignores a global insteadOf" 1 "FAIL origin: origin/main is [0-9a-f]{40}, but origin's main is [0-9a-f]{40}: fetch, or the ref was rewritten" \
  env GIT_CONFIG_GLOBAL="$work/global.gitconfig" BASE=origin/main sh "$here/gates.sh" origin
git_q fetch -q origin
expect "gates: origin refuses a local origin repository" 1 "FAIL origin: origin is \".*origined[.]git\", a local repository" \
  env BASE=origin/main sh "$here/gates.sh" origin
git_q config remote.origin.fetch "+refs/heads/x:refs/remotes/origin/main"
expect "gates: origin refuses a fetch refspec other than the default" 1 "FAIL origin: remote[.]origin[.]fetch is .*not the default refspec" \
  env BASE=origin/main sh "$here/gates.sh" origin

fresh body
cat > body.md <<'EOF'
## Summary

Does a thing for a reason.

---

## Changes

- Add a thing

---

## Testing

- Run the security review on the committed diff, no finding

---

## Notes

None
EOF
expect "gates: pr-body passes the template's shape" 0 "ok   pr-body" gates pr-body body.md
ln -s body.md linked.md
expect "gates: pr-body refuses a linked body file" 1 "the body file linked.md is a link" gates pr-body linked.md
sed 's/^None$/None/' body.md > footer.md
printf '\nGenerated with a tool\n%s\n' "$LINK" >> footer.md
expect "gates: pr-body refuses a footer" 1 "a footer or attribution line" gates pr-body footer.md
sed 's/^None$/None/' body.md > session.md
printf '\nClaude-Session: 0123abcd\n' >> session.md
expect "gates: pr-body refuses a session line" 1 "a session line" gates pr-body session.md
sed 's/^None$/None <!-- left -->/' body.md > comment.md
expect "gates: pr-body refuses a template comment" 1 "a comment or angle bracket" gates pr-body comment.md
sed 's/security review/review/' body.md > nosec.md
expect "gates: pr-body refuses a body without the security review" 1 "does not report the security review" gates pr-body nosec.md
sed 's/^## Notes$/## Remarks/' body.md > shape.md
expect "gates: pr-body refuses other sections" 1 "not exactly Summary" gates pr-body shape.md

# attribution: Claude Code's attribution in .claude/settings.json.
settings() {
  mkdir -p .claude
  printf '{\n  "attribution": {\n    "commit": "%s",\n    "pr": "%s",\n    "sessionUrl": %s\n  }\n}\n' "$1" "$2" "$3" > .claude/settings.json
}
fresh attribution
settings "$TRAILER" "" false
expect "gates: attribution passes the trailer, no pull request text, and no session link" 0 "ok   attribution" gates attribution
settings "$TRAILER" "" true
expect "gates: attribution refuses a session link" 1 'lacks the line "sessionUrl": false' gates attribution
settings "Co-Authored-By: Claude Code <noreply@anthropic.com>" "" false
expect "gates: attribution refuses another commit trailer" 1 'lacks the line "commit"' gates attribution
settings "$TRAILER" "Generated with a tool" false
expect "gates: attribution refuses pull request text" 1 'lacks the line "pr": ""' gates attribution
rm -f .claude/settings.json
expect "gates: attribution refuses a missing settings file" 1 "no .claude/settings.json" gates attribution

# ------------------------------------------------------------ call caps
# The workflow's tool-call caps (CALL_CAPS at a medium estimate, scaled by
# CALL_SCALE; FIXED_CAPS) and the hard ceiling of each agent file, its
# maxTurns: the largest cap of its starts at a large estimate plus a
# return margin, so a start that makes its capped calls one per turn still
# has turns to commit, back up, and return the schema; the merger's is its
# first-green cap, which holds two waits, 2 for each of the other five of
# its 30 minutes, and the margin.
margin=5
wf="$here/../.claude/workflows/deliver-change.js"
agents="$here/../.claude/agents"
table() {
  sed -n "s/^const $1 = { \\(.*\\) }\$/\\1/p" "$wf" | tr -d " '" | tr ',' '\n'
}
caps=$(table CALL_CAPS)
fixed=$(table FIXED_CAPS)
scale=$(table CALL_SCALE)
cap_of() {
  printf '%s\n' "$caps" "$fixed" | sed -n "s/^$1://p"
}
missing=""
for kind in planner scout implement fix package push checker quality security bench close resume areas record merger; do
  cap_of "$kind" | grep -q -E '^[0-9]+$' || missing="$missing $kind"
done
for kind in $(grep -o -E "(capLine|callCap)\\('[a-z]+'\\)" "$wf" | sed "s/.*('\\(.*\\)')/\\1/" | sort -u); do
  cap_of "$kind" | grep -q -E '^[0-9]+$' || missing="$missing $kind"
done
expect "caps: every kind of start has a cap" 0 "^none$" echo "${missing:-none}"
expect "caps: a larger estimate never lowers a cap" 0 "^rising$" sh -c 'printf "%s\n" "$1" | awk -F: "{ s[\$1] = \$2 } END { print (s[\"small\"] < s[\"medium\"] && s[\"medium\"] == 1 && s[\"medium\"] < s[\"large\"]) ? \"rising\" : \"not rising\" }"' _ "$scale"
large=$(printf '%s\n' "$scale" | sed -n 's/^large:\([0-9.]*\)$/\1/p')
# turns AGENT KIND...: the largest cap of KIND... at a large estimate,
# plus the margin.
turns() {
  agent=$1
  shift
  for kind in "$@"; do cap_of "$kind"; done | awk -v l="$large" -v r="$margin" '{ v = $1 * l; if (v > int(v)) v = int(v) + 1; if (v > m) m = v } END { print m + r }'
}
for pair in benchmark:bench checker:checker contributor:implement,fix,package,push,body planner:planner quality-reviewer:quality retrospective:close scout:scout security-reviewer:security; do
  agent=${pair%%:*}
  want=$(turns "$agent" $(echo "${pair#*:}" | tr ',' ' '))
  expect "caps: the $agent file's maxTurns is its large cap and the margin" 0 "^maxTurns: $want$" grep -E '^maxTurns: ' "$agents/$agent.md"
done
expect "caps: the merger file's maxTurns is its ceiling" 0 "^maxTurns: $(($(cap_of merger) + 10 + margin))$" grep -E '^maxTurns: ' "$agents/merger.md"
# The periodic review's starts: a fixed cap stated in every start, which
# leaves the margin under both reviewers' maxTurns, and the record start's
# the record cap; a security review without a result is retried once and
# recorded as not run.
pwf="$here/../.claude/workflows/periodic-review.js"
pcap=$(sed -n 's/^const PERIODIC_CAP = \([0-9]*\)$/\1/p' "$pwf")
for agent in quality-reviewer security-reviewer; do
  expect "caps: the periodic cap leaves the margin under the $agent file's maxTurns" 0 "^within$" \
    sh -c '[ -n "$1" ] && [ $(($1 + $2)) -le "$(sed -n "s/^maxTurns: //p" "$3")" ] && echo within' _ "$pcap" "$margin" "$agents/$agent.md"
done
expect "caps: the periodic record start has the record cap" 0 "^const RECORD_CAP = $(cap_of record)$" grep '^const RECORD_CAP = ' "$pwf"
unstated=$(grep -n -A1 'agent(' "$pwf" | awk '/agent\(/ { if (line != "" && !ok) bad = bad " " line; line = $0; ok = ($0 ~ /agent\(task|capLine\(/); next } { if ($0 ~ /capLine\(/) ok = 1 } END { if (line != "" && !ok) bad = bad " " line; print bad == "" ? "none" : bad }')
expect "caps: every periodic start states its cap" 0 "^none$" echo "$unstated"
expect "caps: the periodic task line states the periodic cap" 0 "capLine[(]PERIODIC_CAP[)]" grep '^const task = ' "$pwf"
expect "periodic: a security review without a commit head is retried" 0 "s[.]ran && isCommit[(]s[.]head[)]" grep 'if (s && s.ran' "$pwf"
expect "periodic: a security review without a result is recorded as not run" 0 "^[}] else record[(]'periodic-security', 'not-run'" grep "record('periodic-security', 'not-run'" "$pwf"
expect "periodic: a review with areas not reviewed is recorded as partial" 0 "missed[.]length [?] 'partial'" grep '^const result = ' "$pwf"
# A first green: the merger file's calls of one each, the branch deletion
# among them, and two waits of two calls stay within its cap of at most 12.
calls=$(grep -o '(one call)' "$agents/merger.md" | wc -l | tr -d ' ')
expect "caps: the merger's first green fits its cap" 0 "^within$" sh -c '[ "$1" -le 12 ] && [ "$2" -ge 7 ] && [ $(($2 + 4)) -le "$1" ] && echo within' _ "$(cap_of merger)" "$calls"
expect "caps: the merger counts the branch deletion" 0 "push origin --delete <branch>. [(]one call[)]" grep -o 'push origin --delete <branch>. (one call)' "$agents/merger.md"

# ------------------------------------------------------------ calibration
# CALIBRATION: every kind of start's TIER/EFFORT, every agent start taking
# its options from it; the cheap tier is exactly the agent files with a
# model: line, the kinds with no agent file run on the session's tier, and
# the security reviewer keeps the session's tier and effort.
calib=$(table CALIBRATION)
profile_of() {
  printf '%s\n' "$calib" | sed -n "s/^$1://p"
}
missing=""
for kind in resume planner areas scout contributor checker quality security bench record merger close $(grep -o -E "calibrate\\('[a-z]+'" "$wf" | sed "s/.*('//; s/'//" | sort -u); do
  profile_of "$kind" | grep -q -E '^(cheap|session)/(low|session)$' || missing="$missing $kind"
done
expect "calibration: every kind of start has a profile" 0 "^none$" echo "${missing:-none}"
expect "calibration: every agent start takes its options from the table" 0 "^same$" \
  sh -c '[ "$(grep -c "agent(" "$1")" -eq "$(grep -c "calibrate(.[a-z]*., [{]" "$1")" ] && ! grep -q "effort: .low." "$1" && echo same' _ "$wf"
wrong=""
for pair in benchmark:bench checker:checker contributor:contributor merger:merger planner:planner quality-reviewer:quality retrospective:close scout:scout security-reviewer:security; do
  if grep -q -E '^model: ' "$agents/${pair%%:*}.md"; then tier=cheap; else tier=session; fi
  case "$(profile_of "${pair#*:}")" in "$tier"/*) ;; *) wrong="$wrong ${pair#*:}" ;; esac
done
for kind in resume areas record; do
  case "$(profile_of "$kind")" in session/*) ;; *) wrong="$wrong $kind" ;; esac
done
expect "calibration: the cheap tier is the agent files' model lines" 0 "^none$" echo "${wrong:-none}"
expect "calibration: the security reviewer keeps the session's tier and effort" 0 "^session/session$" profile_of security

# ------------------------------------------------------------ workflow helpers
# The workflows' pure helpers, run by node (which make doctor requires for
# OpenSpec): js FILE NAMES EXPRESSION prints EXPRESSION as JSON after the
# named top-level functions and one-line constants of FILE.
js() {
  file=$1 names=$2 expr=$3
  {
    for n in $names; do
      awk -v n="$n" 'index($0, "function " n "(") == 1 || index($0, "async function " n "(") == 1 { on = 1 }
        on { print; if ($0 == "}") exit; next }
        index($0, "const " n " = ") == 1 { print; exit }' "$file"
    done
    printf 'console.log(JSON.stringify(%s))\n' "$expr"
  } | node -
}
work_js() {
  js "$wf" "CONTINUES continuation workLeft reviewLeft combineReviews pushedHead keepPushed" "$1"
}
calib_js() {
  js "$wf" "SIZES CHANGE CALIBRATION calibrated calibrate restoreCalibration usage firstPass metricLine" "$1"
}
expect "workflow: calibrate passes a low effort and records the profile" 0 '^\[[{]"schema":1,"effort":"low"[}],[{]"schema":1[}],[{]"scout":"cheap/low","planner":"session/session"[}]\]$' \
  calib_js "[calibrate('scout', { schema: 1 }), calibrate('planner', { schema: 1 }), calibrated]"
expect "workflow: the metric line carries the profiles" 0 ' calib[.]scout=cheap/low calib[.]security=session/session"$' \
  calib_js "(() => { rework = 0; extra = 0; stopKind = 'none'; ciMinutes = null; estimate = ''; planned = null; state = { change: 'c' }; calibrate('scout', {}); calibrate('security', {}); return metricLine() })()"
expect "workflow: a restart restores the recorded profiles of the kinds not used yet" 0 '^[{]"planner":"session/session","scout":"cheap/low"[}]$' \
  calib_js "(() => { calibrate('planner', {}); return restoreCalibration({ 'metric.calib.scout': 'cheap/low', 'metric.calib.planner': 'cheap/low', 'metric.calib.checker': 'cheap/high', 'metric.rework': '1' }, calibrated) })()"
speed_js() {
  js "$wf" "COMMIT CLOSABLE noteText staleRed findingAt reRaised settledRecords securityBlocking narrowedFrom" "$1"
}
expect "workflow: a late finding becomes a shell-safe note" 0 '^"a [(]x[)] q y b"$' \
  speed_js 'noteText("a $(x) \"q\" `y` b")'
expect "workflow: a red superseded by a green run of the same check is stale" 0 '^\[true,false,false\]$' \
  speed_js '[staleRed(["scan, completed, failure", "spin, completed, success", "scan, completed, success"]), staleRed(["scan, completed, success", "scan, completed, failure"]), staleRed([])]'
expect "workflow: a blocking finding at an earlier advisory's location is re-raised" 0 '^\[true,false,true\]$' \
  speed_js '[reRaised(findingAt("abc1234 tools/x.sh:12 a thing"), ["tools/x.sh:12 earlier"]), reRaised(findingAt("abc1234 tools/x.sh:13 b"), ["tools/x.sh:12 earlier"]), reRaised("tools/x.sh:4", ["abc1234 tools/x.sh:4 an advisory"])]'
expect "workflow: a re-rated security Medium at confidence 8 still blocks" 0 '^\[2,0\]$' \
  speed_js '[securityBlocking([{ severity: "Medium", confidence: 8, in_change: true, file: "tools/x.sh", line: 4 }, { severity: "High", confidence: 9, in_change: true }, { severity: "Low", confidence: 9, in_change: true }, { severity: "Medium", confidence: 7, in_change: true }, { severity: "High", confidence: 9, in_change: false }]).length, securityBlocking([]).length]'
expect "workflow: no security finding is kept non-blocking by its location" 0 '^none$' \
  sh -c 'grep -q -e "security re-rating kept non-blocking" -e "reRaised(\`\${f.file}" "$1" && echo found || echo none' _ "$wf"
expect "workflow: a fix round narrows both reviews only from this start's pass" 0 '^\["abc1234","","","",""\]$' \
  speed_js '[narrowedFrom({ "review.quality": "pass abc1234" }, "quality", "def5678"), narrowedFrom({ "review.security": "pass def5678" }, "security", "def5678"), narrowedFrom({ "review.security": "blocked abc1234" }, "security", "def5678"), narrowedFrom({}, "quality", "def5678"), narrowedFrom({ "review.quality": "pass x" }, "quality", "def5678")]'
expect "workflow: both reviews' scopes read this start's records" 0 '^2$' grep -c "narrowedFrom(ran, '" "$wf"
expect "workflow: a settled resume trusts the recorded check and reviews" 0 '^\[[{]"phase.check":"abc1234","review.quality":"pass abc1234","review.security":"pass abc1234","review.bench":"pass abc1234"[}],null,null\]$' \
  speed_js '[settledRecords({ "phase.check": "abc1234", "review.quality": "pass abc1234 blocking=0", "review.security": "pass abc1234", "review.bench": "pass abc1234" }, true), settledRecords({ "phase.check": "abc1234", "review.quality": "blocked abc1234", "review.security": "pass abc1234", "review.bench": "pass abc1234" }, true), settledRecords({ "phase.check": "abc1234" }, false)]'
expect "workflow: only check and review records need a record start" 0 '^\[true,false,false,true\]$' \
  speed_js '["sh tools/run_state.sh note c late-finding \"x (y) z\"", "sh tools/run_state.sh review c security pass \"high=0\" abc1234", "sh tools/run_state.sh phase c check abc1234", "sh tools/run_state.sh phase c implement abc1234"].map((l) => CLOSABLE.test(l))'
expect "workflow: no record start runs at the close" 0 '^1$' grep -c 'await flush(' "$wf"
expect "workflow: a red only on the body's scan is fixed once, before any fix round" 0 '^body before fix$' \
  sh -c 'b=$(grep -n "m.body_only === true && !bodyFixed" "$1" | cut -d: -f1); f=$(grep -n "if (m.ci !== .red. || !mayFix())" "$1" | cut -d: -f1); [ -n "$b" ] && [ -n "$f" ] && [ "$b" -lt "$f" ] && grep -q "^### body$" "$2" && echo body before fix' _ "$wf" "$here/../.claude/agents/contributor.md"
expect "guard: the close profile runs a late-finding note" 0 "^$" guard close 'sh tools/run_state.sh note c late-finding \"security Medium (7) tools/x.sh:3 a; fix: y\" && sh tools/run_state.sh phase c report abc1234'
expect "agents: the quality reviewer blocks only on correctness and a missing test" 0 '^4[.] Blocking is only a correctness bug or a behavior change without its test[.]' \
  grep -E '^4[.] Blocking' "$here/../.claude/agents/quality-reviewer.md"
expect "agents: the merger reads only the latest run of each check name" 0 'keep only the latest run of each check name' \
  grep -E '^2[.] Read the check runs' "$here/../.claude/agents/merger.md"
expect "agents: the contributor creates the pull request with the body file unchanged" 0 "the file's text, unchanged, as the body" \
  grep -E '^4[.] Write the body' "$here/../.claude/agents/contributor.md"
expect "workflow: a contributor that finished is done" 0 '^[{]"next":"done","left":\[\][}]$' \
  work_js "(r => continuation(r, workLeft(r), 0))({ status: 'done' })"
expect "workflow: a capped contributor start is continued with what it left" 0 '^[{]"next":"continue","left":\["4.2 the docs"\][}]$' \
  work_js "(r => continuation(r, workLeft(r), 0))({ status: 'partial', remaining: ['4.2 the docs'] })"
expect "workflow: a capped contributor naming nothing left resumes from tasks.md" 0 '"left":\["the unchecked tasks of tasks.md"\]' \
  work_js "(r => continuation(r, workLeft(r), 1))({ status: 'partial', remaining: [] })"
expect "workflow: a contributor start with no result is continued" 0 '^[{]"next":"continue","left":\[\][}]$' \
  work_js "continuation(null, null, 0)"
expect "workflow: a contributor with a question stops" 0 '^[{]"next":"stop"' \
  work_js "(r => continuation(r, workLeft(r), 0))({ status: 'stopped', question: 'which scope?' })"
expect "workflow: a start still unfinished after the continuations stops" 0 '^\["stop","stop",2\]$' \
  work_js "[continuation(null, null, CONTINUES).next, continuation({ status: 'partial', remaining: ['x'] }, ['x'], CONTINUES).next, CONTINUES]"
expect "workflow: a capped review is continued over the files it left" 0 '^[{]"next":"continue","left":\["tools/gates.sh"\][}]$' \
  work_js "(r => continuation(r, reviewLeft(r), 0))({ head: 'abc1234', blocking: [], advisory: [], not_reviewed: ['tools/gates.sh'] })"
expect "workflow: a security review that did not run is continued whole" 0 '^[{]"next":"continue","left":\["the whole diff"\][}]$' \
  work_js "(r => continuation(r, reviewLeft(r), 0))({ ran: false, head: 'abc1234', findings: [] })"
expect "workflow: a covered review is done" 0 '^[{]"next":"done"' \
  work_js "(r => continuation(r, reviewLeft(r), 0))({ ran: true, head: 'abc1234', findings: [], not_reviewed: [] })"
expect "workflow: a continued review keeps the findings of both starts" 0 '^[{]"head":"abc1234","blocking":\["a","c"\],"advisory":\["b"\],"not_reviewed":\[\][}]$' \
  work_js "combineReviews({ head: 'abc1234', blocking: ['a'], advisory: ['b'], not_reviewed: ['f'] }, { head: 'abc1234', blocking: ['c'], advisory: ['b'], not_reviewed: [] })"
expect "workflow: a security review with files left never passes" 0 "if [(]!s [|][|] reviewLeft[(]s[)][.]length[)]" grep -F 'if (!s || reviewLeft(s).length)' "$wf"
full=abcdef0123456789abcdef0123456789abcdef01
expect "workflow: the merger gets the full pushed sha" 0 "^\"$full\"$" work_js "pushedHead('$full', 'abcdef012345')"
expect "workflow: a pushed sha other than the reported head is refused" 0 '^\["","",""\]$' \
  work_js "[pushedHead('1bcdef0123456789abcdef0123456789abcdef01', 'abcdef012345'), pushedHead('abcdef012345', 'abcdef012345'), pushedHead('$full', '')]"
expect "workflow: the merge prompt names the checked pushed sha" 0 'The pushed head is [$][{]pushed[}]' grep -F 'The pushed head is ${pushed}' "$wf"
expect "workflow: the merge stops before the merger without a checked sha" 0 "if [(]!pushed[)]" grep -F 'if (!pushed) { stopped' "$wf"
expect "workflow: a continued package start keeps the sha its capped start pushed" 0 "^\[\"$full\",\"$full\",\"\"\]$" \
  work_js "[keepPushed('package', '', { status: 'partial', pushed: '$full' }), keepPushed('package', '$full', { status: 'done' }), keepPushed('fix', '', { status: 'done', pushed: '$full' })]"
expect "workflow: a later push start's sha replaces the kept one" 0 '^"1bcdef0123456789abcdef0123456789abcdef01"$' \
  work_js "keepPushed('push', '$full', { status: 'done', pushed: '1bcdef0123456789abcdef0123456789abcdef01' })"
expect "workflow: every contributor start's pushed sha is kept" 0 "state[.]pushed = keepPushed[(]mode, state[.]pushed, result[)]" grep -F 'state.pushed = keepPushed(mode, state.pushed, result)' "$wf"
expect "workflow: a continued package or push start returns the recorded pushed sha" 0 'get [$][{]state[.]change[}] pushed' grep -F 'get ${state.change} pushed\` as \`pushed\`' "$wf"
expect "workflow: the package step returns the recorded pushed sha" 0 'get <change> pushed`, the full sha, as `pushed`' grep -F 'Return `sh tools/run_state.sh get <change> pushed`, the full sha, as `pushed`' "$agents/contributor.md"
expect "workflow: the push mode returns the pushed sha" 0 'returning `pushed` as in package' grep -F -- '--ci-fix`, one push per CI fix, returning `pushed` as in package' "$agents/contributor.md"
expect "workflow: a forged record in the run state skips nothing" 0 '^\[false,false,true,true,false\]$' \
  js "$wf" "passedAt" "[passedAt({}, 'review.security', 'abc1234'), passedAt({ 'review.security': 'blocked abc1234' }, 'review.security', 'abc1234'), passedAt({ 'review.security': 'pass abc1234' }, 'review.security', 'abc1234'), passedAt({ 'phase.check': 'abc1234' }, 'phase.check', 'abc1234'), passedAt({}, 'phase.check', '')]"
expect "workflow: the skips read only this start's records" 0 "^2$" sh -c 'grep -c -E "^const (doneAtHead|reviewedAtHead) = .*=> passedAt[(]ran, " "$1"' _ "$wf"
expect "workflow: only phaseDone and reviewed write this start's records" 0 "^2$" sh -c 'grep -c -E "^ *ran\[" "$1"' _ "$wf"
expect "workflow: the merge gates' records come from this start's alone" 0 '^\[\[\],\["security:pass:abc1234","check:pass:abc1234"\]\]$' \
  js "$wf" "mergeRecords" "[mergeRecords({}), mergeRecords({ 'review.security': 'pass abc1234', 'phase.check': 'abc1234' })]"
expect "workflow: the merge lines use this start's records" 0 "const records = mergeRecords[(]ran[)]" grep -F 'const records = mergeRecords(ran)' "$wf"
expect "workflow: a resume past the push checks and reviews again unless this start ran them" 0 '^\[false,false,true\]$' \
  js "$wf" "ranAll" "[ranAll({}), ranAll({ 'review.quality': 'pass a', 'review.security': 'pass a', 'phase.check': 'a' }), ranAll({ 'review.quality': 'pass a', 'review.security': 'blocked b', 'review.bench': 'pass a', 'phase.check': 'a' })]"
expect "workflow: the resume check reads this start's records" 0 "if [(]!ranAll[(]ran[)][)]" grep -F "if (!ranAll(ran))" "$wf"
expect "workflow: the resume check runs no fix round" 0 "verify[(]false[)]" grep -F "verify(false)" "$wf"
expect "workflow: the green line fetches and adds the copy with no global configuration or hook" 0 "^2$" sh -c 'grep -c -F -e "const PINNED_GIT = '\''GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -c core.hooksPath=/dev/null'\''" -e "&& \${PINNED_GIT} fetch -q --refmap= origin +refs/heads/main:refs/remotes/origin/main && \${PINNED_GIT} worktree add -q --detach" "$1"' _ "$wf"
# A local bare origin planted after the push, by branch code the checks
# ran: the green line's origin check, the script's, fails before the
# fetch, whose main would bring its own gates and guard, and main's guard
# refuses the fetch; the hosted repository passes both.
expect "workflow: the green line checks origin before its fetch" 0 "originCheck" grep -F '&& ${originCheck(state.repo)} && ${PINNED_GIT} fetch -q --refmap= origin' "$wf"
origin_check=$(js "$wf" "PINNED_GIT originCheck" "originCheck('o/r.x')" | sed 's/^"//; s/"$//; s/\\\\/\\/g')
fresh planted
gh="https:/""/github.com"
git_q remote add origin "$gh"/o/r.x.git
expect "workflow: the origin check passes the hosted repository" 0 "^ok$" sh -c "$origin_check && echo ok"
PROJECT=$PWD
expect "guard: merger fetches from the hosted repository" 0 "^$" guard merger 'git fetch -q --prune origin'
# The green line fetches main by its own refspec, reading no configured
# one; any other refspec is refused, and every call while the repository
# maps a ref other than a clone's onto origin/main.
expect "guard: merger fetches main by its pinned refspec" 0 "^$" guard merger 'git fetch -q --refmap= origin +refs/heads/main:refs/remotes/origin/main'
expect "guard: merger refuses the pinned refspec reading the configured one" 2 "git fetch other than" guard merger 'git fetch -q origin +refs/heads/main:refs/remotes/origin/main'
expect "guard: merger refuses another refspec onto origin/main" 2 "git fetch other than" guard merger 'git fetch -q --refmap= origin +refs/heads/x:refs/remotes/origin/main +refs/heads/main:refs/remotes/origin/main'
git_q config remote.origin.fetch '+refs/heads/x:refs/remotes/origin/main'
expect "guard: a fetch refspec other than a clone's refuses every call" 2 "every call while remote.origin.fetch is" guard read 'git status'
git_q config --add remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
expect "guard: a second fetch refspec refuses every call" 2 "every call while remote.origin.fetch is" guard merger 'git fetch -q --refmap= origin +refs/heads/main:refs/remotes/origin/main'
git_q config --unset-all remote.origin.fetch
expect "guard: no fetch refspec refuses nothing" 0 "^$" guard read 'git status'
git_q config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git_q init -q --bare "$work/planted.git"
git_q push -q "$work/planted.git" HEAD:refs/heads/main 2>/dev/null
git_q remote set-url origin "$work/planted.git"
expect "workflow: the origin check fails a local bare origin planted after the push" 1 "^$" sh -c "$origin_check"
expect "guard: merger refuses a fetch from a planted local origin" 2 "a local repository or a remote helper" guard merger 'git fetch -q --prune origin'
expect "guard: the security reviewer refuses a fetch from a planted local origin" 2 "a local repository or a remote helper" guard read 'git fetch -q origin'
git_q remote set-url origin "file:/""/$work/planted.git"
expect "workflow: the origin check fails a file: origin" 1 "^$" sh -c "$origin_check"
git_q remote set-url origin "ext::sh -c true"
expect "guard: merger refuses a fetch through a remote helper" 2 "a local repository or a remote helper" guard merger 'git fetch -q --prune origin'
git_q remote set-url origin "$gh"/o/r.x.git
git_q config url."$work/planted.git".insteadOf "$gh"/o/r.x.git
expect "workflow: the origin check fails an insteadOf to a local origin" 1 "^$" sh -c "$origin_check"
git_q config --unset url."$work/planted.git".insteadOf
git_q remote set-url origin "$gh"/o/rex.git
expect "workflow: the origin check fails another repository" 1 "^$" sh -c "$origin_check"
unset PROJECT
expect "workflow: a run state's repository of another form matches nothing" 0 '^\[true,true,true,false\]$' \
  js "$wf" "PINNED_GIT originCheck" "['../x', 'o/..', 'o/r x', 'o/r.x'].map((r) => originCheck(r).includes(')a^b('))"
cd "$work" || exit 1
areas=$(grep -c -E '^## [0-9]+[.] ' "$here/../docs/codebase-map.md")
expect "periodic: MAP_AREAS is the map's count of areas" 0 "^const MAP_AREAS = $areas$" grep '^const MAP_AREAS = ' "$pwf"
expect "periodic: the quality slices cover every area once" 0 '^true$' \
  js "$pwf" "MAP_AREAS QUALITY_SLICES areaSlices" "(a => a.length === QUALITY_SLICES && a.flat().join(',') === Array.from({ length: MAP_AREAS }, (_, i) => i + 1).join(','))(areaSlices(MAP_AREAS, QUALITY_SLICES))"
expect "periodic: the areas left are kept to the start's slice" 0 '^\[\[3\],\[1,2,3\],\[\]\]$' \
  js "$pwf" "areasLeft" "[areasLeft({ head: 'abc1234', not_reviewed: [3, 9] }, [1, 2, 3]), areasLeft(null, [1, 2, 3]), areasLeft({ head: 'abc1234', not_reviewed: [] }, [1, 2, 3])]"
expect "periodic: each quality start has its own worktree" 0 'tmp/[.]review-quality-[$][{]n[}]' grep '^const taskAreas = ' "$pwf"
expect "periodic: the quality record states its coverage" 0 'covered=[$][{]MAP_AREAS - ' grep -F 'covered=${MAP_AREAS - ' "$pwf"

echo "$passed/$total passed"
test "$passed" -eq "$total"
