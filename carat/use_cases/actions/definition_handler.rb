require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../outcome"
require_relative "../definitions/request_definition"
require_relative "../definitions/choose_definition"
require_relative "../definitions/walk_jumps"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # gd and <leader>dd ask for the definition through RequestDefinition,
    # Enter in the pick list chooses through ChooseDefinition, and Ctrl-O
    # and Ctrl-I walk the jump list through WalkJumps by the count.
    class DefinitionHandler < ActionHandler
      # @rbs @request_definition: RequestDefinition
      # @rbs @choose_definition: ChooseDefinition
      # @rbs @walk_jumps: WalkJumps
      # @rbs @variant: Symbol

      #: (request_definition: RequestDefinition, choose_definition: ChooseDefinition, walk_jumps: WalkJumps, variant: Symbol) -> void
      def initialize(request_definition:, choose_definition:, walk_jumps:, variant:)
        super(kind: :action, repeat: false)
        @request_definition = request_definition
        @choose_definition = choose_definition
        @walk_jumps = walk_jumps
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        variant = @variant
        return @request_definition.call(state, false) if variant == :jump
        return @request_definition.call(state, true) if variant == :peek
        return @choose_definition.call(state) if variant == :choose
        return @walk_jumps.call(state, -command.count_or(1)) if variant == :older
        @walk_jumps.call(state, command.count_or(1))
      end

      #: (ActionTable, request_definition: RequestDefinition, choose_definition: ChooseDefinition, walk_jumps: WalkJumps) -> void
      def self.register(table, request_definition:, choose_definition:, walk_jumps:)
        table.register("definition.jump", DefinitionHandler.new(request_definition: request_definition, choose_definition: choose_definition, walk_jumps: walk_jumps, variant: :jump), "Go to the definition under the cursor")
        table.register("definition.peek", DefinitionHandler.new(request_definition: request_definition, choose_definition: choose_definition, walk_jumps: walk_jumps, variant: :peek), "Peek at the definition under the cursor")
        table.register("definition.choose", DefinitionHandler.new(request_definition: request_definition, choose_definition: choose_definition, walk_jumps: walk_jumps, variant: :choose), "Go to the definition picked in the list")
        table.register("jump.older", DefinitionHandler.new(request_definition: request_definition, choose_definition: choose_definition, walk_jumps: walk_jumps, variant: :older), "Go to the older position in the jump list")
        table.register("jump.newer", DefinitionHandler.new(request_definition: request_definition, choose_definition: choose_definition, walk_jumps: walk_jumps, variant: :newer), "Go to the newer position in the jump list")
      end
    end
  end
end
