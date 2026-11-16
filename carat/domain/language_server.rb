require_relative "diagnostic_list"

module Carat
  module Domain
    # One language server the gateway runs: its language, the command's
    # words, the name shown on the bar, the process handle (0 when none),
    # the state (:starting, :ready, :indexing, :stopped, or :crashed), the
    # progress percent and how many progress reports run, the next request
    # id and the initialize request's, and per document URI the version
    # sent, the buffer's change counters at that send, the lines sent
    # (kept only under incremental sync), and the tick that last saw it;
    # the diagnostics published per URI; and the textDocumentSync kind
    # the server announced (0 none, 1 full, 2 incremental). A Struct
    # record: the hashes start empty through the writers.
    class LanguageServer < Struct.new(:language, :words, :name, :handle, :state, :percent, :tasks, :next_id, :init_id, :versions, :changes, :closed, :seen, :tick, :diagnostics, :texts, :sync_kind, keyword_init: true)
      # @rbs @language: String
      # @rbs @words: Array[String]
      # @rbs @name: String
      # @rbs @handle: Integer
      # @rbs @state: Symbol
      # @rbs @percent: Integer
      # @rbs @tasks: Integer
      # @rbs @next_id: Integer
      # @rbs @init_id: Integer
      # @rbs @versions: Hash[String, Integer]
      # @rbs @changes: Hash[String, Integer]
      # @rbs @closed: Hash[String, Integer]
      # @rbs @seen: Hash[String, Integer]
      # @rbs @tick: Integer
      # @rbs @diagnostics: Hash[String, DiagnosticList]
      # @rbs @texts: Hash[String, Array[String]]
      # @rbs @sync_kind: Integer

      #: (language: String, words: Array[String], name: String, handle: Integer) -> void
      def initialize(language:, words:, name:, handle:)
        super()
        self.language = language
        self.words = words
        self.name = name
        self.handle = handle
        self.state = :starting
        self.percent = 0
        self.tasks = 0
        self.next_id = 0
        self.init_id = -1
        self.versions = {}
        self.changes = {}
        self.closed = {}
        self.seen = {}
        self.tick = 0
        self.diagnostics = {}
        self.texts = {}
        self.sync_kind = 0
      end

      # Whether the server answered initialize and runs, so documents are
      # sent to it.
      #: () -> bool
      def running?
        state == :ready || state == :indexing
      end

      # The next request id.
      #: () -> Integer
      def take_id
        self.next_id = next_id + 1
        next_id
      end

      # Forgets a document: its counters, its text, and its diagnostics.
      #: (String) -> void
      def forget(uri)
        versions.delete(uri)
        changes.delete(uri)
        closed.delete(uri)
        seen.delete(uri)
        diagnostics.delete(uri)
        texts.delete(uri)
      end
    end
  end
end
