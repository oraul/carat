# Backlog: tools/scan_text.sh

## The scanner and gates miss statuses and paths found at bd86828

- Where: `tools/scan_text.sh:83` (`--diff` keeps only awk's status, so a missing FILE scans clean); `tools/gates.sh:282` (the docs gate's process files omit `tools/rules.sh`, `tools/scan_text.sh`, `tools/pr_scan.sh`, `.github/workflows/`). Periodic quality.
- Why it matters: a scanner error reads as clean, and a process change escapes its CLAUDE.md check.
- Fix outline: a nonzero status for a missing file and the paths added to the docs gate, each with a `tools_test` case. Queue item `content-gate-gaps`.
- Also: tools/gates.sh, tools/rules.sh, tools/pr_scan.sh, CLAUDE.md
- Category: pipeline
- Added: 2026-11-11
