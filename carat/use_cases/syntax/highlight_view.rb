require_relative "../../domain/editor_state"
require_relative "../../domain/window"
require_relative "../../domain/buffer"
require_relative "../../domain/syntax_cache"
require_relative "../plugins/plugin_entry"
require_relative "../plugins/plugin_syntax"

module Carat
  module UseCases
    # Brings the syntax cache of every buffer shown in the current tab
    # page up to date for the next frame, so the frame presenter only
    # reads it. For each window it finds the plugin that tokenizes the
    # buffer's syntax; without one, or with syntax off, the cache is
    # dropped and the buffer drawn plain. Otherwise the end states are
    # advanced from the first row not known to be right down to the last
    # visible row, tokenizing a row above the window for its end state
    # only, and every visible row gets its tokens for its start state,
    # tokenizing only a line the cache does not hold. Rows below the
    # window are never tokenized. A plugin that raises is disabled by the
    # guard and its buffer dropped in the same frame, or taken over by the
    # next plugin that declares the syntax. tokenized counts the
    # lines tokenized since the editor started, which the benchmark
    # reads. Run before every render, after ArrangeView.
    class HighlightView
      attr_reader :syntax #: PluginSyntax
      attr_reader :tokenized #: Integer

      # @rbs @serial: Integer

      #: (syntax: PluginSyntax) -> void
      def initialize(syntax:)
        @syntax = syntax
        @tokenized = 0
        @serial = 0
      end

      #: (Domain::EditorState) -> void
      def call(state)
        @serial += 1
        on = state.options.syntax_on
        layout = state.tab.layout
        ids = layout.leaves
        i = 0
        while i < ids.length
          highlight(layout.window_at(ids[i]), on)
          i += 1
        end
      end

      private

      # Brings the cache of one window's buffer up to date, or drops it.
      # When the tokenizer fails its plugin is disabled, and the next
      # plugin that declares the syntax, if any, takes over in this frame.
      #: (Domain::Window, bool) -> void
      def highlight(window, on)
        buffer = window.buffer
        cache = buffer.syntax_cache
        name = buffer.syntax
        while true
          entry = on && !name.empty? ? @syntax.provider(name) : nil
          if entry.nil?
            cache.drop
            return
          end
          cache.prepare(entry.name, name, @serial)
          top = window.top
          bottom = top + window.height
          count = buffer.line_count
          bottom = count if bottom > count
          return if top >= bottom
          failed = advance(entry, buffer, cache, name, top, bottom) == PluginSyntax::FAILED
          failed = fill(entry, buffer, cache, name, top, bottom) == PluginSyntax::FAILED unless failed
          return unless failed
          cache.drop
        end
      end

      # Moves valid down to bottom; returns 0, or FAILED when the plugin
      # failed.
      #: (PluginEntry, Domain::Buffer, Domain::SyntaxCache, String, Integer, Integer) -> Integer
      def advance(entry, buffer, cache, name, top, bottom)
        while cache.valid < bottom
          row = cache.valid
          start = cache.start_of(row)
          line = buffer.line(row)
          finish = -1
          if row >= top
            hit = cache.find(line, start)
            finish = hit.end_state unless hit.nil?
          end
          if finish < 0
            finish = @syntax.tokenize(entry, name, line, start)
            return PluginSyntax::FAILED if finish == PluginSyntax::FAILED
            @tokenized += 1
            cache.store(line, start, @syntax.copied_tokens, finish) if row >= top
          end
          cache.advance(row, finish)
        end
        0
      end

      # Gives every visible row its tokens for its start state; returns 0,
      # or FAILED when the plugin failed.
      #: (PluginEntry, Domain::Buffer, Domain::SyntaxCache, String, Integer, Integer) -> Integer
      def fill(entry, buffer, cache, name, top, bottom)
        row = top
        while row < bottom
          start = cache.start_of(row)
          line = buffer.line(row)
          if cache.find(line, start).nil?
            finish = @syntax.tokenize(entry, name, line, start)
            return PluginSyntax::FAILED if finish == PluginSyntax::FAILED
            @tokenized += 1
            cache.store(line, start, @syntax.copied_tokens, finish)
          end
          row += 1
        end
        0
      end
    end
  end
end
