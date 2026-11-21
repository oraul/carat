### Spinel now enforces private_constant, so its backlog entry is fixed by the pin
- Location: docs/spinel-notes.md, Known miscompilations (the `private_constant` note); the backlog entry "Spinel compiles private_constant without enforcing it"
- Why: since Spinel ae6a3602, in the pin from 2f6c2486, a read of a private constant from another class raises `NameError`, as CRuby's does (a reduced probe read it at 0d1a7ca3 and raised at 2f6c2486), so the backlog entry describes a defect the pin no longer has; the `lint` rule stays because carat's layering asks for it whatever the compiler does, so no workaround code is to be dropped.
- Fix: the planner's grooming closes the backlog entry as fixed, citing this change; nothing in carat's code changes.
