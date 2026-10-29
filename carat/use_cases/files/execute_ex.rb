require_relative "../../domain/editor_state"
require_relative "../../domain/ex_grammar"
require_relative "../outcome"
require_relative "open_file"
require_relative "save_file"
require_relative "quit"

module Carat
  module UseCases
    # Parses a command line and runs the matching ex command. The registry is
    # the case below; later changes add their commands as arms. The "all"
    # commands act on the single buffer until the buffer list exists.
    class ExecuteEx
      E141 = "E141: No file name for buffer 1"

      # @rbs @open_file: OpenFile
      # @rbs @save_file: SaveFile
      # @rbs @quit: Quit

      #: (OpenFile, SaveFile, Quit) -> void
      def initialize(open_file, save_file, quit)
        @open_file = open_file
        @save_file = save_file
        @quit = quit
      end

      #: (Domain::EditorState, String) -> Outcome
      def call(state, text)
        command = Domain::ExGrammar.parse(text)
        case command.name
        when ""
          command.args.empty? ? Outcome.success("") : unknown(text)
        when "w", "write"
          @save_file.call(state, command.args)
        when "q", "quit"
          @quit.call(state, command.bang)
        when "wq"
          written = @save_file.call(state, command.args)
          return written unless written.ok
          @quit.call(state, true)
        when "x", "xit", "exi", "exit"
          exit_editor(state, command)
        when "wa", "wall"
          write_all(state)
        when "qa", "qall", "quita", "quitall"
          @quit.call(state, command.bang)
        when "wqa", "wqall", "xa", "xall"
          written = write_all(state)
          return written unless written.ok
          @quit.call(state, true)
        when "e", "edit"
          edit(state, command)
        else
          unknown(text)
        end
      end

      private

      #: (String) -> Outcome
      def unknown(text)
        shown = text.strip
        shown = shown[1, shown.length - 1] while shown.start_with?(":")
        Outcome.failure("E492: Not an editor command: #{shown}")
      end

      #: (Domain::EditorState, Domain::ExCommand) -> Outcome
      def edit(state, command)
        path = command.args.empty? ? state.buffer.path : command.args
        return Outcome.failure("E32: No file name") if path.nil?
        return Outcome.failure(Quit::E37) if state.buffer.modified && !command.bang
        @open_file.call(state, path)
      end

      # :x writes only when there is something to write: a modified buffer or
      # a file argument. After a successful write it quits as :wq does.
      #: (Domain::EditorState, Domain::ExCommand) -> Outcome
      def exit_editor(state, command)
        if state.buffer.modified || !command.args.empty?
          written = @save_file.call(state, command.args)
          return written unless written.ok
        end
        @quit.call(state, true)
      end

      # Writes every modified buffer to its own path; with one buffer this is
      # one write or nothing. A modified buffer with no name reports E141.
      #: (Domain::EditorState) -> Outcome
      def write_all(state)
        buffer = state.buffer
        return Outcome.success("") unless buffer.modified
        return Outcome.failure(E141) if buffer.path.nil?
        @save_file.call(state, "")
      end
    end
  end
end
