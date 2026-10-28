module Carat
  module Domain
    # The editor modes as symbols, with the names used in the JSON keymaps.
    module Mode
      NORMAL = :normal
      INSERT = :insert
      REPLACE = :replace
      VISUAL = :visual
      VISUAL_LINE = :visual_line
      VISUAL_BLOCK = :visual_block
      OPERATOR_PENDING = :operator_pending
      CMDLINE = :cmdline

      NAMES = ["normal", "insert", "replace", "visual", "visual_line", "visual_block", "operator_pending", "cmdline"]

      #: (String) -> Symbol?
      def self.from_name(name)
        case name
        when "normal" then NORMAL
        when "insert" then INSERT
        when "replace" then REPLACE
        when "visual" then VISUAL
        when "visual_line" then VISUAL_LINE
        when "visual_block" then VISUAL_BLOCK
        when "operator_pending" then OPERATOR_PENDING
        when "cmdline" then CMDLINE
        else nil
        end
      end

      #: (Symbol) -> String
      def self.name_of(mode)
        mode.to_s
      end
    end
  end
end
