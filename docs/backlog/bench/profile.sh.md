# Backlog: bench/profile.sh

### exit status hidden: perf report runs with its errors sent at bench/profile.sh:27 (sprint-32 sweep quality, note 88)
- Location: bench/profile.sh:27
- Why: exit status hidden: perf report runs with its errors sent to /dev/null and piped into awk, so under set -eu a failing report (a bad data file, a missing symbol map) prints an empty top list and the script exits 0
- Fix: write the report to a file first and fail on its status, then run awk over it
- Category: quality
