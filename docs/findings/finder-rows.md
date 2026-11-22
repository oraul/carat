### The grep preview's matched line has the bar but no fill or color
- Location: carat/plugins/finder/plugin.rb (preview_lines, the grep preview passing MARK to Grep#preview), carat/plugins/finder/grep.rb:174
- Why: design section 5 marks a selected row with the sapphire bar, the selection fill, and a bold label; the preview's matched line now starts with the same `▎ ` but in plain NormalFloat text, so the bar is not sapphire there and the line carries no fill, which may read as a second selected row or as a mark without its color.
- Fix: decide in docs/design.md how the preview marks its matched line (a sapphire bar alone, or the fill); then style the preview float after each fill with style_float, a PmenuMarkSel span on the bar and, if the fill is chosen, the line as its selected row, with a test under truecolor, 16 colors, and NO_COLOR.

### The finder's rows lack the dim folder and the sapphire matched letters
- Location: carat/plugins/finder/plugin.rb (list_lines, style_list), docs/design.md section 8 (Finder)
- Why: the Finder note of design section 8 draws the folder dim, the file name bright, and the matched letters sapphire; the rows now carry the selected row's look only, so the folder and the matched letters still read in the row's text color.
- Fix: have Matcher and Grep report the matched columns, and add PmenuMatch spans for them and a dim span for the folder part of each row in style_list, keeping the finder within PICKER_BUDGETS, with snapshots at every color depth.
