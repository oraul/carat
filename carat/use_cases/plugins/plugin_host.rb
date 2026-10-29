require_relative "../../plugin_api"
require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../../domain/window"
require_relative "../../domain/keymap"
require_relative "../../domain/manifest_check"
require_relative "../../domain/icons"
require_relative "../../domain/position"
require_relative "../../domain/range"
require_relative "../../domain/command"
require_relative "../../domain/ex_command"
require_relative "../../domain/mode"
require_relative "../../ports/file_port"
require_relative "../outcome"
require_relative "../files/open_file"
require_relative "../windows/close_window"
require_relative "plugin_entry"
require_relative "plugin_link"

module Carat
  module UseCases
    # The plugin host: registers the compiled plugins, validates their
    # manifests, enables them from the configuration, merges their default
    # bindings into the editor keymap, routes plugin actions and ex
    # commands to them, delivers events after the key that caused them,
    # and executes their requests against the editor state and the ports.
    # Every call into a plugin is guarded: a plugin that raises is disabled
    # with a message, and the editor goes on. ExecuteEx is attached after
    # construction because it routes plugin commands here while the host
    # runs ex command strings through it.
    class PluginHost
      E36 = "E36: Not enough room"
      E444 = "E444: Cannot close last window"

      # @rbs @state: Domain::EditorState
      # @rbs @files: Ports::FilePort
      # @rbs @open_file: OpenFile
      # @rbs @close_window: CloseWindow
      # @rbs @keymap: Domain::Keymap
      # @rbs @leader: String
      # @rbs @entries: Array[untyped]
      # @rbs @errors: Array[String]
      # @rbs @execute_ex: ExecuteEx?
      # @rbs @known: Array[untyped]
      # @rbs @last_buffer: Domain::Buffer?
      # @rbs @last_changes: Integer
      # @rbs @last_row: Integer
      # @rbs @last_col: Integer
      # @rbs @last_mode: Symbol
      # @rbs @last_tab: Integer
      # @rbs @last_window: Integer
      # @rbs @last_rows: Integer
      # @rbs @last_cols: Integer
      # @rbs @quit_sent: bool

      #: (Domain::EditorState, Ports::FilePort, OpenFile, CloseWindow, Domain::Keymap, String) -> void
      def initialize(state, files, open_file, close_window, keymap, leader)
        @state = state
        @files = files
        @open_file = open_file
        @close_window = close_window
        @keymap = keymap
        @leader = leader
        @entries = []
        @errors = []
        @execute_ex = nil
        @known = []
        @last_buffer = nil
        @last_changes = 0
        @last_row = 0
        @last_col = 0
        @last_mode = Domain::Mode::NORMAL
        @last_tab = 0
        @last_window = 0
        @last_rows = 0
        @last_cols = 0
        @quit_sent = false
        snapshot(state)
      end

      # Attaches the ex command runner the run_ex request uses.
      #: (ExecuteEx) -> void
      def attach(execute_ex)
        @execute_ex = execute_ex
      end

      # ------------------------------------------------------ registration

      # Registers a plugin: its manifest is checked, and a broken rule or a
      # newer major API version registers it disabled with the reason.
      #: (PluginApi::Plugin) -> void
      def register(plugin)
        manifest = plugin.manifest
        name = manifest.name
        entry = PluginEntry.new(plugin, manifest, name, PluginLink.new(self, name))
        problems = Domain::ManifestCheck.check(manifest)
        unless problems.empty?
          entry.enabled = false
          entry.reason = problems[0]
          @errors << "plugin #{name}: #{problems[0]}"
        end
        @entries << entry
      end

      # Activates every registered plugin the configuration leaves enabled:
      # resolves its options, merges its default bindings into the keymap,
      # and calls activate with its link. config_plugins is the "plugins"
      # object of the configuration, or anything else for no entries.
      #: (untyped) -> void
      def activate_all(config_plugins)
        i = 0
        while i < @entries.length
          e = entry(i)
          if e.enabled
            setting = config_plugins.is_a?(Hash) ? config_plugins[e.name] : nil
            if setting.is_a?(Hash) && setting["enabled"] == false
              e.enabled = false
              e.reason = "disabled in the configuration"
            else
              e.options = resolve_options(e, setting)
              @keymap.add_all(e.manifest.bindings, @leader)
              begin
                e.plugin.activate(e.link)
              rescue StandardError => error
                disable(e, error.message)
              end
            end
          end
          i += 1
        end
      end

      #: (Integer) -> PluginEntry
      def entry(i)
        @entries[i]
      end

      #: () -> Integer
      def count
        @entries.length
      end

      # The problems recorded while registering and activating: manifest
      # rules broken and option values of the wrong type.
      #: () -> Array[String]
      def errors
        @errors
      end

      #: (String) -> bool
      def enabled?(name)
        e = find(name)
        e.nil? ? false : e.enabled
      end

      # Why a plugin is disabled, or "" when it is enabled or unknown.
      #: (String) -> String
      def reason(name)
        e = find(name)
        e.nil? ? "" : e.reason
      end

      # The description of an action across the plugins, "" when none
      # declares it.
      #: (String) -> String
      def describe(action)
        i = 0
        while i < @entries.length
          text = entry(i).manifest.describe(action)
          return text unless text.empty?
          i += 1
        end
        ""
      end

      # ----------------------------------------------------------- routing

      # Runs a plugin.<name>.<action> action, with the count and register
      # of the command, in the plugin that owns it.
      #: (Domain::EditorState, String, Domain::Command) -> void
      def action(state, name, command)
        parts = name.split(".")
        plugin_name = parts.length > 1 ? parts[1] : ""
        e = find(plugin_name)
        if e.nil?
          state.show("No plugin named #{plugin_name}", true)
          return
        end
        unless e.enabled
          state.show("Plugin #{plugin_name} is disabled", true)
          return
        end
        unless e.manifest.actions.key?(name)
          state.show("Plugin #{plugin_name} has no action #{name}", true)
          return
        end
        context = PluginApi::Context.new(command.count, command.register, state.buffer_number(state.buffer), window_number(state), path_of(state.buffer), state.cursor.row, state.cursor.col)
        begin
          e.plugin.on_action(name, context)
        rescue StandardError => error
          disable(e, error.message)
        end
      end

      # Whether an enabled plugin declared the ex command, by name or
      # abbreviation.
      #: (String) -> bool
      def command?(name)
        !owner_of_command(name).nil?
      end

      # Runs the ex command in the plugin that declared it.
      #: (Domain::EditorState, Domain::ExCommand) -> Outcome
      def command(state, ex_command)
        e = owner_of_command(ex_command.name)
        return Outcome.failure("E492: Not an editor command: #{ex_command.name}") if e.nil?
        call = PluginApi::Command.new(e.full_command(ex_command.name), ex_command.bang, ex_command.args)
        begin
          e.plugin.on_command(call)
        rescue StandardError => error
          disable(e, error.message)
        end
        Outcome.success("")
      end

      # ------------------------------------------------------------ events

      # Compares the state with the snapshot of the previous call and
      # delivers the events the difference means, in the order of the spec:
      # buffer_open, buffer_change, cursor_move, mode_change, window_focus,
      # then quit, after which every enabled plugin is deactivated. The
      # snapshot is taken after delivery, so what a plugin changes while
      # handling an event produces no event.
      #: (Domain::EditorState) -> void
      def observe(state)
        i = 0
        while i < state.buffer_count
          b = state.buffer_at(i)
          unless known?(b)
            @known << b
            deliver(event(:buffer_open, state, b))
          end
          i += 1
        end
        prune(state)
        current = state.buffer
        cursor = state.cursor
        same = same_buffer?(current)
        deliver(event(:buffer_change, state, current)) if same && current.changes != @last_changes
        deliver(event(:cursor_move, state, current)) if !same || cursor.row != @last_row || cursor.col != @last_col
        deliver(event(:mode_change, state, current).with(detail: Domain::Mode.name_of(state.mode))) if state.mode != @last_mode
        deliver(event(:window_focus, state, current)) if state.tab_index != @last_tab || state.tab.current != @last_window
        snapshot(state)
        return unless state.quit && !@quit_sent
        @quit_sent = true
        deliver(event(:quit, state, current))
        deactivate_all
      end

      # A buffer was written: delivered by SaveFile, since no state
      # difference tells a write from a reload.
      #: (Domain::Buffer) -> void
      def saved(buffer)
        deliver(event(:buffer_save, @state, buffer))
      end

      # The editor was drawn at a size: delivers resize when it changed.
      #: (Integer, Integer) -> void
      def resized(rows, cols)
        return if rows == @last_rows && cols == @last_cols
        @last_rows = rows
        @last_cols = cols
        deliver(PluginApi::Event.new(:resize, 0, 0, "", rows, cols, ""))
      end

      # ---------------------------------------------------------- requests
      #
      # Every request of a disabled plugin is refused, so a plugin that
      # raised cannot go on changing the editor from a call it still holds.

      #: (String, Integer) -> PluginApi::BufferView
      def read_buffer(name, number)
        return PluginApi::BufferView.missing unless enabled?(name)
        buffer = buffer_for(number)
        return PluginApi::BufferView.missing if buffer.nil?
        row = 0
        col = 0
        if buffer.equal?(@state.buffer)
          row = @state.cursor.row
          col = @state.cursor.col
        end
        PluginApi::BufferView.new(true, @state.buffer_number(buffer), path_of(buffer), copy(buffer.lines), row, col, buffer.modified)
      end

      # Validates every edit before touching a line, then applies them
      # from the last to the first so earlier positions stay valid.
      #: (String, Integer, Array[untyped]) -> PluginApi::Response
      def edit_buffer(name, number, edits)
        why = refused(name)
        return PluginApi::Response.failure(why) unless why.empty?
        buffer = buffer_for(number)
        return PluginApi::Response.failure("No buffer #{number}") if buffer.nil?
        prev_row = 0
        prev_col = 0
        i = 0
        while i < edits.length
          e = edit_at(edits, i)
          problem = check_edit(buffer, e, prev_row, prev_col)
          return PluginApi::Response.failure("edit #{i + 1}: #{problem}") unless problem.empty?
          prev_row = e.to_row
          prev_col = e.to_col
          i += 1
        end
        i = edits.length - 1
        while i >= 0
          e = edit_at(edits, i)
          range = Domain::Range.charwise(Domain::Position.new(e.from_row, e.from_col), Domain::Position.new(e.to_row, e.to_col))
          buffer.replace(range, e.text)
          i -= 1
        end
        @state.clamp_cursors(buffer)
        PluginApi::Response.success("", edits.length)
      end

      #: (String, Integer, Integer) -> PluginApi::Response
      def move_cursor(name, row, col)
        why = refused(name)
        return PluginApi::Response.failure(why) unless why.empty?
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

      # Opens the plugin's scratch buffer with that title in a fixed-width
      # window at the edge of the tab page, or refreshes and focuses the
      # one already shown.
      #: (String, String, Symbol, Integer, Array[String], untyped) -> PluginApi::Response
      def open_scratch(name, title, side, width, lines, bindings)
        why = refused(name)
        return PluginApi::Response.failure(why) unless why.empty?
        state = @state
        layout = state.tab.layout
        existing = state.scratch_for(name, title)
        unless existing.nil?
          id = window_showing(state, existing)
          if id >= 0
            replace_lines(existing, lines)
            state.tab.focus(id)
            return PluginApi::Response.success("", layout.number_of(id))
          end
          state.drop_buffer(existing)
        end
        buffer = Domain::Buffer.new(copy(lines), nil, "\n")
        buffer.owner = name
        buffer.title = title
        keymap = Domain::Keymap.build(bindings, @leader)
        record_errors(name, keymap.errors)
        buffer.keymap = keymap
        window = Domain::Window.new(buffer)
        window.fixed_width = true
        id = layout.split_edge(window, width, side == :left)
        return PluginApi::Response.failure(E36) if id < 0
        state.add_buffer(buffer)
        state.tab.focus(id)
        PluginApi::Response.success("", layout.number_of(id))
      end

      #: (String, String, Array[String]) -> PluginApi::Response
      def set_scratch_lines(name, title, lines)
        why = refused(name)
        return PluginApi::Response.failure(why) unless why.empty?
        buffer = @state.scratch_for(name, title)
        return PluginApi::Response.failure("No scratch buffer #{title}") if buffer.nil?
        replace_lines(buffer, lines)
        PluginApi::Response.success("", 0)
      end

      #: (String, String) -> PluginApi::Response
      def close_scratch(name, title)
        why = refused(name)
        return PluginApi::Response.failure(why) unless why.empty?
        state = @state
        buffer = state.scratch_for(name, title)
        id = buffer.nil? ? -1 : window_showing(state, buffer)
        return PluginApi::Response.failure("No window shows #{title}") if id < 0
        return PluginApi::Response.failure(E444) if state.total_windows <= 1
        @close_window.remove(state, id)
        PluginApi::Response.success("", 0)
      end

      #: (String, Integer) -> PluginApi::Response
      def focus_window(name, number)
        why = refused(name)
        return PluginApi::Response.failure(why) unless why.empty?
        tab = @state.tab
        return PluginApi::Response.success("", tab.layout.number_of(tab.current)) if number == 0
        return PluginApi::Response.failure("No window #{number}") if number < 0 || number > tab.window_count
        tab.focus(tab.layout.leaf_number(number))
        PluginApi::Response.success("", number)
      end

      #: (String, Integer, String) -> PluginApi::Response
      def open_file(name, number, path)
        why = refused(name)
        return PluginApi::Response.failure(why) unless why.empty?
        focused = focus_window(name, number)
        return focused unless focused.ok
        outcome = @open_file.call(@state, path)
        PluginApi::Response.new(outcome.ok, outcome.message, focused.number, [])
      end

      #: (String, String, bool) -> PluginApi::Response
      def message(name, text, error)
        why = refused(name)
        return PluginApi::Response.failure(why) unless why.empty?
        @state.show(text, error)
        PluginApi::Response.success("", 0)
      end

      #: (String, String) -> PluginApi::Response
      def set_status(name, text)
        why = refused(name)
        return PluginApi::Response.failure(why) unless why.empty?
        if text.empty?
          @state.segments.delete(name)
        else
          @state.segments[name] = text
        end
        PluginApi::Response.success("", 0)
      end

      #: (String, Integer, Integer, String) -> PluginApi::Response
      def place_sign(name, number, row, icon)
        why = refused(name)
        return PluginApi::Response.failure(why) unless why.empty?
        buffer = buffer_for(number)
        return PluginApi::Response.failure("No buffer #{number}") if buffer.nil?
        return PluginApi::Response.failure("Row #{row} is outside the buffer") if row < 0 || row >= buffer.line_count
        glyph = Domain::Icons.glyph(icon, @state.options.icons)
        return PluginApi::Response.failure("No icon named #{icon}") if glyph.empty?
        key = row.to_s
        buffer.signs[key] = glyph
        buffer.sign_owners[key] = name
        PluginApi::Response.success("", 0)
      end

      #: (String, Integer) -> PluginApi::Response
      def clear_signs(name, number)
        why = refused(name)
        return PluginApi::Response.failure(why) unless why.empty?
        buffer = buffer_for(number)
        return PluginApi::Response.failure("No buffer #{number}") if buffer.nil?
        rows = []
        buffer.sign_owners.each do |key, owner|
          rows << key if owner == name
        end
        i = 0
        while i < rows.length
          buffer.signs.delete(rows[i])
          buffer.sign_owners.delete(rows[i])
          i += 1
        end
        PluginApi::Response.success("", rows.length)
      end

      #: (String, String) -> PluginApi::Response
      def run_ex(name, text)
        why = refused(name)
        return PluginApi::Response.failure(why) unless why.empty?
        runner = @execute_ex
        return PluginApi::Response.failure("No ex command runner") if runner.nil?
        outcome = runner.call(@state, text)
        PluginApi::Response.new(outcome.ok, outcome.message, 0, [])
      end

      #: (String, String) -> PluginApi::Response
      def list_dir(name, path)
        why = refused(name)
        return PluginApi::Response.failure(why) unless why.empty?
        names = []
        begin
          names = @files.list(path)
        rescue StandardError => error
          return PluginApi::Response.failure(error.message)
        end
        PluginApi::Response.listing(copy(names))
      end

      #: (String, String) -> PluginApi::FileInfo
      def stat(name, path)
        return PluginApi::FileInfo.missing unless enabled?(name)
        info = nil
        begin
          info = @files.stat(path)
        rescue StandardError
          return PluginApi::FileInfo.missing
        end
        PluginApi::FileInfo.new(true, int_of(info, "size"), int_of(info, "mtime"), int_of(info, "directory") == 1)
      end

      #: (String, String) -> String
      def icon(name, icon_name)
        return "" unless enabled?(name)
        Domain::Icons.glyph(icon_name, @state.options.icons)
      end

      #: (String, String) -> String
      def option(name, key)
        e = find(name)
        return "" if e.nil? || !e.enabled
        value = e.options[key]
        value.nil? ? "" : value
      end

      private

      # The reason a request from the named plugin is refused, "" for none.
      #: (String) -> String
      def refused(name)
        e = find(name)
        return "No plugin named #{name}" if e.nil?
        e.enabled ? "" : "Plugin #{name} is disabled"
      end

      #: (String) -> PluginEntry?
      def find(name)
        i = 0
        while i < @entries.length
          e = entry(i)
          return e if e.name == name
          i += 1
        end
        nil
      end

      #: (String) -> PluginEntry?
      def owner_of_command(name)
        i = 0
        while i < @entries.length
          e = entry(i)
          return e if e.enabled && e.command?(name)
          i += 1
        end
        nil
      end

      # Disables a plugin that raised: the message row says so, and its
      # status segment goes.
      #: (PluginEntry, String) -> void
      def disable(e, why)
        e.enabled = false
        e.reason = why
        @state.segments.delete(e.name)
        @state.show("Plugin #{e.name} disabled: #{why}", true)
      end

      # The manifest defaults, with the configuration entry's options of
      # the right type over them; a wrong type or an unknown option is
      # recorded and keeps the default.
      #: (PluginEntry, untyped) -> Hash[String, String]
      def resolve_options(e, setting)
        result = {}
        e.manifest.options.each { |key, default| result[key] = default }
        return result unless setting.is_a?(Hash)
        given = setting["options"]
        return result unless given.is_a?(Hash)
        given.each do |key, value|
          type = e.manifest.option_types[key.to_s]
          if type.nil?
            @errors << "plugin #{e.name}: unknown option #{key}"
          elsif option_valid?(value, type)
            result[key.to_s] = option_text(value, type)
          else
            @errors << "plugin #{e.name}: option #{key} must be a #{type}"
          end
        end
        result
      end

      #: (untyped, Symbol) -> bool
      def option_valid?(value, type)
        case type
        when :bool then value == true || value == false
        when :integer then value.is_a?(Integer)
        when :string then value.is_a?(String)
        when :list
          return false unless value.is_a?(Array)
          value.each { |item| return false unless item.is_a?(String) }
          true
        else false
        end
      end

      #: (untyped, Symbol) -> String
      def option_text(value, type)
        case type
        when :bool then value == true ? "true" : "false"
        when :integer then value.to_s
        when :list
          items = []
          value.each { |item| items << item.to_s }
          items.join("\n")
        else value.to_s
        end
      end

      #: (String, Array[String]) -> void
      def record_errors(name, errors)
        i = 0
        while i < errors.length
          @errors << "plugin #{name}: binding #{errors[i]}"
          i += 1
        end
      end

      #: (PluginApi::Event) -> void
      def deliver(event)
        i = 0
        while i < @entries.length
          e = entry(i)
          if e.enabled && e.subscribed?(event.name)
            begin
              e.plugin.on_event(event)
            rescue StandardError => error
              disable(e, error.message)
            end
          end
          i += 1
        end
      end

      #: () -> void
      def deactivate_all
        i = 0
        while i < @entries.length
          e = entry(i)
          if e.enabled
            begin
              e.plugin.deactivate
            rescue StandardError => error
              disable(e, error.message)
            end
          end
          i += 1
        end
      end

      #: (Symbol, Domain::EditorState, Domain::Buffer) -> PluginApi::Event
      def event(name, state, buffer)
        row = 0
        col = 0
        if buffer.equal?(state.buffer)
          row = state.cursor.row
          col = state.cursor.col
        end
        PluginApi::Event.new(name, state.buffer_number(buffer), window_number(state), path_of(buffer), row, col, "")
      end

      #: (Domain::EditorState) -> void
      def snapshot(state)
        current = state.buffer
        @last_buffer = current
        @last_changes = current.changes
        @last_row = state.cursor.row
        @last_col = state.cursor.col
        @last_mode = state.mode
        @last_tab = state.tab_index
        @last_window = state.tab.current
      end

      #: (Domain::Buffer) -> bool
      def same_buffer?(buffer)
        last = @last_buffer
        last.nil? ? false : last.equal?(buffer)
      end

      #: (Domain::Buffer) -> bool
      def known?(buffer)
        i = 0
        while i < @known.length
          return true if known_at(i).equal?(buffer)
          i += 1
        end
        false
      end

      #: (Integer) -> Domain::Buffer
      def known_at(i)
        @known[i]
      end

      # Forgets the buffers that left the list, so a buffer opened again
      # later is an open again.
      #: (Domain::EditorState) -> void
      def prune(state)
        kept = []
        i = 0
        while i < @known.length
          b = known_at(i)
          kept << b if state.buffer_index(b) >= 0
          i += 1
        end
        @known = kept
      end

      #: (Domain::EditorState) -> Integer
      def window_number(state)
        tab = state.tab
        tab.layout.number_of(tab.current)
      end

      #: (Domain::Buffer) -> String
      def path_of(buffer)
        path = buffer.path
        path.nil? ? "" : path
      end

      # Buffer number 0 is the current buffer, n the n-th listed one.
      #: (Integer) -> Domain::Buffer?
      def buffer_for(number)
        return @state.buffer if number == 0
        return nil if number < 0 || number > @state.buffer_count
        @state.buffer_at(number - 1)
      end

      # The leaf id of the window in the current tab page showing the
      # buffer, or -1.
      #: (Domain::EditorState, Domain::Buffer) -> Integer
      def window_showing(state, buffer)
        layout = state.tab.layout
        ids = layout.leaves
        i = 0
        while i < ids.length
          return ids[i] if layout.window_at(ids[i]).buffer.equal?(buffer)
          i += 1
        end
        -1
      end

      #: (Domain::Buffer, Array[String]) -> void
      def replace_lines(buffer, lines)
        fresh = copy(lines)
        fresh << "" if fresh.empty?
        buffer.lines = fresh
        buffer.modified = false
        @state.clamp_cursors(buffer)
      end

      #: (Array[String]) -> Array[String]
      def copy(lines)
        out = []
        i = 0
        while i < lines.length
          out << lines[i]
          i += 1
        end
        out
      end

      #: (Array[untyped], Integer) -> PluginApi::Edit
      def edit_at(edits, i)
        edits[i]
      end

      # The first rule an edit breaks, or "".
      #: (Domain::Buffer, PluginApi::Edit, Integer, Integer) -> String
      def check_edit(buffer, e, prev_row, prev_col)
        last = buffer.line_count - 1
        return "row #{e.from_row} is outside the buffer" if e.from_row < 0 || e.from_row > last
        return "row #{e.to_row} is outside the buffer" if e.to_row < 0 || e.to_row > last
        return "column #{e.from_col} is outside row #{e.from_row}" if e.from_col < 0 || e.from_col > buffer.line(e.from_row).length
        return "column #{e.to_col} is outside row #{e.to_row}" if e.to_col < 0 || e.to_col > buffer.line(e.to_row).length
        return "end precedes start" if e.to_row < e.from_row || (e.to_row == e.from_row && e.to_col < e.from_col)
        return "overlaps the edit before it" if e.from_row < prev_row || (e.from_row == prev_row && e.from_col < prev_col)
        ""
      end

      #: (untyped, String) -> Integer
      def int_of(hash, key)
        return 0 unless hash.is_a?(Hash)
        value = hash[key]
        value.is_a?(Integer) ? value : 0
      end
    end
  end
end
