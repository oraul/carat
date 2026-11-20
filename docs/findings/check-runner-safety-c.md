### Security: a check's escape scan leaves the XDG global git configuration and the main checkout's HEAD out

- Location: `tools/run_state.sh`, `escaped_paths` and `refs_view`.
- Why: git also reads `${XDG_CONFIG_HOME:-$HOME/.config}/git/config` as global configuration (a hook path, an alias, a credential helper), and `refs_view` lists `for-each-ref`, which leaves out the common directory's `HEAD`, so a stage writing either by an absolute path still passes the check; the queue item named only `$HOME/.gitconfig` and the references.
- Fix: `escape_scan` the XDG configuration file beside `$HOME/.gitconfig`, and add `git -C "$main_tree" symbolic-ref -q HEAD || git -C "$main_tree" rev-parse HEAD` to the compared views from a lane, each with a failing-stage case in `tools/tools_test.sh`.
