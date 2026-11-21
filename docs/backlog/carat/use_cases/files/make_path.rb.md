# Backlog: carat/use_cases/files/make_path.rb

## Creating a file follows a link that appears after the probe

- Where: `carat/use_cases/files/make_path.rb` line 47 at 847851d: an existence probe, then `FilePort#write`. Periodic security Low (3). Queue item `file-access-tidy`.
- Why it matters: a file or link appearing between the probe and the write is truncated or followed.
- Fix outline: a create that fails on an existing path or link, used here, with a case.
- Category: security
- Added: 2026-11-09
