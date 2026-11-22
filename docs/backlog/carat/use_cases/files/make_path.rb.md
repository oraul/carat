# Backlog: carat/use_cases/files/make_path.rb

## Creating a file follows a link that appears after the probe

- Where: `carat/use_cases/files/make_path.rb` line 47 at 847851d: an existence probe, then `FilePort#write`. Periodic security Low (3). Queue item `file-access-tidy`.
- Why it matters: a file or link appearing between the probe and the write is truncated or followed.
- Fix outline: a create that fails on an existing path or link, used here, with a case.
- Category: security
- Added: 2026-11-09

### MakePath's create still follows a parent directory swapped for a link after ResolveInside
- Location: carat/use_cases/files/make_path.rb:41 (ResolveInside) and :47 (FilePort#create); carat/drivers/disk_files.rb create
- Why: the exclusive, no-follow create refuses a link at the target itself, but a directory on the path to it that is replaced by a link to a directory outside the tree between ResolveInside's real_path and the open still redirects the new empty file outside the root (an untrusted-project Low, left by drivers-lsp-lows because Spinel offers no openat).
- Fix: when Spinel offers openat or Dir#fileno with an *at open, hold a descriptor of the resolved parent and create the name relative to it with O_CREAT, O_EXCL, and O_NOFOLLOW; until then, re-resolve the parent after the create and delete the file when it landed outside the root.
- Also: carat/drivers/disk_files.rb
- Category: editor
- Added: 2026-11-22

### Exclusive create still follows a parent directory swapped for a link after ResolveInside (security Low (5), two security reviews of this change)
- Location: carat/use_cases/files/make_path.rb:49 (the file create) and :47 (the directory mkdir)
- Why: someone who can write inside an untrusted project tree could swap a parent directory for a link to an outside directory between the real_path check of ResolveInside and the open, so the new empty file, or the directory made at line 47, lands outside the root. This was already there before the change, which only adds the no-follow exclusive create of the final name; both security reviews of the change raised it, the second after the commit that documents why the interim delete-after-resolve is not applied, and it extends the parent-swap entry recorded earlier in this file.
- Fix: when Spinel offers openat, hold a descriptor of the resolved parent and create the name relative to it with O_CREAT, O_EXCL and O_NOFOLLOW (mkdirat for directories). Until then an interim fix that resolves the parent again after the create and deletes what landed outside the root needs a file identity check first (dev and inode from the create descriptor compared with an lstat), since a second swap could otherwise delete an unrelated file that already exists and FilePort gives no inode to compare.
none
- Category: security
- Added: 2026-11-22
