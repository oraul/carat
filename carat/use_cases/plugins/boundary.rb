module Carat
  module UseCases
    # What the plugin host does to values crossing the plugin boundary:
    # strings are copied in both directions, so a plugin never shares a
    # mutable string with the editor. A module function rather than a
    # concern, so its signature is applied.
    module Boundary
      # A new array holding a copy of each string.
      #: (Array[String]) -> Array[String]
      def self.copied_lines(lines)
        out = []
        i = 0
        while i < lines.length
          out << lines[i] + ""
          i += 1
        end
        out
      end
    end
  end
end
