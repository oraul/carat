require_relative "../../plugin_api"
require_relative "groups"
require_relative "keywords"
require_relative "tokenizer"

module Carat
  module Plugins
    module Ruby
      # Syntax highlighting for Ruby: the plugin declares the ruby filetype
      # and tokenizes its lines with Tokenizer, after resolving the names
      # of its highlight groups through the host once, when it is
      # activated. It has no actions, commands, bindings, events, or
      # options.
      class Plugin < Carat::PluginApi::Plugin
        NAME = "ruby"

        attr_reader :tokenizer #: Tokenizer

        #: () -> void
        def initialize
          @tokenizer = Tokenizer.new(keywords: Keywords.new)
        end

        # Returns the manifest.
        # @rbs skip
        def manifest
          Carat::PluginApi::Manifest.new(NAME, "1.0.0", Carat::PluginApi::VERSION, {}, {}, nil, [], {}, {}, ["ruby"])
        end

        # Resolves the group names; a name the host does not know leaves its
        # tokens out.
        #: (Carat::PluginApi::Host) -> void
        def activate(host)
          ids = Array.new(Groups::NAMES.length, -1)
          i = 0
          while i < Groups::NAMES.length
            response = host.syntax_group(Groups::NAMES[i])
            ids[i] = response.number if response.ok
            i += 1
          end
          @tokenizer.ids = ids
        end

        # Returns the state at the end of the line.
        # @rbs filetype: String
        # @rbs text: String
        # @rbs state: Integer
        # @rbs tokens: Array[Integer]
        def tokenize(filetype, text, state, tokens)
          @tokenizer.call(text, state, tokens)
        end
      end
    end
  end
end
