require_relative "../../plugin_api"
require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../../domain/buffer_feed"
require_relative "../../domain/mode"
require_relative "../concerns/guarded"
require_relative "plugin_registry"
require_relative "pending_event"

module Carat
  module UseCases
    # Delivers events to the plugins. Buffer events come from the editor
    # state's buffer feed (opens, closes, renames, and closed
    # transactions), saves from SaveFile, resizes from the render, and
    # cursor_move, mode_change, and window_focus from comparing the state
    # after a key with the last snapshot. Events are queued, never
    # delivered from inside a plugin call: flush delivers them once no
    # plugin call is in progress, in rounds, each to every enabled
    # subscriber except the plugin whose request caused it, and what a
    # round's deliveries cause forms the next round, up to MAX_ROUNDS.
    class PluginEvents
      include Guarded

      MAX_ROUNDS = 8

      # @rbs @state: Domain::EditorState
      # @rbs @registry: PluginRegistry
      # @rbs @queue: Array[untyped]
      # @rbs @announced: Hash[String, String]
      # @rbs @flushing: bool
      # @rbs @last_buffer: Integer
      # @rbs @last_row: Integer
      # @rbs @last_col: Integer
      # @rbs @last_mode: Symbol
      # @rbs @last_tab: Integer
      # @rbs @last_window: Integer
      # @rbs @last_rows: Integer
      # @rbs @last_cols: Integer
      # @rbs @quit_sent: bool

      # What the feed recorded before the host existed, the empty buffer
      # the editor starts with, is forgotten: no plugin saw it open.
      #: (Domain::EditorState, PluginRegistry) -> void
      def initialize(state, registry)
        @state = state
        @registry = registry
        @queue = []
        @announced = {}
        @flushing = false
        @last_buffer = 0
        @last_row = 0
        @last_col = 0
        @last_mode = Domain::Mode::NORMAL
        @last_tab = 0
        @last_window = 0
        @last_rows = 0
        @last_cols = 0
        @quit_sent = false
        state.feed.clear
        snapshot
      end

      # Delivers what is queued, unless a plugin call or another flush is
      # in progress: the outermost call delivers.
      #: () -> void
      def flush
        return if @flushing || @registry.busy?
        @flushing = true
        rounds = 0
        while true
          collect
          break if @queue.empty?
          if rounds >= MAX_ROUNDS
            @queue = []
            @state.feed.clear
            @state.show("Plugin events dropped after #{MAX_ROUNDS} rounds", true)
            break
          end
          batch = @queue
          @queue = []
          i = 0
          while i < batch.length
            deliver(pending_at(batch, i))
            i += 1
          end
          rounds += 1
        end
        @flushing = false
      end

      # Delivers the buffer events of the key, then compares the state
      # with the snapshot of the previous call: cursor_move, mode_change,
      # window_focus, and quit, after which every enabled plugin is
      # deactivated. The snapshot is taken after delivery.
      #: () -> void
      def observe
        flush
        state = @state
        cursor = state.cursor
        buffer = state.buffer
        same = buffer.id == @last_buffer
        queue("cursor_move", buffer, cursor.row, cursor.col, "", "") if !same || cursor.row != @last_row || cursor.col != @last_col
        queue("mode_change", buffer, cursor.row, cursor.col, Domain::Mode.name_of(state.mode), "") if state.mode != @last_mode
        queue("window_focus", buffer, cursor.row, cursor.col, "", "") if state.tab_index != @last_tab || state.window_id != @last_window
        snapshot
        flush
        return unless state.quit && !@quit_sent
        @quit_sent = true
        queue("quit", buffer, cursor.row, cursor.col, "", "")
        flush
        @registry.deactivate_all
      end

      # A buffer was written: queued after what the feed holds, with the
      # plugin whose request wrote it as its cause.
      #: (Domain::Buffer) -> void
      def saved(buffer)
        collect
        row = 0
        col = 0
        if buffer.equal?(@state.buffer)
          row = @state.cursor.row
          col = @state.cursor.col
        end
        queue("buffer_save", buffer, row, col, "", @registry.cause)
      end

      # The editor was drawn at a size: queues resize when it changed.
      #: (Integer, Integer) -> void
      def resized(rows, cols)
        return if rows == @last_rows && cols == @last_cols
        @last_rows = rows
        @last_cols = cols
        @queue << PendingEvent.new(PluginApi::Event.new("resize", 0, 0, "", rows, cols, "", 0, 0), "")
      end

      private

      # The concern's reader.
      #: () -> PluginRegistry
      def registry
        @registry
      end

      #: (Array[untyped], Integer) -> PendingEvent
      def pending_at(batch, i)
        batch[i]
      end

      # Moves the feed's notices into the queue as events. A close is
      # delivered only for a buffer whose open was.
      #: () -> void
      def collect
        feed = @state.feed
        n = feed.count
        i = 0
        while i < n
          notice = feed.notice_at(i)
          key = notice.buffer_id.to_s
          case notice.kind
          when "open"
            @announced[key] = notice.path
            enqueue(notice, "buffer_open")
          when "close"
            if @announced.key?(key)
              @announced.delete(key)
              enqueue(notice, "buffer_close")
            end
          when "rename"
            enqueue(notice, "buffer_rename")
          else
            enqueue(notice, "buffer_change")
          end
          i += 1
        end
        feed.clear
      end

      #: (Domain::BufferNotice, String) -> void
      def enqueue(notice, name)
        row = notice.row
        col = 0
        current = @state.buffer
        if !notice.change? && current.id == notice.buffer_id
          row = @state.cursor.row
          col = @state.cursor.col
        end
        event = PluginApi::Event.new(name, notice.buffer_id, @state.window_id, notice.path.dup, row, col, notice.detail.dup, notice.removed, notice.inserted)
        @queue << PendingEvent.new(event, notice.cause)
      end

      #: (String, Domain::Buffer, Integer, Integer, String, String) -> void
      def queue(name, buffer, row, col, detail, cause)
        event = PluginApi::Event.new(name, buffer.id, @state.window_id, buffer.path_text.dup, row, col, detail, 0, 0)
        @queue << PendingEvent.new(event, cause)
      end

      # Delivers one event to every enabled subscriber but its cause, in
      # registration order.
      #: (PendingEvent) -> void
      def deliver(pending)
        event = pending.event
        i = 0
        while i < @registry.count
          e = @registry.entry(i)
          if e.enabled && e.subscribed?(event.name) && pending.for?(e.name)
            guarded(e) { e.plugin.on_event(event) }
          end
          i += 1
        end
      end

      #: () -> void
      def snapshot
        state = @state
        @last_buffer = state.buffer.id
        @last_row = state.cursor.row
        @last_col = state.cursor.col
        @last_mode = state.mode
        @last_tab = state.tab_index
        @last_window = state.window_id
      end
    end
  end
end
