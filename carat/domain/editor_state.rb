module Carat
  module Domain
    # Everything a use case reads or changes: the buffer list, the tab pages
    # and which is current, the mode, the options, the command line, the
    # message, the keys pending in the keymap, the quit flag, the registers,
    # the command grammar with the keys of the command being typed, the
    # last f/t motion for ";" and ",", and the status line segments the
    # plugins set, by plugin name in registration order, and the prompt a
    # plugin opened on the command line (its text, the plugin, and the
    # plugin's id for it, all "" when none is open), and the repetition a
    # blockwise insert owes when insert mode is left. The current window,
    # its buffer, and its cursor are reached through the current tab page,
    # and so is the visual selection, which the current window owns. A
    # Struct record: mutable, with a reader and a writer per member.
    class EditorState < Struct.new(:buffers, :tabs, :tab_index, :mode, :options, :timeoutlen, :cmdline, :message, :message_error, :pending_keys, :quit, :registers, :grammar, :last_find, :segments, :prompt, :prompt_owner, :prompt_id, :block_insert)
      # @rbs @buffers: Array[untyped]
      # @rbs @tabs: Array[untyped]
      # @rbs @tab_index: Integer
      # @rbs @mode: Symbol
      # @rbs @options: Options
      # @rbs @timeoutlen: Integer
      # @rbs @cmdline: String
      # @rbs @message: String
      # @rbs @message_error: bool
      # @rbs @pending_keys: Array[Integer]
      # @rbs @quit: bool
      # @rbs @registers: Registers
      # @rbs @grammar: CommandGrammar
      # @rbs @last_find: Find?
      # @rbs @segments: Hash[String, String]
      # @rbs @prompt: String
      # @rbs @prompt_owner: String
      # @rbs @prompt_id: String
      # @rbs @block_insert: BlockInsert

      # The lists are stored through the writers, not passed to super, so
      # their element type is the pinned one; the rest follows for symmetry.
      #: (Buffer, Options, Integer) -> void
      def initialize(buffer, options, timeoutlen)
        super()
        self.buffers = []
        self.tabs = []
        buffers << buffer
        tabs << TabPage.new(Window.new(buffer))
        self.tab_index = 0
        self.mode = Mode::NORMAL
        self.options = options
        self.timeoutlen = timeoutlen
        self.cmdline = ""
        self.message = ""
        self.message_error = false
        self.pending_keys = []
        self.quit = false
        self.registers = Registers.new
        self.grammar = CommandGrammar.new
        self.last_find = nil
        self.segments = {}
        self.prompt = ""
        self.prompt_owner = ""
        self.prompt_id = ""
        self.block_insert = BlockInsert.new
      end

      # Whether a plugin's prompt holds the command line.
      #: () -> bool
      def prompting?
        !prompt_owner.empty?
      end

      # ------------------------------------------------------- current view

      #: () -> TabPage
      def tab
        tab_at(tab_index)
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

      # The keys of the command being typed, for the pending-keys display:
      # what the grammar has taken plus what the keymap is still waiting on.
      #: () -> String
      def showcmd
        text = grammar.typed
        keys = pending_keys
        i = 0
        while i < keys.length
          text = text + CommandGrammar.display(keys[i])
          i += 1
        end
        text
      end

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

      # -------------------------------------------------------- buffer list

      #: (Integer) -> Buffer
      def buffer_at(index)
        buffers[index]
      end

      #: () -> Integer
      def buffer_count
        buffers.length
      end

      # The position of a buffer in the list by identity, or -1. Identity,
      # not value: two unnamed empty buffers are equal by value.
      #: (Buffer) -> Integer
      def buffer_index(target)
        i = 0
        while i < buffers.length
          return i if buffer_at(i).equal?(target)
          i += 1
        end
        -1
      end

      # The listed buffer with that path, or nil.
      #: (String) -> Buffer?
      def buffer_for(path)
        i = 0
        while i < buffers.length
          candidate = buffer_at(i)
          return candidate if candidate.path == path
          i += 1
        end
        nil
      end

      # Whether some window of some tab page shows the buffer.
      #: (Buffer) -> bool
      def shown?(target)
        t = 0
        while t < tabs.length
          layout = tab_at(t).layout
          ids = layout.leaves
          i = 0
          while i < ids.length
            return true if layout.window_at(ids[i]).buffer.equal?(target)
            i += 1
          end
          t += 1
        end
        false
      end

      # The first modified buffer in the list, or nil. A scratch buffer is
      # never unsaved work, however its lines changed.
      #: () -> Buffer?
      def modified_buffer
        i = 0
        while i < buffers.length
          candidate = buffer_at(i)
          return candidate if candidate.modified && !candidate.scratch?
          i += 1
        end
        nil
      end

      #: () -> bool
      def any_modified?
        !modified_buffer.nil?
      end

      # The first modified buffer no window shows, or nil.
      #: () -> Buffer?
      def hidden_modified
        i = 0
        while i < buffers.length
          candidate = buffer_at(i)
          return candidate if candidate.modified && !candidate.scratch? && !shown?(candidate)
          i += 1
        end
        nil
      end

      # Keeps every cursor on the buffer inside its text after the buffer
      # was replaced in place.
      #: (Buffer) -> void
      def clamp_cursors(target)
        t = 0
        while t < tabs.length
          layout = tab_at(t).layout
          ids = layout.leaves
          i = 0
          while i < ids.length
            window = layout.window_at(ids[i])
            if window.buffer.equal?(target)
              cursor = window.cursor
              last = target.line_count - 1
              cursor.row = last if cursor.row > last
              max = target.line(cursor.row).length
              max = max > 0 ? max - 1 : 0
              cursor.col = max if cursor.col > max
              window.top = 0 if window.top > last
            end
            i += 1
          end
          t += 1
        end
      end

      #: (Buffer) -> void
      def add_buffer(target)
        buffers << target if buffer_index(target) < 0
      end

      #: (Buffer) -> void
      def drop_buffer(target)
        index = buffer_index(target)
        buffers.delete_at(index) if index >= 0
      end

      # Lets go of a buffer a window stopped showing: it leaves the list
      # when it is unmodified and no window shows it, and stays hidden in
      # the list otherwise, so no edit is lost. A scratch buffer leaves as
      # soon as no window shows it.
      #: (Buffer) -> void
      def release(target)
        drop_buffer(target) if (!target.modified || target.scratch?) && !shown?(target)
      end

      # The 1-based list position of a buffer, or 0 when it is not listed.
      #: (Buffer) -> Integer
      def buffer_number(target)
        buffer_index(target) + 1
      end

      # The listed scratch buffer a plugin owns with that title, or nil.
      #: (String, String) -> Buffer?
      def scratch_for(owner, title)
        i = 0
        while i < buffers.length
          candidate = buffer_at(i)
          return candidate if candidate.owner == owner && candidate.title == title
          i += 1
        end
        nil
      end

      # Shows a buffer in the current window, listing it if needed. The
      # buffer the window showed leaves the list when no window shows it any
      # more; the callers make sure it is unmodified or that its changes
      # were discarded on purpose.
      #: (Buffer) -> void
      def load(target)
        old = window.buffer
        add_buffer(target)
        window.show(target)
        drop_buffer(old) unless old.equal?(target) || shown?(old)
      end

      # ------------------------------------------------------------ windows

      #: () -> Integer
      def window_count
        tab.window_count
      end

      # The number of windows over every tab page.
      #: () -> Integer
      def total_windows
        total = 0
        t = 0
        while t < tabs.length
          total += tab_at(t).window_count
          t += 1
        end
        total
      end

      # ---------------------------------------------------------- tab pages

      #: (Integer) -> TabPage
      def tab_at(index)
        tabs[index]
      end

      #: () -> Integer
      def tab_count
        tabs.length
      end

      # Inserts a tab page after the current one and makes it current.
      #: (TabPage) -> void
      def add_tab(page)
        tabs.insert(tab_index + 1, page)
        self.tab_index = tab_index + 1
      end

      # Removes the tab page at index. When it was the current one, the one
      # after it becomes current, or the one before it when it was last, as
      # Neovim's alt_tabpage picks; otherwise the current one stays current.
      #: (Integer) -> void
      def remove_tab(index)
        tabs.delete_at(index)
        self.tab_index = tab_index - 1 if index < tab_index
        self.tab_index = tabs.length - 1 if tab_index > tabs.length - 1
      end

      # Goes to tab page number n (1-based) when it exists; with 0, to the
      # next one, wrapping. Returns whether the current tab page changed.
      #: (Integer) -> bool
      def next_tab(n)
        if n == 0
          self.tab_index = (tab_index + 1) % tabs.length
          return true
        end
        return false if n > tabs.length
        self.tab_index = n - 1
        true
      end

      # Goes n tab pages back, wrapping; 0 counts as 1.
      #: (Integer) -> void
      def previous_tab(n)
        steps = n > 0 ? n : 1
        self.tab_index = (tab_index - steps) % tabs.length
      end
    end
  end
end
