### set_float_lines retitles a listed scratch buffer a float was switched to
- Location: carat/use_cases/plugins/window_requests.rb `set_float_lines`
- Why: a float whose window was switched to one of the same plugin's listed scratch buffers (`:b` inside the float) still passes `own_float_tab`, so a refill reloads that scratch buffer and changes its title, after which `set_scratch_lines` and `scratch_window` no longer find it by its old title.
- Fix: refill only the buffer the float was opened with (a float-owned flag on the buffer, or refuse a listed buffer with "No float N"), with a test that switches a float to a scratch buffer and refills it.
