require_relative "../../domain/editor_state"
require_relative "../../domain/themes"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :colo[rscheme] name makes the shipped palette of that name the theme
    # option, which the screen presenter picks up at the next frame,
    # repainting every group; another name is Neovim's E185 and keeps the
    # palette, and no name shows the current palette's name. A bang is
    # ignored, as :syntax ignores it.
    class ColorschemeCommandHandler < ExHandler
      #: (spec: String) -> void
      def initialize(spec:)
        super(spec: spec)
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        name = command.args.strip
        options = state.options
        return Outcome.success(options.theme) if name.empty?
        return Outcome.failure("E185: Cannot find color scheme '#{name}'") unless Domain::Themes.known?(name)
        options.theme = name
        Outcome.none
      end

      # Registers :colorscheme after :set.
      #: (ExTable) -> void
      def self.register(table)
        table.register(ColorschemeCommandHandler.new(spec: "colo[rscheme]"), "Switch the color scheme")
      end
    end
  end
end
