#!/bin/sh
# Tests the shell tools behind CI and the delivery pipeline, each in a
# temporary git repository or directory outside this one:
# tools/ci_scope.sh (which changes run the checks), tools/ci_wait.sh (the
# merger's wait), tools/metrics.sh (the measurement and the comparison with
# main), tools/run_state.sh (the run state, stages, resume, the push rule,
# the records only the workflow writes, the history, the budget, and the
# review areas), tools/agent_guard.sh (each profile's forms and refusals,
# and the agents' hook lines), tools/docs_lint.sh (budgets, content, wraps,
# paths, queue, histories), tools/new.sh (every generator and its refusals),
# tools/spec_validate.sh (the archive preview, with a stub openspec),
# tools/spinel_warnings.sh (the build targets on a stub toolchain), and
# every gate of tools/gates.sh, each passing and refusing.
# Prints "ok   NAME" or "FAIL NAME" and the output, then "P/T passed";
# exits 1 when any failed. Run by make tools-test.
#
# Forbidden text (addresses, links, model names) is assembled from pieces
# here, so this file does not trip the content gate it tests.
set -u

here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/carat-tools-test.XXXXXX")
# The lane histories' line 1, run_state.sh's HEADER with its tabs, since
# history refuses a lane file under any other (metrics-header-fix).
HISTORY_HEADER=$(sed -n 's/^HEADER="\(.*\)"$/\1/p' "$here/run_state.sh" | sed "s/[$]{TAB}/$(printf '\t')/g")
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

pushing_dir=$work
mkdir -p "$work/bin"
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
fresh scopedcarry
state init scopedcarry chore/scopedcarry > /dev/null
echo notes > docs/notes.md
commit "docs: notes"
scoped_stages="docs-lint dev-build test-run metrics tools-test gates"
env BASE=main STAGES="$scoped_stages" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check scopedcarry > /dev/null
scoped_at=$(git rev-parse --short=12 HEAD)
mkdir -p test && echo t > test/own_test.rb
commit "test: a tests-only commit"
env BASE=main STAGES="$scoped_stages" MAKE="$work/bin/fake-make" sh "$here/run_state.sh" check scopedcarry "$scoped_at" > /dev/null
expect "run_state: a stage recorded scoped is never carried across a tests-only commit" 0 "^0 0s [0-9a-f]{12} [^ ]+ scoped$" state get scopedcarry stage.dev-build
echo "$passed/$total passed"
