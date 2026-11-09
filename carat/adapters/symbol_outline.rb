require_relative "../domain/symbol_request"
require_relative "../domain/control_text"

module Carat
  module Adapters
    # Reads a textDocument/documentSymbol answer, untrusted, into the
    # shared SymbolRequest: the held symbols are dropped and the next ones
    # kept for the buffer last asked. A DocumentSymbol list (range,
    # children) or a SymbolInformation list (location.range) is walked in
    # order, parents before children, keeping at most LIMIT symbols and
    # DEPTH_LIMIT levels, each name stripped of control characters and
    # cut to NAME_LIMIT characters. An item without a string name or with
    # a range whose start line is negative or whose end is before its
    # start is skipped, its children still read; an error or a result
    # that is not a list holds no symbols.
    class SymbolOutline
      LIMIT = 500
      DEPTH_LIMIT = 8
      NAME_LIMIT = 40

      #: (untyped, Domain::SymbolRequest) -> void
      def self.read(result, symbols)
        symbols.restart
        walk(result, symbols, 1) if result.is_a?(Array)
      end

      #: (untyped, Domain::SymbolRequest, Integer) -> void
      def self.walk(list, symbols, depth)
        i = 0
        while i < list.length && symbols.count < LIMIT
          item = list[i]
          i += 1
          next unless item.is_a?(Hash)
          keep(item, symbols)
          children = item["children"]
          walk(children, symbols, depth + 1) if children.is_a?(Array) && depth < DEPTH_LIMIT
        end
      end

      # Keeps one item when it has a string name and a valid range.
      #: (untyped, Domain::SymbolRequest) -> void
      def self.keep(item, symbols)
        name = item["name"]
        return unless name.is_a?(String)
        range = item["range"]
        location = item["location"]
        range = location["range"] if !range.is_a?(Hash) && location.is_a?(Hash)
        return unless range.is_a?(Hash)
        first = line_of(range["start"])
        last = line_of(range["end"])
        return if first < 0 || last < first
        text = Domain::ControlText.strip(name.to_s, NAME_LIMIT)
        symbols.add(text, first, last) unless text.empty?
      end

      # The line of a position, -1 when it has none.
      #: (untyped) -> Integer
      def self.line_of(position)
        return -1 unless position.is_a?(Hash)
        line = position["line"]
        line.is_a?(Integer) ? line.to_i : -1
      end
    end
  end
end
