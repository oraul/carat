require_relative "frame"
require_relative "start_art"

module Carat
  module Domain
    # The start screen shown when the editor starts without a file: whether
    # it shows, the frame of its picture it is on, when it started on the
    # clock, and the picture. Frames follow each other STEP seconds apart
    # until the last, which stays until a key dismisses the screen. The
    # input controller advances it on the clock and the frame presenter
    # paints it. A Struct record.
    class StartScreen < Struct.new(:showing, :step, :started, :art, keyword_init: true)
      # @rbs @showing: bool
      # @rbs @step: Integer
      # @rbs @started: Float
      # @rbs @art: StartArt

      # Seconds between frames, a binary fraction so a clock moved by it
      # lands on each frame exactly; the last frame comes at 0.625 s.
      STEP = 0.125

      # Not showing, with no picture.
      #: () -> void
      def initialize
        super(showing: false, step: 0, started: 0.0, art: StartArt.none)
      end

      # Shows art from its first frame at now, or from its last when
      # animate is false.
      #: (Float, bool, StartArt) -> void
      def start(now, animate, art)
        self.showing = true
        self.started = now
        self.art = art
        self.step = animate ? 0 : StartArt::LAST
      end

      # Whether a later frame is still to come.
      #: () -> bool
      def animating?
        showing && step < StartArt::LAST
      end

      # Whether the next frame's time has come at now.
      #: (Float) -> bool
      def due?(now)
        animating? && now >= next_time
      end

      # Moves to the latest frame whose time has come at now.
      #: (Float) -> void
      def advance(now)
        self.step = step + 1 while animating? && now >= next_time
      end

      # Seconds from now to the next frame, 0.0 when it is due.
      #: (Float) -> Float
      def wait(now)
        left = next_time - now
        left > 0.0 ? left : 0.0
      end

      #: () -> void
      def dismiss
        self.showing = false
      end

      # Paints the current frame into the rectangle of frame given by its
      # top row, left column, height, and width.
      #: (Frame, Integer, Integer, Integer, Integer) -> void
      def paint(frame, top, left, height, width)
        art.paint(frame, step, top, left, height, width)
      end

      private

      #: () -> Float
      def next_time
        started + STEP * (step + 1)
      end
    end
  end
end
