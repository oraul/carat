require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../../domain/position"
require_relative "../../domain/selection"
require_relative "../../domain/block"
require_relative "../../domain/operators"
require_relative "../../domain/registers"
require_relative "../../domain/register_entry"
require_relative "../../domain/selection_cut"
require_relative "../../domain/display_width"
require_relative "../../domain/messages"
require_relative "../outcome"

module Carat
  module UseCases
    # Visual p (keep false) and P (keep true): leaves visual mode and
    # replaces the selection by the register, read before anything is
    # removed, as Neovim's nv_put does in visual mode; p stores the
    # removed text in the unnamed register, P leaves every register
    # alone. E353 when the register is empty.
    class PutOverSelection
      attr_reader :registers #: Domain::Registers

      #: (registers: Domain::Registers) -> void
      def initialize(registers:)
        @registers = registers
      end

      #: (Domain::EditorState, Domain::Command, bool) -> Outcome
      def call(state, command, keep)
        entry = @registers.read_with_file(command.register, state.buffer.path_text)
        selection = state.end_visual
        return Outcome.failure(Domain::Messages.nothing_in_register(command.register)) if entry.nil?
        count = command.count_or(1)
        buffer = state.buffer
        tabstop = state.options.tab_width
        line_count = buffer.line_count
        block = selection.block(buffer, tabstop)
        top_col = block.span(buffer.line(block.top), tabstop).from
        from = selection.char_range(buffer).from
        removed = Domain::SelectionCut.call(state, selection)
        @registers.delete("", removed, selection.numbered_delete?) unless keep
        if selection.kind == :linewise
          put_lines(state, selection, entry, count, line_count)
        elsif selection.kind == :blockwise
          put_in_block(state, block, top_col, entry, count, keep)
        else
          put_at(state, from, entry, count)
        end
        Outcome.none
      end

      private

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
        tabstop = state.options.tab_width
        if entry.blockwise?
          place(state, Domain::Operators.put_block(buffer, block.top, block.left, entry, count, tabstop))
        elsif entry.linewise?
          row = keep ? block.top : block.bottom
          place(state, Domain::Operators.put(buffer, Domain::Position.new(row: row, col: 0), entry, count, !keep))
        elsif entry.lines.length == 1
          rows = []
          row = block.top
          while row <= block.bottom
            rows << entry.text
            row += 1
          end
          place(state, Domain::Operators.put_block(buffer, block.top, block.left, Domain::RegisterEntry.block(rows), count, tabstop))
        else
          place(state, Domain::Operators.put(buffer, Domain::Position.new(row: block.top, col: top_col), entry, count, false))
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
          tabstop = state.options.tab_width
          place(state, Domain::Operators.put_block(buffer, from.row, Domain::DisplayWidth.column(line, col, tabstop), entry, count, tabstop))
        else
          place(state, Domain::Operators.put(buffer, Domain::Position.new(row: from.row, col: col), entry, count, false))
        end
      end

      #: (Domain::EditorState, Domain::Position) -> void
      def place(state, pos)
        state.cursor.move_to(pos.row, state.clamp_col(pos.row, pos.col))
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
