require_relative "../domain/editor_state"
require_relative "../domain/mode"
require_relative "../domain/cmdline_menu"
require_relative "../domain/palette"
require_relative "../domain/search_prompt"
require_relative "../domain/plugin_ui"
require_relative "../domain/display_width"
require_relative "../domain/buffer"
require_relative "../domain/syntax_line"
require_relative "../domain/highlight"
require_relative "../domain/window"
require_relative "../domain/float_spec"
require_relative "../domain/float_window"
require_relative "../domain/themes"
require_relative "../ports/file_port"
require_relative "ex/ex_table"
require_relative "windows/open_float"
require_relative "windows/close_float"
require_relative "outcome"

module Carat
  module UseCases
    # <Tab> and <S-Tab> at the `:` prompt, as Neovim's wildmenu with
    # wildoptions=pum: while the menu is current (CmdlineMenu#current?)
    # the selection moves by step, through the matches and back to the
    # typed text; otherwise the word before the cursor is completed
    # afresh: an ex command name when the text before the cursor is only
    # letters, a prefix of the full names in their precedence order; a
    # path after a command of PATH_COMMANDS, its blanks, and an optional
    # bang, from at most MAX_ENTRIES entries of its directory read through
    # the file port (relative to the working directory, as typed after
    # "/", under the home after "~/"), a directory ending in "/", a dot
    # file only for a typed name starting with a dot; a shipped palette
    # name after :colorscheme, in the order of Themes::NAMES. The selection
    # replaces the word, the text after the cursor kept, and a bordered
    # popup above the command line lists the labels at the word's column
    # in Pmenu, the selection in PmenuSel, the typed characters in
    # PmenuMatch, at most MAX_ROWS rows around the selection, EMPTY when
    # nothing matches. Any other prompt, and an argument of another
    # command, is left as it is.
    class CompleteCommandLine
      MAX_ENTRIES = 1_000
      MAX_ROWS = 10
      PATH_COMMANDS = ["edit", "write", "split", "vsplit", "tabedit"].freeze
      EMPTY = "No matches  Esc close"
      Z = 950
      private_constant :MAX_ENTRIES, :MAX_ROWS, :PATH_COMMANDS, :EMPTY, :Z

      attr_reader :menu #: Domain::CmdlineMenu
      attr_reader :commands #: ExTable
      attr_reader :files #: Ports::FilePort
      attr_reader :palette #: Domain::Palette
      attr_reader :search_prompt #: Domain::SearchPrompt
      attr_reader :plugin_ui #: Domain::PluginUi
      attr_reader :open_float #: OpenFloat
      attr_reader :close_float #: CloseFloat

      #: (menu: Domain::CmdlineMenu, commands: ExTable, files: Ports::FilePort, palette: Domain::Palette, search_prompt: Domain::SearchPrompt, plugin_ui: Domain::PluginUi, open_float: OpenFloat, close_float: CloseFloat) -> void
      def initialize(menu:, commands:, files:, palette:, search_prompt:, plugin_ui:, open_float:, close_float:)
        @menu = menu
        @commands = commands
        @files = files
        @palette = palette
        @search_prompt = search_prompt
        @plugin_ui = plugin_ui
        @open_float = open_float
        @close_float = close_float
      end

      # step is 1 for <Tab> and -1 for <S-Tab>.
      #: (Domain::EditorState, Integer) -> Outcome
      def call(state, step)
        return Outcome.none unless colon_prompt?(state)
        menu = @menu
        if menu.showing? && menu.current?(state)
          move(menu, step)
        else
          close(state)
          menu.clear
          collect(state)
          return Outcome.none if menu.start < 0
          count = menu.matches.length
          menu.selected = count == 0 ? -1 : (step > 0 ? 0 : count - 1)
        end
        insert(state)
        close(state)
        show(state)
        Outcome.none
      end

      private

      # Whether the command line is the `:` prompt: no palette, search, or
      # plugin prompt holds it.
      #: (Domain::EditorState) -> bool
      def colon_prompt?(state)
        state.mode == Domain::Mode::CMDLINE && !@palette.active && !@search_prompt.active && !@plugin_ui.prompting?
      end

      # The selection moved by step, the typed text (-1) between the last
      # match and the first.
      #: (Domain::CmdlineMenu, Integer) -> void
      def move(menu, step)
        count = menu.matches.length
        return if count == 0
        at = menu.selected + step
        at = -1 if at >= count
        at = count - 1 if at < -1
        menu.selected = at
      end

      # Fills the menu with the word before the cursor and its matches;
      # its start stays -1 when that word is not one completion knows.
      #: (Domain::EditorState) -> void
      def collect(state)
        menu = @menu
        menu.start = -1
        position = state.cmdline_position
        head = state.cmdline[0, position].to_s
        letters = letter_count(head)
        if letters == head.length
          menu.start = 0
          menu.typed = head
          collect_names(head)
          return
        end
        return if letters == 0
        at = letters
        # The name, the bang, and the blanks are ASCII, so a byte index
        # is a character index up to the argument.
        at += 1 if head.getbyte(at).to_i == 33
        blanks = at
        blanks += 1 while head.getbyte(blanks).to_i == 32
        return if blanks == at
        handler = @commands.find(head[0, letters].to_s)
        return if handler.nil?
        full = handler.name.full
        themes = full == "colorscheme"
        return unless themes || PATH_COMMANDS.include?(full)
        typed = head[blanks, head.length - blanks].to_s
        menu.start = blanks
        menu.typed = typed
        if themes
          collect_themes(typed)
        else
          collect_paths(typed)
        end
      end

      # The ASCII letters at the start of text.
      #: (String) -> Integer
      def letter_count(text)
        count = 0
        while count < text.length
          byte = text.getbyte(count).to_i
          break unless (byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122)
          count += 1
        end
        count
      end

      # The full command names the typed letters begin, in precedence order.
      #: (String) -> void
      def collect_names(typed)
        menu = @menu
        names = @commands.full_names
        i = 0
        while i < names.length
          name = names[i]
          if name.start_with?(typed)
            menu.matches << name
            menu.labels << name
          end
          i += 1
        end
      end

      # The shipped palette names the typed text begins, in their order.
      #: (String) -> void
      def collect_themes(typed)
        menu = @menu
        names = Domain::Themes::NAMES
        i = 0
        while i < names.length
          name = names[i]
          if name.start_with?(typed)
            menu.matches << name
            menu.labels << name
          end
          i += 1
        end
      end

      # The entries of the typed path's directory its last name begins,
      # each the directory part as typed and the entry, "/" after a
      # directory, labelled by the entry.
      #: (String) -> void
      def collect_paths(typed)
        menu = @menu
        cut = typed.rindex("/")
        part = cut.nil? ? "" : typed[0, cut + 1].to_s
        base = cut.nil? ? typed : typed[cut + 1, typed.length - cut - 1].to_s
        dir = directory_of(part)
        return if dir.empty?
        names = listing(dir)
        dotted = base.start_with?(".")
        i = 0
        while i < names.length
          name = names[i]
          if name.start_with?(base) && (dotted || !name.start_with?("."))
            label = @files.stat(joined(dir, name)).directory ? "#{name}/" : name
            menu.matches << part + label
            menu.labels << label
          end
          i += 1
        end
      end

      # The directory a typed directory part names: the working directory
      # for none, the part as typed from "/", under the home from "~/",
      # else below the working directory; "" with no home.
      #: (String) -> String
      def directory_of(part)
        return @files.cwd if part.empty?
        return part if part.start_with?("/")
        if part.start_with?("~/")
          home = @files.home
          return "" if home.empty?
          return home + part[1, part.length - 1].to_s
        end
        joined(@files.cwd, part)
      end

      #: (String, String) -> String
      def joined(dir, name)
        dir.end_with?("/") ? dir + name : "#{dir}/#{name}"
      end

      # At most MAX_ENTRIES names of the directory, none when it cannot be
      # read.
      #: (String) -> Array[String]
      def listing(dir)
        names = [""]
        names.clear
        begin
          names = @files.list_first(dir, MAX_ENTRIES)
        rescue StandardError
          return names
        end
        names
      end

      # Puts the selection, or the typed word, in place of the word before
      # the cursor, the text after it kept, and records the line it left.
      #: (Domain::EditorState) -> void
      def insert(state)
        menu = @menu
        text = menu.selected >= 0 ? menu.matches[menu.selected] : menu.typed
        line = state.cmdline
        position = state.cmdline_position
        state.cmdline = line[0, menu.start].to_s + text + line[position, line.length - position].to_s
        state.cmdline_position = menu.start + text.length
        menu.line = state.cmdline
        menu.position = state.cmdline_position
      end

      #: (Domain::EditorState) -> void
      def close(state)
        menu = @menu
        return if menu.float_id == 0
        @close_float.call(state, menu.float_id)
        menu.float_id = 0
      end

      # Opens the popup: a bordered menu at the bottom of the editor above
      # the command line, its text at the column of the word's last name,
      # the rows around the selection, none selected while the typed text
      # shows (the selection past the last row keeps the rows in Pmenu).
      #: (Domain::EditorState) -> void
      def show(state)
        menu = @menu
        room = state.screen_rows - 4
        return if room < 1 || state.screen_cols < 8
        labels = menu.labels
        rows = labels.empty? ? [EMPTY] : labels
        height = rows.length
        height = MAX_ROWS if height > MAX_ROWS
        height = room if height > room
        top = menu.selected - height + 1
        top = 0 if top < 0
        width = widest(rows)
        limit = Domain::FloatWindow.text_room(state.screen_cols, state.options.winborder)
        width = limit if width > limit
        lines = []
        r = top
        while r < top + height
          lines << Domain::DisplayWidth.cut(rows[r], width)
          r += 1
        end
        typed = menu.typed
        cut = typed.rindex("/")
        name_start = cut.nil? ? menu.start : menu.start + cut + 1
        col = 1 + Domain::DisplayWidth.text_width(state.cmdline[0, name_start].to_s, 0) - 1 - Domain::FloatWindow::PAD
        col = 0 if col < 0
        spec = Domain::FloatSpec.new(anchor: "editor", row: state.screen_rows, col: col, height: height, width: width, border: true, title: "", z: Z)
        buffer = Domain::Buffer.new(lines: lines, path: nil, line_ending: "\n")
        buffer.owner = Domain::CmdlineMenu::OWNER
        typed_length = cut.nil? ? typed.length : typed.length - cut - 1
        buffer.styles = styles(lines, top, typed_length) unless labels.empty? || typed_length == 0
        float = Domain::FloatWindow.new(window: Domain::Window.new(buffer: buffer), spec: spec)
        float.selected = menu.selected >= 0 ? menu.selected - top : lines.length
        return unless @open_float.call(state, float, false).ok
        menu.float_id = float.id
      end

      # The cells of the widest row, at least one.
      #: (Array[String]) -> Integer
      def widest(rows)
        width = 1
        i = 0
        while i < rows.length
          cells = Domain::DisplayWidth.text_width(rows[i], 0)
          width = cells if cells > width
          i += 1
        end
        width
      end

      # A style per row: its first typed_length characters, the typed
      # ones, in PmenuMatch, PmenuMatchSel on the selected row.
      #: (Array[String], Integer, Integer) -> Array[untyped]
      def styles(lines, top, typed_length)
        out = Array.new(0, nil)
        i = 0
        while i < lines.length
          group = top + i == @menu.selected ? Domain::Highlight::POPUP_MENU_MATCH_SELECTED : Domain::Highlight::POPUP_MENU_MATCH
          length = lines[i].length < typed_length ? lines[i].length : typed_length
          out << Domain::SyntaxLine.new(text: lines[i], start: 0, tokens: [0, length, group], end_state: 0)
          i += 1
        end
        out
      end
    end
  end
end
