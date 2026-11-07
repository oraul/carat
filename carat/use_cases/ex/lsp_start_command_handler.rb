require_relative "../../domain/editor_state"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :LspStart, nvim-lspconfig's command: starts the current buffer's
    # language server when none runs for its file type, the explicit start
    # a directory outside language.trusted_roots waits for, as the bar's
    # "untrusted :LspStart" names. A buffer whose file type names no
    # server, or a command that cannot start, is reported as an error.
    # Arguments are refused.
    class LspStartCommandHandler < ExHandler
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
        message = @services.start(state).to_s
        return Outcome.none if message.empty?
        Outcome.failure(message)
      end

      # Registers :LspStart before :LspRestart and the plugin commands; no
      # core command shares its spelling.
      #: (ExTable, Ports::LanguageServicePort) -> void
      def self.register(table, services)
        table.register(LspStartCommandHandler.new(spec: "LspStart", services: services))
      end
    end
  end
end
