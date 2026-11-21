# Backlog: tools/pr_scan.sh

## The range scan of commit messages and added lines has two copies

- Where: `tools/pr_scan.sh:44-50` and `gate_content` in `tools/gates.sh:186-198`. Quality advisory of `url-email-guard`.
- Why it matters: both scan a range's commit messages and added lines with `tools/scan_text.sh`, so a rule change in one leaves the other behind (one clear way to do each thing).
- Fix outline: move the range scan into one function in `tools/rules.sh`, say `scan_range BASE HEAD`, that both call. Queue item `content-gate-gaps`.
- Also: tools/gates.sh, tools/scan_text.sh, tools/rules.sh
- Category: pipeline
- Added: 2026-11-11
