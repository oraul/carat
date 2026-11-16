
### open-pr pins its actions by tag beside PR_TOKEN (security Low, confidence 6)
- Location: .github/workflows/open-pr.yml:46
- Why: actions/checkout and actions/cache are pinned by tag in the job that holds PR_TOKEN, so a moved tag would run foreign code beside the token
- Fix: pin every action to a full commit sha with the tag in a comment

### git_signs relies on GIT_NO_LAZY_FETCH, which a git older than 2.44 ignores (security Low, confidence 5)

- Location: carat/plugins/git_signs/plugin.rb:27
- Why: under a trusted root, a git older than 2.44 ignores GIT_NO_LAZY_FETCH, so a crafted partial clone can trigger a lazy fetch over ssh or another allowed transport and run the repository's core.sshCommand, against the comment's claim that the repository's configuration stays untrusted inside a trusted root; defense in depth only, since the user trusted the directory and language servers run there too.
- Fix: refuse every transport on the command line, not only ext: pass -c protocol.allow=never plus -c protocol.NAME.allow=never for file, git, ssh, http, and https, since a per-protocol setting in the repository outranks protocol.allow; or check the git version, or pass --no-lazy-fetch where git supports it.
