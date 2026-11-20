### Security: a check's escape scan leaves the XDG global git configuration and the main checkout's HEAD out

- Location: `tools/run_state.sh`, `escaped_paths` and `refs_view`.
- Why: git also reads `${XDG_CONFIG_HOME:-$HOME/.config}/git/config` as global configuration (a hook path, an alias, a credential helper), and `refs_view` lists `for-each-ref`, which leaves out the common directory's `HEAD`, so a stage writing either by an absolute path still passes the check; the queue item named only `$HOME/.gitconfig` and the references.
- Fix: `escape_scan` the XDG configuration file beside `$HOME/.gitconfig`, and add `git -C "$main_tree" symbolic-ref -q HEAD || git -C "$main_tree" rev-parse HEAD` to the compared views from a lane, each with a failing-stage case in `tools/tools_test.sh`.

### Security: a check leaves the remote-tracking refs unchecked, so a stage can forge origin/main for the next lane

- Location: `tools/run_state.sh`, `refs_view` and `main_moved`.
- Why: `refs_view` leaves out `refs/remotes/`, which every lane's fetch and push rewrite, and `main_moved` accepts the main checkout's HEAD at its branch's remote-tracking ref, so a stage can write `refs/remotes/origin/main` and fast-forward the main checkout to it; the forged ref lasts until the next fetch, and `lane-open` bases a new lane on the local `origin/main` without fetching.
- Fix: have `lane-open` fetch origin before it reads `origin/main`, or compare each remote-tracking ref after the check against `git ls-remote origin`, with a failing-stage case in `tools/tools_test.sh`.

### Security: a check's escape scan leaves the XDG global git configuration and the branch the main checkout's HEAD names out

- Location: `tools/run_state.sh`, `escaped_paths` and `main_moved`.
- Why: git also reads `${XDG_CONFIG_HOME:-$HOME/.config}/git/config` as global configuration (a hook path, an alias, a credential helper), and `main_moved` compares only the commit the main checkout's HEAD names, so a stage writing the XDG file, or switching the main checkout's HEAD to another branch at the same commit, by an absolute path still passes the check; the queue item named only `$HOME/.gitconfig`, the main checkout, and the references.
- Fix: `escape_scan` the XDG configuration file beside `$HOME/.gitconfig`, and compare `git -C "$main_tree" symbolic-ref -q HEAD` beside the commit in `main_moved`, each with a failing-stage case in `tools/tools_test.sh`.
