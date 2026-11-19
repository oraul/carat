## 1. Implementation

- [x] 1.1 Open closed folds holding the cursor in insert and replace modes (ArrangeView)
- [x] 1.2 Drop the folds of a closed window or tab page (BufferList)

## 2. Tests and docs

- [x] 2.1 Table row for zfjiX and an assertion for zfj<C-w>s<C-w>c in test/editor_folds.rb
- [x] 2.2 Update docs/compatibility.md

## 3. Review fixes

- [x] 3.1 Open folds in RepeatLast before a replayed insert (Window#open_cursor_folds), with a table row
- [x] 3.2 Drop the folds of kept slots' view windows on tab page close; test :tabclose
- [x] 3.3 Name foldOpenCursor in the class comment, compatibility doc, and delta spec; rewrap the comment
