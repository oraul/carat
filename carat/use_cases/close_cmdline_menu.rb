require_relative "../domain/editor_state"
require_relative "../domain/cmdline_menu"
require_relative "windows/close_float"

module Carat
  module UseCases
    # Closes the completion menu of the `:` prompt: its popup goes and its
    # matches are forgotten, the command line kept as it shows. HandleKey
    # runs it after a key that changed the line or left the command line
    # while the menu shows, and Escape runs it before it would discard
    # the line.
    class CloseCmdlineMenu
      attr_reader :menu #: Domain::CmdlineMenu
      attr_reader :close_float #: CloseFloat

      #: (menu: Domain::CmdlineMenu, close_float: CloseFloat) -> void
      def initialize(menu:, close_float:)
        @menu = menu
        @close_float = close_float
      end

      #: (Domain::EditorState) -> void
      def call(state)
        menu = @menu
        @close_float.call(state, menu.float_id) if menu.float_id != 0
        menu.clear
      end
    end
  end
end
