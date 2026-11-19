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
      # float titled with the counts, the highlighted row marked; a screen
      # of PREVIEW_COLUMNS or more also previews the highlighted file in a
      # second float. Enter opens the file in the editing window (it
      # arrives as the prompt's answer, and with no match the prompt opens
      # again on the same text); the prompt's own keys move the
      # highlight and open it in a split, a vertical split, or as a tab;
      # Esc closes it. Each change closes the floats and opens them again,
      # as the command palette does.
      # The grep picker (plugin.finder.grep) is the same picker over the
      # lines of the files: Grep reads them once when it opens, each row
      # is a line, Enter opens the file at its line and column, and a wide
      # screen previews the highlighted row's file around its line, from the
      # text Grep read when it opened.
      class Plugin < Carat::PluginApi::Plugin
        NAME = "finder"
        PROMPT_ID = "find"
        PROMPT = "> "
        TITLE = "Files"
        EMPTY = "No match"
        MARK = "> "
        SPACE = "  "
        PREVIEW_COLUMNS = 100
        Z = 900
        OPEN = "plugin.finder.open"
        GREP = "plugin.finder.grep"
        GREP_TITLE = "Grep"
        HINT = "Type to search the files' lines"
        KEYS = [
          "keymap.cmdline <C-n> plugin.finder.next",
          "keymap.cmdline <Down> plugin.finder.next",
          "keymap.cmdline <C-p> plugin.finder.previous",
          "keymap.cmdline <Up> plugin.finder.previous",
          "keymap.cmdline <C-x> plugin.finder.open_split",
          "keymap.cmdline <C-s> plugin.finder.open_split",
          "keymap.cmdline <C-v> plugin.finder.open_vsplit",
          "keymap.cmdline <C-t> plugin.finder.open_tab"
        ]

        # @rbs @host: Carat::PluginApi::Host?
        # @rbs @open: bool
        # @rbs @root: String
        # @rbs @grep: bool
        # @rbs @index: Grep
        # @rbs @paths: Array[String]
        # @rbs @matches: Array[Integer]
        # @rbs @selected: Integer
        # @rbs @list_float: Integer
        # @rbs @preview_float: Integer
        # @rbs @rows: Integer
        # @rbs @cols: Integer

        #: () -> void
        def initialize
          @host = nil
          @grep = false
          @index = Grep.new
          @open = false
          @root = ""
          @paths = Grep.no_strings
          @matches = []
          @selected = 0
          @list_float = 0
          @preview_float = 0
          @rows = 24
          @cols = 80
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
              "plugin.finder.next" => "Highlight the next file in the finder",
              "plugin.finder.previous" => "Highlight the previous file in the finder",
              "plugin.finder.open_split" => "Open the highlighted file in a horizontal split",
              "plugin.finder.open_vsplit" => "Open the highlighted file in a vertical split",
              "plugin.finder.open_tab" => "Open the highlighted file as a tab: a buffer tab under option.gt buffers, a tab page under option.gt tabpages"
            },
            commands: {},
            bindings: ["keymap.normal <leader>ff plugin.finder.open", "keymap.normal <leader>fg plugin.finder.grep", "keymap.normal <C-p> plugin.finder.open"],
            events: ["resize"],
            options: ["plugin.finder.ignore .git build tmp"],
            option_types: { "ignore" => "list" },
            filetypes: []
          )
        end

        #: (Carat::PluginApi::Host) -> void
        def activate(host)
          @host = host
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
          return open(host, false) if name == OPEN
          return open(host, true) if name == GREP
          return unless @open
          case name
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
          return if !input.cancelled && path.empty? && host.live_prompt(PROMPT_ID, PROMPT, input.text, KEYS).ok
          close(host)
          return if input.cancelled || path.empty?
          open_path(host, path, :edit, line, column)
        end

        private

        # Lists the files and opens the prompt; a grep also reads their text.
        #: (Carat::PluginApi::Host, bool) -> void
        def open(host, grep)
          return if @open
          root = host.working_directory.text
          listing = host.list_files(root, ignored(host))
          unless listing.ok
            host.message(listing.message, true)
            return
          end
          opened = host.live_prompt(PROMPT_ID, PROMPT, "", KEYS)
          unless opened.ok
            host.message(opened.message, true)
            return
          end
          host.message(listing.message, false) unless listing.message.empty?
          @root = root
          @paths = listing.lines
          @grep = grep
          @index.load(host, root, @paths) if grep
          @open = true
          filter("")
          refresh(host)
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
          return filter_lines(query) if @grep
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
          return @index.path_at(@matches[@selected]) if @grep
          @paths[@matches[@selected]]
        end

        # The line of the highlighted row to open at, 0 for a file.
        #: () -> Integer
        def selected_line
          return 0 if !@grep || @matches.empty?
          @index.number_at(@matches[@selected])
        end

        # The column of the highlighted row to open at.
        #: () -> Integer
        def selected_column
          return 0 if !@grep || @matches.empty?
          @index.column_at(@matches[@selected])
        end

        #: (Carat::PluginApi::Host) -> void
        def close(host)
          close_floats(host)
          @open = false
          @grep = false
          @index = Grep.new
          @paths = Grep.no_strings
          @matches = []
          @selected = 0
        end

        #: (Carat::PluginApi::Host) -> void
        def close_floats(host)
          host.close_float(@list_float) if @list_float != 0
          host.close_float(@preview_float) if @preview_float != 0
          @list_float = 0
          @preview_float = 0
        end

        # Opens the list float, and the preview beside it on a wide
        # screen, for the matches and the highlight, sized from the frame
        # the host answers for a bordered float: the host's margin from
        # each screen edge, the preview's box in the column after the
        # list's, so the boxes share an edge under every border style.
        #: (Carat::PluginApi::Host) -> void
        def refresh(host)
          close_floats(host)
          cols = @cols
          height = @rows - 6
          height = 1 if height < 1
          preview = cols >= PREVIEW_COLUMNS
          box = host.float_frame(true)
          margin = box.margin
          frame = box.box_width(0)
          room = cols - 2 * margin
          width = room - frame
          width = (room - 2 * frame) / 2 if preview
          width = 1 if width < 1
          title = @grep ? "#{GREP_TITLE} #{@index.counts}" : "#{TITLE} #{@matches.length}/#{@paths.length}"
          shown = host.open_float(float_at(margin, height, width, title), list_lines(height))
          @list_float = shown.ok ? shown.window : 0
          return unless preview && !@matches.empty?
          title = @grep ? @index.shown_path(@matches[@selected]) : selected_path
          previewed = host.open_float(float_at(margin + width + frame, height, room - width - 2 * frame, title), preview_lines(host, height))
          @preview_float = previewed.ok ? previewed.window : 0
        end

        # The highlighted file's preview rows: for a grep row the stored
        # lines around its line, its line marked as the list marks the
        # highlight; for a file its first rows, read from the disk.
        #: (Carat::PluginApi::Host, Integer) -> Array[String]
        def preview_lines(host, height)
          return @index.preview(@matches[@selected], height, MARK, SPACE) if @grep
          read = host.read_file(PluginApi::Paths.join(@root, selected_path), height)
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
            lines << (@grep && @index.idle? ? HINT : EMPTY)
            return lines
          end
          top = @selected - height + 1
          top = 0 if top < 0
          r = top
          while r < top + height && r < matches.length
            mark = r == @selected ? MARK : SPACE
            lines << mark + (@grep ? @index.row_text(matches[r]) : @paths[matches[r]])
            r += 1
          end
          lines
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
