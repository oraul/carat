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
### An indented code block inside a quote still flows into one quote row
- Location: carat/domain/markdown_text.rb:158
- Why: the four-space check counts only the spaces before the quote markers, so '>     x = 1' followed by '>     y = 2' (five spaces after the marker) joins into one quote row and the code loses its line breaks in the reading view.
- Fix: also return -1 when the spaces after the last quote marker are five or more (four beyond the marker's one), with a test/domain_markdown_text.rb case for a two-line indented block in a quote.

### marker_end can disagree with the quote-marker scans of flow_key and block
- Location: carat/domain/markdown_text.rb:175
- Why: marker_end repeats the leading-space and quote-marker scan of flow_key (:153) and block (:619) with a looser loop (any mix of spaces and >), so the join in parse can cut a line at a different byte than the block that classified it, a latent correctness divergence.
- Fix: one helper returning the byte after the markers, used by flow_key, block, and the join in parse, with a test of a quote line mixing spaces and markers.

### No hover test shows a flowed paragraph, and the README names the flow only for the reading view
- Location: test/adapters_hover.rb, README.md:69
- Why: MarkdownText.parse is shared, so the paragraph and quote flow and the hanging prefix also reach the hover and completion floats, but no test proves it there and the README states it only for the reading view.
- Fix: add a two-line paragraph case to test/adapters_hover.rb and say in the README's floats sentence that paragraphs and quotes flow there too.
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
