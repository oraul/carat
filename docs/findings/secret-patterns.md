### The configuration-file pattern of the secret check leaves out common formats
- Location: tools/rules.sh:37 (CONFIG_PATH_RE)
- Why: security Low (confidence 4): .json, .ini, .conf, .cfg, .properties, and .env.* variants are not matched, so an unquoted credential such as password=hunter2hunter2 committed in one of them passes the content gate and the pull request scan.
- Fix: add those extensions and a (^|/)\.env(\.[^/]*)?$ form to CONFIG_PATH_RE, each with a refusing expect case in tools/tools_test.sh.

### The bare assignment pattern refuses a shell test comparison
- Location: tools/rules.sh:38 (BARE_ASSIGN_RE, separator form)
- Why: correctness: the optional quote lets the closing quote of an expansion stand before =, so [ "$token" = expected_value ] in a shell file is refused, a false positive the design's risks do not name.
- Fix: require the name not to follow a dollar sign or brace, for example (^|[^$A-Za-z0-9_{])[A-Za-z0-9_-]* before the secret word, with a pass case in tools/tools_test.sh.

### A placeholder comment in the generator now matches the bare assignment pattern
- Location: tools/new.sh:133
- Why: correctness: the existing comment '# fill TOKEN=VALUE...:' matches BARE_ASSIGN_RE, so the next change that edits that line fails the content gate on a placeholder; this change edits only the gate rules, so the line was left as is.
- Fix: reword it to 'fill NAME=VALUE...', or skip shell comment lines in the configuration check.

### No case pins the eight-character boundary of the bare assignment check
- Location: tools/tools_test.sh:2845
- Why: missing test: a workflow line such as 'id-token: write' in a .yml file, the most edited configuration kind, passing is untested, so a later edit of the value length could refuse it unnoticed.
- Fix: add a pass case for a seven-character value in config/app.yml beside the refused eight-character one.
