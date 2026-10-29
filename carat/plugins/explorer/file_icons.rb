module Carat
  module Plugins
    module Explorer
      # Chooses the icon name of a tree line from the host's icon table:
      # a folder closed or open for a directory, symlink for a link, and
      # for a file the icon of its type, by name or extension.
      module FileIcons
        NAMES = {
          "Makefile" => "makefile",
          "makefile" => "makefile",
          "GNUmakefile" => "makefile",
          ".gitignore" => "git",
          ".gitattributes" => "git",
          ".gitmodules" => "git"
        }

        EXTENSIONS = {
          "rb" => "ruby",
          "json" => "json",
          "md" => "markdown",
          "toml" => "toml",
          "sh" => "shell",
          "c" => "c",
          "h" => "c",
          "yml" => "yaml",
          "yaml" => "yaml",
          "lock" => "lock"
        }

        #: (String, bool, bool, bool) -> String
        def self.name_for(name, directory, expanded, symlink)
          return "symlink" if symlink
          return expanded ? "folder_open" : "folder_closed" if directory
          file_type(name)
        end

        # The icon name of a file: by its whole name first, then by the
        # text after its last dot, "default" otherwise.
        #: (String) -> String
        def self.file_type(name)
          whole = NAMES[name]
          return whole unless whole.nil?
          dot = name.rindex(".")
          return "default" if dot.nil? || dot == 0
          by_extension = EXTENSIONS[name[dot + 1, name.length - dot - 1]]
          by_extension.nil? ? "default" : by_extension
        end
      end
    end
  end
end
