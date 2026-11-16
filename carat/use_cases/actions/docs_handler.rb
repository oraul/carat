require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../outcome"
require_relative "../docs/request_hover"
require_relative "../docs/pin_hover"
require_relative "../docs/toggle_reading"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # K, <leader>dp, and <leader>dr: the hover documentation through
    # RequestHover, its float pinned into a split through PinHover, and a
    # Markdown file's reading view through ToggleReading, chosen by
    # action (:hover, :pin, or :reading).
    class DocsHandler < ActionHandler
      # @rbs @request_hover: RequestHover
      # @rbs @pin_hover: PinHover
      # @rbs @toggle_reading: ToggleReading
      # @rbs @action: Symbol

      #: (request_hover: RequestHover, pin_hover: PinHover, toggle_reading: ToggleReading, action: Symbol) -> void
      def initialize(request_hover:, pin_hover:, toggle_reading:, action:)
        super(kind: :action, repeat: false)
        @request_hover = request_hover
        @pin_hover = pin_hover
        @toggle_reading = toggle_reading
        @action = action
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        return @pin_hover.call(state) if @action == :pin
        return @toggle_reading.call(state, command) if @action == :reading
        @request_hover.call(state)
      end

      #: (ActionTable, request_hover: RequestHover, pin_hover: PinHover, toggle_reading: ToggleReading) -> void
      def self.register(table, request_hover:, pin_hover:, toggle_reading:)
        table.register("docs.hover", DocsHandler.new(request_hover: request_hover, pin_hover: pin_hover, toggle_reading: toggle_reading, action: :hover), "Documentation under the cursor")
        table.register("docs.pin", DocsHandler.new(request_hover: request_hover, pin_hover: pin_hover, toggle_reading: toggle_reading, action: :pin), "Pin the documentation float")
        table.register("docs.toggle_reading", DocsHandler.new(request_hover: request_hover, pin_hover: pin_hover, toggle_reading: toggle_reading, action: :reading), "Toggle the Markdown reading view")
      end
    end
  end
end
