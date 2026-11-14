module Carat
  module Domain
    # The command palette: its entries, built when it opens, as parallel
    # arrays of names (an action name, or ":" and an ex command's full
    # name), keys (the first normal-mode key, "" for none), and
    # descriptions; matches, the indexes of the entries the typed text
    # matches, best first, with fields, for each match, 0 when its name's
    # score ranked it and 1 when its description's did; selected, the index into matches of the chosen
    # row; query, the typed text the matches were filtered for; active
    # while its prompt holds the command line; float_id, its float, 0 for
    # none, with shown_query and shown_selected, what the float shows; and
    # chosen, the action Enter picked for HandleKey to run, "" for none.
    # A Struct record built with no arguments.
    class Palette < Struct.new(:names, :keys, :descriptions, :matches, :fields, :selected, :query, :active, :float_id, :shown_query, :shown_selected, :chosen, keyword_init: true)
      # @rbs @names: Array[String]
      # @rbs @keys: Array[String]
      # @rbs @descriptions: Array[String]
      # @rbs @matches: Array[Integer]
      # @rbs @fields: Array[Integer]
      # @rbs @selected: Integer
      # @rbs @query: String
      # @rbs @active: bool
      # @rbs @float_id: Integer
      # @rbs @shown_query: String
      # @rbs @shown_selected: Integer
      # @rbs @chosen: String

      # The owner of the scratch buffer the list is shown in.
      OWNER = ":palette"

      # The empty string arrays go through the writers, as Keymap's do.
      #: () -> void
      def initialize
        super()
        self.names = []
        self.keys = []
        self.descriptions = []
        self.matches = []
        self.fields = []
        self.selected = 0
        self.query = ""
        self.active = false
        self.float_id = 0
        self.shown_query = ""
        self.shown_selected = -1
        self.chosen = ""
      end

      # Whether HandleKey must follow the palette after a key: it is open
      # or its float still shows.
      #: () -> bool
      def following?
        active || float_id != 0
      end

      # Drops the entries and opens the palette with an empty text.
      #: () -> void
      def start
        self.names = []
        self.keys = []
        self.descriptions = []
        self.matches = []
        self.fields = []
        self.selected = 0
        self.query = ""
        self.shown_query = ""
        self.shown_selected = -1
        self.chosen = ""
        self.active = true
      end

      #: (String, String, String) -> void
      def add(name, key, description)
        names << name
        keys << key
        descriptions << description
      end

      # Moves the selection by step, staying on the list.
      #: (Integer) -> void
      def move(step)
        last = matches.length - 1
        at = selected + step
        at = last if at > last
        at = 0 if at < 0
        self.selected = at
      end

      # The entry index of the selected row, -1 when nothing matches.
      #: () -> Integer
      def selected_entry
        return -1 if selected < 0 || selected >= matches.length
        matches[selected]
      end

      # Takes the action Enter chose, leaving none.
      #: () -> String
      def take_chosen
        name = chosen
        self.chosen = ""
        name
      end
    end
  end
end
