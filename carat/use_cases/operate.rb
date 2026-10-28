require_relative "../domain/editor_state"
require_relative "../domain/command"
require_relative "../domain/command_grammar"
require_relative "../domain/range"
require_relative "../domain/motions"
require_relative "../domain/text_objects"
require_relative "../domain/operators"
require_relative "../domain/registers"

module Carat
  module UseCases
    # Runs an operator over its operand: a motion, a text object, or the
    # count lines of a doubled operator. Resolves the range with Vim's
    # exclusive-motion adjustments, writes the register, applies the
    # buffer work from Operators, and places the cursor and the mode. The
    # standalone commands x s S C D Y are the same path with a fixed
    # operand; p, P, and J have their own entry points.
    class Operate
      DELETE = "operator.delete"
      CHANGE = "operator.change"
      YANK = "operator.yank"
      INDENT = "operator.indent"
      DEDENT = "operator.dedent"

      #: (Domain::EditorState, Domain::Command) -> void
      def call(state, command)
        range = operand(state, command)
        return if range.nil?
        case command.operator
        when DELETE then delete(state, command, range)
        when CHANGE then change(state, command, range)
        when YANK then yank(state, command, range)
        when INDENT then shift(state, range, 1)
        when DEDENT then shift(state, range, -1)
        end
      end

      # x, s, S, C, D, and Y as an operator with a fixed motion.
      #: (Domain::EditorState, Domain::Command, String, String, bool) -> void
      def fixed(state, command, operator, motion, linewise)
        call(state, Domain::Command.new(command.register, command.count, operator, motion, "", linewise, command.keys))
      end

      #: (Domain::EditorState, Domain::Command, bool) -> void
      def put(state, command, after)
        entry = state.registers.read(command.register)
        if entry.nil?
          name = command.register.empty? ? "\"" : command.register
          state.show("E353: Nothing in register #{name}", true)
          return
        end
        pos = Domain::Operators.put(state.buffer, state.cursor.position, entry, command.count_or(1), after)
        state.cursor.move_to(pos.row, pos.col)
      end

      #: (Domain::EditorState, Domain::Command) -> void
      def join(state, command)
        cursor = state.cursor
        last = state.buffer.line_count - 1
        return if cursor.row >= last
        count = command.count_or(2)
        count = 2 if count < 2
        count = last - cursor.row + 1 if cursor.row + count - 1 > last
        col = Domain::Operators.join(state.buffer, cursor.row, count)
        cursor.move_to(cursor.row, clamp(state, cursor.row, col))
      end

      private

      # The range of the operand, or nil when there is none.
      #: (Domain::EditorState, Domain::Command) -> Domain::Range?
      def operand(state, command)
        cursor = state.cursor
        if command.linewise
          last = state.buffer.line_count - 1
          last_row = cursor.row + command.count_or(1) - 1
          last_row = last if last_row > last
          return Domain::Range.new(cursor.position, Domain::Position.new(last_row, cursor.col), :linewise, true)
        end
        action = command.action
        return Domain::TextObjects.call(state, action, command.count) if Domain::CommandGrammar.text_object?(action)
        motion = motion_for(state, command)
        return nil if motion.nil?
        from = cursor.position
        to = motion.target
        if to.before?(from)
          swap = from
          from = to
          to = swap
        end
        return Domain::Range.new(from, to, :linewise, true) if motion.linewise
        inclusive = motion.inclusive
        if !inclusive && to.col == 0 && to.row > from.row
          if from.col <= state.buffer.first_nonblank(from.row)
            return Domain::Range.new(from, Domain::Position.new(to.row - 1, 0), :linewise, true)
          end
          to = Domain::Position.new(to.row - 1, state.buffer.line(to.row - 1).length)
        end
        Domain::Range.new(from, to, :charwise, inclusive)
      end

      # The motion of an operator command; "cw" and "cW" on a non-blank
      # character become "ce" and "cE" stopping at the end of the word.
      #: (Domain::EditorState, Domain::Command) -> Domain::Motion?
      def motion_for(state, command)
        action = command.action
        if command.operator == CHANGE && (action == "motion.word_forward" || action == "motion.big_word_forward")
          line = state.current_line
          col = state.cursor.col
          if col < line.length && !Domain::Motions.blank?(line[col, 1])
            return Domain::Motions.word_end(state, command.count_or(1), action == "motion.big_word_forward", true, true)
          end
        end
        Domain::Motions.for_command(state, command, true)
      end

      #: (Domain::EditorState, Domain::Command, Domain::Range) -> void
      def delete(state, command, range)
        buffer = state.buffer
        state.registers.write(command.register, Domain::Operators.extract(buffer, range))
        Domain::Operators.delete(buffer, range)
        cursor = state.cursor
        if range.kind == :linewise
          row = range.from.row
          row = buffer.line_count - 1 if row > buffer.line_count - 1
          cursor.move_to(row, buffer.first_nonblank(row))
        else
          from = range.normalized.from
          cursor.move_to(from.row, clamp(state, from.row, from.col))
        end
      end

      #: (Domain::EditorState, Domain::Command, Domain::Range) -> void
      def change(state, command, range)
        buffer = state.buffer
        state.registers.write(command.register, Domain::Operators.extract(buffer, range))
        cursor = state.cursor
        if range.kind == :linewise
          indent = state.options.autoindent ? buffer.indent_of(range.from.row) : ""
          buffer.set_lines(range.from.row, range.to.row + 1, [indent])
          cursor.move_to(range.from.row, indent.length)
        else
          Domain::Operators.delete(buffer, range)
          from = range.normalized.from
          cursor.move_to(from.row, from.col)
        end
        state.mode = Domain::Mode::INSERT
      end

      #: (Domain::EditorState, Domain::Command, Domain::Range) -> void
      def yank(state, command, range)
        state.registers.write(command.register, Domain::Operators.extract(state.buffer, range))
        cursor = state.cursor
        if range.kind == :linewise
          cursor.row = range.from.row
          cursor.col = clamp(state, range.from.row, range.from.col)
        else
          from = range.normalized.from
          cursor.move_to(from.row, clamp(state, from.row, from.col))
        end
      end

      #: (Domain::EditorState, Domain::Range, Integer) -> void
      def shift(state, range, amount)
        options = state.options
        buffer = state.buffer
        Domain::Operators.shift(buffer, range.from.row, range.to.row, amount, options.shiftwidth, options.tabstop, options.expandtab)
        state.cursor.move_to(range.from.row, buffer.first_nonblank(range.from.row))
      end

      #: (Domain::EditorState, Integer, Integer) -> Integer
      def clamp(state, row, col)
        max = state.max_col(row)
        col > max ? max : col
      end
    end
  end
end
