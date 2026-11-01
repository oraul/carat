require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../../domain/mode"
require_relative "../../domain/position"
require_relative "../../domain/range"
require_relative "../../domain/selection"
require_relative "../../domain/display_width"
require_relative "../../domain/operators"
require_relative "../../domain/registers"
require_relative "../outcome"
require_relative "../operate"

module Carat
  module UseCases
    # Runs the operators and commands of visual mode on the selection.
    # Every entry point leaves visual mode first, which stores the
    # selection on the window for "gv", and then works on the selection it
    # left with normal-mode cursor rules: deletes, changes, and yanks write
    # the register named by the command, and the cursor and the mode end
    # where Neovim leaves them. The uppercase keys follow Neovim's v_visop:
    # X D Y C act on whole lines except in a block, where D and C reach the
    # end of every row and X and Y keep the block; S and R always change
    # whole lines. Deletes and changes write the registers by Vim's delete
    # rules (register 1 for whole lines or more than one line), yanks by
    # its yank rules, and naming a read-only register leaves visual mode
    # and refuses the command with E354.
    class OperateOnSelection
      attr_reader :registers #: Domain::Registers

      #: (registers: Domain::Registers) -> void
      def initialize(registers:)
        @registers = registers
      end

      # d, x, and <Del>.
      #: (Domain::EditorState, Domain::Command) -> Outcome
      def delete(state, command)
        selection = state.end_visual
        return Operate.read_only(command.register) if Domain::Registers.read_only?(command.register)
        remove(state, command.register, selection)
        Outcome.none
      end

      # X (to_end false) and D (to_end true).
      #: (Domain::EditorState, Domain::Command, bool) -> Outcome
      def delete_lines(state, command, to_end)
        selection = state.end_visual
        return Operate.read_only(command.register) if Domain::Registers.read_only?(command.register)
        remove(state, command.register, lines_or_block(selection, to_end))
        Outcome.none
      end

      #: (Domain::EditorState, Domain::Command) -> Outcome
      def yank(state, command)
        selection = state.end_visual
        return Operate.read_only(command.register) if Domain::Registers.read_only?(command.register)
        copy(state, command.register, selection)
        Outcome.none
      end

      # Y.
      #: (Domain::EditorState, Domain::Command) -> Outcome
      def yank_lines(state, command)
        selection = state.end_visual
        return Operate.read_only(command.register) if Domain::Registers.read_only?(command.register)
        copy(state, command.register, lines_or_block(selection, false))
        Outcome.none
      end

      # c and s.
      #: (Domain::EditorState, Domain::Command) -> Outcome
      def change(state, command)
        selection = state.end_visual
        return Operate.read_only(command.register) if Domain::Registers.read_only?(command.register)
        alter(state, command.register, selection)
        Outcome.none
      end

      # S and R (to_end false) change whole lines in every kind; C (to_end
      # true) changes a block to the end of every row and whole lines
      # otherwise.
      #: (Domain::EditorState, Domain::Command, bool) -> Outcome
      def change_lines(state, command, to_end)
        selection = state.end_visual
        return Operate.read_only(command.register) if Domain::Registers.read_only?(command.register)
        if to_end && selection.kind == :blockwise
          alter(state, command.register, selection.as(:blockwise, true))
        else
          alter(state, command.register, selection.as(:linewise, false))
        end
        Outcome.none
      end

      # > (direction 1) and < (direction -1), count steps of shiftwidth.
      #: (Domain::EditorState, Domain::Command, Integer) -> Outcome
      def shift(state, command, direction)
        selection = state.end_visual
        amount = command.count_or(1) * direction
        options = state.options
        buffer = state.buffer
        cursor = state.cursor
        if selection.kind == :blockwise
          tabstop = tabstop_of(state)
          block = selection.block(buffer, tabstop)
          col = block.span(buffer.line(block.top), tabstop).from
          Domain::Operators.shift_block(buffer, block, amount, options.shiftwidth, tabstop)
          cursor.move_to(block.top, clamp(state, block.top, col))
          return Outcome.none
        end
        top = selection.top
        Domain::Operators.shift(buffer, top, selection.bottom, amount, options.shiftwidth, options.tabstop, options.expandtab)
        cursor.move_to(top, buffer.first_nonblank(top))
        Outcome.none
      end

      # J (spaces true) and gJ (spaces false): the selected rows, at least
      # two.
      #: (Domain::EditorState, Domain::Command, bool) -> Outcome
      def join(state, command, spaces)
        selection = state.end_visual
        buffer = state.buffer
        top = selection.top
        return Outcome.none if top >= buffer.line_count - 1
        count = selection.bottom - top + 1
        count = 2 if count < 2
        col = Domain::Operators.join(buffer, top, count, spaces)
        state.cursor.move_to(top, clamp(state, top, col))
        Outcome.none
      end

      # ~ (:toggle), u (:lower), U (:upper), and r{char} (:replace) over
      # every selected character; the cursor goes to the start.
      #: (Domain::EditorState, Domain::Command, Symbol) -> Outcome
      def recase(state, command, how)
        selection = state.end_visual
        buffer = state.buffer
        tabstop = tabstop_of(state)
        top = selection.top
        home = selection.start
        if selection.kind == :linewise
          home = selection.line_start
        elsif selection.kind == :blockwise
          home = Domain::Position.new(top, selection.span(buffer, top, tabstop).from)
        end
        lines = []
        row = top
        while row <= selection.bottom
          line = buffer.line(row)
          span = selection.span(buffer, row, tabstop)
          lines << line[0, span.from] + Domain::Operators.recase(line[span.from, span.to - span.from], how, command.char) + line[span.to, line.length - span.to]
          row += 1
        end
        buffer.set_lines(top, selection.bottom + 1, lines)
        state.cursor.move_to(home.row, clamp(state, home.row, home.col))
        Outcome.none
      end

      # I (append false) and A (append true): before the start or after the
      # end of the selection; in a block, on the top row, with the typed
      # text repeated on the other rows when insert mode is left.
      #: (Domain::EditorState, Domain::Command, bool) -> Outcome
      def insert(state, command, append)
        selection = state.end_visual
        if selection.kind == :blockwise
          insert_block(state, selection, append)
          return Outcome.none
        end
        buffer = state.buffer
        row = selection.bottom
        col = buffer.line(row).length
        unless append
          start = selection.line_start
          row = start.row
          col = start.col
        end
        state.mode = Domain::Mode::INSERT
        len = buffer.line(row).length
        state.cursor.move_to(row, col > len ? len : col)
        Outcome.none
      end

      # p (keep false) and P (keep true): the selection is replaced by the
      # register, read before anything is removed; p stores the removed
      # text in the unnamed register, P leaves every register alone.
      #: (Domain::EditorState, Domain::Command, bool) -> Outcome
      def put(state, command, keep)
        entry = @registers.read_with_file(command.register, state.buffer.path_text)
        selection = state.end_visual
        if entry.nil?
          name = command.register.empty? ? "\"" : command.register
          return Outcome.failure("E353: Nothing in register #{name}")
        end
        replace_with(state, selection, entry, command.count_or(1), keep)
        Outcome.none
      end

      private

      #: (Domain::EditorState) -> Integer
      def tabstop_of(state)
        state.options.tabstop > 0 ? state.options.tabstop : 8
      end

      #: (Domain::EditorState, Integer, Integer) -> Integer
      def clamp(state, row, col)
        max = state.max_col(row)
        col > max ? max : col
      end

      # The selection an uppercase key acts on: whole lines, or in a block
      # the block itself, reaching every row's end with to_end.
      #: (Domain::Selection, bool) -> Domain::Selection
      def lines_or_block(selection, to_end)
        return selection.as(:blockwise, selection.to_end || to_end) if selection.kind == :blockwise
        selection.as(:linewise, false)
      end

      #: (Domain::EditorState, String, Domain::Selection) -> void
      def remove(state, register, selection)
        @registers.delete(register, cut(state, selection), big?(selection))
      end

      # Whether a delete of the selection goes to register 1: whole lines
      # or more than one line.
      #: (Domain::Selection) -> bool
      def big?(selection)
        selection.kind == :linewise || selection.top != selection.bottom
      end

      # Deletes the selection and returns what it held, leaving the cursor
      # at the start of a charwise selection, on the first non-blank of the
      # top row for a linewise one, and on the block's top-left.
      #: (Domain::EditorState, Domain::Selection) -> Domain::RegisterEntry
      def cut(state, selection)
        buffer = state.buffer
        cursor = state.cursor
        if selection.kind == :linewise
          range = selection.line_range
          entry = Domain::Operators.extract(buffer, range)
          Domain::Operators.delete(buffer, range)
          row = selection.top
          row = buffer.line_count - 1 if row > buffer.line_count - 1
          cursor.move_to(row, buffer.first_nonblank(row))
          return entry
        end
        if selection.kind == :blockwise
          tabstop = tabstop_of(state)
          block = selection.block(buffer, tabstop)
          col = block.span(buffer.line(block.top), tabstop).from
          entry = Domain::Operators.extract_block(buffer, block, tabstop)
          Domain::Operators.delete_block(buffer, block, tabstop)
          cursor.move_to(block.top, clamp(state, block.top, col))
          return entry
        end
        range = selection.char_range(buffer)
        entry = Domain::Operators.extract(buffer, range)
        Domain::Operators.delete(buffer, range)
        from = range.from
        cursor.move_to(from.row, clamp(state, from.row, from.col))
        entry
      end

      # Copies the selection into the register; the cursor goes to the
      # start of a charwise selection, the start of a linewise operand, or
      # the block's top-left.
      #: (Domain::EditorState, String, Domain::Selection) -> void
      def copy(state, register, selection)
        buffer = state.buffer
        cursor = state.cursor
        if selection.kind == :linewise
          @registers.yank(register, Domain::Operators.extract(buffer, selection.line_range))
          start = selection.line_start
          cursor.move_to(start.row, clamp(state, start.row, start.col))
        elsif selection.kind == :blockwise
          tabstop = tabstop_of(state)
          block = selection.block(buffer, tabstop)
          col = block.span(buffer.line(block.top), tabstop).from
          @registers.yank(register, Domain::Operators.extract_block(buffer, block, tabstop))
          cursor.move_to(block.top, clamp(state, block.top, col))
        else
          @registers.yank(register, Domain::Operators.extract(buffer, selection.char_range(buffer)))
          start = selection.start
          cursor.move_to(start.row, clamp(state, start.row, start.col))
        end
      end

      # Deletes the selection into the register and enters insert mode: at
      # the start, on one line keeping the top row's indent with
      # autoindent, or at the block's top-left with the text to be repeated
      # on the rows that reach the block.
      #: (Domain::EditorState, String, Domain::Selection) -> void
      def alter(state, register, selection)
        buffer = state.buffer
        cursor = state.cursor
        if selection.kind == :linewise
          top = selection.top
          @registers.delete(register, Domain::Operators.extract(buffer, selection.line_range), true)
          indent = state.options.autoindent ? buffer.indent_of(top) : ""
          buffer.set_lines(top, selection.bottom + 1, [indent])
          state.mode = Domain::Mode::INSERT
          cursor.move_to(top, indent.length)
          return
        end
        if selection.kind == :blockwise
          tabstop = tabstop_of(state)
          block = selection.block(buffer, tabstop)
          rows = reaching_rows(buffer, block, tabstop)
          col = block.span(buffer.line(block.top), tabstop).from
          remove(state, register, selection)
          line = buffer.line(block.top)
          state.mode = Domain::Mode::INSERT
          col = line.length if col > line.length
          cursor.move_to(block.top, col)
          state.block_insert.start(:change, block.top, col, line.length, buffer.line_count, rows, block.left, -1)
          return
        end
        range = selection.char_range(buffer)
        @registers.delete(register, Domain::Operators.extract(buffer, range), big?(selection))
        Domain::Operators.delete(buffer, range)
        state.mode = Domain::Mode::INSERT
        cursor.move_to(range.from.row, range.from.col)
      end

      # The rows of a block below its top row whose text reaches it.
      #: (Domain::Buffer, Domain::Block, Integer) -> Array[Integer]
      def reaching_rows(buffer, block, tabstop)
        rows = []
        row = block.top + 1
        while row <= block.bottom
          rows << row unless block.short?(buffer.line(row), tabstop)
          row += 1
        end
        rows
      end

      # Block I and A: insert mode on the top row before the block, after
      # it (padding a short top row), or at the row's end after "$", with
      # the repetition recorded for leaving insert mode.
      #: (Domain::EditorState, Domain::Selection, bool) -> void
      def insert_block(state, selection, append)
        buffer = state.buffer
        tabstop = tabstop_of(state)
        block = selection.block(buffer, tabstop)
        top = block.top
        line = buffer.line(top)
        home = block.span(line, tabstop).from
        kind = :insert
        vcol = block.left
        rows = reaching_rows(buffer, block, tabstop)
        col = Domain::DisplayWidth.col_at(line, vcol, tabstop)
        if append
          rows = []
          row = top + 1
          while row <= block.bottom
            rows << row
            row += 1
          end
          if block.to_end
            kind = :append_end
            col = line.length
          else
            kind = :append
            vcol = block.right + 1
            width = Domain::DisplayWidth.column(line, line.length, tabstop)
            if width < vcol
              line = line + (" " * (vcol - width))
              buffer.set_lines(top, top + 1, [line])
            end
            col = Domain::DisplayWidth.col_at(line, vcol, tabstop)
          end
        end
        state.mode = Domain::Mode::INSERT
        state.cursor.move_to(top, col)
        state.block_insert.start(kind, top, col, line.length, buffer.line_count, rows, vcol, home)
      end

      # The selection removed and the register put in its place, as
      # Neovim's nv_put does in visual mode.
      #: (Domain::EditorState, Domain::Selection, Domain::RegisterEntry, Integer, bool) -> void
      def replace_with(state, selection, entry, count, keep)
        buffer = state.buffer
        tabstop = tabstop_of(state)
        line_count = buffer.line_count
        block = selection.block(buffer, tabstop)
        top_col = block.span(buffer.line(block.top), tabstop).from
        from = selection.char_range(buffer).from
        removed = cut(state, selection)
        @registers.delete("", removed, big?(selection)) unless keep
        if selection.kind == :linewise
          put_lines(state, selection, entry, count, line_count)
        elsif selection.kind == :blockwise
          put_in_block(state, block, top_col, entry, count, keep)
        else
          put_at(state, from, entry, count)
        end
      end

      # A register as whole lines in place of the removed rows; when every
      # row was removed, the empty line left behind is replaced too.
      #: (Domain::EditorState, Domain::Selection, Domain::RegisterEntry, Integer, Integer) -> void
      def put_lines(state, selection, entry, count, line_count)
        buffer = state.buffer
        lines = repeated(entry.lines, count)
        top = selection.top
        if top == 0 && selection.bottom == line_count - 1
          buffer.set_lines(0, 1, lines)
        else
          buffer.set_lines(top, top, lines)
        end
        state.cursor.move_to(top, buffer.first_nonblank(top))
      end

      # A register where a block was: a block in its place, one line of
      # text on every row, lines below the block for p and above it for P,
      # or other text before the block's top-left.
      #: (Domain::EditorState, Domain::Block, Integer, Domain::RegisterEntry, Integer, bool) -> void
      def put_in_block(state, block, top_col, entry, count, keep)
        buffer = state.buffer
        tabstop = tabstop_of(state)
        if entry.blockwise?
          place(state, Domain::Operators.put_block(buffer, block.top, block.left, entry, count, tabstop))
        elsif entry.linewise?
          row = keep ? block.top : block.bottom
          place(state, Domain::Operators.put(buffer, Domain::Position.new(row, 0), entry, count, !keep))
        elsif entry.lines.length == 1
          rows = []
          row = block.top
          while row <= block.bottom
            rows << entry.text
            row += 1
          end
          place(state, Domain::Operators.put_block(buffer, block.top, block.left, Domain::RegisterEntry.block(rows), count, tabstop))
        else
          place(state, Domain::Operators.put(buffer, Domain::Position.new(block.top, top_col), entry, count, false))
        end
      end

      # A register at the start of a removed charwise selection: lines
      # split the line there, a block goes at its display column, and text
      # goes before it.
      #: (Domain::EditorState, Domain::Position, Domain::RegisterEntry, Integer) -> void
      def put_at(state, from, entry, count)
        buffer = state.buffer
        line = buffer.line(from.row)
        col = from.col > line.length ? line.length : from.col
        if entry.linewise?
          parts = [line[0, col]]
          parts.concat(repeated(entry.lines, count))
          parts << line[col, line.length - col]
          buffer.set_lines(from.row, from.row + 1, parts)
          state.cursor.move_to(from.row + 1, buffer.first_nonblank(from.row + 1))
        elsif entry.blockwise?
          tabstop = tabstop_of(state)
          place(state, Domain::Operators.put_block(buffer, from.row, Domain::DisplayWidth.column(line, col, tabstop), entry, count, tabstop))
        else
          place(state, Domain::Operators.put(buffer, Domain::Position.new(from.row, col), entry, count, false))
        end
      end

      #: (Domain::EditorState, Domain::Position) -> void
      def place(state, pos)
        state.cursor.move_to(pos.row, clamp(state, pos.row, pos.col))
      end

      # lines count times over.
      #: (Array[String], Integer) -> Array[String]
      def repeated(lines, count)
        result = []
        i = 0
        while i < count
          result.concat(lines)
          i += 1
        end
        result
      end
    end
  end
end
