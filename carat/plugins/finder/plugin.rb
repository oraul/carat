require_relative "../../plugin_api"
require_relative "matcher"

module Carat
  module Plugins
    module Finder
      # The fuzzy file finder: opened by its action, it lists the files
      # below the working directory once (the ignore option's names left
      # out, links that leave the project skipped), opens a live prompt on
      # the command line, and after every change of the typed text filters
      # the list again through Matcher, best match first, in a bordered
      # float titled with the counts, the highlighted row marked; a screen
      # of PREVIEW_COLUMNS or more also previews the highlighted file in a
      # second float. Enter opens the file in the editing window (it
      # arrives as the prompt's answer); the prompt's own keys move the
      # highlight and open it in a split, a vertical split, or a tab page;
      # Esc closes it. Each change closes the floats and opens them again,
      # as the command palette does.
      class Plugin < Carat::PluginApi::Plugin
        NAME = "finder"
        PROMPT_ID = "find"
        PROMPT = "> "
        TITLE = "Files"
        EMPTY = "No match"
        MARK = "> "
        SPACE = "  "
        PREVIEW_COLUMNS = 100
        # The columns between a box and the screen's edge.
        MARGIN = 1
        # The columns a bordered box takes beside its text, its padding
        # and its border on each side, as FloatOptions documents.
        FRAME = 4
        Z = 900
        OPEN = "plugin.finder.open"
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
          @open = false
          @root = ""
          @paths = no_paths
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
              "plugin.finder.open" => "Find a file of the project by a fuzzy match of its path",
              "plugin.finder.next" => "Highlight the next file in the finder",
              "plugin.finder.previous" => "Highlight the previous file in the finder",
              "plugin.finder.open_split" => "Open the highlighted file in a horizontal split",
              "plugin.finder.open_vsplit" => "Open the highlighted file in a vertical split",
              "plugin.finder.open_tab" => "Open the highlighted file in a new tab page"
            },
            commands: {},
            bindings: ["keymap.normal <leader>ff plugin.finder.open", "keymap.normal <C-p> plugin.finder.open"],
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
          return open(host) if name == OPEN
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

        # Enter opens the highlighted file; a cancel opens nothing.
        #: (Carat::PluginApi::Input) -> void
        def on_input(input)
          host = @host
          return if host.nil? || !@open || input.id != PROMPT_ID
          path = selected_path
          close(host)
          return if input.cancelled || path.empty?
          open_path(host, path, :edit)
        end

        private

        #: () -> Array[String]
        def no_paths
          paths = [""]
          paths.clear
          paths
        end

        #: (Carat::PluginApi::Host) -> void
        def open(host)
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
          @open = true
          filter("")
          refresh(host)
        end

        #: (Carat::PluginApi::Host) -> Array[String]
        def ignored(host)
          text = host.option("ignore").text
          text.empty? ? no_paths : text.split("\n")
        end

        # Matches the query against every path, best first; every path in
        # listing order for an empty query.
        #: (String) -> void
        def filter(query)
          paths = @paths
          matches = []
          @selected = 0
          if query.empty?
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
          host.close_prompt
          close(host)
          open_path(host, path, how) unless path.empty?
        end

        #: () -> String
        def selected_path
          return "" if @matches.empty?
          @paths[@matches[@selected]]
        end

        #: (Carat::PluginApi::Host) -> void
        def close(host)
          close_floats(host)
          @open = false
          @paths = no_paths
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
        # screen, for the matches and the highlight: MARGIN from each
        # screen edge, the preview's box in the column after the list's,
        # so with a drawn border the boxes share an edge and under
        # winborder none, each box losing its edge columns, they keep a
        # gap.
        #: (Carat::PluginApi::Host) -> void
        def refresh(host)
          close_floats(host)
          cols = @cols
          height = @rows - 6
          height = 1 if height < 1
          preview = cols >= PREVIEW_COLUMNS
          room = cols - 2 * MARGIN
          width = room - FRAME
          width = (room - 2 * FRAME) / 2 if preview
          width = 1 if width < 1
          title = "#{TITLE} #{@matches.length}/#{@paths.length}"
          shown = host.open_float(float_at(MARGIN, height, width, title), list_lines(height))
          @list_float = shown.ok ? shown.window : 0
          return unless preview && !@matches.empty?
          path = selected_path
          read = host.read_file(PluginApi::Paths.join(@root, path), height)
          lines = read.ok ? read.lines : [read.message]
          lines = [""] if lines.empty?
          previewed = host.open_float(float_at(MARGIN + width + FRAME, height, room - width - 2 * FRAME, path), lines)
          @preview_float = previewed.ok ? previewed.window : 0
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
          lines = no_paths
          matches = @matches
          if matches.empty?
            lines << EMPTY
            return lines
          end
          top = @selected - height + 1
          top = 0 if top < 0
          r = top
          while r < top + height && r < matches.length
            mark = r == @selected ? MARK : SPACE
            lines << mark + @paths[matches[r]]
            r += 1
          end
          lines
        end

        # Opens the path, relative to the working directory, in the
        # editing window, a split of it, or a tab page; the path goes to
        # the host as it is, never inside an ex command line.
        #: (Carat::PluginApi::Host, String, Symbol) -> void
        def open_path(host, path, how)
          if how == :tab
            report(host, host.open_in_tab(path))
            return
          end
          target = host.editing_window.window
          case how
          when :split, :vsplit
            report(host, host.open_in_split(target, path, how == :vsplit))
          else
            report(host, host.open_file(target, path))
          end
        end

        #: (Carat::PluginApi::Host, Carat::PluginApi::WindowResponse) -> void
        def report(host, response)
          host.message(response.message, true) unless response.ok
        end
      end
    end
  end
end
