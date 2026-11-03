#!/bin/sh
# Tests the shell tools behind CI and the delivery pipeline, each in a
# temporary git repository or directory outside this one:
# tools/ci_scope.sh (which changes run the checks), tools/ci_wait.sh (the
# merger's wait), tools/metrics.sh (the
# measurement and the comparison with main), tools/run_state.sh (the run
# state, stages, resume, the push rule, the records only the workflow
# writes, the history, and the budget), tools/agent_guard.sh (each
# profile's refusals and allowances), tools/docs_lint.sh (budgets, content,
# wraps, paths, queue), tools/new.sh (every generator and its refusals),
# and every gate of tools/gates.sh, each passing and refusing.
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
LINK="$SCHEME//example.org/page"
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
expect "run_state: check resumes after the passed stages" 0 "stage a: passed at .*, skipped" \
  env STAGES="a b" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check state
expect "run_state: check records the phase" 0 "^$(git rev-parse --short=12 HEAD)$" state get state phase.check
# A commit that changes only tests reruns the test stages and carries the
# others; one that changes anything else reruns every stage.
env STAGES="a b test-run diagnose metrics docs-lint" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check state > /dev/null 2>&1
before_tests=$(git rev-parse --short=12 HEAD)
echo "check" > test/t.rb
commit "test: t"
env STAGES="a b test-run diagnose metrics docs-lint" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check state > carry.out 2>&1
expect "run_state: check carries a stage after a test-only commit" 0 "^stage a: passed at $before_tests, carried to $(git rev-parse --short=12 HEAD)" cat carry.out
expect "run_state: check reruns the test stages" 0 "^stage test-run: exit 0" cat carry.out
expect "run_state: check reruns diagnose, which reads the test runner, after a test-only commit" 0 "^stage diagnose: exit 0" cat carry.out
expect "run_state: check reruns docs-lint, which reads the docs and the test paths they name, after a test-only commit" 0 "^stage docs-lint: exit 0" cat carry.out
expect "run_state: check reruns metrics, which reads the test runner's rounds, after a test-only commit" 0 "^stage metrics: exit 0" cat carry.out
expect "run_state: a carried stage names its commit" 0 "^0 0s $(git rev-parse --short=12 HEAD) .* carried-from-$before_tests$" state get state stage.b
rm carry.out
echo "check" > tools/t.sh
commit "chore: t"
expect "run_state: check reruns every stage after a change outside test/" 0 "^stage a: exit 0" \
  env STAGES="a b test-run" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check state
git_q mv tools/t.sh test/moved.sh
commit "chore: move t"
expect "run_state: check reruns every stage after a file moves under test/" 0 "^stage a: exit 0" \
  env STAGES="a b test-run" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check state
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

fresh pushing
git_q init -q --bare "$work/origin.git"
git_q remote add origin "$work/origin.git"
git_q push -q origin main 2>/dev/null
state init pushing chore/pushing > /dev/null
echo more >> README.md
commit "chore: more"
expect "run_state: push refuses before the checks and the review" 1 "pre-push gates failed" \
  env BASE=main STAGES=lint sh "$here/run_state.sh" push pushing
expect "run_state: a refused push counts a gate failure" 0 "^1$" state get pushing gates_failed
state stage pushing lint true > /dev/null
state review pushing security pass "no finding" > /dev/null
expect "run_state: push passes the gates and pushes" 0 "ok   security" \
  env BASE=main STAGES=lint sh "$here/run_state.sh" push pushing
expect "run_state: a push is counted" 0 "^1$" state get pushing pushes
expect "run_state: a second push is refused" 1 "refused: 1 push" \
  env BASE=main STAGES=lint sh "$here/run_state.sh" push pushing
expect "run_state: a CI fix push needs a red CI run" 1 "needs a red CI run" \
  env BASE=main STAGES=lint sh "$here/run_state.sh" push pushing --ci-fix
state set pushing ci "red abc" > /dev/null
expect "run_state: a CI fix allows one more push" 0 "ok   pushes|ok   stages" \
  env BASE=main STAGES=lint sh "$here/run_state.sh" push pushing --ci-fix

fresh history
state init history chore/history > /dev/null
state metric history rework=1 first_pass=check:1,quality:0,security:1 ci_min=2.5 out_tokens=1200 tool_calls=40 phases=implement=1000/30,check=200/10 > /dev/null
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
state set history pr 9 > /dev/null
state set history pushes 1 > /dev/null
state set history gates_failed 1 > /dev/null
expect "run_state: pending names a merged change without a row" 0 "^history$" state pending
expect "run_state: history appends the row" 0 "appended history" state history
expect "run_state: the history starts with its header" 0 "^change[[:space:]]date[[:space:]]merged" head -1 docs/metrics.tsv
expect "run_state: the row groups the measurements and the first passes" 0 \
  "^carat=2 lh=27[.]0,j=28[.]0 lh=50[.]0 check:1,quality:0,security:1,gates:0 implement=1000/30,check=200/10 -$" \
  awk -F'\t' 'NR == 2 { print $8, $9, $10, $6, $13, $14 }' docs/metrics.tsv
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
state set derived merged "$(git rev-parse --short=12 HEAD)" > /dev/null
state set derived pushes 1 > /dev/null
state history > /dev/null
expect "run_state: history takes only the stored first verdicts" 0 "^bench:0,ci:0,gates:1$" \
  awk -F'\t' 'NR == 2 { print $6 }' docs/metrics.tsv
expect "run_state: history groups the phase figures" 0 "^implement=1000/30,check=200/10$" awk -F'\t' 'NR == 2 { print $13 }' docs/metrics.tsv
expect "run_state: history sums the phase figures" 0 "^1200 40$" awk -F'\t' 'NR == 2 { print $11, $12 }' docs/metrics.tsv
expect "run_state: history records no estimate without a queue item" 0 "^-$" awk -F'\t' 'NR == 2 { print $15 }' docs/metrics.tsv

# The estimate: the size word of the change's item in the queue at the
# parent of its squash commit, against the run's output tokens.
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
expect "run_state: budget names an overrun" 0 "^over: estimated small, budget 300000, actual 310000 output tokens$" state budget sized
expect "run_state: budget passes a run within its budget" 0 "^within: estimated large, budget 1200000, actual 900000 output tokens$" state budget large
expect "run_state: budget says when no estimate was made" 0 "^no estimate: neither the run state nor a queue item of unsized states a size" state budget unsized
expect "run_state: budget says when no output tokens were recorded" 0 "^unmeasured: estimated medium, budget 700000" state budget quiet
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
expect "run_state: budget reads the stored estimate of a change with no queue item" 0 "^within: estimated medium, budget 700000, actual 200000 output tokens$" state budget planned
expect "run_state: the stored estimate wins over the queue item" 0 "^over: estimated medium, budget 700000, actual 900000 output tokens$" state budget large
expect "run_state: budget reads the stored estimate before the merge" 0 "^within: estimated small, budget 300000, actual 1000 output tokens$" state budget early
expect "run_state: a stored word that is not a size leaves the queue item's" 0 "^unmeasured: estimated medium" state budget quiet
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
expect "run_state: every history row has the header's columns" 0 "^15$" sh -c "awk -F'\t' '{ print NF }' docs/metrics.tsv | sort -u"

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
row f "security=pass quality=pass" >> docs/metrics.tsv
expect "run_state: a periodic review restarts the count" 1 "^not due: 1 of 5" state review-due due

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

# guard PROFILE COMMAND: the guard's answer to a Bash call of COMMAND, given
# already escaped for JSON.
guard() {
  printf '{"session_id":"s","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"%s","description":"d"}}' "$2" |
    sh "$here/agent_guard.sh" "$1"
}

# guard_edit PROFILE TOOL PATH [DIR]: the guard's answer to an edit of
# PATH in the project /w, whose text names a refused command.
guard_edit() {
  printf '{"tool_name":"%s","tool_input":{"file_path":"%s","old_string":"a","new_string":"\\"command\\": \\"git push\\""}}' "$2" "$3" |
    CLAUDE_PROJECT_DIR=/w sh "$here/agent_guard.sh" "$1" ${4:+"$4"}
}

expect "guard: read refuses git push" 2 "refused for the read profile: a git command" guard read 'git push origin chore/x'
expect "guard: read refuses git push after global options" 2 "a git command" guard read 'cd /w && git -C tmp/.base -c a=b push'
expect "guard: read refuses git push after a long option" 2 "a git command" guard read 'git --no-pager push origin x'
expect "guard: read refuses a commit after a long option with a value" 2 "a git command" guard read 'git --git-dir=.git commit -m x'
expect "guard: read refuses an add after mixed global options" 2 "a git command" guard read 'git -C . --work-tree . add x'
expect "guard: read allows a long option before a git read" 0 "^$" guard read 'git --no-pager log --oneline -5'
expect "guard: read refuses a commit on a later line" 2 "a git command" guard read 'git status\ngit commit -m \"x\"'
expect "guard: read allows a git read that names push" 0 "^$" guard read 'git log --oneline --grep push -5'
expect "guard: read allows a worktree checkout" 0 "^$" guard read 'git -C tmp/.base checkout -q --detach origin/main'
expect "guard: read refuses gh" 2 "a gh command" guard read 'gh pr merge 5 --squash'
expect "guard: read refuses a gh api write" 2 "a gh command" guard read 'x=1; gh api -X POST repos/o/r/merges'
expect "guard: read refuses a review record" 2 "a run state command" guard read 'sh tools/run_state.sh review c security pass \"high=0\"'
expect "guard: read refuses a phase record" 2 "a run state command" guard read 'sh \"$PWD/tools/run_state.sh\" phase c plan'
expect "guard: read refuses a stage record" 2 "a run state command" guard read 'sh tools/run_state.sh stage c lint true'
expect "guard: read refuses a push" 2 "a run state command" guard read 'sh tools/run_state.sh push c'
expect "guard: read allows the checks" 0 "^$" guard read 'sh tools/run_state.sh check c > build/stages/c/check.out 2>&1'
expect "guard: read allows a note and the state" 0 "^$" guard read 'sh tools/run_state.sh note c security \"Low (2) x\" && sh tools/run_state.sh show c'
expect "guard: read refuses a fake make for the checks" 2 "an environment override" guard read 'MAKE=true STAGES=lint sh tools/run_state.sh check c'
expect "guard: read refuses an edit of the run state file" 2 "the run state's directory" guard read 'sed -i s/blocked/pass/ build/pipeline/c.json'
expect "guard: read refuses the run state's directory from inside build" 2 "the run state's directory" guard read 'cd build && cat > pipeline/c.json'
expect "guard: an unknown profile refuses" 2 "no such profile" guard writer 'ls'
expect "guard: merger allows the branch deletion" 0 "^$" guard merger 'git ls-remote --heads origin chore/x && git push origin --delete chore/x'
expect "guard: merger refuses the deletion of main" 2 "a git command" guard merger 'git push origin --delete main'
expect "guard: merger refuses a second ref after the branch" 2 "a git command" guard merger 'git push origin --delete chore/x main'
expect "guard: merger refuses another push" 2 "a git command" guard merger 'git push origin HEAD:main'
expect "guard: merger allows the fast-forward of main" 0 "^$" guard merger 'git checkout -q main && git merge -q --ff-only origin/main && git branch -D chore/x'
expect "guard: merger allows the body file" 0 "^$" guard merger 'CHANGE=c RECORDS=\"security:pass:abc1234\" sh tools/gates.sh merge build/pipeline/c.body.md'
expect "guard: merger refuses a phase record" 2 "a run state command" guard merger 'sh tools/run_state.sh phase c merge'
expect "guard: contributor allows the gated push" 0 "^$" guard contributor 'sh tools/run_state.sh push c'
expect "guard: contributor allows a commit and the history" 0 "^$" guard contributor 'git -c user.name=C commit -q -m x && sh tools/run_state.sh history'
expect "guard: contributor refuses git push" 2 "refused for the contributor profile: a git command" guard contributor 'git push -u origin chore/x'
expect "guard: contributor refuses a review record" 2 "a run state command" guard contributor 'sh tools/run_state.sh review c security pass x'
expect "guard: contributor refuses gh" 2 "a gh command" guard contributor 'gh pr merge 5'
expect "guard: contributor refuses an edit of the run state" 2 "the run state's directory" guard_edit contributor Edit /w/build/pipeline/c.json
expect "guard: contributor allows an edit elsewhere, whatever its text" 0 "^$" guard_edit contributor Write /w/tools/x.sh
expect "guard: read refuses a file edit without a directory" 2 "an agent that writes no file" guard_edit read Write /w/tools/x.sh
expect "guard: read allows a pack in its directory, whatever its text" 0 "^$" guard_edit read Write /w/tmp/scout/area.md tmp/scout
expect "guard: read allows a relative path in its directory" 0 "^$" guard_edit read Write build/plan/queue.md build/plan
expect "guard: read refuses a file outside its directory" 2 "outside tmp/scout" guard_edit read Write /w/tools/x.sh tmp/scout
expect "guard: read refuses a parent step out of its directory" 2 "a parent step" guard_edit read Write /w/tmp/scout/../../tools/x.sh tmp/scout
expect "guard: merger writes the body file" 0 "^$" guard_edit merger Write /w/build/pipeline/c.body.md build/pipeline
expect "guard: merger refuses the run state file" 2 "the run state's directory" guard_edit merger Write /w/build/pipeline/c.body.md.json build/pipeline
expect "guard: merger refuses a path through the body file" 2 "the run state's directory" guard merger 'mkdir build/pipeline/c.body.md && cat x > build/pipeline/c.body.md/../c.json'
expect "guard: contributor writes the body file" 0 "^$" guard_edit contributor Write /w/build/pipeline/c.body.md
expect "guard: contributor allows the body gate" 0 "^$" guard contributor 'sh tools/gates.sh pr-body build/pipeline/c.body.md'
expect "guard: contributor refuses a path through the body file" 2 "the run state's directory" guard_edit contributor Write /w/build/pipeline/c.body.md/../c.json
expect "guard: contributor still refuses the run state file" 2 "the run state's directory" guard contributor 'cat build/pipeline/c.body.md build/pipeline/c.json'
expect "guard: read refuses a metrics override of the bench" 2 "an environment override" guard read 'METRICS_OUT=x.tsv sh tools/run_state.sh bench c'

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
docs link
echo "See $LINK." >> docs/notes.md
expect "docs_lint: refuses a URL in a document" 1 "FAIL content: a URL" doclint
docs mail
echo "Write to $MAIL." >> README.md
expect "docs_lint: refuses an email address" 1 "FAIL content: an email address" doclint
docs model
echo "Run it on $TIER." >> .claude/agents/x.md
expect "docs_lint: refuses a model name outside the frontmatter" 1 "FAIL content: a model name" doclint
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
expect "gates: records passes the workflow's results" 0 "ok   records: the run state holds the workflow's 1 review" \
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
mkdir -p openspec/changes/archive/x
echo archived > openspec/changes/archive/x/tasks.md
commit "chore: archive"
expect "gates: security passes after an archive only" 0 "ok   security: pass" gates security
echo "1. next" > docs/queue.md
echo change > docs/metrics.tsv
commit "docs: record the queue and the metrics"
expect "gates: security passes after the planning records only" 0 "ok   security: pass" gates security
echo code > tools/fix.sh
commit "fix: code"
expect "gates: security refuses after code changed" 1 "code changed since" gates security
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
sed 's/^None$/None/' body.md > footer.md
printf '\nGenerated with a tool\n%s\n' "$LINK" >> footer.md
expect "gates: pr-body refuses a footer" 1 "a footer or attribution line" gates pr-body footer.md
sed 's/^None$/None <!-- left -->/' body.md > comment.md
expect "gates: pr-body refuses a template comment" 1 "a comment or angle bracket" gates pr-body comment.md
sed 's/security review/review/' body.md > nosec.md
expect "gates: pr-body refuses a body without the security review" 1 "does not report the security review" gates pr-body nosec.md
sed 's/^## Notes$/## Remarks/' body.md > shape.md
expect "gates: pr-body refuses other sections" 1 "not exactly Summary" gates pr-body shape.md

echo "$passed/$total passed"
test "$passed" -eq "$total"
