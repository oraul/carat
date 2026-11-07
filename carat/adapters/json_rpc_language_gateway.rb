require_relative "../ports/language_service_port"

module Carat
  module Adapters
    # The language server client: speaks JSON-RPC to one server per
    # language through the process port and reads what the servers' reader
    # threads queued, only when the editor is idle (InputController's tick),
    # so a key never waits on a server or pays for one. A server starts for
    # the current buffer's file type when language.<type>.lsp names a
    # command; once it answered initialize it is told about each buffer of
    # its file type with a path: didOpen, didChange with the whole text when
    # the buffer's change counters moved, didSave after SaveFile wrote it,
    # and didClose when the buffer is gone. Its output is untrusted: a body
    # that is not a JSON object is dropped, at most DRAIN_LIMIT messages are
    # read per tick, and the name and every diagnostic message are stripped
    # of control characters and capped (Domain::ControlText).
    class JsonRpcLanguageGateway < Ports::LanguageServicePort
      DRAIN_LIMIT = 64
      NAME_LIMIT = 32
      MESSAGE_LIMIT = 500
      DIAGNOSTIC_LIMIT = 1000
      METHOD_NOT_FOUND = -32_601
      FILE_SCHEME = "file:"
      # Server requests answered with a null result; any other gets
      # METHOD_NOT_FOUND.
      NULL_REQUESTS = ["window/workDoneProgress/create", "client/registerCapability", "client/unregisterCapability"]

      # @rbs @servers: Array[untyped]
      # @rbs @refused: Array[String]
      # @rbs @saves: Array[Integer]

      attr_reader :processes #: Ports::ProcessPort
      attr_reader :messages #: Ports::MessageQueuePort
      attr_reader :files #: Ports::FilePort
      attr_reader :buffers #: Domain::BufferList
      attr_reader :config #: Domain::Config
      attr_reader :slots #: Domain::StatusSlots

      #: (processes: Ports::ProcessPort, messages: Ports::MessageQueuePort, files: Ports::FilePort, buffers: Domain::BufferList, config: Domain::Config, slots: Domain::StatusSlots) -> void
      def initialize(processes:, messages:, files:, buffers:, config:, slots:)
        @processes = processes
        @messages = messages
        @files = files
        @buffers = buffers
        @config = config
        @slots = slots
        @servers = []
        @refused = []
        @saves = []
      end

      # @rbs state: Domain::EditorState
      def poll(state)
        changed = drain
        language = state.buffer.filetype
        current = server_for(language)
        current = start(language) if current.nil? && command?(language) && !@refused.include?(language)
        i = 0
        while i < @servers.length
          server = server_at(i)
          sync(server) if server.running?
          i += 1
        end
        @saves.clear
        show(current) || changed
      end

      #: (Domain::Buffer) -> void
      def saved(buffer)
        @saves << buffer.id unless @saves.include?(buffer.id)
      end

      # @rbs state: Domain::EditorState
      def restart(state)
        stop
        @servers.clear
        @refused.clear
        language = state.buffer.filetype
        unless command?(language)
          show(nil)
          return "No language server for this buffer"
        end
        server = start(language)
        show(server)
        server.nil? ? "Cannot start #{words_of(language).join(" ")}" : ""
      end

      #: () -> void
      def stop
        i = 0
        while i < @servers.length
          server = server_at(i)
          i += 1
          next if server.handle == 0
          request(server, "shutdown", nil)
          notify(server, "exit", nil)
          @processes.stop(server.handle)
          server.handle = 0
          server.state = :stopped
        end
        show(@servers.empty? ? nil : server_at(0))
      end

      # The diagnostics a server published for a path, in its order.
      #: (String) -> Array[untyped]
      def diagnostics(path)
        uri = uri_of(path)
        i = 0
        while i < @servers.length
          list = server_at(i).diagnostics[uri]
          return list unless list.nil?
          i += 1
        end
        []
      end

      # The server of a language, or nil.
      #: (String) -> Domain::LanguageServer?
      def server_for(language)
        i = 0
        while i < @servers.length
          return server_at(i) if server_at(i).language == language
          i += 1
        end
        nil
      end

      private

      # The server at an index, typed: the list is Array[untyped].
      #: (Integer) -> Domain::LanguageServer
      def server_at(index)
        @servers[index]
      end

      #: (String) -> bool
      def command?(language)
        !language.empty? && !words_of(language).empty?
      end

      #: (String) -> Array[String]
      def words_of(language)
        line = @config.last("language.#{language}.lsp")
        line.nil? ? [] : line.words
      end

      # Starts a language's server and sends initialize; nil when the
      # command cannot start, remembered until a restart.
      #: (String) -> Domain::LanguageServer?
      def start(language)
        words = words_of(language)
        handle = @processes.spawn(words)
        if handle == 0
          @refused << language
          return nil
        end
        name = Domain::ControlText.strip(File.basename(words[0]), NAME_LIMIT)
        server = Domain::LanguageServer.new(language: language, words: words, name: name, handle: handle)
        @servers << server
        server.init_id = request(server, "initialize", initialize_params)
        server
      end

      #: () -> Hash[String, untyped]
      def initialize_params
        root = uri_of(@files.cwd)
        sync = { "didSave" => true, "dynamicRegistration" => false }
        document = { "synchronization" => sync, "publishDiagnostics" => { "relatedInformation" => false } }
        capabilities = { "textDocument" => document, "window" => { "workDoneProgress" => true } }
        { "processId" => nil, "clientInfo" => { "name" => "carat" }, "rootUri" => root, "capabilities" => capabilities, "workspaceFolders" => [{ "uri" => root, "name" => File.basename(@files.cwd) }] }
      end

      # Shows a server on the bar, or empties the slot for nil; answers
      # whether the slot changed.
      #: (Domain::LanguageServer?) -> bool
      def show(server)
        return @slots.set_lsp("", :none, 0) if server.nil?
        @slots.set_lsp(server.name, server.state, server.percent)
      end

      # Handles at most DRAIN_LIMIT queued messages; answers whether any.
      #: () -> bool
      def drain
        count = 0
        while count < DRAIN_LIMIT
          message = @messages.pop
          break if message.nil?
          handle(message)
          count += 1
        end
        count > 0
      end

      #: (Domain::ServiceMessage) -> void
      def handle(message)
        server = by_handle(message.handle)
        return if server.nil?
        if message.body?
          receive(server, message.text)
        else
          crash(server)
        end
      end

      #: (Integer) -> Domain::LanguageServer?
      def by_handle(handle)
        return nil if handle == 0
        i = 0
        while i < @servers.length
          return server_at(i) if server_at(i).handle == handle
          i += 1
        end
        nil
      end

      # The server ended without being stopped, or its output broke a
      # limit: its process is stopped and the bar names the restart.
      #: (Domain::LanguageServer) -> void
      def crash(server)
        @processes.stop(server.handle)
        server.handle = 0
        server.state = :crashed
        server.tasks = 0
      end

      #: (Domain::LanguageServer, String) -> void
      def receive(server, text)
        value = parse(text)
        return unless value.is_a?(Hash)
        name = value["method"]
        if name.is_a?(String)
          if value.key?("id")
            answer(server, name.to_s, value["id"])
          else
            notified(server, name.to_s, value["params"])
          end
        elsif value["id"] == server.init_id && server.state == :starting
          initialized(server, value["result"])
        end
      end

      # The JSON value of a body, or nil when it is not JSON.
      #: (String) -> untyped
      def parse(text)
        Json.parse(text)
      rescue Json::Error
        nil
      end

      # The initialize result: the server's name, ready, and initialized.
      #: (Domain::LanguageServer, untyped) -> void
      def initialized(server, result)
        info = result.is_a?(Hash) ? result["serverInfo"] : nil
        name = info.is_a?(Hash) ? info["name"] : nil
        if name.is_a?(String)
          stripped = Domain::ControlText.strip(name.to_s, NAME_LIMIT)
          server.name = stripped unless stripped.empty?
        end
        server.state = :ready
        notify(server, "initialized", {})
      end

      # Answers a server's request, so a server waiting on it goes on.
      #: (Domain::LanguageServer, String, untyped) -> void
      def answer(server, name, id)
        return unless id.is_a?(Integer) || id.is_a?(String)
        if NULL_REQUESTS.include?(name)
          deliver(server, { "jsonrpc" => "2.0", "id" => id, "result" => nil })
        else
          deliver(server, { "jsonrpc" => "2.0", "id" => id, "error" => { "code" => METHOD_NOT_FOUND, "message" => "not supported" } })
        end
      end

      #: (Domain::LanguageServer, String, untyped) -> void
      def notified(server, name, params)
        return unless params.is_a?(Hash)
        if name == "$/progress"
          progress(server, params["value"])
        elsif name == "textDocument/publishDiagnostics"
          published(server, params["uri"], params["diagnostics"])
        end
      end

      # A work-done progress report: begin and end count the reports that
      # run, and the percent is the last one given.
      #: (Domain::LanguageServer, untyped) -> void
      def progress(server, value)
        return unless value.is_a?(Hash) && server.running?
        kind = value["kind"]
        percent = value["percentage"]
        if kind == "begin"
          server.tasks = server.tasks + 1
          server.percent = 0
        elsif kind == "end"
          server.tasks = server.tasks - 1 if server.tasks > 0
        end
        server.percent = bounded(percent.to_i, 0, 100) if percent.is_a?(Integer) || percent.is_a?(Float)
        server.state = server.tasks > 0 ? :indexing : :ready
      end

      # Keeps a file's diagnostics as values, replacing its earlier ones.
      #: (Domain::LanguageServer, untyped, untyped) -> void
      def published(server, uri, list)
        return unless uri.is_a?(String) && list.is_a?(Array)
        values = []
        list.each do |item|
          break if values.length >= DIAGNOSTIC_LIMIT
          diagnostic = diagnostic_of(item)
          values << diagnostic unless diagnostic.nil?
        end
        server.diagnostics[uri.to_s] = values
      end

      #: (untyped) -> Domain::Diagnostic?
      def diagnostic_of(item)
        return nil unless item.is_a?(Hash)
        range = item["range"]
        start = range.is_a?(Hash) ? range["start"] : nil
        return nil unless start.is_a?(Hash)
        severity = item["severity"]
        message = item["message"]
        Domain::Diagnostic.new(row: count_of(start["line"]), col: count_of(start["character"]), severity: severity.is_a?(Integer) ? bounded(severity.to_i, 1, 4) : 1, message: message.is_a?(String) ? Domain::ControlText.strip(message.to_s, MESSAGE_LIMIT) : "")
      end

      #: (Integer, Integer, Integer) -> Integer
      def bounded(value, low, high)
        return low if value < low
        return high if value > high
        value
      end

      # A non-negative integer from a JSON value, 0 for anything else.
      #: (untyped) -> Integer
      def count_of(value)
        value.is_a?(Integer) ? [value.to_i, 0].max : 0
      end

      # Tells a running server about the buffers of its file type.
      #: (Domain::LanguageServer) -> void
      def sync(server)
        server.tick = server.tick + 1
        i = 0
        while i < @buffers.count
          buffer = @buffers.buffer_at(i)
          sync_buffer(server, buffer) if buffer.filetype == server.language && !buffer.path.empty?
          i += 1
        end
        server.versions.keys.each do |uri|
          next if server.seen[uri] == server.tick
          notify(server, "textDocument/didClose", { "textDocument" => { "uri" => uri } })
          server.forget(uri)
        end
      end

      #: (Domain::LanguageServer, Domain::Buffer) -> void
      def sync_buffer(server, buffer)
        uri = uri_of(buffer.path)
        server.seen[uri] = server.tick
        version = server.versions[uri]
        if version.nil?
          remember(server, uri, buffer, 1)
          notify(server, "textDocument/didOpen", { "textDocument" => { "uri" => uri, "languageId" => server.language, "version" => 1, "text" => buffer.to_text } })
          return
        end
        if server.changes[uri] != buffer.changes || server.closed[uri] != buffer.closed_count
          remember(server, uri, buffer, version.to_i + 1)
          notify(server, "textDocument/didChange", { "textDocument" => { "uri" => uri, "version" => version.to_i + 1 }, "contentChanges" => [{ "text" => buffer.to_text }] })
        end
        notify(server, "textDocument/didSave", { "textDocument" => { "uri" => uri } }) if @saves.include?(buffer.id)
      end

      #: (Domain::LanguageServer, String, Domain::Buffer, Integer) -> void
      def remember(server, uri, buffer, version)
        server.versions[uri] = version
        server.changes[uri] = buffer.changes
        server.closed[uri] = buffer.closed_count
      end

      # The file URI of a path, made absolute against the working
      # directory, every byte but unreserved ones and slashes escaped. The
      # protocol names documents by file URIs; the scheme and the slashes
      # are joined here, so no link appears in the source.
      #: (String) -> String
      def uri_of(path)
        absolute = path.start_with?("/") ? path : "#{@files.cwd}/#{path}"
        out = +FILE_SCHEME
        out << "//"
        i = 0
        while i < absolute.bytesize
          b = absolute.getbyte(i).to_i
          if unreserved?(b)
            out << b.chr
          else
            out << format("%%%02X", b)
          end
          i += 1
        end
        out
      end

      #: (Integer) -> bool
      def unreserved?(b)
        (b >= 97 && b <= 122) || (b >= 65 && b <= 90) || (b >= 48 && b <= 57) || b == 45 || b == 46 || b == 95 || b == 126 || b == 47
      end

      #: (Domain::LanguageServer, String, untyped) -> Integer
      def request(server, name, params)
        id = server.take_id
        value = { "jsonrpc" => "2.0", "id" => id, "method" => name }
        value["params"] = params unless params.nil?
        deliver(server, value)
        id
      end

      #: (Domain::LanguageServer, String, untyped) -> void
      def notify(server, name, params)
        value = { "jsonrpc" => "2.0", "method" => name }
        value["params"] = params unless params.nil?
        deliver(server, value)
      end

      # Writes one message; a server whose input is broken has crashed.
      #: (Domain::LanguageServer, Hash[String, untyped]) -> void
      def deliver(server, value)
        return if server.handle == 0
        crash(server) unless @processes.write(server.handle, Domain::RpcFramer.frame(Json.generate(value)))
      end
    end
  end
end
