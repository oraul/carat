### An exception paragraph naming a change without backticks leaves it counted in the sprint
- Location: tools/run_state.sh:2611, tools/docs_lint.sh:177; the groom-evidence-only line was docs/queue-backlog.md:7 at 01bee7b47329.
- Why: the sprint count and the docs lint read a change out of the 3 only when the exception paragraph names it in backticks, so a paragraph naming it in plain words, as that line does, leaves the change counted toward the sprint's 3 backlog changes and can close or overfill the sprint early.
- Fix: read a change name in an exception paragraph with or without backticks (a kebab-case word matching a merged or queued change), or have docs-lint refuse an exception paragraph that names a change without backticks; a tools-test case each.
