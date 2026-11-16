require_relative "../../plugin_api"
require_relative "groups"
require_relative "keywords"
require_relative "tokenizer"
require_relative "structure"

module Carat
  module Plugins
    module Ruby
      # Syntax highlighting for Ruby: the plugin declares the ruby filetype
      # and tokenizes its lines with Tokenizer, after resolving the names
      # of its highlight groups through the host once, when it is
      # activated. It also marks the block opener a Ruby file leaves open
      # with the error sign, found by Structure when the buffer opens,
      # after each change outside the typing modes, and when a typing
      # mode ends, so a keystroke never rescans the buffer. It has no
      # actions, commands, bindings, or options.
      class Plugin < Carat::PluginApi::Plugin
        NAME = "ruby"
        # The modes in which a change waits for the mode to end.
        TYPING = ["insert", "replace", "completion"]
        # The file name endings and names that make a buffer Ruby, as the
        # editor's filetype detection reads them.
        EXTENSIONS = [".rb", ".rake", ".gemspec", ".ru"]
        NAMES = ["Gemfile", "Rakefile"]

        attr_reader :tokenizer #: Tokenizer

        # @rbs @structure: Structure
        # @rbs @host: Carat::PluginApi::Host?
        # @rbs @typing: bool
        # @rbs @waiting: Array[Integer]

        #: () -> void
        def initialize
          keywords = Keywords.new
          @tokenizer = Tokenizer.new(keywords: keywords)
          @structure = Structure.new(keywords: keywords)
          @host = nil
          @typing = false
          @waiting = Array.new(0, 0)
        end

        # Returns the manifest.
        # @rbs skip
        def manifest
          Carat::PluginApi::Manifest.new(name: NAME, version: "1.1.0", api_version: Carat::PluginApi::VERSION, actions: {}, commands: {}, bindings: [], events: ["buffer_open", "buffer_change", "mode_change"], options: [], option_types: {}, filetypes: ["ruby"])
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
          @host = host
        end

        #: () -> void
        def deactivate
          @host = nil
        end

        # Checks a Ruby buffer when it opens, when it changes outside the
        # typing modes, and, for the buffers changed while typing, when
        # the typing mode ends.
        #: (Carat::PluginApi::Event) -> void
        def on_event(event)
          if event.name == "mode_change"
            @typing = TYPING.include?(event.detail)
            return if @typing
            i = 0
            while i < @waiting.length
              check(@waiting[i])
              i += 1
            end
            @waiting.clear
            return
          end
          return unless ruby_path?(event.path)
          if event.name == "buffer_change" && @typing
            @waiting << event.buffer unless @waiting.include?(event.buffer)
            return
          end
          check(event.buffer)
        end

        # Returns the state at the end of the line.
        # @rbs filetype: String
        # @rbs text: String
        # @rbs state: Integer
        # @rbs tokens: Array[Integer]
        def tokenize(filetype, text, state, tokens)
          @tokenizer.call(text, state, tokens)
        end

        private

        # Moves the plugin's sign in the buffer to the opener it leaves
        # open, removing it when none is.
        #: (Integer) -> void
        def check(buffer)
          host = @host
          return if host.nil?
          view = host.read_buffer(buffer)
          return unless view.ok
          row = @structure.call(view.lines)
          host.clear_signs(buffer)
          host.place_sign(buffer, row, "error") if row >= 0
        end

        # Whether the file name at the end of path is a Ruby file name.
        #: (String) -> bool
        def ruby_path?(path)
          slash = path.byterindex("/")
          name = slash.nil? ? path : path.byteslice(slash + 1, path.bytesize - slash - 1).to_s
          return true if NAMES.include?(name)
          i = 0
          while i < EXTENSIONS.length
            return true if name.end_with?(EXTENSIONS[i]) && name.bytesize > EXTENSIONS[i].bytesize
            i += 1
          end
          false
        end
      end
    end
  end
end
