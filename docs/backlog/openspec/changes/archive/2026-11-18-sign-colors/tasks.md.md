# Backlog: openspec/changes/archive/2026-11-18-sign-colors/tasks.md

### Task 5.2 of sign-colors describes the superseded shown-layer scan
- Location: openspec/changes/archive/2026-11-18-sign-colors/tasks.md:22 (task 5.2, reviewed as openspec/changes/sign-colors/tasks.md:22)
- Why: docs currency: task 5.2 still calls Buffer#shown_layer_index private and says sign_at and sign_group_at read the shown layer once, while task 6.2 made it public and the presenter now does the one scan, so the archived record misdescribes the code.
- Fix: reword 5.2 to name the shared scan, or note that 6.2 supersedes it.
- Category: pipeline
- Added: 2026-11-18
