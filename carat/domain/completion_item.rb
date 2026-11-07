require_relative "control_text"

module Carat
  module Domain
    # One completion candidate as the menu keeps it: the label the row
    # shows, the kind (one of KINDS, its icon named kind_<kind>), the
    # detail or type shown on the right, and the text an accepted item
    # inserts. Built by from_source, which treats every string as
    # untrusted. A Data value.
    class CompletionItem < Data.define(:label, :kind, :detail, :text)
      # @rbs @label: String
      # @rbs @kind: String
      # @rbs @detail: String
      # @rbs @text: String

      KINDS = ["text", "method", "function", "constructor", "field", "variable", "class", "module", "property", "keyword", "snippet", "constant"]
      LABEL_LIMIT = 80
      DETAIL_LIMIT = 80
      TEXT_LIMIT = 200

      # A candidate from a source's strings: escape sequences and controls
      # dropped and each string cut to its limit of bytes; a kind outside
      # KINDS reads as text and an empty text as the label.
      #: (String, String, String, String) -> CompletionItem
      def self.from_source(label, kind, detail, text)
        clean_label = ControlText.plain(label, LABEL_LIMIT)
        clean_text = ControlText.plain(text, TEXT_LIMIT)
        clean_text = ControlText.plain(label, TEXT_LIMIT) if clean_text.empty?
        CompletionItem.new(label: clean_label, kind: KINDS.include?(kind) ? kind : "text", detail: ControlText.plain(detail, DETAIL_LIMIT), text: clean_text)
      end

      # The icon name of the kind.
      #: () -> String
      def icon_name
        "kind_" + kind
      end
    end
  end
end
