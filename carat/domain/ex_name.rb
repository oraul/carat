module Carat
  module Domain
    # The name of an ex command in Vim's notation name[suffix]: the
    # shortest spelling, short, and the full one. A typed name matches
    # when it is at least as long as short and the full name starts with
    # it, so "vs", "vsp", and "vsplit" all name vs[plit] and "vsplitx" and
    # "v" do not. A Data value: equal by value and frozen.
    class ExName < Data.define(:short, :full)
      # @rbs @short: String
      # @rbs @full: String

      # Reads Vim's notation: "tabfir[st]" has the short form "tabfir" and
      # the full form "tabfirst"; a spec without brackets, as "new", is
      # its own short form.
      #: (String) -> ExName
      def self.parse(spec)
        open = spec.index("[")
        return ExName.new(spec, spec) if open.nil?
        close = spec.index("]")
        close = spec.length if close.nil? || close < open
        short = spec[0, open]
        ExName.new(short, short + spec[open + 1, close - open - 1])
      end

      #: (String) -> bool
      def match?(typed)
        typed.length >= short.length && typed.length <= full.length && full.start_with?(typed)
      end

      # The name in Vim's notation.
      #: () -> String
      def to_s
        return full if short == full
        "#{short}[#{full[short.length, full.length - short.length]}]"
      end
    end
  end
end
