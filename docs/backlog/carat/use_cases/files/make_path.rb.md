# Backlog: carat/use_cases/files/make_path.rb

## Creating a file follows a link that appears after the probe

- Where: `carat/use_cases/files/make_path.rb` line 47 at 847851d: an existence probe, then `FilePort#write`. Periodic security Low (3). Queue item `file-access-tidy`.
- Why it matters: a file or link appearing between the probe and the write is truncated or followed.
- Fix outline: a create that fails on an existing path or link, used here, with a case.
- Category: security
- Added: 2026-11-09

### Exclusive create still follows a parent directory swapped for a link after ResolveInside (security Low (5)); merges "MakePath's create still follows a parent directory swapped for a link after ResolveInside" and "File operations check containment and act in separate calls"
- Location: carat/use_cases/files/make_path.rb:47 and :49 (`@files.mkdir(target)`, `@files.create(target)` after `@resolve_inside.call(base, parent, target)` at :43); carat/use_cases/files/resolve_inside.rb:28 (`@files.real_path(root)` and `real_path(dir)`, a check by path); carat/use_cases/files/rename_path.rb and delete_path.rb act by path after the same check; carat/drivers/disk_files.rb:40 creates by path with `O_NOFOLLOW` on the final component only.
- Why: in an untrusted tree a process racing the editor can swap the checked parent directory, or any directory above it inside the tree, for a link leading out between ResolveInside and the act, so the create, mkdir, rename, or delete lands outside the tree root. Not fixed in files-ex-lows: closing it needs a descriptor-relative open, which neither the pinned Spinel nor Ruby's core offers, and moving the process's working directory into the parent by path would change what every relative path of the editor names while it is away.
- Fix: open the parent once with `O_DIRECTORY | O_NOFOLLOW` walking from the root's descriptor component by component, check it is the root or inside it from that descriptor, and act relative to it (`openat` with `O_CREAT | O_EXCL | O_NOFOLLOW`, `mkdirat`, `renameat`, `unlinkat`), behind new `FilePort` methods taking the root and the relative path; or, with `fchdir`, enter the checked parent and come back by descriptor. Needs the Spinel runtime to expose those calls; a test plants the link at the parent between the check and the act through a double, as test/drivers_disk_files.rb's PlantingDisk plants one at the target.
- Also: carat/use_cases/files/resolve_inside.rb, carat/use_cases/files/rename_path.rb, carat/drivers/disk_files.rb, test/drivers_disk_files.rb
- Category: security
- Added: 2026-11-22
