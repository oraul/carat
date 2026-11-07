module Carat
  module Domain
    # What a language server's reader thread hands the editor thread
    # through the message queue: the server's handle, the kind ("body",
    # one framed JSON-RPC message in text; "exit", the server's output
    # ended; "overflow", a frame over the limits, so reading stopped), and
    # the text. A Data value.
    class ServiceMessage < Data.define(:handle, :kind, :text)
      # @rbs @handle: Integer
      # @rbs @kind: String
      # @rbs @text: String

      # Whether the message carries a framed body.
      #: () -> bool
      def body?
        kind == "body"
      end
    end
  end
end
