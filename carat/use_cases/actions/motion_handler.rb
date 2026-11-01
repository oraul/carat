require_relative "../../domain/motions"
require_relative "../move"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # Every motion: moves the cursor through Move. Under an operator the
    # dispatcher runs the operator's handler instead, which reads the
    # motion from the command; in a visual mode a motion moves the cursor
    # end of the selection.
    class MotionHandler < ActionHandler
      # @rbs @move: Move

      #: (move: Move, kind: Symbol) -> void
      def initialize(move:, kind:)
        super(kind: kind, repeat: false)
        @move = move
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        @move.call(state, command)
      end

      # Registers Domain::Motions::NAMES with the kind :motion and the find
      # motions, which read a character, with the kind :find.
      #: (ActionTable, move: Move) -> void
      def self.register(table, move:)
        motion = MotionHandler.new(move: move, kind: :motion)
        names = Domain::Motions::NAMES
        i = 0
        while i < names.length
          table.register(names[i], motion)
          i += 1
        end
        find = MotionHandler.new(move: move, kind: :find)
        names = Domain::Motions::FIND_NAMES
        i = 0
        while i < names.length
          table.register(names[i], find)
          i += 1
        end
      end
    end
  end
end
