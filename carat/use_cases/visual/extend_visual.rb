require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../../domain/mode"
require_relative "../../domain/position"
require_relative "../../domain/range"
require_relative "../../domain/display_width"
require_relative "../../domain/text_objects"

module Carat
  module UseCases
    # Changes the selection without editing: "o" and "O" move to the other
    # end or corner, and the text objects select or extend. Motions need
    # nothing here: Move moves the cursor end and the anchor stays.
    class ExtendVisual
      EXTENDING = ["textobject.inner_word", "textobject.a_word", "textobject.inner_big_word", "textobject.a_big_word", "textobject.inner_sentence", "textobject.a_sentence"]
      PARAGRAPHS = ["textobject.inner_paragraph", "textobject.a_paragraph"]
      MAX_LEVELS = 20

      # "o": the anchor and the cursor change places.
      #: (Domain::EditorState) -> void
      def swap_ends(state)
        window = state.window
        cursor = state.cursor
        anchor = window.anchor
        window.anchor = cursor.position
        cursor.move_to(anchor.row, anchor.col)
      end

      # "O": in a block, the cursor goes to the other corner on its row and
      # the anchor to the opposite column on its own, as Neovim's
      # v_swap_corners; in the other kinds, as "o".
      #: (Domain::EditorState) -> void
      def swap_corner(state)
        unless state.mode == Domain::Mode::VISUAL_BLOCK
          swap_ends(state)
          return
        end
        tabstop = tabstop_of(state)
        buffer = state.buffer
        window = state.window
        cursor = state.cursor
        anchor = window.anchor
        block = state.selection.block(buffer, tabstop)
        anchor_line = buffer.line(anchor.row)
        cursor_line = buffer.line(cursor.row)
        anchor_col = Domain::DisplayWidth.col_at(anchor_line, block.left, tabstop)
        cursor_col = Domain::DisplayWidth.col_at(cursor_line, block.right, tabstop)
        if cursor_col == cursor.col
          anchor_col = Domain::DisplayWidth.col_at(anchor_line, block.right, tabstop)
          cursor_col = Domain::DisplayWidth.col_at(cursor_line, block.left, tabstop)
        end
        window.anchor = Domain::Position.new(anchor.row, anchor_col)
        cursor.move_to(cursor.row, cursor_col)
      end

      # A text object in a visual mode: on a selection of one character
      # (one row for a paragraph) the object is selected; on a larger one
      # word, sentence, and paragraph objects extend the cursor end, and
      # the enclosing objects select the smallest larger object.
      #: (Domain::EditorState, Domain::Command) -> void
      def text_object(state, command)
        action = command.action
        n = command.count_or(1)
        anchor = state.window.anchor
        head = state.cursor.position
        if PARAGRAPHS.include?(action)
          if anchor.row == head.row
            select_at(state, action, n, head)
          else
            extend_lines(state, action, n, !head.before?(anchor))
          end
        elsif EXTENDING.include?(action)
          if anchor == head
            select_at(state, action, n, head)
          else
            extend_chars(state, action, n, !head.before?(anchor))
          end
        else
          enclose(state, action, n, anchor == head)
        end
      end

      private

      #: (Domain::EditorState) -> Integer
      def tabstop_of(state)
        state.options.tabstop > 0 ? state.options.tabstop : 8
      end

      # The object the action finds with the cursor at pos; the cursor is
      # put back, because the text objects read it.
      #: (Domain::EditorState, String, Integer, Domain::Position) -> Domain::Range?
      def object_at(state, action, n, pos)
        cursor = state.cursor
        row = cursor.row
        col = cursor.col
        want = cursor.want_col
        cursor.row = pos.row
        cursor.col = pos.col
        range = Domain::TextObjects.call(state, action, n)
        cursor.row = row
        cursor.col = col
        cursor.want_col = want
        range
      end

      #: (Domain::EditorState, String, Integer, Domain::Position) -> void
      def select_at(state, action, n, pos)
        range = object_at(state, action, n, pos)
        return if range.nil?
        select(state, range)
      end

      # Makes range the selection: a linewise range turns the selection
      # linewise from column 0, a charwise one turns a linewise selection
      # charwise and ends on its last character.
      #: (Domain::EditorState, Domain::Range) -> void
      def select(state, range)
        window = state.window
        cursor = state.cursor
        if range.kind == :linewise
          state.mode = Domain::Mode::VISUAL_LINE
          window.anchor = Domain::Position.new(range.from.row, 0)
          cursor.move_to(range.to.row, 0)
          return
        end
        state.mode = Domain::Mode::VISUAL if state.mode == Domain::Mode::VISUAL_LINE
        window.anchor = Domain::Position.new(range.from.row, range.from.col)
        last = last_of(state.buffer, range)
        cursor.move_to(last.row, last.col)
      end

      # The last selected position of a range: its end for an inclusive
      # range, the character before an exclusive end, or the end of the
      # previous line, which selects its line break, when the end is at
      # the start of a line.
      #: (Domain::Buffer, Domain::Range) -> Domain::Position
      def last_of(buffer, range)
        from = range.from
        to = range.to
        return Domain::Position.new(to.row, buffer.line(to.row).length) if range.kind == :linewise
        return Domain::Position.new(to.row, to.col) if range.inclusive
        return Domain::Position.new(to.row, to.col - 1) if to.col > 0
        return Domain::Position.new(to.row - 1, buffer.line(to.row - 1).length) if to.row > from.row
        Domain::Position.new(from.row, from.col)
      end

      # The position one character after pos, crossing to the next line,
      # or pos itself at the end of the buffer.
      #: (Domain::Buffer, Domain::Position) -> Domain::Position
      def after(buffer, pos)
        return Domain::Position.new(pos.row, pos.col + 1) if pos.col + 1 < buffer.line(pos.row).length
        return Domain::Position.new(pos.row + 1, 0) if pos.row < buffer.line_count - 1
        pos
      end

      # The position one character before pos, crossing to the end of the
      # previous line, or pos itself at the start of the buffer.
      #: (Domain::Buffer, Domain::Position) -> Domain::Position
      def before(buffer, pos)
        return Domain::Position.new(pos.row, pos.col - 1) if pos.col > 0
        if pos.row > 0
          len = buffer.line(pos.row - 1).length
          return Domain::Position.new(pos.row - 1, len > 0 ? len - 1 : 0)
        end
        pos
      end

      # Word and sentence objects over a larger selection: the cursor end
      # moves over count more objects in its direction.
      #: (Domain::EditorState, String, Integer, bool) -> void
      def extend_chars(state, action, n, forward)
        buffer = state.buffer
        head = state.cursor.position
        pos = forward ? after(buffer, head) : before(buffer, head)
        return if pos == head
        range = object_at(state, action, n, pos)
        return if range.nil?
        state.mode = Domain::Mode::VISUAL if state.mode == Domain::Mode::VISUAL_LINE
        move_end(state, range, forward)
      end

      #: (Domain::EditorState, Domain::Range, bool) -> void
      def move_end(state, range, forward)
        cursor = state.cursor
        if forward
          last = last_of(state.buffer, range)
          cursor.move_to(last.row, last.col)
        else
          cursor.move_to(range.from.row, range.from.col)
        end
      end

      # Paragraph objects over several rows: the cursor end moves over
      # count more paragraphs, and the selection becomes linewise.
      #: (Domain::EditorState, String, Integer, bool) -> void
      def extend_lines(state, action, n, forward)
        buffer = state.buffer
        row = state.cursor.row + (forward ? 1 : -1)
        return if row < 0 || row > buffer.line_count - 1
        range = object_at(state, action, n, Domain::Position.new(row, 0))
        return if range.nil?
        state.mode = Domain::Mode::VISUAL_LINE
        state.cursor.move_to(forward ? range.to.row : range.from.row, 0)
      end

      # Bracket and quote objects: on one character the count-th object;
      # on a larger selection the first object, counting outward from the
      # count-th, that is strictly larger than the selection, or nothing.
      #: (Domain::EditorState, String, Integer, bool) -> void
      def enclose(state, action, n, single)
        selection = state.selection
        start = selection.start
        finish = selection.finish
        level = n
        tries = 0
        while tries < MAX_LEVELS
          range = object_at(state, action, level, start)
          return if range.nil?
          if single || larger?(state.buffer, range, start, finish)
            select(state, range)
            return
          end
          level += 1
          tries += 1
        end
      end

      # Whether range covers from start to finish and more.
      #: (Domain::Buffer, Domain::Range, Domain::Position, Domain::Position) -> bool
      def larger?(buffer, range, start, finish)
        first = range.kind == :linewise ? Domain::Position.new(range.from.row, 0) : range.from
        last = last_of(buffer, range)
        return false if start.before?(first) || last.before?(finish)
        first != start || last != finish
      end
    end
  end
end
