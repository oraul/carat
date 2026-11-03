#!/bin/sh
# The test step behind make test and make test-one: runs test programs from
# a compiled runner and compares each one's output with its committed
# snapshot, as spin test does.
#
#   tools/run_tests.sh RUNNER [test/NAME.rb ...]
#
# RUNNER is a binary that takes a test name and runs that test: the runner
# compiled from test/runner/run_all.rb, which holds every test, or a single
# test compiled on its own, which ignores the name. With no test files, every
# test/*.rb is run. Each test runs in a process of its own; its standard
# output and standard error, merged, must equal test/NAME.rb.expected byte
# for byte, and it must exit 0. A test without a snapshot fails: nothing here
# ever compares against an interpreter. The outputs are kept under
# build/test/ next to the runner for inspection.
set -u

runner=$1
shift
if [ ! -x "$runner" ]; then
  echo "run_tests: no runner at $runner; it did not compile" >&2
  exit 1
fi
if [ $# -eq 0 ]; then
  set -- test/*.rb
fi
out_dir=$(dirname "$runner")

passed=0
failed=0
for path in "$@"; do
  name=$(basename "$path" .rb)
  expected="test/$name.rb.expected"
  actual="$out_dir/$name.out"
  "$runner" "$name" > "$actual" 2>&1
  status=$?
  if [ ! -f "$expected" ]; then
    echo "FAIL $name.rb: no snapshot $expected; write it with make snapshots and review it"
    failed=$((failed + 1))
  elif [ $status -ne 0 ] || ! cmp -s "$expected" "$actual"; then
    echo "FAIL $name.rb (exit $status)"
    diff -u "$expected" "$actual" | sed 's/^/  /'
    failed=$((failed + 1))
  else
    echo "ok   $name.rb"
    passed=$((passed + 1))
  fi
done
echo "$passed/$((passed + failed)) passed"
test $failed -eq 0
