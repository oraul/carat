require_relative "../../domain/editor_state"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :LspRestart, nvim-lspconfig's command: stops every language server
    # and starts the current buffer's again, the way out of the crashed
    # state the bar names. The bar's lsp slot shows the new server
    # starting; a buffer whose file type names no server, or a command
    # that cannot start, is reported as an error. Arguments are refused.
    class LspRestartCommandHandler < ExHandler
      attr_reader :services #: Ports::LanguageServicePort

      #: (spec: String, services: Ports::LanguageServicePort) -> void
      def initialize(spec:, services:)
        super(spec: spec)
        @services = services
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        args = command.args.strip
        return Outcome.failure("E488: Trailing characters: #{args}") unless args.empty?
        message = @services.restart(state).to_s
        return Outcome.none if message.empty?
        Outcome.failure(message)
      end

      # Registers :LspRestart last before the plugin commands; no core
      # command shares its spelling.
      #: (ExTable, Ports::LanguageServicePort) -> void
      def self.register(table, services)
        table.register(LspRestartCommandHandler.new(spec: "LspRestart", services: services))
      end
    end
  end
end
