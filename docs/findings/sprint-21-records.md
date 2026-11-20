### Folded Correction entry points at a removed findings file
- Location: docs/backlog.md, the folded 'Correction' entry whose Location names the removed check-runner-safety findings file
- Why: the Location names a file this change removes, so it points at no file
- Fix: point it at the backlog entry '### Shared state a check stage can still write without failing the check'

### Duplicate file finder path sanitizing entries after the fold
- Location: docs/backlog.md, 'File finder rows and preview title show the listed path unsanitized', beside '### The file finder shows paths as the file lists them', the security Low bullet restating it, and two quality advisories about lines of the removed finder-grep-preview findings file
- Why: the fold kept near-same entries and two advisories about removed lines, so the backlog repeats itself
- Fix: merge the unsanitized-path entry and the security Low bullet into '### The file finder shows paths as the file lists them' keeping the security Low (5) rating and the U+202E test outline, and drop the two advisories about the removed findings file
