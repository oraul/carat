require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../../domain/palette"
require_relative "../outcome"
require_relative "../discovery/open_palette"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The command palette's actions: palette.open opens it through
    # OpenPalette; palette.next and palette.previous move its selection
    # by one, and do nothing while it is closed. FollowPalette shows the
    # moved selection after the key.
    class PaletteHandler < ActionHandler
      # @rbs @open_palette: OpenPalette
      # @rbs @palette: Domain::Palette
      # @rbs @step: Integer

      #: (open_palette: OpenPalette, palette: Domain::Palette, step: Integer) -> void
      def initialize(open_palette:, palette:, step:)
        super(kind: :action, repeat: false)
        @open_palette = open_palette
        @palette = palette
        @step = step
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        return @open_palette.call(state) if @step == 0
        @palette.move(@step) if @palette.active
        Outcome.none
      end

      #: (ActionTable, open_palette: OpenPalette, palette: Domain::Palette) -> void
      def self.register(table, open_palette:, palette:)
        table.register("palette.open", PaletteHandler.new(open_palette: open_palette, palette: palette, step: 0), "Command palette")
        table.register("palette.next", PaletteHandler.new(open_palette: open_palette, palette: palette, step: 1), "Next palette entry")
        table.register("palette.previous", PaletteHandler.new(open_palette: open_palette, palette: palette, step: -1), "Previous palette entry")
      end
    end
  end
end
