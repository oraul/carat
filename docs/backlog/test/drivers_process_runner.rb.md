# Backlog: test/drivers_process_runner.rb

### Process runner deadline test waits the full two seconds
- Location: test/drivers_process_runner.rb:60
- Why: the deadline test waits the full 2-second CAPTURE_SECONDS on every make test run.
- Fix: accept it knowingly, or let the driver take the deadline as a constructor keyword so the test passes a short one.
- Category: code-quality
- Added: 2026-11-16

### The stalled server test does not prove the blocked write path and sleeps 0.7 s
- Location: test/drivers_process_runner.rb:91
- Why: the stalled case relies on `sleep 0.2` for the writer thread to block in `write` before `stop`; when it has not, the write fails at once on the closed pipe and the case still passes without exercising the blocked write, and its three sleeps add 0.7 s to every test run.
- Fix: stop only after a second write returns while the first is pending (or poll until the outbox is drained into the pipe), and drop the sleep before `stop_cat`, which the next spawn does not need.
- Category: code-quality
- Added: 2026-11-17
