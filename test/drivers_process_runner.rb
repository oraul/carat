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

  # A message's kind and text; typed, since the queue answers untyped.
  #: (Carat::Domain::ServiceMessage) -> String
  def self.describe_one(message)
    "#{message.kind} #{message.text}"
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

    t.assert_equal(0, runner.spawn(["carat-no-such-command"]), "a missing command does not start")
    t.assert_equal(0, runner.spawn([]), "no words start nothing")
    t.assert_equal(false, runner.write(9, "x"), "an unknown handle takes no input")

    loud = runner.spawn(["sh", "-c", "printf 'Content-Length: 999999999\\r\\n\\r\\n'; sleep 1"])
    t.assert_equal(true, loud > 0, "sh starts")
    t.assert_equal("overflow ", describe(queue), "an oversized frame stops the reading")
    runner.stop(loud)

    t.finish
  end
end

DriversProcessRunnerTest.main if __FILE__ == $0
