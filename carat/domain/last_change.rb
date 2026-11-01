require_relative "command"
require_relative "position"
require_relative "selection"
require_relative "buffer"
require_relative "display_width"

module Carat
  module Domain
    # The last change, which the dot command repeats: the command that
    # made it (nil before any change), the kind of the visual selection it
    # acted on (:none outside a visual mode) with the selection's size
    # (rows below the top; for a charwise selection on one line the
    # characters after the first, on several lines the end column; for a
    # block the display columns after the first, or the line ends when
    # to_end), and the insert session it opened, as steps: an action name
    # per step, "" for typed text, with the text in texts.
    #
    # recording is set while that session is open, restart after an arrow
    # key ended it (the next text typed starts a new change, "i" with that
    # text), and replaying while the dot command runs the change again, so
    # nothing is recorded twice. typed is the text of the current insert
    # session for the "." register. next_* hold the size of the selection
    # the command now running acts on, measured before it runs. A Struct
    # record: mutable, with a reader and a writer per member.
    class LastChange < Struct.new(:command, :visual, :rows, :cols, :to_end, :steps, :texts, :recording, :restart, :replaying, :typed, :next_visual, :next_rows, :next_cols, :next_to_end)
      # @rbs @command: Command?
      # @rbs @visual: Symbol
      # @rbs @rows: Integer
      # @rbs @cols: Integer
      # @rbs @to_end: bool
      # @rbs @steps: Array[String]
      # @rbs @texts: Array[String]
      # @rbs @recording: bool
      # @rbs @restart: bool
      # @rbs @replaying: bool
      # @rbs @typed: String
      # @rbs @next_visual: Symbol
      # @rbs @next_rows: Integer
      # @rbs @next_cols: Integer
      # @rbs @next_to_end: bool

      # No change yet. The lists are stored through the writers, so they
      # take the pinned type.
      #: () -> void
      def initialize
        super()
        self.command = nil
        self.visual = :none
        self.rows = 0
        self.cols = 0
        self.to_end = false
        self.steps = []
        self.texts = []
        self.recording = false
        self.restart = false
        self.replaying = false
        self.typed = ""
        self.next_visual = :none
        self.next_rows = 0
        self.next_cols = 0
        self.next_to_end = false
      end

      # Measures the selection the next command acts on.
      #: (Selection, Buffer, Integer) -> void
      def measure(selection, buffer, tabstop)
        kind = selection.kind
        self.next_visual = kind
        self.next_rows = selection.bottom - selection.top
        self.next_to_end = false
        if kind == :blockwise
          block = selection.block(buffer, tabstop)
          self.next_cols = block.right - block.left
          self.next_to_end = block.to_end
        elsif kind == :charwise
          self.next_cols = next_rows == 0 ? selection.finish.col - selection.start.col : selection.finish.col
        else
          self.next_cols = 0
        end
      end

      # The next command acts on no selection.
      #: () -> void
      def unmeasure
        self.next_visual = :none
      end

      # Records command as the last change, with the selection measured
      # for it, and no insert session yet.
      #: (Command) -> void
      def start(made)
        self.command = made
        self.visual = next_visual
        self.rows = next_rows
        self.cols = next_cols
        self.to_end = next_to_end
        self.next_visual = :none
        self.steps = []
        self.texts = []
        self.recording = false
        self.restart = false
      end

      # The change opened an insert session: what is typed now belongs to
      # it.
      #: () -> void
      def begin_session
        self.recording = true
        self.restart = false
        self.typed = ""
      end

      # Text typed in insert mode.
      #: (String) -> void
      def add_text(text)
        return if replaying
        self.typed = typed + text
        return unless resumed?
        last = steps.length - 1
        if last >= 0 && steps[last].empty?
          texts[last] = texts[last] + text
        else
          steps << ""
          texts << text
        end
      end

      # An insert-mode action: Enter, Backspace, Delete, or Tab, with the
      # text it put in the "." register's text ("" for none) and whether it
      # took the last typed character out.
      #: (String, String, bool) -> void
      def add_action(name, text, back)
        return if replaying
        if back
          self.typed = typed[0, typed.length - 1] unless typed.empty?
        else
          self.typed = typed + text
        end
        return unless resumed?
        steps << name
        texts << ""
      end

      # The insert session ended.
      #: () -> void
      def stop
        self.recording = false
        self.restart = false
      end

      # An arrow key ended the change in insert mode; text typed next is a
      # new change.
      #: () -> void
      def split
        self.recording = false
        self.restart = true
      end

      # The step at i, "" for typed text.
      #: (Integer) -> String
      def step_at(i)
        steps[i]
      end

      #: (Integer) -> String
      def text_at(i)
        texts[i]
      end

      private

      # Whether the session is recorded, starting the change "i" after an
      # arrow key.
      #: () -> bool
      def resumed?
        return true if recording
        return false unless restart
        self.next_visual = :none
        start(Command.plain("mode.insert"))
        self.recording = true
        true
      end
    end
  end
end
