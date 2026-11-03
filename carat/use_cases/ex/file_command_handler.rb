require_relative "../../domain/editor_state"
require_relative "../files/open_file"
require_relative "../../domain/messages"
require_relative "../files/save_file"
require_relative "../files/save_all"
require_relative "../files/quit"
require_relative "../files/quit_all"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # The ex commands that write, quit, and edit files: :w, :wq, :x, :wa,
    # :wqa, :xa, :q, :qa, and :e, with their bang and argument. The "all"
    # commands act on every buffer in the list, across every tab page.
    class FileCommandHandler < ExHandler
      # @rbs @save_file: SaveFile
      # @rbs @save_all: SaveAll
      # @rbs @quit: Quit
      # @rbs @quit_all: QuitAll
      # @rbs @open_file: OpenFile
      # @rbs @variant: Symbol

      #: (spec: String, save_file: SaveFile, save_all: SaveAll, quit: Quit, quit_all: QuitAll, open_file: OpenFile, variant: Symbol) -> void
      def initialize(spec:, save_file:, save_all:, quit:, quit_all:, open_file:, variant:)
        super(spec: spec)
        @save_file = save_file
        @save_all = save_all
        @quit = quit
        @quit_all = quit_all
        @open_file = open_file
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        case @variant
        when :write then @save_file.call(state.buffer, command.args)
        when :quit then @quit.call(state, command.bang ? :force : :quit)
        when :write_quit then write_quit(state, command)
        when :exit then exit_editor(state, command)
        when :write_all then @save_all.call(state)
        when :quit_all then @quit_all.call(state, command.bang)
        when :write_quit_all then write_quit_all(state)
        else edit(state, command)
        end
      end

      # Registers the file commands in the order of docs/compatibility.md,
      # which is their order of precedence.
      #: (ExTable, save_file: SaveFile, save_all: SaveAll, quit: Quit, quit_all: QuitAll, open_file: OpenFile) -> void
      def self.register(table, save_file:, save_all:, quit:, quit_all:, open_file:)
        specs = ["w[rite]", "q[uit]", "wq", "x[it]", "exi[t]", "wa[ll]", "qa[ll]", "quita[ll]", "wqa[ll]", "xa[ll]", "e[dit]"]
        variants = [:write, :quit, :write_quit, :exit, :exit, :write_all, :quit_all, :quit_all, :write_quit_all, :write_quit_all, :edit]
        i = 0
        while i < specs.length
          table.register(FileCommandHandler.new(spec: specs[i], save_file: save_file, save_all: save_all, quit: quit, quit_all: quit_all, open_file: open_file, variant: variants[i]))
          i += 1
        end
      end

      private

      # :wq writes, then leaves as :q does after a write.
      #: (Domain::EditorState, Domain::ExCommand) -> Outcome
      def write_quit(state, command)
        written = @save_file.call(state.buffer, command.args)
        return written unless written.ok
        @quit.call(state, :written)
      end

      # :x writes only when there is something to write: a modified buffer or
      # a file argument. After a successful write it leaves as :wq does.
      #: (Domain::EditorState, Domain::ExCommand) -> Outcome
      def exit_editor(state, command)
        if state.buffer.modified? || !command.args.empty?
          written = @save_file.call(state.buffer, command.args)
          return written unless written.ok
        end
        @quit.call(state, :written)
      end

      #: (Domain::EditorState) -> Outcome
      def write_quit_all(state)
        written = @save_all.call(state)
        return written unless written.ok
        @quit_all.call(state, true)
      end

      #: (Domain::EditorState, Domain::ExCommand) -> Outcome
      def edit(state, command)
        path = command.args.empty? ? state.buffer.path : command.args
        return Outcome.failure("E32: No file name") if path.nil?
        return Outcome.failure(Domain::Messages::E37) if state.buffer.modified? && !command.bang
        @open_file.call(state, path)
      end
    end
  end
end
