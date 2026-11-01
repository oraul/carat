require_relative "find"

module Carat
  module Domain
    # What the command grammar produces: the register name ("" for the
    # unnamed register), the count (0 when none was typed), the pending
    # operator action ("" for none), the action that completed the command
    # (a motion, a text object, or a standalone action), the character
    # argument of a find motion or "", whether a doubled operator made it
    # linewise, and the key codes that formed it, kept for the dot register.
    # A Data value: equal by value and frozen.
    class Command < Data.define(:register, :count, :operator, :action, :char, :linewise, :keys)
      # A command for an action with no register, count, or operator, as
      # insert and command-line modes dispatch.
      #: (String) -> Command
      def self.plain(action)
        Command.new("", 0, "", action, "", false, [])
      end

      # The count, or the default when none was typed.
      #: (Integer) -> Integer
      def count_or(default)
        count > 0 ? count : default
      end

      #: () -> bool
      def operator?
        !operator.empty?
      end
    end
  end
end
