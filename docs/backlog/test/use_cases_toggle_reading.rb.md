# Backlog: test/use_cases_toggle_reading.rb

### The markdown-reading spec has no scenario for a closed source
- Location: test/use_cases_toggle_reading.rb:83
- Why: tests beside behavior: the new test cites scenario 'Toggling back to the source', but the delta spec has no scenario for the closed-source refusal (quality advisory, markdown-reading-a)
- Fix: add a scenario 'The source file was closed' (THEN the message 'The Markdown file is closed' shows and the view stays) to openspec/specs/markdown-reading/spec.md through a proposal and cite it in the test comment
- Also: openspec/specs/markdown-reading/spec.md
- Category: code-quality
- Added: 2026-11-16

### Brittle snapshot (sprint-20 review quality, use_cases_toggle_reading.rb:88)

- Location: `test/use_cases_toggle_reading.rb:88`
- Why: brittle snapshot: the label interpolates raw highlight ids (test/use_cases_toggle_reading.rb.expected:4 prints [2, 5, 112]), so adding a highlight group churns an unrelated snapshot
- Fix: print the span's group through Highlight.name_of instead of its numeric id
- Also: test/use_cases_toggle_reading.rb.expected
- Category: code-quality
- Added: 2026-11-19
