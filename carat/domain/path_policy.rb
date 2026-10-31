require_relative "../plugin_api"

module Carat
  module Domain
    # The rules a path or a name given for a file operation must obey,
    # without touching the disk: containment in a root is lexical, after
    # resolving "." and "..", as the tree shows it; a created path needs a
    # last name, and a new name for a rename is one name in the same
    # directory. Each check answers the message of the rule broken, or ""
    # when the rule holds. Paths are normalized absolute paths.
    module PathPolicy
      # The last name of a path as typed: "" when it ends with a "/".
      #: (String) -> String
      def self.last_name(path)
        return "" if path.end_with?("/")
        PluginApi::Paths.basename(path)
      end

      #: (String) -> String
      def self.create_problem(path)
        last = last_name(path)
        return "Empty name" if last.empty? || last == "." || last == ".."
        ""
      end

      #: (String) -> String
      def self.rename_problem(name)
        return "Empty name" if name.empty?
        return "Name contains a path separator: #{name}" if name.include?("/")
        return "Invalid name: #{name}" if name == "." || name == ".."
        ""
      end

      # Whether target lies strictly below root.
      #: (String, String) -> bool
      def self.inside?(root, target)
        PluginApi::Paths.inside?(root, target)
      end

      # The path for a message: relative to the working directory when it
      # lies below it.
      #: (String, String) -> String
      def self.shown(cwd, path)
        PluginApi::Paths.relative(cwd, path)
      end
    end
  end
end
