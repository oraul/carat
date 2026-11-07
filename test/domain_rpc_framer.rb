require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainRpcFramerTest
  D = Carat::Domain

  # The bodies a framer answers for the chunks, then "refused" when it
  # refused the stream.
  def self.bodies_of(chunks)
    framer = D::RpcFramer.new
    out = []
    chunks.each do |chunk|
      framer.feed(chunk.to_s)
      body = framer.next_body
      until body.nil?
        out << body
        body = framer.next_body
      end
    end
    out << "refused" if framer.refused?
    out
  end

  def self.strip(text, limit)
    D::ControlText.strip(text.to_s, limit.to_i)
  end

  def self.line(text, limit)
    D::ControlText.line(text.to_s, limit.to_i)
  end

  def self.main
    t = Carat::Testing.new("domain_rpc_framer")

    big = "Content-Length: #{D::RpcFramer::BODY_LIMIT + 1}\r\n\r\n"
    t.table([
      ["one frame", ["Content-Length: 2\r\n\r\n{}"], ["{}"]],
      ["two frames in one chunk", ["Content-Length: 1\r\n\r\n1Content-Length: 1\r\n\r\n2"], ["1", "2"]],
      ["a frame split in the header and the body", ["Content-Len", "gth: 3\r\n\r", "\n[1", "]"], ["[1]"]],
      ["the name in any case and a Content-Type header", ["content-type: x\r\nCONTENT-LENGTH:3\r\n\r\nabc"], ["abc"]],
      ["the length counts bytes", ["Content-Length: 4\r\n\r\n\"é\""], ["\"é\""]],
      ["an empty body", ["Content-Length: 0\r\n\r\n"], [""]],
      ["a missing length refuses", ["X: 1\r\n\r\nabc"], ["refused"]],
      ["a length that is not digits refuses", ["Content-Length: 1x\r\n\r\nab"], ["refused"]],
      ["ten digits refuse", ["Content-Length: 1234567890\r\n\r\n"], ["refused"]],
      ["a body over the limit refuses", [big], ["refused"]],
      ["a header over the limit refuses", ["X: " + ("a" * 1100)], ["refused"]],
      ["nothing after a refusal", ["X: 1\r\n\r\n", "Content-Length: 1\r\n\r\n1"], ["refused"]],
      ["an incomplete body waits", ["Content-Length: 5\r\n\r\nab"], []]
    ]) { |chunks| bodies_of(chunks) }

    t.assert_equal("Content-Length: 4\r\n\r\n\"é\"", D::RpcFramer.frame("\"é\""), "a frame counts the body's bytes")

    framer = D::RpcFramer.new
    count = 0
    300.times do
      framer.feed("Content-Length: 100\r\n\r\n" + ("x" * 100))
      count += 1 unless framer.next_body.nil?
    end
    t.assert_equal(300, count, "many frames through one framer")

    t.table([
      ["plain text stays", ["ruby-lsp", 32], "ruby-lsp"],
      ["an escape sequence loses its escape", ["a\e[31mb", 32], "a[31mb"],
      ["C0, DEL, and C1 controls are dropped", ["a\r\n\tb\x7Fc\u009Bd", 32], "abcd"],
      ["an illegal byte becomes U+FFFD", ["a\xFFb", 32], "a\u{FFFD}b"],
      ["UTF-8 is kept", ["é\u{1F600}", 32], "é\u{1F600}"],
      ["the cut keeps whole characters", ["abé", 3], "ab"],
      ["the limit in bytes", ["abcdef", 4], "abcd"]
    ]) { |args| strip(args[0], args[1]) }

    t.table([
      ["breaks and tabs become spaces", ["expected end\nfound EOF\r\tx", 64], "expected end found EOF  x"],
      ["an escape sequence still loses its escape", ["a\n\e[31mb", 32], "a [31mb"],
      ["the cut counts the spaces", ["ab\ncd", 3], "ab "]
    ]) { |args| line(args[0], args[1]) }

    t.finish
  end
end

DomainRpcFramerTest.main if __FILE__ == $0
