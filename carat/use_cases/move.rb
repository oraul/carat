require_relative "../domain/editor_state"
require_relative "../domain/command"
require_relative "../domain/motions"
require_relative "../domain/last_find"
require_relative "outcome"

module Carat
  module UseCases
    # Moves the cursor by a motion command: every motion comes from
    # Domain::Motions, and the result decides what happens to the wanted
    # column. A motion that cannot move changes nothing. f, F, t, and T
    # are remembered in the last find, which ";" and "," repeat.
    class Move
      attr_reader :last_find #: Domain::LastFind

      #: (last_find: Domain::LastFind) -> void
      def initialize(last_find:)
        @last_find = last_find
      end

      #: (Domain::EditorState, Domain::Command) -> Outcome
      def call(state, command)
        motion = Domain::Motions.for_command(state, @last_find, command, false)
        return Outcome.none if motion.nil?
        cursor = state.cursor
        target = motion.target
        case motion.want
        when :keep
          cursor.row = target.row
          cursor.col = target.col
        when :end
          cursor.move_to(target.row, target.col)
          cursor.want_col = -1
        else
          cursor.move_to(target.row, target.col)
        end
        Outcome.none
      end

      # The column of the first character that is not a space or a tab, or
      # the last column when the line is blank.
      #: (String) -> Integer
      def first_nonblank(line)
        i = 0
        i += 1 while i < line.length && (line[i, 1] == " " || line[i, 1] == "\t")
        i >= line.length ? (line.length > 0 ? line.length - 1 : 0) : i
      end
    end
  end
end
