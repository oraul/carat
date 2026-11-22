### The recent files are kept for one run only
- Location: carat/domain/buffer_list.rb (`recent`, `RECENT_LIMIT`), carat/plugins/finder/plugin.rb (`<leader>fr`)
- Why: Neovim's `oldfiles` survives a restart through shada, so `<leader>fr` in a fresh session lists only what was opened since; a relative path recorded before a `:cd` also names another file after it, as `:ls` does.
- Fix: write the recent list, as absolute paths, to a state file under the user's state directory on quit and read it at startup through the file port, bounded as now, a missing or unreadable file read as empty; a proposal decides the file's place and format.
