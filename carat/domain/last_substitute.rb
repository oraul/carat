module Carat
  module Domain
    # What the last substitute leaves for the next one, as Vim keeps it:
    # its pattern ("" before the first), the string as typed, which :& and
    # & reuse, the string after "~" was expanded, which the next "~"
    # inserts, and the flags that "&" keeps: every match (all), whether a
    # pattern not found is reported (report), counting only (count_only),
    # case (:options, :ignore, or :match), and printing (:none, :line, or
    # :number, the line with its number). A Struct record: mutable, with a
    # reader and a writer per member.
    class LastSubstitute < Struct.new(:pattern, :replacement, :replacement_kept, :previous, :previous_kept, :all, :report, :count_only, :case_mode, :print, keyword_init: true)
      # @rbs @pattern: String
      # @rbs @replacement: String
      # @rbs @replacement_kept: bool
      # @rbs @previous: String
      # @rbs @previous_kept: bool
      # @rbs @all: bool
      # @rbs @report: bool
      # @rbs @count_only: bool
      # @rbs @case_mode: Symbol
      # @rbs @print: Symbol

      #: () -> void
      def initialize
        super(pattern: "", replacement: "", replacement_kept: false, previous: "", previous_kept: false, all: false, report: true, count_only: false, case_mode: :options, print: :none)
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
          self.case_mode = :options
          self.print = :none
        end
        i = 0
        while i < flags.length
          case flags[i, 1]
          when "g" then self.all = !all
          when "e" then self.report = !report
          when "n" then self.count_only = true
          when "i" then self.case_mode = :ignore
          when "I" then self.case_mode = :match
          when "p" then self.print = :line if print == :none
          when "#" then self.print = :number
          end
          i += 1
        end
      end

      # The string typed for this substitute, which a later :& reuses.
      #: (String) -> void
      def keep_replacement(text)
        self.replacement = text
        self.replacement_kept = true
      end

      # The string after "~" was expanded, which the next "~" inserts.
      #: (String) -> void
      def keep_previous(text)
        self.previous = text
        self.previous_kept = true
      end
    end
  end
end
