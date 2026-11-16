fix(lsp): send document changes by the announced sync kind

## Summary

Sends each document change to a language server in the form the server announced in its initialize result: ranged content changes for incremental sync, the whole text for full sync, and nothing for no sync. ruby-lsp 0.26 announces incremental sync and drops whole-text changes, so its copy of the document went stale after the first edit and completion failed with InvalidLocationError.

---

## Changes

- Fix the didChange notification to honor the announced textDocumentSync kind, read as a number or as the TextDocumentSyncOptions object's change field, in `carat/adapters/json_rpc_language_gateway.rb`
- Add ranged content changes for sync kind 2, with zero-based lines and UTF-16 character positions, replacing the span that differs from the text last sent so their application reproduces the buffer after inserts, deletes, multi-line edits, and undo
- Keep the whole-text change for sync kind 1, and send no didChange for sync kind 0, an unknown kind, or none announced, while didOpen, didSave, and didClose are still sent
- Add the sync kind and the lines last sent per document to `LanguageServer`, forgotten with the document
- Add table-driven tests over canned servers announcing kinds 2, 1, 0, and the options object, including a non-ASCII line, and make the completion tests' canned server announce kind 2 as ruby-lsp does
- Change the language-server spec so the document requirement no longer fixes the whole text and a new requirement sends changes by the announced sync kind
- Document the sync kinds in the language services flow of the codebase map and the gateway's header comment

---

## Testing

- Run the security review of the committed diff, passed with no High, Medium, or Low finding
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run the quality review, passed with no blocking finding and eight advisories
- Run the benchmark review, allocations held at lh 26.0, j 27.0, and insert 26.0
- Run make spec-validate after the archive, 53 passed and 0 failed

---

## Notes

The ranged change is computed from the text last sent rather than from the buffer's edit records, because records can be reverted without a record of their own, so the text diff is the faithful source. Two advisories are recorded as findings for later: a reload that only changes the line ending sends nothing under incremental sync, and no replayed row covers a CRLF buffer. The openClose and save sync options and pull diagnostics are out of scope.
