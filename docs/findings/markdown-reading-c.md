### A check pass after a fix round costs more than a first pass
- Location: `.claude/workflows/deliver-change.js` check phase; backlog pool item `check-skip` (git-signs-status-b retro note 9).
- Why: git-signs-status-b's check took 57,747 output tokens in 11 calls (16.8% of 342,779) over 2 passes that both passed; the last 20 lane rows ran 1,970 to 24,171; check first pass 121/123.
- Fix: fold into `check-skip`; accepted when the next three feature runs keep check at or under 6,000 output tokens per pass with first.check still 1.

### A resumed run records 0 output tokens for the phases done before the resume
- Location: `.claude/workflows/deliver-change.js` resume path, `metric.phases` and the history row (git-signs-status-b retro note 10).
- Why: git-signs-status-b recorded plan=0/10, areas=0/2, scout=0/14 against plan 10,124 to 25,457 and scout 18,002 to 64,257 output in the last 10 feature rows, so its output total and the check-pass budget line undercount.
- Fix: accepted when a resumed run's carried phases show their recorded tokens or are marked carried in the phases and the history row, never 0 beside non-zero calls.

### Quality fails its first pass on about half the runs
- Location: the quality review's blocking findings across the lane histories (git-signs-status-b retro note 11).
- Why: quality first pass 62/123 against 117/124 or better for every other gate; first.quality 0 on git-signs-status-a and git-signs-status-b (plugin state keyed by buffer id with no rename case); the fix round took output from 164,154 to 342,779, over medium's 200,000.
- Fix: find what the blocking findings of the last ten quality first-pass failures share and remove the cause upstream; accepted when quality first pass reaches 7 of the next 10 runs.
