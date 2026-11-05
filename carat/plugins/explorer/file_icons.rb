module Carat
  module Plugins
    module Explorer
      # Chooses the icon name of a tree line from the host's icon table:
      # a folder closed or open for a directory, symlink for a link, and
      # for a file the icon of its type, by name or extension. GROUPS names
      # the file-icon highlight group each icon is drawn in.
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

        GROUPS = {
          "folder_closed" => "DevIconFolder",
          "folder_open" => "DevIconFolder",
          "symlink" => "DevIconSymlink",
          "ruby" => "DevIconRb",
          "json" => "DevIconJson",
          "markdown" => "DevIconMd",
          "toml" => "DevIconToml",
          "makefile" => "DevIconMakefile",
          "shell" => "DevIconSh",
          "c" => "DevIconC",
          "yaml" => "DevIconYml",
          "git" => "DevIconGitIgnore",
          "lock" => "DevIconLock",
          "default" => "DevIconDefault"
        }

        #: (String, bool, bool, bool) -> String
        def self.name_for(name, directory, expanded, symlink)
          return "symlink" if symlink
          return expanded ? "folder_open" : "folder_closed" if directory
          file_type(name)
        end

        # The icon name of a file: by its whole name first, then by the
        # text after its last dot, "default" otherwise. The dot is found by
        # bytes, so a name that is not UTF-8 finds its extension.
        #: (String) -> String
        def self.file_type(name)
          whole = NAMES[name]
          return whole unless whole.nil?
          dot = name.byterindex(".")
          return "default" if dot.nil? || dot == 0
          by_extension = EXTENSIONS[name.byteslice(dot + 1, name.bytesize - dot - 1).to_s]
          by_extension.nil? ? "default" : by_extension
        end
      end
    end
  end
end
