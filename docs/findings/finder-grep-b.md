### A file longer than 1000 lines is searched in part with no mark
- Location: carat/plugins/finder/grep.rb (FILE_ROWS, `load`), carat/use_cases/plugins/file_requests.rb (the `read_file` row limit)
- Why: the user can search a long file and miss a line past its 1000th with nothing on the rows or the title saying the file was cut; docs/plugins.md now states the bound but the picker does not show it.
- Fix: have `read_file` report that rows were dropped (a host request change with a minor version bump), then count the cut files in `Grep` and show a note on the title or the prompt's count.
