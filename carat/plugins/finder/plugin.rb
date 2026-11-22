require_relative "../../plugin_api"
require_relative "matcher"
require_relative "grep"

module Carat
  module Plugins
    module Finder
      # The file finder: opened by its action, it lists the files
      # below the working directory once (the ignore option's names left
      # out, links that leave the project skipped), opens a live prompt on
      # the command line, and after every change of the typed text filters
      # the list again through Matcher, best match first, in a bordered
      # float titled with the counts, its first row the query, the prompt
      # and the typed text, where the cursor stands (the command line stays
      # blank; the same form as the command palette's), the highlighted row drawn as a
      # selected list row (a sapphire bar, the selection fill, a bold
      # label); a screen of PREVIEW_COLUMNS or more also previews the
      # highlighted file in a second float. Enter opens the file in the
      # editing window (it arrives as the prompt's answer, and with no
      # match the prompt opens again on the same text); the prompt's own
      # keys move the highlight and open it in a split, a vertical split,
      # or as a tab; Esc closes it. Each change closes the floats and
      # opens them again, as the command palette does.
      # The grep picker (plugin.finder.grep) is the same picker over the
      # lines of the files: Grep reads them once when it opens, each row
      # is a line, Enter opens the file at its line and column, and a wide
      # screen previews the highlighted row's file around its line, from the
      # text Grep read when it opened.
      # The buffer picker (plugin.finder.buffers) and the recent files
      # picker (plugin.finder.recent) are the same picker over the host's
      # listed file buffers and its recent files, most recent first. The
      # resume (plugin.finder.resume) opens the last picker closed again
      # with its typed text, its list read again, and its highlight.
      # plugin.finder.word opens the grep picker on the word under the
      # cursor; the prompt's switch key (plugin.finder.switch) closes the
      # picker and opens the file picker, or the grep picker from any other,
      # on the same typed text.
      class Plugin < Carat::PluginApi::Plugin
        NAME = "finder"
        PROMPT_ID = "find"
        PROMPT = "> "
        QUERY_ROWS = 1
        TITLE = "Files"
        EMPTY = "No match"
        MARK = "▎ "
        SPACE = "  "
        MARK_GROUP = "PmenuMarkSel"
        LABEL_GROUP = "PmenuLabelSel"
        PREVIEW_COLUMNS = 100
        Z = 900
        OPEN = "plugin.finder.open"
        GREP = "plugin.finder.grep"
        GREP_TITLE = "Grep"
        BUFFERS = "plugin.finder.buffers"
        RECENT = "plugin.finder.recent"
        RESUME = "plugin.finder.resume"
        WORD = "plugin.finder.word"
        SWITCH = "plugin.finder.switch"
        BUFFERS_TITLE = "Buffers"
        RECENT_TITLE = "Recent"
        NOTHING_TO_RESUME = "No search to resume"
        HINT = "Type to search the files' lines"
        KEYS = [
          "keymap.cmdline <C-n> plugin.finder.next",
          "keymap.cmdline <Down> plugin.finder.next",
          "keymap.cmdline <C-p> plugin.finder.previous",
          "keymap.cmdline <Up> plugin.finder.previous",
          "keymap.cmdline <C-x> plugin.finder.open_split",
          "keymap.cmdline <C-s> plugin.finder.open_split",
          "keymap.cmdline <C-v> plugin.finder.open_vsplit",
          "keymap.cmdline <C-t> plugin.finder.open_tab",
          "keymap.cmdline <C-g> plugin.finder.switch"
        ]

        # @rbs @host: Carat::PluginApi::Host?
        # @rbs @open: bool
        # @rbs @root: String
        # @rbs @source: Symbol
        # @rbs @query: String
        # @rbs @last_source: Symbol
        # @rbs @last_query: String
        # @rbs @last_selected: Integer
        # @rbs @index: Grep
        # @rbs @paths: Array[String]
        # @rbs @matches: Array[Integer]
        # @rbs @selected: Integer
        # @rbs @list_float: Integer
        # @rbs @preview_float: Integer
        # @rbs @list_box: String
        # @rbs @preview_box: String
        # @rbs @rows: Integer
        # @rbs @cols: Integer
        # @rbs @mark_group: Integer
        # @rbs @label_group: Integer

        #: () -> void
        def initialize
          @host = nil
          @source = :files
          @query = ""
          @last_source = :none
          @last_query = ""
          @last_selected = 0
          @index = Grep.new
          @open = false
          @root = ""
          @paths = Grep.no_strings
          @matches = []
          @selected = 0
          @list_float = 0
          @preview_float = 0
          @list_box = ""
          @preview_box = ""
          @rows = 24
          @cols = 80
          @mark_group = 0
          @label_group = 0
        end

        # Returns the manifest.
        # @rbs skip
        def manifest
          Carat::PluginApi::Manifest.new(
            name: NAME,
            version: "0.1.0",
            api_version: Carat::PluginApi::VERSION,
            actions: {
              "plugin.finder.open" => "Find a file of the project by a substring or initials match of its path",
              "plugin.finder.grep" => "Find a line in the files of the project by the words of its text, and open the file there",
              "plugin.finder.buffers" => "Find an open buffer by a substring or initials match of its path",
              "plugin.finder.recent" => "Find a recently opened file, most recent first, by a substring or initials match of its path",
              "plugin.finder.resume" => "Open the last finder search again with its text and highlight",
              "plugin.finder.word" => "Find a line in the files of the project by the word under the cursor, an empty search when the cursor is on no word",
              "plugin.finder.next" => "Highlight the next file in the finder",
              "plugin.finder.previous" => "Highlight the previous file in the finder",
              "plugin.finder.open_split" => "Open the highlighted file in a horizontal split",
              "plugin.finder.open_vsplit" => "Open the highlighted file in a vertical split",
              "plugin.finder.open_tab" => "Open the highlighted file as a tab: a buffer tab under option.gt buffers, a tab page under option.gt tabpages",
              "plugin.finder.switch" => "Switch the finder between the file picker and the grep picker, keeping the typed text"
            },
            commands: {},
            bindings: ["keymap.normal <leader>ff plugin.finder.open", "keymap.normal <leader>fg plugin.finder.grep", "keymap.normal <C-p> plugin.finder.open", "keymap.normal <leader>fb plugin.finder.buffers", "keymap.normal <leader>fr plugin.finder.recent", "keymap.normal <leader>fR plugin.finder.resume", "keymap.normal <leader>fw plugin.finder.word"],
            events: ["resize"],
            options: ["plugin.finder.ignore .git build tmp"],
            option_types: { "ignore" => "list" },
            filetypes: []
          )
        end

        #: (Carat::PluginApi::Host) -> void
        def activate(host)
          @host = host
          @mark_group = host.syntax_group(MARK_GROUP).number
          @label_group = host.syntax_group(LABEL_GROUP).number
        end

        #: () -> void
        def deactivate
          @host = nil
        end

        # The screen size the floats are laid out in.
        #: (Carat::PluginApi::Event) -> void
        def on_event(event)
          host = @host
          return if host.nil? || event.name != "resize"
          @rows = event.row
          @cols = event.col
          refresh(host) if @open
        end

        #: (String, Carat::PluginApi::Context) -> void
        def on_action(name, context)
          host = @host
          return if host.nil?
          return open(host, :files, "", 0) if name == OPEN
          return open(host, :grep, "", 0) if name == GREP
          return open(host, :buffers, "", 0) if name == BUFFERS
          return open(host, :recent, "", 0) if name == RECENT
          return resume(host) if name == RESUME
          return open(host, :grep, word_under_cursor(host), 0) if name == WORD
          return unless @open
          case name
          when SWITCH then switch(host)
          when "plugin.finder.next" then move(host, 1)
          when "plugin.finder.previous" then move(host, -1)
          when "plugin.finder.open_split" then pick(host, :split)
          when "plugin.finder.open_vsplit" then pick(host, :vsplit)
          when "plugin.finder.open_tab" then pick(host, :tab)
          end
        end

        # The typed text changed: filter again from the first row.
        #: (Carat::PluginApi::Input) -> void
        def on_prompt_change(input)
          host = @host
          return if host.nil? || !@open || input.id != PROMPT_ID
          filter(input.text)
          refresh(host)
        end

        # Enter opens the highlighted file; a cancel opens nothing. Enter
        # with no match opens the prompt again on the typed text, the list
        # and its floats kept, so a typo costs only its correction.
        #: (Carat::PluginApi::Input) -> void
        def on_input(input)
          host = @host
          return if host.nil? || !@open || input.id != PROMPT_ID
          path = selected_path
          line = selected_line
          column = selected_column
          if !input.cancelled && path.empty? && host.live_prompt(PROMPT_ID, PROMPT, input.text, KEYS).ok
            attach_prompt(host)
            return
          end
          close(host)
          return if input.cancelled || path.empty?
          open_path(host, path, :edit, line, column)
        end

        private

        # Lists the source's paths and opens the prompt on the query, the
        # highlight on the row selected or the last match; a grep also
        # reads the files' text.
        #: (Carat::PluginApi::Host, Symbol, String, Integer) -> void
        def open(host, source, query, selected)
          return if @open
          root = host.working_directory.text
          listing = list(host, source, root)
          unless listing.ok
            host.message(listing.message, true)
            return
          end
          opened = host.live_prompt(PROMPT_ID, PROMPT, query, KEYS)
          unless opened.ok
            host.message(opened.message, true)
            return
          end
          host.message(listing.message, false) unless listing.message.empty?
          @root = root
          @paths = listing.lines
          @source = source
          @index.load(host, root, @paths) if grep?
          @open = true
          filter(query)
          last = @matches.length - 1
          @selected = selected > last ? last : selected
          @selected = 0 if @selected < 0
          refresh(host)
        end

        # The word under the cursor of the current buffer, "" when the
        # cursor is on no word or the buffer cannot be read.
        #: (Carat::PluginApi::Host) -> String
        def word_under_cursor(host)
          view = host.read_buffer(0)
          return "" if !view.ok || view.row < 0 || view.row >= view.lines.length
          Matcher.word_at(view.lines[view.row], view.col)
        end

        # Closes the picker and opens the other one, the file picker from
        # the grep picker and the grep picker from any other, on the text
        # typed so far.
        #: (Carat::PluginApi::Host) -> void
        def switch(host)
          query = @query
          target = grep? ? :files : :grep
          host.close_prompt
          close(host)
          open(host, target, query, 0)
        end

        # Opens the last picker closed again with its text and highlight.
        #: (Carat::PluginApi::Host) -> void
        def resume(host)
          return if @open
          if @last_source == :none
            host.message(NOTHING_TO_RESUME, false)
            return
          end
          open(host, @last_source, @last_query, @last_selected)
        end

        # The source's listing: the files below the root, the listed file
        # buffers, or the recent files.
        #: (Carat::PluginApi::Host, Symbol, String) -> Carat::PluginApi::Response
        def list(host, source, root)
          return host.list_buffers if source == :buffers
          return host.recent_files if source == :recent
          host.list_files(root, ignored(host))
        end

        # Whether the picker searches the files' lines.
        #: () -> bool
        def grep?
          @source == :grep
        end

        #: (Carat::PluginApi::Host) -> Array[String]
        def ignored(host)
          text = host.option("ignore").text
          text.empty? ? Grep.no_strings : text.split("\n")
        end

        # Matches the query against every path, best first; every path in
        # listing order for an empty query or one of spaces only.
        #: (String) -> void
        def filter(query)
          @query = query
          return filter_lines(query) if grep?
          paths = @paths
          matches = []
          @selected = 0
          if Matcher.blank?(query)
            i = 0
            while i < paths.length
              matches << i
              i += 1
            end
            @matches = matches
            return
          end
          keys = []
          i = 0
          while i < paths.length
            path = paths[i]
            score = Matcher.score(query, path)
            keys << Matcher.key(score, path.bytesize, i) if score >= 0
            i += 1
          end
          keys.sort!
          k = keys.length - 1
          while k >= 0
            matches << Matcher.index_of(keys[k])
            k -= 1
          end
          @matches = matches
        end

        # Searches the lines for the query: one row per kept line, best first.
        #: (String) -> void
        def filter_lines(query)
          @index.search(query)
          matches = []
          i = 0
          while i < @index.count
            matches << i
            i += 1
          end
          @matches = matches
          @selected = 0
        end

        #: (Carat::PluginApi::Host, Integer) -> void
        def move(host, step)
          last = @matches.length - 1
          selected = @selected + step
          selected = last if selected > last
          selected = 0 if selected < 0
          return if selected == @selected
          @selected = selected
          refresh(host)
        end

        # A split, vertical split, or tab key: the prompt closes without
        # an answer, then the file opens.
        #: (Carat::PluginApi::Host, Symbol) -> void
        def pick(host, how)
          path = selected_path
          line = selected_line
          column = selected_column
          host.close_prompt
          close(host)
          open_path(host, path, how, line, column) unless path.empty?
        end

        #: () -> String
        def selected_path
          return "" if @matches.empty?
          return @index.path_at(@matches[@selected]) if grep?
          @paths[@matches[@selected]]
        end

        # The line of the highlighted row to open at, 0 for a file.
        #: () -> Integer
        def selected_line
          return 0 if !grep? || @matches.empty?
          @index.number_at(@matches[@selected])
        end

        # The column of the highlighted row to open at.
        #: () -> Integer
        def selected_column
          return 0 if !grep? || @matches.empty?
          @index.column_at(@matches[@selected])
        end

        #: (Carat::PluginApi::Host) -> void
        def close(host)
          close_floats(host)
          @last_source = @source
          @last_query = @query
          @last_selected = @selected
          @open = false
          @source = :files
          @query = ""
          @index = Grep.new
          @paths = Grep.no_strings
          @matches = []
          @selected = 0
        end

        #: (Carat::PluginApi::Host) -> void
        def close_floats(host)
          host.close_float(@list_float) if @list_float != 0
          @list_float = 0
          close_preview(host)
        end

        # Closes the preview float when one is open.
        #: (Carat::PluginApi::Host) -> void
        def close_preview(host)
          host.close_float(@preview_float) if @preview_float != 0
          @preview_float = 0
        end

        # Shows the list float, and the preview beside it on a wide
        # screen, for the matches and the highlight, sized from the frame
        # the host answers for a bordered float: the host's margin from
        # each screen edge, the preview's box in the column after the
        # list's, so the boxes share an edge under every border style. A
        # float whose box is unchanged is refilled in place, so typing and
        # moving the highlight keep the floats the finder opened.
        #: (Carat::PluginApi::Host) -> void
        def refresh(host)
          cols = @cols
          height = @rows - 6
          height = QUERY_ROWS + 1 if height < QUERY_ROWS + 1
          body = height - QUERY_ROWS
          preview = cols >= PREVIEW_COLUMNS
          box = host.float_frame(true)
          margin = box.margin
          frame = box.box_width(0)
          room = cols - 2 * margin
          width = room - frame
          width = (room - 2 * frame) / 2 if preview
          width = 1 if width < 1
          title = grep? ? "#{GREP_TITLE} #{@index.counts}" : "#{list_title} #{@matches.length}/#{@paths.length}"
          list = float_at(margin, height, width, title)
          list_box = box_key(list)
          rows = list_lines(body)
          rows.insert(0, PROMPT + @query)
          @list_float = show_float(host, @list_float, @list_box == list_box, list, rows)
          attach_prompt(host)
          style_list(host, rows, body)
          @list_box = list_box
          unless preview && !@matches.empty?
            close_preview(host)
            return
          end
          preview_title = grep? ? @index.shown_path(@matches[@selected]) : selected_path
          shown = float_at(margin + width + frame, height, room - width - 2 * frame, preview_title)
          preview_box = box_key(shown)
          @preview_float = show_float(host, @preview_float, @preview_box == preview_box, shown, preview_lines(host, height))
          @preview_box = preview_box
        end

        # Shows the typed text on the list float's first row, where the
        # cursor stands, in place of the command line.
        #: (Carat::PluginApi::Host) -> void
        def attach_prompt(host)
          host.float_prompt(@list_float) if @list_float != 0
        end

        # The list float's title word for the source.
        #: () -> String
        def list_title
          return BUFFERS_TITLE if @source == :buffers
          return RECENT_TITLE if @source == :recent
          TITLE
        end

        # Refills the float with the id with the lines and the options'
        # title when its box is the one it was shown at (same, the box key
        # built once by the caller); otherwise, or when the refill fails,
        # closes it and opens a float. Returns the id of the float showing
        # the lines, 0 when the open failed.
        #: (Carat::PluginApi::Host, Integer, bool, PluginApi::FloatOptions, Array[String]) -> Integer
        def show_float(host, id, same, options, lines)
          if id != 0
            return id if same && host.set_float_lines(id, lines, options.title.to_s).ok
            host.close_float(id)
          end
          opened = host.open_float(options, lines)
          opened.ok ? opened.window : 0
        end

        # The column, height, and width of a float's box, as one string.
        #: (PluginApi::FloatOptions) -> String
        def box_key(options)
          "#{options.col.to_i} #{options.height.to_i} #{options.width.to_i}"
        end

        # The highlighted file's preview rows: for a grep row the stored
        # lines around its line, its line marked as the list marks the
        # highlight; for a file its first rows, read from the disk.
        #: (Carat::PluginApi::Host, Integer) -> Array[String]
        def preview_lines(host, height)
          return @index.preview(@matches[@selected], height, MARK, SPACE) if grep?
          read = host.read_file(PluginApi::Paths.absolute(@root, selected_path), height)
          lines = read.ok ? read.lines : [read.message]
          lines = [""] if lines.empty?
          lines
        end

        #: (Integer, Integer, Integer, String) -> PluginApi::FloatOptions
        def float_at(col, height, width, title)
          width = 1 if width < 1
          PluginApi::FloatOptions.new(anchor: "editor", row: 1, col: col, height: height, width: width, border: true, title: title, z: Z, enter: false)
        end

        # The rows of the matches around the highlight, the highlighted
        # one marked.
        #: (Integer) -> Array[String]
        def list_lines(height)
          lines = Grep.no_strings
          matches = @matches
          if matches.empty?
            lines << (grep? && @index.idle? ? HINT : EMPTY)
            return lines
          end
          top = list_top(height)
          r = top
          while r < top + height && r < matches.length
            mark = r == @selected ? MARK : SPACE
            lines << (grep? ? @index.row_text(matches[r], mark) : mark + @paths[matches[r]])
            r += 1
          end
          lines
        end

        # The index of the match on the list float's first row: the
        # highlight on its last row once it moves past the float's height.
        #: (Integer) -> Integer
        def list_top(height)
          top = @selected - height + 1
          top < 0 ? 0 : top
        end

        # Styles the list float's highlighted row as design section 5 draws
        # a selected list row, after every fill, which drops the style: the
        # row in the selection fill, its mark in PmenuMarkSel and its label,
        # the text after the mark, in PmenuLabelSel. The empty list (No
        # match, the grep hint) is left unstyled.
        #: (Carat::PluginApi::Host, Array[String], Integer) -> void
        def style_list(host, rows, height)
          return if @list_float == 0 || @matches.empty?
          row = @selected - list_top(height) + QUERY_ROWS
          length = rows[row].length - MARK.length
          spans = length > 0 ? [row, 0, 1, @mark_group, row, MARK.length, length, @label_group] : [row, 0, 1, @mark_group]
          host.style_float(@list_float, row, spans)
        end

        # Opens the path, relative to the working directory, in the
        # editing window, a split of it, or as the tab the top row shows
        # (a buffer tab or a tab page, by option.gt); with no file window
        # a tab pick opens as Enter does, so no tab page is left without
        # one; a grep row then moves the cursor to its line (1-based, 0 for
        # a file) and column. The path goes to the host as it is, never
        # inside an ex command line.
        #: (Carat::PluginApi::Host, String, Symbol, Integer, Integer) -> void
        def open_path(host, path, how, line, column)
          target = host.editing_window.window
          opened = case how
                   when :tab then target == 0 ? host.open_file(target, path) : host.open_as_tab(path)
                   when :split, :vsplit then host.open_in_split(target, path, how == :vsplit)
                   else host.open_file(target, path)
                   end
          report(host, opened)
          return unless opened.ok && line > 0
          moved = host.move_cursor(line - 1, column)
          host.message(moved.message, true) unless moved.ok
        end

        #: (Carat::PluginApi::Host, Carat::PluginApi::WindowResponse) -> void
        def report(host, response)
          host.message(response.message, true) unless response.ok
        end
      end
    end
  end
end
