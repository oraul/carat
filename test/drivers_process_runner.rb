require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# ProcessRunner over real children: cat echoes a frame back, sh writes an
# oversized header, and a missing command does not start.
module DriversProcessRunnerTest
  D = Carat::Domain
  ENVIRONMENT = { "GIT_NO_LAZY_FETCH" => "1", "GIT_ALLOW_PROTOCOL" => "" }

  # The next message, waiting up to two seconds for a thread to push it.
  def self.next_message(queue)
    50.times do
      message = queue.pop
      return message unless message.nil?
      sleep 0.04
    end
    nil
  end

  # The kind and text of the next message, or "none".
  def self.describe(queue)
    message = next_message(queue)
    return "none" if message.nil?
    describe_one(message)
  end

  # The handle and kind of the next message, or "none".
  def self.ended(queue)
    message = next_message(queue)
    return "none" if message.nil?
    handle_and_kind(message)
  end

  # A message's handle and kind; typed, since the queue answers untyped.
  #: (Carat::Domain::ServiceMessage) -> String
  def self.handle_and_kind(message)
    "#{message.handle} #{message.kind}"
  end

  # A message's kind and text; typed, since the queue answers untyped.
  #: (Carat::Domain::ServiceMessage) -> String
  def self.describe_one(message)
    "#{message.kind} #{message.text}"
  end

  # Starts cat, echoes one frame, stops it, and describes its end.
  def self.stop_cat(runner, queue)
    handle = runner.spawn(["cat"])
    runner.write(handle, D::RpcFramer.frame("{}"))
    describe(queue)
    runner.stop(handle)
    describe(queue)
  end

  def self.main
    t = Carat::Testing.new("drivers_process_runner")
    queue = Carat::Drivers::RuntimeQueue.new
    runner = Carat::Drivers::ProcessRunner.new(messages: queue)

    t.assert_equal(nil, queue.pop, "an empty queue answers nil at once")
    handle = runner.spawn(["cat"])
    t.assert_equal(1, handle, "the first child's handle is 1")
    t.assert_equal(true, runner.write(handle, D::RpcFramer.frame("{\"a\":1}")), "a running child takes input")
    t.assert_equal("body {\"a\":1}", describe(queue), "the reader thread frames the echo")
    runner.write(handle, D::RpcFramer.frame("1") + D::RpcFramer.frame("22"))
    t.assert_equal(["body 1", "body 22"], [describe(queue), describe(queue)], "two frames in one write")
    runner.stop(handle)
    t.assert_equal("exit ", describe(queue), "a stopped child's output ends")
    t.assert_equal(false, runner.write(handle, "x"), "a stopped child takes no input")

    # Scenario "Stopping a server ends only that server": a child that
    # ignores its input ends only when stopped, and its sibling runs on.
    first = runner.spawn(["sleep", "30"])
    second = runner.spawn(["sleep", "30"])
    runner.stop(first)
    t.assert_equal("#{first} exit", ended(queue), "stopping a server ends only that server: the stopped child ends")
    sleep 0.3
    t.assert_equal(true, queue.pop.nil?, "and its sibling keeps running")
    runner.stop(second)
    t.assert_equal("#{second} exit", ended(queue), "until it is stopped in turn")

    # Scenario "Stopping a stalled server keeps the editor running":
    # A child stopped while its writer is blocked on a full pipe: the
    # write after it ends answers EPIPE, never SIGPIPE ending the runner.
    stalled = runner.spawn(["sleep", "30"])
    t.assert_equal(true, runner.write(stalled, "x" * 200_000), "a stalled child takes more input than its pipe holds")
    sleep 0.2
    runner.stop(stalled)
    t.assert_equal("#{stalled} exit", ended(queue), "stopping a child its writer is blocked on still ends it, and the runner survives the broken pipe")
    sleep 0.2
    t.assert_equal("exit ", stop_cat(runner, queue), "and the runner starts and stops the next child")

    # Scenario "A server ignoring its end of input and TERM is killed".
    stubborn = runner.spawn(["sh", "-c", "trap '' TERM; exec sleep 30"])
    sleep 0.2
    runner.stop(stubborn)
    t.assert_equal("#{stubborn} exit", ended(queue), "A server ignoring its end of input and TERM is killed: its output ends")

    # Scenario "A server whose input broke takes no more input".
    deaf = runner.spawn(["sh", "-c", "exec 0<&-; exec sleep 30"])
    sleep 0.2
    t.assert_equal(true, runner.write(deaf, "x"), "a write to a child that closed its input is queued")
    sleep 0.3
    t.assert_equal(false, runner.write(deaf, "x"), "A server whose input broke takes no more input: the next write answers false")
    runner.stop(deaf)
    t.assert_equal("#{deaf} exit", ended(queue), "and it still stops")

    t.assert_equal(0, runner.spawn(["carat-no-such-command"]), "a missing command does not start")
    t.assert_equal(0, runner.spawn([]), "no words start nothing")
    t.assert_equal(false, runner.write(9, "x"), "an unknown handle takes no input")

    # The driver runs a program without a shell
    t.assert_equal("a;b", runner.capture(["printf", "%s", "a;b"], ENVIRONMENT).to_s, "capture answers the output of the words as given, no shell splitting them")
    t.assert_equal([true, false], [runner.capture(["carat-no-such-command"], ENVIRONMENT).nil?, runner.timed_out?], "capture of a missing program answers nothing and did not time out")
    # The driver adds the variables to the child environment
    t.assert_equal("1", runner.capture(["sh", "-c", "printf %s \"$GIT_NO_LAZY_FETCH\""], ENVIRONMENT).to_s, "capture adds the variables to the child's environment: it sees GIT_NO_LAZY_FETCH=1")
    # The driver adds an empty variable to the child environment
    t.assert_equal("set:", runner.capture(["sh", "-c", "printf %s \"${GIT_ALLOW_PROTOCOL+set}:$GIT_ALLOW_PROTOCOL\""], ENVIRONMENT).to_s, "capture sets a variable given the empty string: the child sees GIT_ALLOW_PROTOCOL set, and empty")
    t.assert_equal(true, runner.capture([], ENVIRONMENT).nil?, "capture of no words answers nothing")
    # Scenario "run_program says a program ran past its deadline": the port's half.
    t.assert_equal([true, true], [runner.capture(["sh", "-c", "sleep 5"], ENVIRONMENT).nil?, runner.timed_out?], "capture of a program past the deadline answers nothing and says it timed out")
    t.assert_equal(["x", false], [runner.capture(["printf", "x"], ENVIRONMENT).to_s, runner.timed_out?], "and the next capture clears it")
    # "é\n" is three bytes, so byte 65,536 of the stream is the second byte of an é
    long = runner.capture(["sh", "-c", "yes é | head -c 70000"], ENVIRONMENT).to_s
    t.assert_equal(65_535, long.bytesize, "capture of output over the limit keeps at most 64 KiB, cut before the character the limit splits")
    t.assert_equal(true, long.valid_encoding?, "capture of long valid UTF-8 output answers valid UTF-8")

    loud = runner.spawn(["sh", "-c", "printf 'Content-Length: 999999999\\r\\n\\r\\n'; sleep 1"])
    t.assert_equal(true, loud > 0, "sh starts")
    t.assert_equal("overflow ", describe(queue), "an oversized frame stops the reading")
    runner.stop(loud)

    t.finish
  end
end

DriversProcessRunnerTest.main if __FILE__ == $0
