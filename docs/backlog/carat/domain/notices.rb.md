# Backlog: carat/domain/notices.rb

### the class comment says each notice is a one-line text at carat/domain/notices.rb:6 (sprint-32 sweep quality, note 6)
- Location: carat/domain/notices.rb:6
- Why: the class comment says each notice is a one-line text, but add shows a text of several lines and only keeps it out of the message history
- Fix: reword to say a notice may have several lines and only one of one line is kept in the history
- Category: quality

### The message history rule is spelled twice and differs for an error of several lines at carat/domain/notices.rb:38 (sprint-32 review quality)
- Location: carat/domain/notices.rb:38 (add keeps only a one-line text), carat/domain/editor_state.rb:167 (show keeps an error of several lines), docs/codebase-map.md:125
- Why: an error notice of several lines (a language server failure) is left out of :messages while the same text shown on the message row is kept; the map credits MessageHistory with the rule, which lives in two callers.
- Fix: one MessageHistory method taking the text and whether it is an error that both callers use, a domain_messages row for a two-line error notice, and the map entry corrected.
- Category: quality

### Comment lines the sprint's edits left past the wrap width at carat/domain/notices.rb:9 (sprint-32 review quality)
- Location: carat/domain/notices.rb:9 and :34, carat/domain/buffer.rb:52, carat/domain/editor_state.rb:13, carat/adapters/tab_bar.rb:14
- Why: each edited line runs past the 72 columns of the text around it, as sprint-32 sweep notes 39 and 64 found for plugin_api.rb:422.
- Fix: rewrap the paragraphs.
- Category: quality
