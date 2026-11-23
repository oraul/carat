### The Host#recent_files comment still says since the editor started
- Location: `carat/plugin_api.rb` (`Host#recent_files`, from 2.14)
- Why: the comment says the list holds the files shown since the editor started; it now also holds the files earlier runs kept and shows each path relative to the working directory below it and absolute elsewhere. Editing the plugin API file is a plugin API change, which this change does not make.
- Fix: reword the comment (the files shown since the editor started and those an earlier run kept, each path relative below the working directory, absolute elsewhere) in a change that may touch `carat/plugin_api.rb`, with the `docs/plugins.md` line if any.

### A buffer opened before a working directory change resolves against a later base
- Location: `carat/domain/buffer_list.rb` (`note_recent`, `base`), `carat/use_cases/files/open_file.rb`
- Why: `base` is the working directory of the last `OpenFile`, so a buffer opened under one directory and shown again after a later open under another is recorded against the newer base. The editor has no `:cd`, so the directory does not change in a real run; the file double's `move_to` is the only way.
- Fix: let a buffer carry its absolute path (or the directory it was opened in) so `note_recent` needs no base, when a `:cd` or `:lcd` command is added.

### The state file is written through a link and without a lock
- Location: `carat/use_cases/files/save_recent_files.rb`
- Why: `FilePort#write` follows a symbolic link at the state file and two editors ending together leave the later one's list. The file is in the user's own home and holds a convenience list, so neither loses anything that matters.
- Fix: write a temporary file and rename it over the state file, and merge the file's current paths with the list at save.

### Two editors ending together share one temporary state file name
- Location: `carat/adapters/editor_assembly.rb`, `save_recent_files` (the `recent_files.tmp` beside the state file)
- Why: the private write removes a leftover temporary file and then creates it exclusively, so two editors ending at the same moment can remove each other's file or fail the create, and one list is lost; the list is a convenience and every failure is skipped, so nothing breaks, but the later list may not be the one kept.
- Fix: name the temporary file by the process id, or take an advisory lock on the state directory around the write.
