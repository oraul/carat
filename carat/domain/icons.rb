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

      NAMES = ["folder_closed", "folder_open", "file", "symlink", "modified", "current", "error", "warning", "info", "hint", "ruby", "json", "markdown", "toml", "makefile", "shell", "c", "yaml", "git", "lock", "default", "kind_text", "kind_method", "kind_function", "kind_constructor", "kind_field", "kind_variable", "kind_class", "kind_module", "kind_property", "kind_keyword", "kind_snippet", "kind_constant"]

      NERD = {
        "folder_closed" => "\u{F07B}",
        "folder_open" => "\u{F07C}",
        "file" => "\u{F016}",
        "symlink" => "\u{F0C1}",
        "modified" => "\u{F111}",
        "current" => "\u{F054}",
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
        "default" => "\u{F016}",
        "kind_text" => "\u{EA93}",
        "kind_method" => "\u{EA8C}",
        "kind_function" => "\u{EA8C}",
        "kind_constructor" => "\u{EA8C}",
        "kind_field" => "\u{EB5F}",
        "kind_variable" => "\u{EA88}",
        "kind_class" => "\u{EB5B}",
        "kind_module" => "\u{EA8B}",
        "kind_property" => "\u{EB65}",
        "kind_keyword" => "\u{EB62}",
        "kind_snippet" => "\u{EB66}",
        "kind_constant" => "\u{EB5D}"
      }

      UNICODE = {
        "folder_closed" => "▸",
        "folder_open" => "▾",
        "file" => "•",
        "symlink" => "→",
        "modified" => "●",
        "current" => "›",
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
        "default" => "•",
        "kind_text" => "≡",
        "kind_method" => "◊",
        "kind_function" => "◊",
        "kind_constructor" => "◘",
        "kind_field" => "▪",
        "kind_variable" => "▫",
        "kind_class" => "◈",
        "kind_module" => "▣",
        "kind_property" => "▸",
        "kind_keyword" => "◇",
        "kind_snippet" => "‣",
        "kind_constant" => "◆"
      }

      ASCII = {
        "folder_closed" => "+",
        "folder_open" => "-",
        "file" => ".",
        "symlink" => "~",
        "modified" => "*",
        "current" => ">",
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
        "default" => ".",
        "kind_text" => "T",
        "kind_method" => "m",
        "kind_function" => "f",
        "kind_constructor" => "n",
        "kind_field" => "d",
        "kind_variable" => "v",
        "kind_class" => "C",
        "kind_module" => "M",
        "kind_property" => "p",
        "kind_keyword" => "k",
        "kind_snippet" => "s",
        "kind_constant" => "K"
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
