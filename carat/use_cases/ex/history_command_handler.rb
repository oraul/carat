require_relative "../../domain/editor_state"
require_relative "../undo"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # The undo ex commands: :u[ndo] with an optional state number, :red[o],
    # :undol[ist], and :ea[rlier] and :lat[er] with a count of changes.
    # A time or file-write argument (10s, 5m, 1h, 1d, 2f) is not
    # implemented yet.
    class HistoryCommandHandler < ExHandler
      # @rbs @undo: Undo
      # @rbs @variant: Symbol

      #: (spec: String, undo: Undo, variant: Symbol) -> void
      def initialize(spec:, undo:, variant:)
        super(spec: spec)
        @undo = undo
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        args = command.args
        case @variant
        when :undo
          return @undo.undo(state, 1) if args.empty?
          return Outcome.failure("E474: Invalid argument") unless HistoryCommandHandler.digits?(args)
          @undo.to(state, args.to_i)
        when :redo then @undo.redo(state, 1)
        when :list then @undo.list(state)
        when :earlier then travel(state, args, -1, "earlier")
        else travel(state, args, 1, "later")
        end
      end

      # Registers the undo commands after the window and tab commands.
      #: (ExTable, undo: Undo) -> void
      def self.register(table, undo:)
        specs = ["u[ndo]", "red[o]", "undol[ist]", "ea[rlier]", "lat[er]"]
        variants = [:undo, :redo, :list, :earlier, :later]
        i = 0
        while i < specs.length
          table.register(HistoryCommandHandler.new(spec: specs[i], undo: undo, variant: variants[i]))
          i += 1
        end
      end

      # Whether text is one or more decimal digits.
      #: (String) -> bool
      def self.digits?(text)
        text.match?(/\A[0-9]+\z/)
      end

      private

      # :earlier and :later: a count of changes, one when none is given.
      #: (Domain::EditorState, String, Integer, String) -> Outcome
      def travel(state, args, direction, name)
        return @undo.travel(state, direction) if args.empty?
        return @undo.travel(state, direction * args.to_i) if HistoryCommandHandler.digits?(args)
        return Outcome.success("Not implemented: :#{name} #{args}") if args.match?(/\A[0-9]+[smhdf]\z/)
        Outcome.failure("E475: Invalid argument: #{args}")
      end
    end
  end
end
