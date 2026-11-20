
### history names the run state file as the lane file it appended to
- Location: `tools/run_state.sh` `append_history`, the `echo "history: appended $change to $file"` line after `write_key row`.
- Why: `write_key` assigns the global `file` to the run state's path, so the message reads `appended second to build/pipeline/second.json` instead of the lane history; a reader of the package step's output is pointed at the wrong file.
- Fix: keep the lane file in its own variable (for example `lane_path`) or print the message before `write_key`, and add a tools-test case matching the lane file in the message.
