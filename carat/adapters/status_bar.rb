require_relative "../plugin_api"
require_relative "../domain/editor_state"
require_relative "../domain/frame"
require_relative "../domain/highlight"
require_relative "../domain/display_width"
require_relative "../domain/icons"
require_relative "../domain/mode"
require_relative "../domain/plugin_ui"
require_relative "../domain/status_slots"

module Carat
  module Adapters
    # Paints the one status bar across a frame row, as Neovim's
    # laststatus=3, for the current window: the mode pill, the file with
    # the modified icon, the git branch, and the diagnostics counts at the
    # left; the plugins' segments, the progress of long work, the lsp slot, the file type, the
    # encoding, the position, and the percent at the right end. Each
    # segment is its text with a space on each side, so the bar has no
    # separator glyphs. An empty slot (branch, diagnostics, lsp, file
    # type, a plugin without a segment) takes no cells but keeps its
    # place in the order.
    #
    # When the segments are wider than the row, the one of lowest
    # priority is dropped, the later one on a tie, until the rest fit;
    # the mode and the file are never dropped but cut at the edge. The
    # widths are counted from the texts and digits and the pieces written
    # straight into the frame, the entries kept in integer arrays that
    # are refilled each time, so a bar costs no object per frame.
    class StatusBar
      MODE = 0
      FILE = 1
      BRANCH = 2
      DIAGNOSTICS = 3
      PLUGIN = 4
      LSP = 5
      FILETYPE = 6
      ENCODING = 7
      POSITION = 8
      PERCENT = 9
      PROGRESS = 10

      # The priority of each kind by its number; a plugin's segment has
      # its own.
      PRIORITIES = [100, 90, 40, 70, 0, 60, 30, 20, 80, 50, 35]

      ENCODING_TEXT = "utf-8"
      NO_NAME = "[No Name]"
      # The cells of the progress bar, and the done cells of one without a
      # percent, which move one cell for each report.
      BAR_CELLS = 10
      BAR_RUN = 3

      attr_reader :plugin_ui #: Domain::PluginUi
      attr_reader :slots #: Domain::StatusSlots
      attr_reader :plain #: bool

      # @rbs @kinds: Array[Integer]
      # @rbs @widths: Array[Integer]
      # @rbs @priorities: Array[Integer]
      # @rbs @shown: Array[Integer]
      # @rbs @owners: Array[Integer]

      #: (plugin_ui: Domain::PluginUi, slots: Domain::StatusSlots) -> void
      def initialize(plugin_ui:, slots:)
        @plugin_ui = plugin_ui
        @slots = slots
        @plain = false
        @kinds = []
        @widths = []
        @priorities = []
        @shown = []
        @owners = []
      end

      # Paints the bar on row of a frame cols wide for the state's current
      # window.
      #: (Domain::Frame, Integer, Integer, Domain::EditorState) -> void
      def paint(frame, row, cols, state)
        collect(state)
        fit(cols)
        frame.blank(row, 0, cols)
        frame.fill(row, 0, cols, Domain::Highlight::STATUS)
        x = 0
        right = 0
        i = 0
        while i < @kinds.length
          if @shown[i] == 1
            if @kinds[i] <= DIAGNOSTICS
              x = paint_entry(frame, row, x, cols, i, state)
            else
              right += @widths[i]
            end
          end
          i += 1
        end
        x = cols - right if cols - right > x
        i = 0
        while i < @kinds.length
          x = paint_entry(frame, row, x, cols, i, state) if @shown[i] == 1 && @kinds[i] > DIAGNOSTICS
          i += 1
        end
      end

      # Draws the progress bar with ASCII glyphs and no color when plain,
      # as NO_COLOR asks.
      #: (bool) -> void
      def plain=(value)
        @plain = value
      end

      # The pill text of a mode.
      #: (Symbol) -> String
      def self.mode_name(mode)
        return "INSERT" if mode == Domain::Mode::INSERT
        return "VISUAL" if mode == Domain::Mode::VISUAL
        return "V-LINE" if mode == Domain::Mode::VISUAL_LINE
        return "V-BLOCK" if mode == Domain::Mode::VISUAL_BLOCK
        return "REPLACE" if mode == Domain::Mode::REPLACE
        return "O-PENDING" if mode == Domain::Mode::OPERATOR_PENDING
        return "COMMAND" if mode == Domain::Mode::CMDLINE
        "NORMAL"
      end

      # The pill group of a mode.
      #: (Symbol) -> Integer
      def self.mode_group(mode)
        return Domain::Highlight::STATUS_MODE_INSERT if mode == Domain::Mode::INSERT
        return Domain::Highlight::STATUS_MODE_VISUAL if Domain::Mode.visual?(mode)
        return Domain::Highlight::STATUS_MODE_REPLACE if mode == Domain::Mode::REPLACE
        return Domain::Highlight::STATUS_MODE_COMMAND if mode == Domain::Mode::CMDLINE
        Domain::Highlight::STATUS_MODE_NORMAL
      end

      # The group of the lsp slot in a state: starting and indexing share
      # one, a crash is an error, and a stopped server or one waiting in an
      # untrusted directory is plain.
      #: (Symbol) -> Integer
      def self.lsp_group(state)
        return Domain::Highlight::STATUS_LSP_STARTING if state == :starting || state == :indexing
        return Domain::Highlight::STATUS_LSP_READY if state == :ready
        return Domain::Highlight::STATUS_LSP_ERROR if state == :crashed
        Domain::Highlight::STATUS
      end

      private

      # Fills the entries in order with each present segment's width and
      # priority, all shown.
      #: (Domain::EditorState) -> void
      def collect(state)
        @kinds.clear
        @widths.clear
        @priorities.clear
        @shown.clear
        @owners.clear
        window = state.window
        buffer = window.buffer
        set = state.options.icons
        slots = @slots
        add(MODE, StatusBar.mode_name(state.mode).length + 2, -1)
        file = text_width(file_name(buffer)) + 2
        file += 1 + text_width(Domain::Icons.glyph("modified", set)) if buffer.modified?
        add(FILE, file, -1)
        add(BRANCH, text_width(Domain::Icons.glyph("git", set)) + text_width(slots.branch) + 3, -1) unless slots.branch.empty?
        add(DIAGNOSTICS, diagnostics_width(set), -1) if slots.diagnostics?
        ui = @plugin_ui
        k = 0
        while k < ui.owners.length
          add(PLUGIN, text_width(ui.text_at(k)) + 2, k)
          k += 1
        end
        add(PROGRESS, progress_width(state), -1) if slots.progress?
        add(LSP, text_width(slots.lsp_label) + 2, -1) if slots.lsp?
        add(FILETYPE, text_width(buffer.filetype) + 2, -1) unless buffer.filetype.empty?
        add(ENCODING, ENCODING_TEXT.length + 2, -1)
        cursor = window.cursor
        add(POSITION, Domain::Frame.digits(cursor.row + 1) + Domain::Frame.digits(cursor.col + 1) + 3, -1)
        percent = percent_of(window)
        add(PERCENT, (percent >= 0 ? Domain::Frame.digits(percent) + 1 : 3) + 2, -1)
      end

      #: (Integer, Integer, Integer) -> void
      def add(kind, width, owner)
        @kinds << kind
        @widths << width
        @priorities << (owner >= 0 ? @plugin_ui.priorities[owner] : PRIORITIES[kind])
        @shown << 1
        @owners << owner
      end

      # Drops the entry of lowest priority, the later one on a tie, while
      # the shown ones are wider than cols; never the mode or the file.
      #: (Integer) -> void
      def fit(cols)
        total = 0
        i = 0
        while i < @widths.length
          total += @widths[i]
          i += 1
        end
        while total > cols
          lowest = -1
          i = 0
          while i < @kinds.length
            if @shown[i] == 1 && @kinds[i] > FILE
              lowest = i if lowest < 0 || @priorities[i] <= @priorities[lowest]
            end
            i += 1
          end
          return if lowest < 0
          @shown[lowest] = 0
          total -= @widths[lowest]
        end
      end

      # Paints entry i from column x, cut at limit, and returns the column
      # after it.
      #: (Domain::Frame, Integer, Integer, Integer, Integer, Domain::EditorState) -> Integer
      def paint_entry(frame, row, x, limit, i, state)
        hl = Domain::Highlight::STATUS
        kind = @kinds[i]
        window = state.window
        buffer = window.buffer
        set = state.options.icons
        slots = @slots
        if kind == MODE
          hl = StatusBar.mode_group(state.mode)
          x = frame.put_within(row, x, " ", hl, limit)
          x = frame.put_within(row, x, StatusBar.mode_name(state.mode), hl, limit)
        elsif kind == FILE
          x = frame.put_within(row, x, " ", hl, limit)
          x = frame.put_within(row, x, file_name(buffer), hl, limit)
          if buffer.modified?
            x = frame.put_within(row, x, " ", hl, limit)
            x = frame.put_within(row, x, Domain::Icons.glyph("modified", set), hl, limit)
          end
        elsif kind == BRANCH
          x = frame.put_within(row, x, " ", hl, limit)
          x = frame.put_within(row, x, Domain::Icons.glyph("git", set), hl, limit)
          x = frame.put_within(row, x, " ", hl, limit)
          x = frame.put_within(row, x, slots.branch, hl, limit)
        elsif kind == DIAGNOSTICS
          x = paint_count(frame, row, x, limit, slots.errors, "error", Domain::Highlight::DIAGNOSTIC_ERROR, set)
          x = paint_count(frame, row, x, limit, slots.warnings, "warning", Domain::Highlight::DIAGNOSTIC_WARN, set)
          x = paint_count(frame, row, x, limit, slots.infos, "info", Domain::Highlight::DIAGNOSTIC_INFO, set)
          x = paint_count(frame, row, x, limit, slots.hints, "hint", Domain::Highlight::DIAGNOSTIC_HINT, set)
          hl = last_count_group
        elsif kind == PLUGIN
          x = frame.put_within(row, x, " ", hl, limit)
          x = frame.put_within(row, x, @plugin_ui.text_at(@owners[i]), hl, limit)
        elsif kind == PROGRESS
          x = frame.put_within(row, x, " ", hl, limit)
          x = frame.put_within(row, x, slots.progress_label, hl, limit)
          x = paint_bar(frame, row, x, limit) if bar?(state)
        elsif kind == LSP
          hl = StatusBar.lsp_group(slots.lsp_state)
          x = frame.put_within(row, x, " ", hl, limit)
          x = frame.put_within(row, x, slots.lsp_label, hl, limit)
        elsif kind == FILETYPE
          x = frame.put_within(row, x, " ", hl, limit)
          x = frame.put_within(row, x, buffer.filetype, hl, limit)
        elsif kind == ENCODING
          x = frame.put_within(row, x, " ", hl, limit)
          x = frame.put_within(row, x, ENCODING_TEXT, hl, limit)
        elsif kind == POSITION
          cursor = window.cursor
          x = frame.put_within(row, x, " ", hl, limit)
          x = frame.put_digits_within(row, x, cursor.row + 1, hl, limit)
          x = frame.put_within(row, x, ":", hl, limit)
          x = frame.put_digits_within(row, x, cursor.col + 1, hl, limit)
        else
          x = frame.put_within(row, x, " ", hl, limit)
          percent = percent_of(window)
          if percent >= 0
            x = frame.put_digits_within(row, x, percent, hl, limit)
            x = frame.put_within(row, x, "%", hl, limit)
          else
            x = frame.put_within(row, x, percent_word(window), hl, limit)
          end
        end
        frame.put_within(row, x, " ", hl, limit)
      end

      # Whether the progress shows a bar: always with a percent, without one
      # only when motion is not reduced.
      #: (Domain::EditorState) -> bool
      def bar?(state)
        @slots.progress_percent >= 0 || !state.options.reducedmotion
      end

      # The cells of the progress segment: its label, the bar with the space
      # before it when it shows, and a space on each side.
      #: (Domain::EditorState) -> Integer
      def progress_width(state)
        label = @slots.progress_label
        width = text_width(label) + 2
        width += BAR_CELLS + (label.empty? ? 0 : 1) if bar?(state)
        width
      end

      # The bar from x: a done cell per ten percent, or BAR_RUN done cells
      # at the report count's place without a percent; returns the column
      # after it.
      #: (Domain::Frame, Integer, Integer, Integer) -> Integer
      def paint_bar(frame, row, x, limit)
        slots = @slots
        x = frame.put_within(row, x, " ", Domain::Highlight::STATUS, limit) unless slots.progress_label.empty?
        percent = slots.progress_percent
        from = 0
        to = percent * BAR_CELLS / 100
        if percent < 0
          from = (slots.progress_step - 1) % (BAR_CELLS - BAR_RUN + 1)
          to = from + BAR_RUN
        end
        done = @plain ? Domain::Highlight::STATUS : Domain::Highlight::STATUS_LSP_READY
        c = 0
        while c < BAR_CELLS && x < limit
          on = c >= from && c < to
          x = frame.put_code(row, x, on ? (@plain ? 0x23 : 0x2501) : (@plain ? 0x2D : 0x2500), 1, on ? done : Domain::Highlight::STATUS)
          c += 1
        end
        x
      end

      # One diagnostics count above zero as a space, its icon, a space, and
      # the number, in its group; nothing for zero.
      #: (Domain::Frame, Integer, Integer, Integer, Integer, String, Integer, String) -> Integer
      def paint_count(frame, row, x, limit, count, icon, hl, set)
        return x if count <= 0
        x = frame.put_within(row, x, " ", hl, limit)
        x = frame.put_within(row, x, Domain::Icons.glyph(icon, set), hl, limit)
        x = frame.put_within(row, x, " ", hl, limit)
        frame.put_digits_within(row, x, count, hl, limit)
      end

      # The group of the last count above zero, which the diagnostics
      # segment's closing space takes.
      #: () -> Integer
      def last_count_group
        slots = @slots
        return Domain::Highlight::DIAGNOSTIC_HINT if slots.hints > 0
        return Domain::Highlight::DIAGNOSTIC_INFO if slots.infos > 0
        return Domain::Highlight::DIAGNOSTIC_WARN if slots.warnings > 0
        Domain::Highlight::DIAGNOSTIC_ERROR
      end

      #: (String) -> Integer
      def diagnostics_width(set)
        slots = @slots
        count_width(slots.errors, "error", set) + count_width(slots.warnings, "warning", set) + count_width(slots.infos, "info", set) + count_width(slots.hints, "hint", set) + 1
      end

      #: (Integer, String, String) -> Integer
      def count_width(count, icon, set)
        return 0 if count <= 0
        text_width(Domain::Icons.glyph(icon, set)) + Domain::Frame.digits(count) + 2
      end

      # The path, the scratch title, or [No Name].
      #: (Domain::Buffer) -> String
      def file_name(buffer)
        name = buffer.display_name
        name.nil? ? NO_NAME : name
      end

      #: (String) -> Integer
      def text_width(text)
        Domain::DisplayWidth.text_width(text, 0)
      end

      # The window's place in its buffer as a percentage of the rows above
      # it, -1 when the word All, Top, or Bot says it.
      #: (Domain::Window) -> Integer
      def percent_of(window)
        count = window.buffer.line_count
        top = window.top
        height = window.height
        return -1 if count <= height || top == 0 || top + height >= count
        top * 100 / (count - height)
      end

      #: (Domain::Window) -> String
      def percent_word(window)
        count = window.buffer.line_count
        return "All" if count <= window.height
        window.top == 0 ? "Top" : "Bot"
      end
    end
  end
end
