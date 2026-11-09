require_relative "ex_handler"

module Carat
  module UseCases
    # The registered ex command handlers in registration order, which is
    # the order of precedence when two accept a typed name, as in Vim's
    # command table, with an index from each full name and abbreviation
    # to its position. A handler whose full name or abbreviation is
    # already registered is refused. A handler with an empty name, the
    # plugin commands, is matched by asking it, after the named ones.
    # Each named command has a short description, which the command
    # palette shows beside it, kept here by full name so the handlers'
    # registrations stay as they are.
    class ExTable
      # @rbs @handlers: Array[untyped]
      # @rbs @index: Hash[String, Integer]
      # @rbs @names: Array[String]
      # @rbs @full_names: Array[String]

      DESCRIPTIONS = {
        "write" => "Write the buffer", "quit" => "Close the window", "wq" => "Write and close the window",
        "xit" => "Write if changed and close", "exit" => "Write if changed and close", "wall" => "Write all buffers",
        "qall" => "Quit the editor", "quitall" => "Quit the editor", "wqall" => "Write all and quit",
        "xall" => "Write all and quit", "edit" => "Edit a file",
        "split" => "Split window", "vsplit" => "Split window vertically", "new" => "Split with an empty buffer",
        "vnew" => "Vertical split, empty buffer", "close" => "Close the window", "only" => "Close other windows",
        "tabnew" => "New tab page", "tabedit" => "Edit a file in a new tab", "tabclose" => "Close the tab page",
        "tabonly" => "Close other tab pages", "tabnext" => "Next tab page", "tabprevious" => "Previous tab page",
        "tabNext" => "Previous tab page", "tabfirst" => "First tab page", "tablast" => "Last tab page",
        "ls" => "List buffers", "buffers" => "List buffers", "files" => "List buffers", "buffer" => "Go to a buffer",
        "bnext" => "Next buffer", "bprevious" => "Previous buffer", "bNext" => "Previous buffer", "bdelete" => "Delete a buffer",
        "undo" => "Undo", "redo" => "Redo", "undolist" => "List undo branches", "earlier" => "Go back in undo time",
        "later" => "Go forward in undo time", "registers" => "List registers", "display" => "List registers",
        "syntax" => "Syntax highlighting on or off", "set" => "Set an option", "nohlsearch" => "Clear search highlight",
        "substitute" => "Substitute in lines", "&" => "Repeat last substitute", "global" => "Run on matching lines",
        "vglobal" => "Run on other lines", "delete" => "Delete lines", "LspStart" => "Start language server",
        "LspRestart" => "Restart language servers", "messages" => "Show the message history"
      }
      private_constant :DESCRIPTIONS

      #: () -> void
      def initialize
        @handlers = []
        @index = {}
        @names = []
        @full_names = []
      end

      # Registers the handler under the name it carries; false, and
      # nothing added, when its full name or abbreviation is taken.
      #: (ExHandler) -> bool
      def register(handler)
        name = handler.name
        return false if !name.full.empty? && (@index.key?(name.full) || @index.key?(name.short))
        unless name.full.empty?
          @index[name.full] = @handlers.length
          @index[name.short] = @handlers.length
          @names << name.to_s
          @full_names << name.full
        end
        @handlers << handler
        true
      end

      # The first handler, in registration order, that the typed name
      # names, or nil.
      #: (String) -> ExHandler?
      def find(typed)
        return nil if typed.empty?
        i = 0
        while i < @handlers.length
          handler = handler_at(i)
          return handler if handler.matches?(typed)
          i += 1
        end
        nil
      end

      # The registered names in Vim's notation, in registration order.
      #: () -> Array[String]
      def names
        @names
      end

      # The full names of the named commands, in registration order.
      #: () -> Array[String]
      def full_names
        @full_names
      end

      # The description of a command by its full name, "" for none.
      #: (String) -> String
      def describe(full)
        text = DESCRIPTIONS[full]
        text.nil? ? "" : text
      end

      #: () -> Integer
      def count
        @handlers.length
      end

      #: (Integer) -> ExHandler
      def handler_at(i)
        @handlers[i]
      end
    end
  end
end
