require_relative "../../plugin_api"
require_relative "../../domain/highlight"
require_relative "../../domain/syntax_line"
require_relative "../concerns/guarded"
require_relative "plugin_entry"
require_relative "plugin_registry"

module Carat
  module UseCases
    # The plugins as tokenizers: which enabled plugin tokenizes a syntax
    # (the first registered that declares it), and one guarded call per
    # line. The text the plugin receives is a copy in a string this class
    # reuses, and the tokens go into an integer array it reuses too, so a
    # call allocates nothing on the host's side; copied_tokens copies the
    # valid triples of the last call for a row the cache keeps. The token
    # array is made with Array.new rather than an empty literal, which
    # Spinel copies when it is passed to another method, so the plugin's
    # appends would be lost. A plugin that raises is disabled by the
    # guard, as for every plugin call.
    class PluginSyntax
      include Guarded

      attr_reader :registry #: PluginRegistry
      attr_reader :tokens #: Array[Integer]

      # @rbs @text: String
      # @rbs @end_state: Integer

      #: (registry: PluginRegistry) -> void
      def initialize(registry:)
        @registry = registry
        @text = +""
        @tokens = Array.new(0, 0)
        @end_state = 0
      end

      # The enabled plugin that tokenizes the syntax, the first registered
      # that declares it, or nil.
      #: (String) -> PluginEntry?
      def provider(syntax)
        registry = @registry
        i = 0
        count = registry.count
        while i < count
          e = registry.entry(i)
          return e if e.enabled && e.tokenizes?(syntax)
          i += 1
        end
        nil
      end

      # Tokenizes one line with the entry's plugin for the syntax, from the
      # start state, and returns the end state, 0 for one that is not a
      # non-negative integer, or Domain::SyntaxLine::FAILED when the plugin
      # raised and is disabled. The tokens stay in tokens until the next call.
      #: (PluginEntry, String, String, Integer) -> Integer
      def tokenize(entry, syntax, line, start)
        @tokens.clear
        @text.replace(line)
        @end_state = 0
        plugin = entry.plugin
        text = @text
        tokens = @tokens
        ok = guarded(entry) { @end_state = state_of(plugin.tokenize(syntax, text, start, tokens)) }
        ok ? @end_state : Domain::SyntaxLine::FAILED
      end

      # A copy of the valid triples of the last call: a start of 0 or
      # more, a length of 1 or more, and a syntax or file-icon group id.
      #: () -> Array[Integer]
      def copied_tokens
        copy = Array.new(0, 0)
        tokens = @tokens
        i = 0
        while i + 2 < tokens.length
          from = tokens[i]
          length = tokens[i + 1]
          group = tokens[i + 2]
          if from >= 0 && length > 0 && Domain::Highlight.token?(group)
            copy << from
            copy << length
            copy << group
          end
          i += 3
        end
        copy
      end

      private

      # A returned state as the host keeps it: a non-negative integer, 0
      # for anything else.
      #: (untyped) -> Integer
      def state_of(value)
        return 0 unless value.is_a?(Integer)
        value < 0 ? 0 : value
      end
    end
  end
end
