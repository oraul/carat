# Backlog: tools/lane_facts.sh

### duplication: the check verdict line is parsed with its at tools/lane_facts.sh:74 (sprint-26 sweep quality, note 45)

- Location: tools/lane_facts.sh:74
- Why: duplication: the check verdict line is parsed with its own patterns, a copy of run_state.sh check_verdict, which pipeline-lows-a tightened to need the read LOG part while this copy still accepts any check: stage S WORD at C line
- Fix: one verdict parser, such as a run_state.sh verdict command lane_facts.sh calls
- Category: pipeline
- Added: 2026-11-22
