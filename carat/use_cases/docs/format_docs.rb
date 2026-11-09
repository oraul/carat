require_relative "../../domain/editor_state"
require_relative "../../domain/docs_text"
require_relative "../../domain/markdown_text"
require_relative "../../domain/syntax_line"
require_relative "../plugins/plugin_syntax"

module Carat
  module UseCases
    # Documentation markdown as the rows a docs float shows, with their
    # markup spans (MarkdownText) and, when syntax is on, the tokens of
    # each fenced block whose language an enabled plugin tokenizes: each
    # code line without its two-column indent, from the state the line
    # before it in the block ended in, its tokens moved past the indent
    # and drawn over the block's own group. A tokenizer that raises is
    # disabled by the plugin guard and the rest of its block stays plain
    # code. The lines are tokenized whole, then wrapped with their spans.
    # Used by ShowHover and ShowCompletionDocs.
    class FormatDocs
      INDENT = 2
      private_constant :INDENT

      attr_reader :syntax #: PluginSyntax

      #: (syntax: PluginSyntax) -> void
      def initialize(syntax:)
        @syntax = syntax
      end

      #: (Domain::EditorState, String, Integer) -> Domain::DocsText
      def call(state, text, width)
        doc = Domain::MarkdownText.parse(text)
        highlight(doc) if state.options.syntax_on
        Domain::MarkdownText.wrap(doc, width)
      end

      private

      # Adds the tokens of every fenced row of a tokenized language.
      #: (Domain::DocsText) -> void
      def highlight(doc)
        entry = nil
        block = 0
        start = 0
        row = 0
        while row < doc.count
          name = doc.syntax(row)
          if !name.empty? && doc.block(row) != block
            block = doc.block(row)
            entry = @syntax.provider(name)
            start = 0
          end
          if !name.empty? && !entry.nil?
            line = doc.line(row)
            code = line.byteslice(INDENT, line.bytesize - INDENT).to_s
            finish = @syntax.tokenize(entry, name, code, start)
            if finish == Domain::SyntaxLine::FAILED
              entry = nil
            else
              start = finish
              add_tokens(doc, row, @syntax.copied_tokens)
            end
          end
          row += 1
        end
      end

      # Adds the (start, length, group) triples to the row past its
      # indent.
      #: (Domain::DocsText, Integer, Array[Integer]) -> void
      def add_tokens(doc, row, tokens)
        i = 0
        while i + 2 < tokens.length
          from = INDENT + tokens[i]
          doc.add_span(row, from, from + tokens[i + 1], tokens[i + 2])
          i += 3
        end
      end
    end
  end
end
