### A project .caratrc can rebind a key only a plugin manifest binds
- Location: carat/domain/config.rb, held_keys (the held keys are read from the configuration's lines only)
- Why: a plugin's default bindings come from its manifest, applied to the keymap before the configuration, and Config never sees them, so a project file may unbind or rebind such a key; no shipped manifest binds a write, a quit, or the command line today, but a later plugin's could.
- Fix: hold the manifest bindings too, by passing the registry's keymap lines to Config before the project file is read, or by checking a project line against the built keymap in Keymap#add_checked with the same held rule.
