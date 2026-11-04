module Carat
  module Domain
    # What the last substitute leaves for the next one, as Vim keeps it:
    # its pattern ("" before the first), the string as typed, which :& and
    # & reuse, the string after "~" was expanded, which the next "~"
    # inserts, and the flags that "&" keeps: every match (all), whether a
    # pattern not found is reported (report), counting only (count_only),
    # case (0 by the options, 1 ignored, 2 matched), and printing (0 none,
    # 1 the line, 2 with its number). A Struct record: mutable, with a
    # reader and a writer per member.
    class LastSubstitute < Struct.new(:pattern, :replacement, :has_replacement, :previous, :has_previous, :all, :report, :count_only, :case_mode, :print, keyword_init: true)
      # @rbs @pattern: String
      # @rbs @replacement: String
      # @rbs @has_replacement: bool
      # @rbs @previous: String
      # @rbs @has_previous: bool
      # @rbs @all: bool
      # @rbs @report: bool
      # @rbs @count_only: bool
      # @rbs @case_mode: Integer
      # @rbs @print: Integer

      #: () -> void
      def initialize
        super(pattern: "", replacement: "", has_replacement: false, previous: "", has_previous: false, all: false, report: true, count_only: false, case_mode: 0, print: 0)
      end

      # Reads the flags as Vim does: without a leading "&" they start again
      # from none; "g" and "e" switch, "n", "i", "I", "p", and "#" set, and
      # "r", "c", and "l" are read by the command itself.
      #: (String) -> void
      def apply_flags(flags)
        unless flags.start_with?("&")
          self.all = false
          self.report = true
          self.count_only = false
          self.case_mode = 0
          self.print = 0
        end
        i = 0
        while i < flags.length
          case flags[i, 1]
          when "g" then self.all = !all
          when "e" then self.report = !report
          when "n" then self.count_only = true
          when "i" then self.case_mode = 1
          when "I" then self.case_mode = 2
          when "p" then self.print = 1 if print == 0
          when "#" then self.print = 2
          end
          i += 1
        end
      end

      # The string typed for this substitute, which a later :& reuses.
      #: (String) -> void
      def keep_replacement(text)
        self.replacement = text
        self.has_replacement = true
      end

      # The string after "~" was expanded, which the next "~" inserts.
      #: (String) -> void
      def keep_previous(text)
        self.previous = text
        self.has_previous = true
      end
    end
  end
end
