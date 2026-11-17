fix(lsp): end only carat's server and settle its program once

## Summary

Quit and :LspRestart now end only the language server process carat started, and an idle tick for a filetype with no server no longer reads any configuration line. Before, stopping a server could end more than carat's own child, and the gateway rescanned about 760 configuration lines twice on every idle tick while a filetype had no server. The gateway now settles each language's server program once, as it already keeps the trust answer.

---

## Changes

- Change ProcessRunner stop to send TERM to the handle's own pid before detaching, so quit and :LspRestart end only the spawned server, the contract stated in the process port
- Trap PIPE once in the process runner so a write to a server stopped while its writer thread still holds bytes fails with EPIPE instead of ending carat
- Change JsonRpcLanguageGateway to keep each language's settled program in head_of, used by command? and hold, so an idle tick with no server reads no configuration line
- Add tests for stopping only the started server, a stalled server keeping the editor running, quit and :LspRestart stopping only the old server, and an idle tick reading no configuration line
- Add two scenarios to the language-server spec through the archived OpenSpec change
- Document the stop signal in the README and the ProcessRunner entry of the architecture, and the settled program in the codebase map

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low findings
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass
- Run the quality review, pass with no blocking finding
- Run the benchmark comparison against main's recorded figures, allocations and rounds held
- Run make spec-validate after the archive, 53 items pass

---

## Notes

Part b of lsp-container (171). Advisory review findings on the stop ordering against the queued shutdown and on the stalled server test's timing are recorded in the change's findings file for the backlog; the wording advisories on the proposal and the task numbering are fixed here, and the advisories on the architecture entry naming Open3 for one-shot tools, the duplicated signal helper, the parallel settled lists, and the PIPE trap's owner are dropped.
