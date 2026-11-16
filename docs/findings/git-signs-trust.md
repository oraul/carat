
### open-pr pins its actions by tag beside PR_TOKEN (security Low, confidence 6)
- Location: .github/workflows/open-pr.yml:46
- Why: actions/checkout and actions/cache are pinned by tag in the job that holds PR_TOKEN, so a moved tag would run foreign code beside the token
- Fix: pin every action to a full commit sha with the tag in a comment
