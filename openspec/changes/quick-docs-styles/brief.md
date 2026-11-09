# Brief

quick-docs-styles: docs/queue.md item 1 as the planner wrote it (T5 user request, estimated medium): the hover, signature, and completion documentation floats show markdown without colors; give headings, emphasis, code spans, links as text, and fenced code (through the existing syntax highlighter) their own theme groups, each passing 4.5:1 contrast in every palette and color depth, plain under NO_COLOR, with the pinned docs split colored the same way. Allocations per key unchanged with no float shown. Continuous loop; implement-contracts-b takes the pipeline slot after this. Security review is never skipped.

Plan notes:
- The change's package step adds the palette-pad-crash row to docs/metrics.tsv with sh tools/run_state.sh history. That run is merged at 5e4c140 but is not in the history yet.
- Update the docs/backlog.md entry at line 905, 'NO_COLOR reaches only the start screen'. It is stale: since 31919d9, carat/adapters/editor_assembly.rb:489 also passes no_color? to FramePresenter#plain=, which draws the notification boxes and the progress in ASCII. This change works on NO_COLOR, so it can rewrite the Where line to name what already honours it.
- Update the Where line of the docs/backlog.md entry 'Published diagnostics keep any number of URIs' (line 1433) to carat/adapters/json_rpc_language_gateway.rb:1059 at 5e4c140, the periodic security Low (3) that confirmed it again.
- Add the 12 entries in build/plan/backlog.md to docs/backlog.md. Each one names its queue item.
- palette-pad-crash's quality advisories (note.1 to note.3: the spec scenarios at openspec/changes/palette-pad-crash/specs/command-palette/spec.md:9, the cells_of helper at test/editor_palette.rb:66, and the public bytes_within at carat/domain/display_width.rb:148) were put into docs/backlog.md by its package step. Nothing more to do for them.
- The queue is 17,364 of 17,369 bytes, so the next plan has to shorten items before it can add any.
