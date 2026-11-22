chore(records): record sprint 26 and queue sprint 27

## Summary

Records sprint 26 and queues sprint 27: the metrics history, the backlog, the two lane queues, and the sprints file now match the merged work. The sprint's plan was waiting, so its findings files, backlog headings, and queues were still unfolded.

---

## Changes

- Append the pending history rows of every lane to docs/metrics-feature.tsv and docs/metrics-backlog.tsv.
- File each entry of the sprint's findings files into the backlog file of its first named path under docs/backlog/ and remove the folded findings files.
- Replace docs/queue-feature.md and docs/queue-backlog.md with the sprint 27 queues.
- Append the sprint-26 row to docs/sprints.tsv.
- Cite the fixing commit of the four security entries groom removed in the sprint-26 Groom line of docs/queue-backlog.md.
- Add and archive the OpenSpec change sprint-26-records, which alters no spec.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding open at the head.
- Run the check stages of the delivery at the head, all pass.
- Run the benchmark review, pass with no blocking finding.
- Run make spec-validate, all 56 items pass.

---

## Notes

None
