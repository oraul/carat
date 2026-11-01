require_relative "../domain/editor_state"
require_relative "../domain/command"
require_relative "../domain/range"
require_relative "../domain/motions"
require_relative "../domain/text_objects"
require_relative "../domain/operators"
require_relative "../domain/registers"
require_relative "../domain/last_find"
require_relative "../domain/display_width"
require_relative "outcome"

module Carat
  module UseCases
    # Runs an operator over its operand: a motion, a text object, or the
    # count lines of a doubled operator. Resolves the range with Vim's
    # exclusive-motion adjustments, writes the register, applies the
    # buffer work from Operators, and places the cursor and the mode. The
    # standalone commands x s S C D Y are the same path with a fixed
    # operand; p, P, J, r, and ~ have their own entry points. Deletes and
    # changes write the registers by Vim's delete rules and yanks by its
    # yank rules; naming a read-only register refuses the command with
    # E354.
    class Operate
      DELETE = "operator.delete"
      CHANGE = "operator.change"
      YANK = "operator.yank"
      INDENT = "operator.indent"
      DEDENT = "operator.dedent"

      attr_reader :registers #: Domain::Registers
      attr_reader :last_find #: Domain::LastFind

      #: (registers: Domain::Registers, last_find: Domain::LastFind) -> void
      def initialize(registers:, last_find:)
        @registers = registers
        @last_find = last_find
      end

      # The motions after which a delete writes register 1 even within a
      # line, as Vim's use_reg_one; search and marks arrive later.
      REGISTER_ONE_MOTIONS = ["motion.sentence_forward", "motion.sentence_backward", "motion.paragraph_forward", "motion.paragraph_backward"]

      #: (Domain::EditorState, Domain::Command) -> Outcome
      def call(state, command)
        operator = command.operator
        register = command.register
        if Domain::Registers.read_only?(register) && (operator == DELETE || operator == CHANGE || operator == YANK)
          return Operate.read_only(register)
        end
        range = operand(state, command)
        return Outcome.none if range.nil?
        state.buffer.start_at(range.normalized.from) unless range.kind == :linewise
        case command.operator
        when DELETE then delete(state, command, range)
        when CHANGE then change(state, command, range)
        when YANK then yank(state, command, range)
        when INDENT then shift(state, range, 1)
        when DEDENT then shift(state, range, -1)
        end
        Outcome.none
      end

      # x, s, S, C, D, and Y as an operator with a fixed motion.
      #: (Domain::EditorState, Domain::Command, String, String, bool) -> Outcome
      def fixed(state, command, operator, motion, linewise)
        call(state, Domain::Command.new(command.register, command.count, operator, motion, "", linewise, command.keys))
      end

      # The refusal of a write to a read-only register.
      #: (String) -> Outcome
      def self.read_only(name)
        Outcome.failure("E354: Invalid register name: '#{name}'")
      end

      # r{char}: count characters from the cursor replaced by the
      # character, the cursor on the last one; nothing when fewer remain.
      #: (Domain::EditorState, Domain::Command) -> Outcome
      def replace_chars(state, command)
        cursor = state.cursor
        line = state.current_line
        count = command.count_or(1)
        col = cursor.col
        return Outcome.none if command.char.empty? || col + count > line.length
        fresh = line[0, col] + (command.char * count) + line[col + count, line.length - col - count]
        state.buffer.set_lines(cursor.row, cursor.row + 1, [fresh])
        cursor.move_to(cursor.row, col + count - 1)
        Outcome.none
      end

      # ~: the case of count characters from the cursor switched, as many
      # as remain, and the cursor past them, stopping on the last
      # character.
      #: (Domain::EditorState, Domain::Command) -> Outcome
      def toggle_case(state, command)
        cursor = state.cursor
        line = state.current_line
        col = cursor.col
        return Outcome.none if col >= line.length
        count = command.count_or(1)
        count = line.length - col if col + count > line.length
        fresh = line[0, col] + Domain::Operators.recase(line[col, count], :toggle, "") + line[col + count, line.length - col - count]
        state.buffer.set_lines(cursor.row, cursor.row + 1, [fresh])
        cursor.move_to(cursor.row, clamp(state, cursor.row, col + count))
        Outcome.none
      end

      #: (Domain::EditorState, Domain::Command, bool) -> Outcome
      def put(state, command, after)
        entry = @registers.read_with_file(command.register, state.buffer.path_text)
        if entry.nil?
          name = command.register.empty? ? "\"" : command.register
          return Outcome.failure("E353: Nothing in register #{name}")
        end
        if entry.blockwise?
          put_block(state, entry, command.count_or(1), after)
          return Outcome.none
        end
        pos = Domain::Operators.put(state.buffer, state.cursor.position, entry, command.count_or(1), after)
        state.cursor.move_to(pos.row, pos.col)
        Outcome.none
      end

      #: (Domain::EditorState, Domain::Command) -> Outcome
      def join(state, command)
        cursor = state.cursor
        last = state.buffer.line_count - 1
        return Outcome.none if cursor.row >= last
        count = command.count_or(2)
        count = 2 if count < 2
        count = last - cursor.row + 1 if cursor.row + count - 1 > last
        col = Domain::Operators.join(state.buffer, cursor.row, count, true)
        cursor.move_to(cursor.row, clamp(state, cursor.row, col))
        Outcome.none
      end

      private

      # A blockwise register put as a block from the display column of the
      # cursor's character, or the one after it for "p".
      #: (Domain::EditorState, Domain::RegisterEntry, Integer, bool) -> void
      def put_block(state, entry, count, after)
        buffer = state.buffer
        cursor = state.cursor
        tabstop = state.options.tabstop > 0 ? state.options.tabstop : 8
        line = buffer.line(cursor.row)
        vcol = Domain::DisplayWidth.column(line, cursor.col, tabstop)
        vcol += Domain::DisplayWidth.cell(line[cursor.col, 1], vcol, tabstop) if after && cursor.col < line.length
        pos = Domain::Operators.put_block(buffer, cursor.row, vcol, entry, count, tabstop)
        cursor.move_to(pos.row, clamp(state, pos.row, pos.col))
      end

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
        return Domain::TextObjects.call(state, action, command.count) if Domain::TextObjects.object?(action)
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
        Domain::Motions.for_command(state, @last_find, command, true)
      end

      #: (Domain::EditorState, Domain::Command, Domain::Range) -> void
      def delete(state, command, range)
        buffer = state.buffer
        @registers.delete(command.register, Domain::Operators.extract(buffer, range), big?(command, range))
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
        @registers.delete(command.register, Domain::Operators.extract(buffer, range), big?(command, range))
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
        @registers.yank(command.register, Domain::Operators.extract(state.buffer, range))
        cursor = state.cursor
        if range.kind == :linewise
          cursor.row = range.from.row
          cursor.col = clamp(state, range.from.row, range.from.col)
        else
          from = range.normalized.from
          cursor.move_to(from.row, clamp(state, from.row, from.col))
        end
      end

      # Whether a delete or change goes to register 1: whole lines, more
      # than one line, or one of the motions Vim lists.
      #: (Domain::Command, Domain::Range) -> bool
      def big?(command, range)
        return true if range.kind == :linewise || range.from.row != range.to.row
        # The command's members are not pinned, so the action is made a
        # String before the lookup, which otherwise never matches.
        action = command.action.to_s
        !command.operator.empty? && REGISTER_ONE_MOTIONS.include?(action)
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
