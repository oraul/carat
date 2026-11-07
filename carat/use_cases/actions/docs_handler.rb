require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../outcome"
require_relative "../docs/request_hover"
require_relative "../docs/pin_hover"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # K and <leader>dp: the hover documentation through RequestHover, and
    # its float pinned into a split through PinHover.
    class DocsHandler < ActionHandler
      # @rbs @request_hover: RequestHover
      # @rbs @pin_hover: PinHover
      # @rbs @pin: bool

      #: (request_hover: RequestHover, pin_hover: PinHover, pin: bool) -> void
      def initialize(request_hover:, pin_hover:, pin:)
        super(kind: :action, repeat: false)
        @request_hover = request_hover
        @pin_hover = pin_hover
        @pin = pin
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        return @pin_hover.call(state) if @pin
        @request_hover.call(state)
      end

      #: (ActionTable, request_hover: RequestHover, pin_hover: PinHover) -> void
      def self.register(table, request_hover:, pin_hover:)
        table.register("docs.hover", DocsHandler.new(request_hover: request_hover, pin_hover: pin_hover, pin: false), "Documentation under the cursor")
        table.register("docs.pin", DocsHandler.new(request_hover: request_hover, pin_hover: pin_hover, pin: true), "Pin the documentation float")
      end
    end
  end
end
