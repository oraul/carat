require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../files/save_file"
require_relative "../files/save_all"
require_relative "../files/quit_all"
require_relative "../outcome"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The file and quit actions the leader groups and Ctrl-S bind: save
    # the current buffer as :w does, quit as :qa does, and write every
    # modified buffer and quit as :wqa does, through the use cases the ex
    # commands run, so the messages and refusals are theirs. file.find is
    # reserved for the finder and answers "Not implemented" until then.
    class FileHandler < ActionHandler
      # @rbs @save_file: SaveFile
      # @rbs @save_all: SaveAll
      # @rbs @quit_all: QuitAll
      # @rbs @variant: Symbol

      #: (save_file: SaveFile, save_all: SaveAll, quit_all: QuitAll, variant: Symbol) -> void
      def initialize(save_file:, save_all:, quit_all:, variant:)
        super(kind: :action, repeat: false)
        @save_file = save_file
        @save_all = save_all
        @quit_all = quit_all
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        case @variant
        when :save then @save_file.call(state.buffer, "")
        when :quit_all then @quit_all.call(state, false)
        when :write_all then write_quit_all(state)
        else Outcome.success("Not implemented: file.find")
        end
      end

      #: (ActionTable, save_file: SaveFile, save_all: SaveAll, quit_all: QuitAll) -> void
      def self.register(table, save_file:, save_all:, quit_all:)
        names = ["file.save", "file.find", "quit.all", "quit.write_all"]
        variants = [:save, :find, :quit_all, :write_all]
        descriptions = ["Save file", "Find file", "Quit all", "Save all and quit"]
        i = 0
        while i < names.length
          table.register(names[i], FileHandler.new(save_file: save_file, save_all: save_all, quit_all: quit_all, variant: variants[i]), descriptions[i])
          i += 1
        end
      end

      private

      # :wqa: write every modified buffer, then quit, which nothing unsaved
      # refuses after a write that succeeded.
      #: (Domain::EditorState) -> Outcome
      def write_quit_all(state)
        written = @save_all.call(state)
        return written unless written.ok
        @quit_all.call(state, true)
      end
    end
  end
end
