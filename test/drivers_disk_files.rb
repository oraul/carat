require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# DiskFiles over a real directory under build/ holding hostile entries: a
# symbolic link to /dev/zero, a FIFO with no writer, a directory, files at
# and over the limit, a dangling link, and a tree whose links lead inside
# and outside its root. A read that waited or read without bound would
# hang or exhaust this test instead of failing it.
module DriversDiskFilesTest
  DIR = "build/test-files/disk"
  LIMIT = 1024

  # Removes path and everything below it, never following a link.
  def self.remove(path)
    if File.directory?(path) && !File.symlink?(path)
      names = Dir.children(path)
      i = 0
      while i < names.length
        remove("#{path}/#{names[i]}")
        i += 1
      end
      Dir.rmdir(path)
    elsif File.symlink?(path) || File.exist?(path)
      File.delete(path)
    end
  end

  # Makes a directory and those above it.
  def self.make_dirs(path)
    return if File.directory?(path)
    make_dirs(File.dirname(path))
    Dir.mkdir(path)
  end

  # The fresh directory of hostile entries, returned as an absolute path.
  def self.setup
    base = "#{Dir.pwd}/#{DIR}"
    remove(base)
    make_dirs(base)
    File.write("#{base}/reg.txt", "hello\n")
    File.write("#{base}/empty.txt", "")
    File.write("#{base}/exact.bin", "x" * LIMIT)
    File.write("#{base}/over.bin", "x" * (LIMIT + 1))
    File.binwrite("#{base}/latin1.txt", "caf\xE9\n")
    Dir.mkdir("#{base}/dir")
    File.mkfifo("#{base}/fifo")
    File.symlink("/dev/zero", "#{base}/zero")
    File.symlink("#{base}/reg.txt", "#{base}/link.txt")
    File.symlink("#{base}/nowhere", "#{base}/dangling")
    Dir.mkdir("#{base}/outside")
    File.write("#{base}/outside/keep.rb", "keep\n")
    Dir.mkdir("#{base}/tree")
    Dir.mkdir("#{base}/tree/lib")
    File.write("#{base}/tree/lib/in.rb", "in\n")
    File.write("#{base}/tree/root.rb", "root\n")
    File.symlink("#{base}/tree/lib", "#{base}/tree/alias")
    File.symlink("#{base}/outside", "#{base}/tree/out")
    File.symlink("#{base}/outside/new.rb", "#{base}/tree/dangle")
    File.symlink("#{base}/tree", "#{base}/linkroot")
    base
  end

  # The text read, or the message of what was raised.
  def self.read_of(files, path)
    files.read(path, LIMIT)
  rescue StandardError => e
    "raised #{e.message}"
  end

  # The flags of a stat: exists, directory, symlink, regular.
  def self.flags(files, path)
    info = files.stat(path)
    [info.exists, info.directory, info.symlink, info.regular]
  end

  def self.main
    t = Carat::Testing.new("drivers_disk_files")
    base = setup
    files = Carat::Drivers::DiskFiles.new

    # Reads: rows are [label, entry, text or what was raised].
    t.table([
      ["a regular file", "reg.txt", "hello\n"],
      ["an empty file", "empty.txt", ""],
      ["a file of exactly the limit", "exact.bin", "x" * LIMIT],
      ["a file one byte over the limit", "over.bin", "raised File too large"],
      ["a link to a regular file", "link.txt", "hello\n"],
      ["a link to /dev/zero", "zero", "raised Not a regular file"],
      ["a FIFO with no writer", "fifo", "raised Not a regular file"],
      ["a directory", "dir", "raised Is a directory"]
    ]) do |name|
      read_of(files, "#{base}/#{name}")
    end
    latin1 = files.read("#{base}/latin1.txt", LIMIT)
    t.assert_equal(["UTF-8", false, 5], [latin1.encoding.to_s, latin1.valid_encoding?, latin1.bytesize], "a bounded read gives UTF-8 bytes as they are")

    # Stats: rows are [label, entry, [exists, directory, symlink, regular]].
    t.table([
      ["a regular file", "reg.txt", [true, false, false, true]],
      ["a directory", "dir", [true, true, false, false]],
      ["a FIFO", "fifo", [true, false, false, false]],
      ["a link to /dev/zero", "zero", [true, false, true, false]],
      ["a link to a regular file", "link.txt", [true, false, true, true]],
      ["a dangling link", "dangling", [true, false, true, false]],
      ["nothing", "missing", [false, false, false, false]]
    ]) do |name|
      flags(files, "#{base}/#{name}")
    end

    t.assert_equal(["#{base}/tree/lib", "#{base}/outside", "#{base}/tree"], [files.real_path("#{base}/tree/alias"), files.real_path("#{base}/tree/out"), files.real_path("#{base}/linkroot")], "real_path resolves every link")

    # Creates through links: rows are [label, [root, path, directory],
    # [ok, message, where the entry would land exists]].
    probe = Carat::UseCases::ProbePath.new(files: files)
    resolve = Carat::UseCases::ResolveInside.new(files: files)
    make = Carat::UseCases::MakePath.new(files: files, probe_path: probe, resolve_inside: resolve)
    shown = "#{DIR}/tree/out"
    t.table([
      ["a file below a link leading out of the root", ["tree", "tree/out/x.rb", "outside/x.rb", "file"], [false, "Outside the tree root: #{shown}/x.rb", false]],
      ["a directory below a link leading out of the root", ["tree", "tree/out/pkg", "outside/pkg", "dir"], [false, "Outside the tree root: #{shown}/pkg", false]],
      ["a dangling link leading out is an existing entry", ["tree", "tree/dangle", "outside/new.rb", "file"], [false, "Already exists: #{DIR}/tree/dangle", false]],
      ["a file below a link that stays inside", ["tree", "tree/alias/y.rb", "tree/lib/y.rb", "file"], [true, "", true]],
      ["a file below a linked root", ["linkroot", "linkroot/z.rb", "tree/z.rb", "file"], [true, "", true]]
    ]) do |input|
      outcome = make.call("#{base}/#{input[0]}", "#{base}/#{input[1]}", input[3].to_s == "dir")
      [outcome.ok, outcome.message, File.exist?("#{base}/#{input[2]}")]
    end

    # Renames and deletes through links: rows are [label, [root, path,
    # new name or "" to delete, the entry to look for], [ok, message,
    # that entry exists]].
    scratch = Carat::Domain::Buffer.from_text("", nil)
    buffers = Carat::Domain::BufferList.new(tabs: Carat::Domain::TabList.new(window: Carat::Domain::Window.new(buffer: scratch)))
    rename = Carat::UseCases::RenamePath.new(files: files, buffers: buffers, probe_path: probe, resolve_inside: resolve)
    delete = Carat::UseCases::DeletePath.new(files: files, buffers: buffers, probe_path: probe, resolve_inside: resolve)
    t.table([
      ["a rename below a link leading out of the root", ["tree", "tree/out/keep.rb", "moved.rb", "outside/keep.rb"], [false, "Outside the tree root: #{shown}/keep.rb", true]],
      ["a delete below a link leading out of the root", ["tree", "tree/out/keep.rb", "", "outside/keep.rb"], [false, "Outside the tree root: #{shown}/keep.rb", true]],
      ["a rename below a link that stays inside", ["tree", "tree/alias/in.rb", "in2.rb", "tree/lib/in2.rb"], [true, "", true]],
      ["a delete below a linked root", ["linkroot", "linkroot/root.rb", "", "tree/root.rb"], [true, "", false]],
      ["a delete of the link leading out unlinks only the link", ["tree", "tree/out", "", "outside/keep.rb"], [true, "", true]]
    ]) do |input|
      root = "#{base}/#{input[0]}"
      path = "#{base}/#{input[1]}"
      name = input[2].to_s
      outcome = name.empty? ? delete.call(root, path) : rename.call(root, path, name)
      [outcome.ok, outcome.message, File.exist?("#{base}/#{input[3]}")]
    end
    t.assert_equal([false, true], [File.symlink?("#{base}/tree/out"), File.directory?("#{base}/outside")], "the link is gone and its target stays")

    remove(base)
    t.finish
  end
end

DriversDiskFilesTest.main if __FILE__ == $0
