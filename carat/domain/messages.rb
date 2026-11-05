module Carat
  module Domain
    # The editor's messages that more than one use case or handler shows,
    # in Vim's wording: a constant for fixed text, a function for text
    # with a value in it.
    module Messages
      E36 = "E36: Not enough room"
      E37 = "E37: No write since last change (add ! to override)"

      # The two lines of Neovim's check_changed_any, which refuses to quit
      # over another buffer's unsaved changes: E37 without the hint, then
      # E162 naming the buffer by its path, "" for [No Name].
      #: (String) -> String
      def self.unsaved_buffer(path)
        name = path.empty? ? "[No Name]" : path
        "E37: No write since last change\nE162: No write since last change for buffer \"#{name}\""
      end

      # The refusal of a write to a read-only register.
      #: (String) -> String
      def self.read_only_register(name)
        "E354: Invalid register name: '#{name}'"
      end

      # The refusal of a put from an empty register; the unnamed register
      # when name is empty.
      #: (String) -> String
      def self.nothing_in_register(name)
        "E353: Nothing in register #{name.empty? ? "\"" : name}"
      end

      # How long ago, in whole seconds, as Neovim writes it under 100
      # seconds; a negative time counts as 0.
      #: (Float) -> String
      def self.seconds_ago(seconds)
        whole = seconds.to_i
        whole = 0 if whole < 0
        whole == 1 ? "1 second ago" : "#{whole} seconds ago"
      end
    end
  end
end
