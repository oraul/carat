require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../../domain/definition_request"
require_relative "../../domain/keymap"
require_relative "../../domain/mode"
require_relative "../../domain/path_policy"
require_relative "../../ports/file_port"
require_relative "../outcome"
require_relative "../windows/close_float"
require_relative "visit_target"
require_relative "open_definition_float"

module Carat
  module UseCases
    # Uses a definition answer at the idle tick it arrived at, when normal
    # mode, the layout window, its buffer, and the cursor are still where
    # it was asked: an older peek float or pick list closes; no target
    # shows Neovim's "No locations found"; one is visited; several open
    # the pick list, an entered float of numbered "path:line" rows whose
    # scratch buffer has the configuration's keymap.pick bindings, Enter
    # to definition.choose by default.
    class ShowDefinition
      NO_LOCATIONS = "No locations found"
      private_constant :NO_LOCATIONS

      attr_reader :definition #: Domain::DefinitionRequest
      attr_reader :files #: Ports::FilePort
      attr_reader :close_float #: CloseFloat
      attr_reader :visit_target #: VisitTarget
      attr_reader :open_definition_float #: OpenDefinitionFloat
      attr_reader :pick_keymap #: Domain::Keymap

      #: (definition: Domain::DefinitionRequest, files: Ports::FilePort, close_float: CloseFloat, visit_target: VisitTarget, open_definition_float: OpenDefinitionFloat, pick_keymap: Domain::Keymap) -> void
      def initialize(definition:, files:, close_float:, visit_target:, open_definition_float:, pick_keymap:)
        @definition = definition
        @files = files
        @close_float = close_float
        @visit_target = visit_target
        @open_definition_float = open_definition_float
        @pick_keymap = pick_keymap
      end

      #: (Domain::EditorState) -> void
      def call(state)
        definition = @definition
        definition.arrived = false
        window = state.tab.layout_window
        cursor = window.cursor
        return unless state.mode == Domain::Mode::NORMAL && definition.at?(window.id, window.buffer.id, cursor.row, cursor.col)
        close(state)
        count = definition.target_count
        if count == 0
          state.show(NO_LOCATIONS, false)
          return
        end
        if count == 1
          outcome = @visit_target.call(state, 0)
          state.show(outcome.message, !outcome.ok) unless outcome.message.empty?
          return
        end
        pick(state, count)
      end

      private

      # Closes the peek float and the pick list an older answer opened.
      #: (Domain::EditorState) -> void
      def close(state)
        definition = @definition
        @close_float.call(state, definition.float_id) if definition.float_id != 0 && state.tab.floats.index_of(definition.float_id) >= 0
        @close_float.call(state, definition.pick_id) if definition.pick_id != 0 && state.tab.floats.index_of(definition.pick_id) >= 0
        definition.float_id = 0
        definition.pick_id = 0
      end

      #: (Domain::EditorState, Integer) -> void
      def pick(state, count)
        definition = @definition
        cwd = @files.cwd
        rows = [""]
        rows.clear
        i = 0
        while i < count
          rows << "#{i + 1} #{Domain::PathPolicy.shown(cwd, definition.target_paths[i].to_s)}:#{definition.target_rows[i].to_i + 1}"
          i += 1
        end
        buffer = Domain::Buffer.new(lines: rows, path: nil, line_ending: "\n")
        buffer.owner = Domain::DefinitionRequest::OWNER
        buffer.keymap = @pick_keymap
        definition.pick_id = @open_definition_float.call(state, buffer, "Definitions", true)
      end
    end
  end
end
