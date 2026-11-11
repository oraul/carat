---
description: Publish a change's pull request with exactly its gated title and body file, through GitHub's REST API, and record its number
argument-hint: CHANGE TITLE
allowed-tools: Bash(sh tools/publish_pr.sh:*)
---

Run `sh tools/publish_pr.sh $ARGUMENTS`, the first word the change and the rest the pull request title, a Conventional Commits subject. The script gates `build/pipeline/CHANGE.body.md` and the title before any call, opens the pull request from the run state's branch against `main` (or updates the one the run state records), reads the live title and body back, refuses unless they equal the title and the file byte for byte, records the number in the run state, and prints it. Show its output as it is; on a refusal add nothing but the refusal. Never create or edit a pull request any other way: the session's tool appends a footer naming the session.
