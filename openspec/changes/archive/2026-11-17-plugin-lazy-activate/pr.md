feat(plugins): activate each plugin on its first trigger

## Summary

Makes every plugin activate on its first trigger instead of at startup: the host reads each enabled plugin's manifest, options, and default bindings when the editor is assembled and calls `activate` only on the first action or key it binds, the first ex command it declares, the first buffer of a filetype it declares, or, for a plugin with none of these such as git_signs, the first idle after the first frame. Every plugin written to assume activation at startup adds to the time before the first frame and makes the rule harder to change later, so the user asked that a plugin load only when first called, as the standard for every plugin. Delivered as Sprint 16's user-approved exception.

---

## Changes

- Change the plugin registry and host to prepare every enabled plugin at startup and activate it on its first trigger, events reaching only an active plugin and only an active plugin being deactivated at quit.
- Change the input controller and the editor assembly to wake a plugin with no action, ex command, or filetype at the first idle after the first frame, so git_signs runs git only after it.
- Change the syntax provider to activate a tokenizer on its first buffer and pass over one whose late `activate` raises to the next plugin declaring the syntax, the raising plugin disabled and the editor running on.
- Change the explorer's `activate` to read the current buffer's path and the hello plugin's to count the open buffer, so neither loses what happened before it was called.
- Bump the plugin API to 2.9, since when `activate` is called and which events arrive changed; no request was added or removed.
- Document the first-trigger rule in `docs/architecture.md` section 9, a new Activation section of `docs/plugins.md`, the plugin-host spec, and the `make new-plugin` template.
- Add `test/editor_lazy_plugins.rb` showing the explorer, finder, and ruby plugins inactive until their first trigger and working after it, and update the git_signs, plugin host, hardening, syntax, and manifest tests.
- Record the plan, the Sprint 16 exception line, the metrics history, and this change's findings.

---

## Testing

- Run the security review of the committed diff, pass with 0 high, 0 medium, and 0 low findings.
- Run the checker's stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics, all pass.
- Run the quality review, pass with no blocking finding after the two blocking ones were fixed with their tests.
- Run the benchmark review, pass with allocations held at lh 26.0, j 27.0, and insert 26.0.
- Run make spec-validate after archiving, 54 passed and 0 failed.
- Measure startup to the first frame in a pty over 15 runs with git_signs enabled, 7.7 to 15.6 ms with a median of 8.8 ms after, against 11.7 to 13.7 ms before.

---

## Notes

The brief lists the first declared event as a trigger; a plugin that also declares an action, ex command, or filetype is not woken by its events, since the explorer subscribes to cursor_move and would otherwise load on the first cursor move, so events wake only a plugin with no other trigger, at the first idle after the first frame. The startup figures were taken on different machines and move with them; what the change guarantees is that no plugin's activate runs before the first frame. Follow-ups recorded in this change's findings: activating filetype plugins before arrange, the git-status spec scenario on activation, and the hello plugin's buffer count. Comment rewrapping, the public test-only host methods, and the duplicated drawn size were advisories left out of the findings.
