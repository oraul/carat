require_relative "mode"
require_relative "options"
require_relative "selection"
require_relative "block_insert"
require_relative "tab_list"

module Carat
  module Domain
    # The current view the use cases and the presenter share: the tab
    # list, through which the current tab page, window, buffer, cursor, and
    # visual selection are reached, the mode, the options, the command
    # line, the message, the quit flag, and the repetition a blockwise
    # insert owes when insert mode is left, and the size of the screen
    # in rows and columns, 0 before the first render. The rest of the editor's state
    # lives in focused records the composition root hands to the use cases
    # that need them: the buffer list, the input state, the registers, the
    # last find, and the plugins' segments and prompt. A Struct record:
    # mutable, with a reader and a writer per member.
    class EditorState < Struct.new(:tabs, :mode, :options, :cmdline, :message, :message_error, :quit, :block_insert, :screen_rows, :screen_cols)
      # @rbs @tabs: TabList
      # @rbs @mode: Symbol
      # @rbs @options: Options
      # @rbs @cmdline: String
      # @rbs @message: String
      # @rbs @message_error: bool
      # @rbs @quit: bool
      # @rbs @block_insert: BlockInsert
      # @rbs @screen_rows: Integer
      # @rbs @screen_cols: Integer

      #: (TabList, Options) -> void
      def initialize(tabs, options)
        super()
        self.tabs = tabs
        self.mode = Mode::NORMAL
        self.options = options
        self.cmdline = ""
        self.message = ""
        self.message_error = false
        self.quit = false
        self.block_insert = BlockInsert.new
        self.screen_rows = 0
        self.screen_cols = 0
      end

      # Records the size of the screen.
      #: (Integer, Integer) -> void
      def resize(rows, cols)
        self.screen_rows = rows
        self.screen_cols = cols
      end

      # ------------------------------------------------------- current view

      #: () -> TabPage
      def tab
        tabs.tab
      end

      #: () -> Window
      def window
        tab.window
      end

      #: () -> Buffer
      def buffer
        window.buffer
      end

      #: () -> Cursor
      def cursor
        window.cursor
      end

      #: () -> String
      def current_line
        buffer.line(cursor.row)
      end

      # The largest column the cursor may occupy on a row in the current
      # mode: past the last character in insert mode and on the end of
      # the line in the visual modes, where it selects the line break, on
      # the last character otherwise.
      #: (Integer) -> Integer
      def max_col(row)
        len = buffer.line(row).length
        return len if mode == Mode::INSERT || Mode.visual?(mode)
        len > 0 ? len - 1 : 0
      end

      # ---------------------------------------------------------- selection

      # The visual selection of the current window: its anchor, its cursor,
      # the kind the mode gives, and whether "$" set the wanted column to
      # the line end. Outside the visual modes the kind is :none.
      #: () -> Selection
      def selection
        Selection.new(window.anchor, cursor.position, Mode.visual_kind(mode), cursor.want_col < 0)
      end

      # Leaves visual mode: the selection is stored on the window for
      # "gv", the mode returns to normal, and the cursor moves onto the
      # last character when it rested on the end of the line. Returns the
      # selection that was left.
      #: () -> Selection
      def end_visual
        current = selection
        window.last_selection = current
        self.mode = Mode::NORMAL
        c = cursor
        max = max_col(c.row)
        c.col = max if c.col > max
        current
      end

      # ----------------------------------------------------------- messages

      #: (String, bool) -> void
      def show(text, error)
        self.message = text
        self.message_error = error
      end

      #: () -> void
      def clear_message
        self.message = ""
        self.message_error = false
      end
    end
  end
end
