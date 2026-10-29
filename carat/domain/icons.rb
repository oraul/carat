module Carat
  module Domain
    # The icon table: one glyph per name in each of three sets. The nerd
    # set uses Nerd Fonts code points in the private use areas, which take
    # one cell and need a Nerd Font in the terminal; the unicode set uses
    # triangles, bullets, and geometric shapes common terminal fonts have;
    # the ascii set uses plain characters. Plugins ask for icons by name
    # through the host, never by code point, so the icons option switches
    # the whole editor.
    module Icons
      SETS = ["nerd", "unicode", "ascii"]

      NAMES = ["folder_closed", "folder_open", "file", "symlink", "modified", "error", "warning", "info", "hint", "ruby", "json", "markdown", "toml", "makefile", "shell", "c", "yaml", "git", "lock", "default"]

      NERD = {
        "folder_closed" => "\u{F07B}",
        "folder_open" => "\u{F07C}",
        "file" => "\u{F016}",
        "symlink" => "\u{F0C1}",
        "modified" => "\u{F111}",
        "error" => "\u{F057}",
        "warning" => "\u{F071}",
        "info" => "\u{F05A}",
        "hint" => "\u{F0EB}",
        "ruby" => "\u{E791}",
        "json" => "\u{E60B}",
        "markdown" => "\u{E73E}",
        "toml" => "\u{E6B2}",
        "makefile" => "\u{E779}",
        "shell" => "\u{E795}",
        "c" => "\u{E61E}",
        "yaml" => "\u{E6A8}",
        "git" => "\u{E702}",
        "lock" => "\u{F023}",
        "default" => "\u{F016}"
      }

      UNICODE = {
        "folder_closed" => "▸",
        "folder_open" => "▾",
        "file" => "•",
        "symlink" => "→",
        "modified" => "●",
        "error" => "✖",
        "warning" => "▲",
        "info" => "◆",
        "hint" => "◇",
        "ruby" => "◈",
        "json" => "▣",
        "markdown" => "¶",
        "toml" => "≡",
        "makefile" => "▤",
        "shell" => "▶",
        "c" => "□",
        "yaml" => "▥",
        "git" => "±",
        "lock" => "⊘",
        "default" => "•"
      }

      ASCII = {
        "folder_closed" => "+",
        "folder_open" => "-",
        "file" => ".",
        "symlink" => "~",
        "modified" => "*",
        "error" => "X",
        "warning" => "!",
        "info" => "i",
        "hint" => "?",
        "ruby" => "r",
        "json" => "j",
        "markdown" => "m",
        "toml" => "t",
        "makefile" => "M",
        "shell" => "$",
        "c" => "c",
        "yaml" => "y",
        "git" => "g",
        "lock" => "#",
        "default" => "."
      }

      # The glyph for a name in a set, "" for an unknown name; an unknown
      # set reads as nerd.
      #: (String, String) -> String
      def self.glyph(name, set)
        glyph = table(set)[name]
        glyph.nil? ? "" : glyph
      end

      #: (String) -> Hash[String, String]
      def self.table(set)
        case set
        when "unicode" then UNICODE
        when "ascii" then ASCII
        else NERD
        end
      end

      #: (String) -> bool
      def self.set?(name)
        SETS.include?(name)
      end
    end
  end
end
