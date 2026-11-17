fix(gates): refuse unquoted secret assignments in configuration files

## Summary

Makes the content gate and the pull request scan refuse a secret-named key assigned an unquoted literal of eight characters or more in a configuration file (YAML, TOML, shell, or caratrc). Until now only a quoted literal was refused, so an unquoted credential in one of those files passed the gate and reached the backup ref before the security review read the diff. The check runs on configuration-file rows only, so code such as an assignment of next_token to token still passes.

---

## Changes

- Add BARE_ASSIGN_RE and CONFIG_PATH_RE to tools/rules.sh: an unquoted assignment with an equals sign, a colon, or a hash rocket is refused only in configuration files, and a variable, a substitution, or a call passes, as does a whole caratrc setting line whose dotted name ends in a secret word.
- Change tools/scan_text.sh to export CONFIG_PATH_RE and check BARE_ASSIGN_RE only against lines of configuration files, the label alone reported so no log repeats the secret.
- Add tools tests that refuse an unquoted assignment in each of the four file kinds, read from a diff and by name, and pass the same assignments in a Ruby file, on standard input, and for variables and calls.
- Keep TOKEN_RE unchanged, since the project uses no platform outside its ten listed token shapes.
- Document the new patterns in the tools area of docs/codebase-map.md.
- Record the backlog-lane plan, the metrics history row, and four non-blocking review findings in docs/findings/secret-patterns.md.

---

## Testing

- Run the security review of the committed diff, pass with high 0, medium 0, low 1, nothing blocking.
- Run the quality review, pass with 0 blocking findings and 4 advisories, and the benchmark review, pass.
- Run the checker's stages diagnose, docs-lint, dev-build, test-build, bench-budget, tools-test, gates, test-run, and metrics, all pass.
- Run make spec-validate after archiving the change, 54 passed, 0 failed.
- Run make gates and make docs-lint on the packaged branch, all pass.

---

## Notes

This edits the merge gate's rules, so it lands first and alone in Sprint 16. The change also touches tools/scan_text.sh for the one export and its use, a scope widening the main session accepted because without it the rule could not apply to configuration files only. The security Low finding (other configuration formats such as json, ini, conf, and env variants not yet covered), the shell test comparison false positive, the generator placeholder comment that now matches the pattern, and the missing seven-character boundary case are recorded as follow-ups; the advisory to share one secret-word variable across the three patterns is a style point and is dropped.
