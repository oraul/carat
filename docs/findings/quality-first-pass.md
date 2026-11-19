### Mid-tier contributor returned a placeholder result
- Location: the contributor's fix start for round 2's blocking finding (tools/tools_test.sh:4304 at 76a1d047c65f)
- Why: the start returned no result ("placeholder") after committing its fix, so the workflow recorded the head as unknown and the run needed a resume; a trial breach of the schema-return rule by the mid-tier contributor (#219).
- Fix: count it against the trial; keep the schema-checked return, and have the workflow resume from the lane branch head (git rev-parse) when a start returns a placeholder.
