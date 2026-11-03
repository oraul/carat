require_relative "highlight"
require_relative "theme"

module Carat
  module Domain
    # The themes Carat ships, chosen by the option.theme line of the
    # configuration: carat-dark, the default, for a dark terminal and
    # carat-light for a light one. They are Ruby rather than configuration
    # lines because they are not key bindings and the configuration only
    # names one; user themes are in the backlog. Normal
    # keeps the terminal's own colors in both, so a theme never paints the
    # empty screen. Each row is a group id, foreground, background,
    # 16-color foreground, 16-color background, and attributes.
    module Themes
      DEFAULT = "carat-dark"
      NAMES = ["carat-dark", "carat-light"]

      #: (String) -> bool
      def self.known?(name)
        NAMES.include?(name)
      end

      # The theme with that name, carat-dark for an unknown one.
      #: (String) -> Theme
      def self.find(name)
        name == "carat-light" ? light : dark
      end

      #: () -> Theme
      def self.dark
        Theme.from_rows("carat-dark", [
          Highlight::LINE_NUMBER, 0x6c7086, -1, 8, -1, 0,
          Highlight::STATUS, 0xcdd6f4, 0x45475a, 0, 7, Theme::BOLD,
          Highlight::MESSAGE_ERROR, 0xf8f8f8, 0xc0392b, 15, 1, Theme::BOLD,
          Highlight::NON_TEXT, 0x585b70, -1, 8, -1, 0,
          Highlight::STATUS_NC, 0x9399b2, 0x313244, 8, 7, 0,
          Highlight::TAB_LINE, 0xa6adc8, 0x313244, 0, 7, 0,
          Highlight::TAB_LINE_SELECTED, 0xcdd6f4, -1, 15, -1, Theme::BOLD,
          Highlight::TAB_LINE_FILL, -1, 0x313244, -1, 7, 0,
          Highlight::VISUAL, -1, 0x45475a, 0, 7, 0,
          Highlight::SIGN_COLUMN, 0xf9e2af, -1, 11, -1, 0,
          Highlight::COMMENT, 0x7f849c, -1, 8, -1, Theme::ITALIC,
          Highlight::CONSTANT, 0xfab387, -1, 13, -1, 0,
          Highlight::STRING, 0xa6e3a1, -1, 10, -1, 0,
          Highlight::CHARACTER, 0x94e2d5, -1, 10, -1, 0,
          Highlight::NUMBER, 0xfab387, -1, 13, -1, 0,
          Highlight::BOOLEAN, 0xfab387, -1, 13, -1, 0,
          Highlight::FLOAT, 0xfab387, -1, 13, -1, 0,
          Highlight::IDENTIFIER, 0xf2cdcd, -1, 6, -1, 0,
          Highlight::FUNCTION, 0x89b4fa, -1, 12, -1, 0,
          Highlight::STATEMENT, 0xcba6f7, -1, 11, -1, 0,
          Highlight::CONDITIONAL, 0xcba6f7, -1, 11, -1, 0,
          Highlight::REPEAT, 0xcba6f7, -1, 11, -1, 0,
          Highlight::LABEL, 0x74c7ec, -1, 11, -1, 0,
          Highlight::OPERATOR, 0x89dceb, -1, 11, -1, 0,
          Highlight::KEYWORD, 0xcba6f7, -1, 11, -1, 0,
          Highlight::EXCEPTION, 0xf38ba8, -1, 9, -1, 0,
          Highlight::PRE_PROC, 0xf5c2e7, -1, 12, -1, 0,
          Highlight::INCLUDE, 0xf5c2e7, -1, 12, -1, 0,
          Highlight::DEFINE, 0xcba6f7, -1, 11, -1, 0,
          Highlight::MACRO, 0xf5c2e7, -1, 12, -1, 0,
          Highlight::TYPE, 0xf9e2af, -1, 14, -1, 0,
          Highlight::STORAGE_CLASS, 0xf9e2af, -1, 14, -1, 0,
          Highlight::STRUCTURE, 0xcba6f7, -1, 11, -1, 0,
          Highlight::TYPEDEF, 0xf9e2af, -1, 14, -1, 0,
          Highlight::SPECIAL, 0xf5c2e7, -1, 9, -1, 0,
          Highlight::SPECIAL_CHAR, 0xf5c2e7, -1, 9, -1, 0,
          Highlight::DELIMITER, 0x9399b2, -1, 7, -1, 0,
          Highlight::SPECIAL_COMMENT, 0x7f849c, -1, 8, -1, Theme::ITALIC,
          Highlight::TODO, 0x1e1e2e, 0xf9e2af, 0, 11, Theme::BOLD,
          Highlight::ERROR, 0xf38ba8, -1, 15, 1, Theme::UNDERLINE
        ])
      end

      #: () -> Theme
      def self.light
        Theme.from_rows("carat-light", [
          Highlight::LINE_NUMBER, 0x8c8fa1, -1, 8, -1, 0,
          Highlight::STATUS, 0x4c4f69, 0xccd0da, 0, 7, Theme::BOLD,
          Highlight::MESSAGE_ERROR, 0xffffff, 0xd20f39, 15, 1, Theme::BOLD,
          Highlight::NON_TEXT, 0xacb0be, -1, 8, -1, 0,
          Highlight::STATUS_NC, 0x6c6f85, 0xe6e9ef, 8, 7, 0,
          Highlight::TAB_LINE, 0x6c6f85, 0xe6e9ef, 0, 7, 0,
          Highlight::TAB_LINE_SELECTED, 0x4c4f69, -1, 0, -1, Theme::BOLD,
          Highlight::TAB_LINE_FILL, -1, 0xe6e9ef, -1, 7, 0,
          Highlight::VISUAL, -1, 0xbcc0cc, 0, 7, 0,
          Highlight::SIGN_COLUMN, 0xdf8e1d, -1, 3, -1, 0,
          Highlight::COMMENT, 0x8c8fa1, -1, 8, -1, Theme::ITALIC,
          Highlight::CONSTANT, 0xfe640b, -1, 1, -1, 0,
          Highlight::STRING, 0x40a02b, -1, 2, -1, 0,
          Highlight::CHARACTER, 0x179299, -1, 2, -1, 0,
          Highlight::NUMBER, 0xfe640b, -1, 1, -1, 0,
          Highlight::BOOLEAN, 0xfe640b, -1, 1, -1, 0,
          Highlight::FLOAT, 0xfe640b, -1, 1, -1, 0,
          Highlight::IDENTIFIER, 0xdd7878, -1, 6, -1, 0,
          Highlight::FUNCTION, 0x1e66f5, -1, 4, -1, 0,
          Highlight::STATEMENT, 0x8839ef, -1, 5, -1, 0,
          Highlight::CONDITIONAL, 0x8839ef, -1, 5, -1, 0,
          Highlight::REPEAT, 0x8839ef, -1, 5, -1, 0,
          Highlight::LABEL, 0x209fb5, -1, 5, -1, 0,
          Highlight::OPERATOR, 0x04a5e5, -1, 5, -1, 0,
          Highlight::KEYWORD, 0x8839ef, -1, 5, -1, 0,
          Highlight::EXCEPTION, 0xd20f39, -1, 1, -1, 0,
          Highlight::PRE_PROC, 0xea76cb, -1, 4, -1, 0,
          Highlight::INCLUDE, 0xea76cb, -1, 4, -1, 0,
          Highlight::DEFINE, 0x8839ef, -1, 5, -1, 0,
          Highlight::MACRO, 0xea76cb, -1, 4, -1, 0,
          Highlight::TYPE, 0xdf8e1d, -1, 6, -1, 0,
          Highlight::STORAGE_CLASS, 0xdf8e1d, -1, 6, -1, 0,
          Highlight::STRUCTURE, 0x8839ef, -1, 5, -1, 0,
          Highlight::TYPEDEF, 0xdf8e1d, -1, 6, -1, 0,
          Highlight::SPECIAL, 0xea76cb, -1, 1, -1, 0,
          Highlight::SPECIAL_CHAR, 0xea76cb, -1, 1, -1, 0,
          Highlight::DELIMITER, 0x7c7f93, -1, 8, -1, 0,
          Highlight::SPECIAL_COMMENT, 0x8c8fa1, -1, 8, -1, Theme::ITALIC,
          Highlight::TODO, 0xeff1f5, 0xdf8e1d, 0, 11, Theme::BOLD,
          Highlight::ERROR, 0xd20f39, -1, 15, 1, Theme::UNDERLINE
        ])
      end
    end
  end
end
