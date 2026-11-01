require_relative "../../plugin_api"
require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/buffer"
require_relative "../../domain/icons"
require_relative "../../domain/position"
require_relative "../../domain/range"
require_relative "boundary"
require_relative "plugin_registry"

module Carat
  module UseCases
    # The buffer requests of the plugin API: reading a buffer, editing it
    # as one validated transaction, moving the cursor, and placing and
    # clearing signs. Buffers are addressed by id, 0 for the current one.
    # The plugin link has checked that the plugin is enabled.
    class BufferRequests
      attr_reader :state #: Domain::EditorState
      attr_reader :buffers #: Domain::BufferList
      attr_reader :registry #: PluginRegistry

      #: (state: Domain::EditorState, buffers: Domain::BufferList, registry: PluginRegistry) -> void
      def initialize(state:, buffers:, registry:)
        @state = state
        @buffers = buffers
        @registry = registry
      end

      # A copy of the buffer's lines and path, with the cursor when it is
      # the current buffer.
      #: (String, Integer) -> PluginApi::BufferView
      def read_buffer(name, id)
        buffer = buffer_for(id)
        return PluginApi::BufferView.missing("No buffer #{id}") if buffer.nil?
        row = 0
        col = 0
        if buffer.equal?(@state.buffer)
          row = @state.cursor.row
          col = @state.cursor.col
        end
        PluginApi::BufferView.new(true, "", buffer.id, buffer.path_text.dup, Boundary.copied_lines(buffer.lines), row, col, buffer.modified?)
      end

      # Validates every item before touching a line, then applies them
      # from the last to the first so earlier positions stay valid, inside
      # one transaction on the buffer (joining the command's when the
      # request comes from an action bound to a key). Should applying still
      # raise, the records it made are undone and the request fails. The
    # closed transaction keeps the cursors on the buffer inside its text.
      #: (String, Integer, Array[untyped]) -> PluginApi::Response
      def edit_buffer(name, id, edits)
        buffer = buffer_for(id)
        return PluginApi::Response.failure("No buffer #{id}") if buffer.nil?
        return PluginApi::Response.failure("edits is not a list") unless edits.is_a?(Array)
        prev_row = 0
        prev_col = 0
        i = 0
        while i < edits.length
          item = edits[i]
          return PluginApi::Response.failure("edit #{i + 1}: not an edit") unless item.is_a?(PluginApi::Edit)
          e = edit_item(edits, i)
          problem = check_edit(buffer, e, prev_row, prev_col)
          return PluginApi::Response.failure("edit #{i + 1}: #{problem}") unless problem.empty?
          prev_row = e.to_row
          prev_col = e.to_col
          i += 1
        end
        opened = buffer.begin_transaction(cursor_on(buffer))
        mark = buffer.transaction_size
        begin
          apply(buffer, edits)
        rescue StandardError => error
          buffer.revert_to(mark)
          buffer.commit_transaction(cursor_on(buffer)) if opened
          return PluginApi::Response.failure("edit failed: #{error.message}")
        end
        buffer.commit_transaction(cursor_on(buffer)) if opened
        PluginApi::Response.success("", edits.length)
      end

      #: (String, Integer, Integer) -> PluginApi::Response
      def move_cursor(name, row, col)
        buffer = @state.buffer
        cursor = @state.cursor
        last = buffer.line_count - 1
        r = row < 0 ? 0 : row
        r = last if r > last
        max = @state.max_col(r)
        c = col < 0 ? 0 : col
        c = max if c > max
        cursor.row = r
        cursor.col = c
        cursor.want_col = c
        PluginApi::Response.success("", 0)
      end

      # Places the plugin's sign on the row: its own sign there is
      # replaced, another plugin's stays, and the plugin registered first
      # shows when two mark one row.
      #: (String, Integer, Integer, String) -> PluginApi::Response
      def place_sign(name, id, row, icon)
        buffer = buffer_for(id)
        return PluginApi::Response.failure("No buffer #{id}") if buffer.nil?
        return PluginApi::Response.failure("Row #{row} is outside the buffer") if row < 0 || row >= buffer.line_count
        glyph = Domain::Icons.glyph(icon, @state.options.icons)
        return PluginApi::Response.failure("No icon named #{icon}") if glyph.empty?
        owner = @registry.find(name)
        priority = owner.nil? ? @registry.count : owner.priority
        buffer.place_sign(name, priority, row, glyph)
        PluginApi::Response.success("", 0)
      end

      #: (String, Integer) -> PluginApi::Response
      def clear_signs(name, id)
        buffer = buffer_for(id)
        return PluginApi::Response.failure("No buffer #{id}") if buffer.nil?
        PluginApi::Response.success("", buffer.clear_signs(name))
      end

      private

      # Buffer id 0 is the current buffer, any other the listed buffer
      # with that id.
      #: (Integer) -> Domain::Buffer?
      def buffer_for(id)
        return @state.buffer if id == 0
        @buffers.with_id(id)
      end

      #: (Domain::Buffer, Array[untyped]) -> void
      def apply(buffer, edits)
        i = edits.length - 1
        while i >= 0
          e = edit_item(edits, i)
          range = Domain::Range.charwise(Domain::Position.new(e.from_row, e.from_col), Domain::Position.new(e.to_row, e.to_col))
          buffer.replace(range, e.text.dup)
          i -= 1
        end
      end

      # The cursor position on a buffer for a transaction: the current
      # window's cursor when it shows the buffer, else the origin.
      #: (Domain::Buffer) -> Domain::Position
      def cursor_on(buffer)
        return @state.cursor.position if buffer.equal?(@state.buffer)
        Domain::Position.new(0, 0)
      end

      # One item of the list, checked to be an Edit by the caller.
      #: (Array[untyped], Integer) -> PluginApi::Edit
      def edit_item(edits, i)
        edits[i]
      end

      # The first rule an edit breaks, or "".
      #: (Domain::Buffer, PluginApi::Edit, Integer, Integer) -> String
      def check_edit(buffer, e, prev_row, prev_col)
        return "text is not a string" unless e.text.is_a?(String)
        last = buffer.line_count - 1
        return "row #{e.from_row} is outside the buffer" if e.from_row < 0 || e.from_row > last
        return "row #{e.to_row} is outside the buffer" if e.to_row < 0 || e.to_row > last
        return "column #{e.from_col} is outside row #{e.from_row}" if e.from_col < 0 || e.from_col > buffer.line(e.from_row).length
        return "column #{e.to_col} is outside row #{e.to_row}" if e.to_col < 0 || e.to_col > buffer.line(e.to_row).length
        return "end precedes start" if e.to_row < e.from_row || (e.to_row == e.from_row && e.to_col < e.from_col)
        return "overlaps the edit before it" if e.from_row < prev_row || (e.from_row == prev_row && e.from_col < prev_col)
        ""
      end
    end
  end
end
