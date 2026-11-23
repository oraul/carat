# Backlog: carat/use_cases/plugins/plugin_host.rb

### PluginHost builds what EditorAssembly should share

- Location: carat/use_cases/plugins/plugin_host.rb:73 and :78, carat/adapters/editor_assembly.rb:431 (sprint-8 sweep, quality, found twice); queued in `plugin-host-tidy`.
- Why: PluginHost builds its own ResolveInside, MakePath, RenamePath, DeletePath, ListTree, registry, router, events, and families, so test/adapters_assembly.rb cannot check they share one instance.
- Fix: build them in the assembly, pass them in, and extend the one-instance check.
- Also: carat/adapters/editor_assembly.rb, test/adapters_assembly.rb
- Category: plugins
- Added: 2026-11-16

### PluginHost decides run_program trust once at activation

- Location: carat/use_cases/plugins/plugin_host.rb:110. Sprint-11 review, security Low (3).
- Why: the trust flag comes from TrustedRoots.cover? in activate_all and never again; no attack today since the editor has no chdir, but a later :cd or configuration reload changing the working directory or the roots would keep the old decision and could run git in an untrusted directory.
- Fix outline: decide trust at each run_program call, or again wherever the working directory or the roots change, with a test changing the roots after activation.
- Category: security
- Added: 2026-11-17

### PluginHost builds its own ResolveInside

- Location: carat/use_cases/plugins/plugin_host.rb:80, carat/adapters/editor_assembly.rb:433 (sweep, quality).
- Why: two instances against the one-shared-instance rule.
- Fix outline: pass the assembly's resolve_inside as a keyword and assert it in test/adapters_assembly.rb.
- Also: carat/adapters/editor_assembly.rb, test/adapters_assembly.rb
- Category: plugins
- Added: 2026-11-17

### carat/use_cases/plugins/plugin_host.rb:84: PluginHost builds its own ResolveInside, MakePath, RenamePath, DeletePath, and (sprint-22 sweep quality)

- Location: `carat/use_cases/plugins/plugin_host.rb:84`
- Why: PluginHost builds its own ResolveInside, MakePath, RenamePath, DeletePath, and ListTree while EditorAssembly builds a second ResolveInside (carat/adapters/editor_assembly.rb:469): two instances of one use case, and core wiring outside EditorAssembly, against CLAUDE.md (built once in EditorAssembly, the only place that wires the core)
- Fix: build them in EditorAssembly and pass them in, as probe_path already is
- Also: carat/adapters/editor_assembly.rb, CLAUDE.md
- Category: plugins
- Added: 2026-11-20

### PluginHost builds its own file use cases (sprint-24 sweep quality)

- Location: `carat/use_cases/plugins/plugin_host.rb:84`, `carat/adapters/editor_assembly.rb:469`
- Why: a second ResolveInside, MakePath, RenamePath, DeletePath, and ListTree, against the one-instance rule the assembly test checks.
- Fix: build them in the assembly and pass them as keywords.
- Also: carat/adapters/editor_assembly.rb
- Category: plugins
- Added: 2026-11-21

### follow_prompt takes the state the host holds (sprint-24 sweep quality)

- Location: `carat/use_cases/plugins/plugin_host.rb:233`, `carat/use_cases/handle_key.rb:175`
- Why: it re-checks prompt_live the caller checked, and the map's PluginHost list omits six methods.
- Fix: drop the parameter and one check, and list the methods.
- Also: carat/use_cases/handle_key.rb
- Category: plugins
- Added: 2026-11-21
