module Carat
  module Domain
    # What the plugins show around the text, the plugin host's own state:
    # the status line segments they set, by plugin name in registration
    # order, and the prompt a plugin opened on the command line: its text,
    # the plugin, and the plugin's id for it, all "" when none is open.
    # The presenter draws it; the command line hands an answer to the
    # owner. A Struct record: mutable, with a reader and a writer per
    # member.
    class PluginUi < Struct.new(:segments, :prompt, :prompt_owner, :prompt_id)
      # @rbs @segments: Hash[String, String]
      # @rbs @prompt: String
      # @rbs @prompt_owner: String
      # @rbs @prompt_id: String

      # The empty segments are stored through the writer, so they take the
      # pinned type.
      #: () -> void
      def initialize
        super()
        self.segments = {}
        self.prompt = ""
        self.prompt_owner = ""
        self.prompt_id = ""
      end

      # Whether a plugin's prompt holds the command line.
      #: () -> bool
      def prompting?
        !prompt_owner.empty?
      end

      #: (String, String, String) -> void
      def open_prompt(owner, id, text)
        self.prompt = text
        self.prompt_owner = owner
        self.prompt_id = id
      end

      #: () -> void
      def close_prompt
        self.prompt = ""
        self.prompt_owner = ""
        self.prompt_id = ""
      end

      # Sets the plugin's status segment; empty text removes it.
      #: (String, String) -> void
      def segment(owner, text)
        if text.empty?
          segments.delete(owner)
        else
          segments[owner] = text
        end
      end

      # Removes the plugin's segment, and its prompt when one is open.
      #: (String) -> void
      def drop(owner)
        segments.delete(owner)
        close_prompt if prompt_owner == owner
      end
    end
  end
end
