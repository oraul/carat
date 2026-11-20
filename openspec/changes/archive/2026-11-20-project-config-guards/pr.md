fix(config): guard the project caratrc against links, bindings, and big numbers

## Summary

Hardens how a project .caratrc is read: the file is opened without following a symbolic link, it can no longer bind keys to write, quit, or command-line actions or set the leader, and four more options take only bounded numbers. A project .caratrc comes with whatever directory the user opens, so it is untrusted input, and three security Lows let it read a link swapped in after the stat check or make a typed key write, quit, or run an ex command the user did not type.

---

## Changes

- Add FilePort#read_no_link, which reads like read but opens with NOFOLLOW in DiskFiles and refuses a linked path in MemoryFiles, and read the project file through it in RcConfigGateway so a link swapped in after the stat is refused as "cannot be read", while the user file may still be a link
- Refuse a project file's keymap line bound to file.save, quit.all, quit.write_all, window.quit, or any cmdline.* action in every mode, while the defaults and the user file still bind them and the project file can still unbind them with none
- Refuse a project file's keymap.leader line, since a project leader would move the leader-based write and quit bindings onto ordinary keys
- Bound scroll and scrolloff to 0 to 9999, and timeoutlen and undolevels to 0 to 10000, reporting a value outside the range and keeping the earlier value
- Refactor Options#apply to check every bounded number through one bounded helper and every named value through one named helper, with no message changed
- Add tests for the link refusal in the gateway and the disk driver, the refused project bindings and leader, the command line's refused actions, and the four option bounds
- Add four config-files requirements, and document the port method, the project-file rules, and the option bounds in docs/architecture.md, README.md, docs/compatibility.md, and the code map

---

## Testing

- Run the security review on the committed diff, pass with no High, Medium, or Low finding
- Run the checker's stages (docs-lint, dev-build, test-build, diagnose, bench-budget, test-run, gates, tools-test, metrics), all pass
- Run the quality review, pass with no blocking finding, and the benchmark review, pass
- Run make spec-validate after the archive, 54 passed and 0 failed
- Run make gates and make docs-lint on the packaged branch, both pass

---

## Notes

A project file binding a plugin's file action, such as an explorer delete, in a mode the plugin reads is not changed here and is recorded as a finding. The :set command and the count of the scroll keys still set scroll from what the user types, as in Vim. The mode.cmdline action, which only opens the prompt, stays bindable from a project file.
