### A check stage can forge its runner's job status files
- Location: `tools/run_state.sh`, `check_stages` (`job_dir=${check_root%/repo}/jobs`), `stage_launch`, `stages_reap`
- Why: the job files sit beside the clone (`../jobs/STAGE.status`), so a stage can write a passing status for itself or a stage still running before the runner reads it, and the runner records a pass it never saw; `escaped_paths` does not scan them, since the runner writes them during the check.
- Fix: keep the job directory under the delivery clone's `build/stages/<change>/`, outside every path a stage is handed, or have each job report its status through a pipe the runner holds instead of a file.
### Shared state a check stage can still write without failing the check
- Location: `tools/run_state.sh`, `escaped_paths`: `build/pipeline` but the change's own run state (other changes' run states, `build/pipeline/compiled`), `build/stages`, `build/plan`, `build/spinel-cache`, and `tools/run_state.sh` itself
- Why: concurrent lanes and the runner write these during a check, so they are not compared; a stage can forge another lane's run state, a compile record that makes a later check skip a compile stage, or a cache object, or edit the runner while it reads its own script.
- Fix: run the stages under an operating-system sandbox (a separate user or a read-only bind of the delivery clone), or, without one, compare the compile records and the other run states by the writes the runners log.
