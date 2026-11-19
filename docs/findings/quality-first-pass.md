### Mid-tier contributor returned a placeholder result
- Location: the contributor's fix start for round 2's blocking finding (tools/tools_test.sh:4304 at 76a1d047c65f)
- Why: the start returned no result ("placeholder") after committing its fix, so the workflow recorded the head as unknown and the run needed a resume; a trial breach of the schema-return rule by the mid-tier contributor (#219).
- Fix: count it against the trial; keep the schema-checked return, and have the workflow resume from the lane branch head (git rev-parse) when a start returns a placeholder.

### Quality handler note test only greps the literal text
- Location: tools/tools_test.sh:4303
- Why: the handler case only greps the literal note text, so the order (re-raises removed before misses are noted) and that an unmarked finding is not noted go unexercised.
- Fix: move the quality blocking split into a pure helper returning the raised and missed findings and test it through speed_js.

### First-pass miss marker matches anywhere in the text
- Location: .claude/workflows/deliver-change.js:430
- Why: the marker regex matches anywhere in the text, case-sensitively, so a negation such as not a first-pass miss counts and First-pass miss does not.
- Fix: match the marker only right after the location findingAt returns, as the agent file asks, case-insensitively.

### README wording of the miss rule differs from the agent file
- Location: README.md:190
- Why: on lines the last review did not see changed is unclear and differs from the agent file; the quality step also still says the first pass reads every file of the diff to its end, while the agent file says each changed hunk with its enclosing function.
- Fix: say on lines unchanged since the last review, as .claude/agents/quality-reviewer.md:21 does, and use the agent file's reading wording.

### Marker refers to the wrong review commit
- Location: .claude/agents/quality-reviewer.md:21
- Why: that diff refers to the diff since the last passed review, while a blocked round's input names the last review's commit, blocked or passed.
- Fix: tie the marker to the commit the input names, the last quality review, as priorQuality words it.

### Whole-branch quality input lists no blocking findings
- Location: .claude/workflows/deliver-change.js:906
- Why: the agent file excludes the blocking findings its input lists, but priorQuality lists them only on the scoped path; on the whole-branch path none are listed, so the reviewer marks a still-unfixed blocking finding first-pass miss and only qualitySplit's prior filter keeps the record right.
- Fix: list the last review's blocking findings in the whole-branch input too when qualityBlocking holds them.

### Proposal still words the old miss rule
- Location: openspec/changes/archive/2026-11-19-quality-first-pass/proposal.md:9
- Why: What Changes still says lines the diff since the last review did not change and names only firstPassMiss, not that a miss is only a new finding nor the qualitySplit helper; it (and tasks.md:5) still says the first pass reads every file of the diff to its end.
- Fix: word bullets 9 to 11 as the agent file and tasks 2.1 and 2.2 do, and say each changed hunk is read with its enclosing function.

### firstPassMiss cases duplicate each other
- Location: tools/tools_test.sh:4301
- Why: the firstPassMiss case at 4301 and the marker case at 4305 both prove a marked finding counts.
- Fix: fold the unmarked case of 4301 into the 4305 case and drop 4301.

### Task 1.2 names a test that does not exist
- Location: openspec/changes/archive/2026-11-19-quality-first-pass/tasks.md:6
- Why: task 1.2 names a test, a blocking quality finding on unchanged lines is noted as a first-pass miss, that tools/tools_test.sh does not contain.
- Fix: name the existing tests (a first-pass miss is noted only for a new marked finding; the quality handler notes first-pass misses only when the prior list is the last review's).

### The known argument of the quality handler is derived inline and untested
- Location: .claude/workflows/deliver-change.js:1207
- Why: the commit of review.quality equal to qualityAt is derived inline in the handler and never run by a test, so the resumed-without-notes case is unproven.
- Fix: compute it in a small pure helper over ran and qualityAt and test it through speed_js.

### One-use alias of split.raised
- Location: .claude/workflows/deliver-change.js:1209
- Why: const raised = split.raised is a one-use alias.
- Fix: concat split.raised directly.

### Contributor returned a placeholder instead of a result (mid-tier trial)
- Location: the contributor's last fix start of this change (head 76a1d047c65f), workflow phase implement
- Why: the contributor, on the mid tier as a trial (#219), returned the word placeholder instead of its schema result, so the workflow recorded the head as unknown and the run stopped; the fix had committed and its check stages passed, so only the return was lost.
- Fix: count it against the trial; have the workflow reject a placeholder return and re-ask for the schema, reading the head from git when the branch moved.
