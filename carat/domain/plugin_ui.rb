module Carat
  module Domain
    # What the plugins show around the text, the plugin host's own state:
    # the status bar segments they set, by plugin name, with owners
    # holding the names in the order the segments were first set and
    # priorities each one's priority beside it, so the bar reads them
    # without building a list, and the prompt a plugin opened on the command line: its text,
    # the plugin, and the plugin's id for it, all "" when none is open.
    # The presenter draws it; the command line hands an answer to the
    # owner. A Struct record: mutable, with a reader and a writer per
    # member.
    class PluginUi < Struct.new(:segments, :owners, :priorities, :prompt, :prompt_owner, :prompt_id, keyword_init: true)
      # @rbs @segments: Hash[String, String]
      # @rbs @owners: Array[String]
      # @rbs @priorities: Array[Integer]
      # @rbs @prompt: String
      # @rbs @prompt_owner: String
      # @rbs @prompt_id: String

      # The empty segments are stored through the writer, so they take the
      # pinned type.
      #: () -> void
      def initialize
        super()
        self.segments = {}
        self.owners = []
        self.priorities = []
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

      # Sets the plugin's status segment with its priority; empty text
      # removes it. A segment set again keeps its place.
      #: (String, String, Integer) -> void
      def segment(owner, text, priority)
        if text.empty?
          remove_segment(owner)
          return
        end
        segments[owner] = text
        at = owners.index(owner)
        if at.nil?
          owners << owner
          priorities << priority
        else
          priorities[at] = priority
        end
      end

      # The segment text of the owner at position i of owners.
      #: (Integer) -> String
      def text_at(i)
        text = segments[owners[i]]
        text.nil? ? "" : text
      end

      # Removes the plugin's segment, and its prompt when one is open.
      #: (String) -> void
      def drop(owner)
        remove_segment(owner)
        close_prompt if prompt_owner == owner
      end

      # Removes the plugin's segment with its place and priority.
      #: (String) -> void
      def remove_segment(owner)
        segments.delete(owner)
        at = owners.index(owner)
        return if at.nil?
        owners.delete_at(at)
        priorities.delete_at(at)
      end
    end
  end
end
