### Folded Correction entry points at a removed findings file
- Location: docs/backlog.md, the folded 'Correction' entry whose Location names the removed check-runner-safety findings file
- Why: the Location names a file this change removes, so it points at no file
- Fix: point it at the backlog entry '### Shared state a check stage can still write without failing the check'

### Duplicate file finder path sanitizing entries after the fold
- Location: docs/backlog.md, 'File finder rows and preview title show the listed path unsanitized', beside '### The file finder shows paths as the file lists them', the security Low bullet restating it, and two quality advisories about lines of the removed finder-grep-preview findings file
- Why: the fold kept near-same entries and two advisories about removed lines, so the backlog repeats itself
- Fix: merge the unsanitized-path entry and the security Low bullet into '### The file finder shows paths as the file lists them' keeping the security Low (5) rating and the U+202E test outline, and drop the two advisories about the removed findings file

### Backlog Correction entry names a removed findings file
- Location: docs/backlog.md:9262, the folded Correction entry whose Location names docs/findings/check-runner-safety.md, which this change removes.
- Why: the Location points at no file once the findings file is gone.
- Fix: point it at the backlog entry "Shared state a check stage can still write without failing the check".

### Backlog finder path entries duplicated after the fold
- Location: docs/backlog.md:9364, "File finder rows and preview title show the listed path unsanitized", beside its near-same "The file finder shows paths as the file lists them" (9359), restated by the security Low bullet at 9370, with two quality advisories at 9371-9372 about lines of the removed findings/finder-grep-preview.md.
- Why: one problem is listed three times and two advisories cite a file that no longer exists.
- Fix: merge 9364 and 9370 into 9359 keeping the security Low (5) rating and the U+202E test outline, and drop 9371-9372.

### Backlog Correction entry location still stale after the fix round
- Location: docs/backlog.md:9262, the folded Correction entry naming docs/findings/check-runner-safety.md, still present; the fix commit recorded it here instead of fixing it in the change's own file.
- Why: the Location points at no file.
- Fix: point it at the backlog entry "Shared state a check stage can still write without failing the check" and drop the entry recorded above.

### Backlog finder path duplication still present after the fix round
- Location: docs/backlog.md:9359-9372, the file finder unsanitized-path entries and the two advisories about the removed findings/finder-grep-preview.md; the fix commit recorded it here instead of fixing it.
- Why: the same problem stays listed three times beside advisories citing a removed file.
- Fix: merge 9364 and 9370 into 9359 keeping the security Low (5) rating and the U+202E test outline, drop 9371-9372, and drop the entry recorded above.
