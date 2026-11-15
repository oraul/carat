chore: drop the unread formatter setting and register ex descriptions

## Summary

Stops shipping the unread language.ruby.formatter setting and answers a formatter line as not supported yet, moves each ex command's palette description into its registration, and removes five uncalled methods. The architecture review found a setting that was validated but read by nothing, ex descriptions kept in one constant apart from the registrations so a new command could ship without one, and dead code in the domain, use cases, and doubles.

---

## Changes

- Change Config to answer a language.NAME.formatter line from the defaults or the user file with "language setting formatter is not supported yet" and keep nothing, and remove the shipped formatter line from config/default.caratrc and its generated mirror
- Change ExTable#register to take the command's description beside its handler, as ActionTable#register does, remove the DESCRIPTIONS constant, and pass each name's description from every ex family's self.register
- Add a table test that a description arrives with its registration, and make the assembly check fail on an ex command registered with an empty description
- Change the ex command generator in tools/new.sh to write a description placeholder, with its tools test
- Remove DisplayWidth.of_char, ExtendVisual#tabstop_of, CommandGrammar#operator_pending?, TabRequest#counted?, and FakeTerminal#input? with their code-map entries
- Document PluginApi::Command#args? and PluginApi::Edit#insertion? in docs/plugins.md, kept for third-party plugins
- Document the formatter setting as planned in README.md and docs/architecture.md sections 7 and 8
- Add the config-files requirement for the formatter line and archive the OpenSpec change architecture-tidy

---

## Testing

- Run the security review of the committed diff, passed with no High, Medium, or Low finding
- Run the quality review, passed with no blocking finding and four advisories recorded in the backlog
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass with 2 rounds for carat and the runner
- Run the benchmark review against main's recorded figures, passed with no blocking finding
- Run make spec-validate after the archive, all 51 items pass

---

## Notes

The formatter setting returns with roadmap item 14, plugin-git-and-formatting, which runs a formatter; until then a user's formatter line is reported as a configuration problem instead of being silently ignored. A plugin's ex commands register through PluginCommandHandler with an empty description, since the palette lists only named commands. The four quality advisories, including the generator's TODO placeholder passing the description length check, are in docs/backlog.md for a follow-up.
