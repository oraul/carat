fix(lsp): sync only trusted files and stop stubborn servers

## Summary

Tightens the language server client and its process driver: definition targets with dot segments are dropped, only buffers under the working directory are synced to a server, a save made while a server starts is sent once it is ready, a server that ignores TERM is killed on stop, and a broken server input is reported instead of accepted. These close two security Lows and three bugs in delivered language server work, and add the missing test that a command that cannot start is not retried.

---

## Changes

- Change JsonRpcLanguageGateway#path_of to answer an empty path for a URI whose decoded path holds a . or .. segment, escaped forms included, so such a definition target is dropped
- Change the gateway to open a buffer on its server only when its absolute, segment-resolved path lies under the working directory, reading the working directory once a sync, so no document notification names a file outside it
- Fix a save made while the buffer's server is still starting being forgotten: it is kept and sent as didSave after the buffer's didOpen at that server's first sync
- Fix a language server that ignores the end of its input and TERM outliving the editor: ProcessRunner#stop waits up to 0.5 s and then sends KILL, skipping it once the child was reaped
- Fix ProcessRunner#write answering true after its writer stopped: the writer closes its outbox on a failed write and write answers false, so the gateway marks the server crashed
- Add tests for each fix in the gateway, definitions, and process runner suites, plus a test that a refused spawn is attempted once and not retried, with FakeProcesses#attempts counting refused spawns
- Document the working-directory rule and the stop's KILL in the architecture's language server section, the code map's area 17, the ProcessPort stop contract, and the language-server and definitions specs
- Record the four headings left for a follow-up and the open request finding in the change's findings file, and update the backlog queue and metrics history

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the quality review of the committed diff, pass with no blocking finding
- Run the checker's stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics, all pass
- Run the benchmark review against main's recorded figures, pass
- Run make spec-validate after the archive, 54 passed and 0 failed
- Run make gates, all pass

---

## Notes

This delivers 6 of the 10 backlog headings of Sprint 22 backlog item 2; the DiskFiles#stat calls, the two NO_COLOR headings, and the client's repetition are queued as lsp-tidy-c. Requests such as completion and hover for a buffer outside the working directory still name its URI, not its text; that is recorded as a finding. A link inside the working directory that leads out of it is judged lexically, to keep the idle tick off the disk.
