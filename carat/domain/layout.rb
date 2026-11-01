require_relative "layout_node"

module Carat
  module Domain
    # The window layout of one tab page: a tree of splits kept as a flat
    # table of nodes addressed by integer ids, so the walks are over
    # integers and a window keeps its id while it exists. The root starts
    # as one leaf. Sizes are kept consistent by arrange, which assigns every
    # leaf window its rectangle; split, close, equalize, and neighbour work
    # from the rectangles of the last arrange. A Struct record.
    class Layout < Struct.new(:nodes, :root)
      # @rbs @nodes: Array[untyped]
      # @rbs @root: Integer

      LEAF_MIN_HEIGHT = 2
      LEAF_MIN_WIDTH = 1

      # The empty table is stored through the writer, not passed to super,
      # so its element type is the pinned one.
      #: (Window) -> void
      def initialize(window)
        super()
        self.nodes = []
        self.root = 0
        nodes << LayoutNode.new(:leaf, -1, window)
      end

      #: (Integer) -> LayoutNode
      def node(id)
        nodes[id]
      end

      # The window of a leaf. Only leaves are asked; an inner node answers
      # with a throwaway window rather than nil, so the result is never nil.
      #: (Integer) -> Window
      def window_at(id)
        window = node(id).window
        window.nil? ? Window.new(Buffer.from_text("", nil)) : window
      end

      # The number of slots of the node table, free ones included; a walk
      # over 0 to node_count asks node(id).leaf? to visit every window
      # without building the list of leaves.
      #: () -> Integer
      def node_count
        nodes.length
      end

      # The leaf ids in layout order: top to bottom and left to right.
      #: () -> Array[Integer]
      def leaves
        collect_leaves(root)
      end

      #: () -> Integer
      def leaf_count
        leaves.length
      end

      # The 1-based number of a leaf in layout order, as winnr().
      #: (Integer) -> Integer
      def number_of(id)
        position_of(leaves, id) + 1
      end

      # The id of leaf number n, or of the last leaf when n is larger.
      #: (Integer) -> Integer
      def leaf_number(n)
        all = leaves
        index = n - 1
        index = 0 if index < 0
        index = all.length - 1 if index > all.length - 1
        all[index]
      end

      # The leaf whose window has the window id, or -1.
      #: (Integer) -> Integer
      def leaf_of(window_id)
        all = leaves
        i = 0
        while i < all.length
          return all[i] if window_at(all[i]).id == window_id
          i += 1
        end
        -1
      end

      # The first leaf in layout order whose window shows the buffer, or
      # -1.
      #: (Buffer) -> Integer
      def leaf_showing(buffer)
        all = leaves
        i = 0
        while i < all.length
          return all[i] if window_at(all[i]).buffer.equal?(buffer)
          i += 1
        end
        -1
      end

      # Splits leaf id, vertically (side by side) or horizontally (stacked),
      # returning the new leaf's id or -1 when there is not enough room. The
      # new window shows the same view and goes above or to the left. size is
      # the new window's text rows or columns, 0 for half; min_width is one
      # text column plus the gutter.
      #: (Integer, bool, Integer, Integer) -> Integer
      def split(id, vertical, size, min_width)
        leaf = node(id)
        old = window_at(id)
        new_size = 0
        old_size = 0
        if vertical
          total = old.width
          return -1 if total < 2 * min_width + 1
          new_size = size > 0 ? size : total / 2
          new_size = min_width if new_size < min_width
          new_size = total - min_width - 1 if new_size > total - min_width - 1
          old_size = total - new_size - 1
        else
          text = old.height
          return -1 if text < 3
          new_text = size > 0 ? size : text / 2
          new_text = 1 if new_text < 1
          new_text = text - 2 if new_text > text - 2
          new_size = new_text + 1
          old_size = text + 1 - new_size
        end
        fresh = Window.new(old.buffer)
        fresh.copy_from(old)
        kind = vertical ? :row : :column
        parent_id = leaf.parent
        new_id = 0
        if parent_id >= 0 && node(parent_id).kind == kind
          new_id = allocate(:leaf, parent_id, fresh)
          siblings = node(parent_id).children
          siblings.insert(position_of(siblings, id), new_id)
        else
          inner_id = allocate(kind, parent_id, nil)
          inner = node(inner_id)
          inner.size = leaf.size
          inner.row = leaf.row
          inner.col = leaf.col
          inner.height = leaf.height
          inner.width = leaf.width
          if parent_id < 0
            self.root = inner_id
          else
            siblings = node(parent_id).children
            siblings[position_of(siblings, id)] = inner_id
          end
          leaf.parent = inner_id
          new_id = allocate(:leaf, inner_id, fresh)
          inner.children = [new_id, id]
        end
        node(new_id).size = new_size
        leaf.size = old_size
        new_id
      end

      # Adds a window at the left (first) or right edge of the whole layout,
      # size columns wide, as a plugin's side window: when the root is
      # already a row the new leaf joins it at that end, otherwise a new
      # row becomes the root holding the new leaf and the old root, which
      # keeps the rest of the width minus the separator. Returns the new
      # leaf's id, or -1 when the root's width cannot hold the size, the
      # separator, and the minimum of what is there; the next arrange fits
      # the old content to the width left.
      #: (Window, Integer, bool) -> Integer
      def split_edge(window, size, first)
        old_root = node(root)
        total = old_root.width
        return -1 if size < LEAF_MIN_WIDTH || total < size + 1 + min_size(root, true)
        new_id = 0
        if old_root.kind == :row
          new_id = allocate(:leaf, root, window)
          first ? old_root.children.unshift(new_id) : old_root.children.push(new_id)
        else
          inner_id = allocate(:row, -1, nil)
          inner = node(inner_id)
          inner.size = old_root.size
          inner.row = old_root.row
          inner.col = old_root.col
          inner.height = old_root.height
          inner.width = old_root.width
          old_root.parent = inner_id
          old_root.size = total - size - 1
          new_id = allocate(:leaf, inner_id, window)
          inner.children = first ? [new_id, root] : [root, new_id]
          self.root = inner_id
        end
        node(new_id).size = size
        new_id
      end

      # Closes leaf id, giving its space to the sibling after it, or before
      # it when it was last, preferring a sibling that is not fixed-width.
      # Returns the id of the node that took the space, or -1 for the last
      # leaf, which cannot be closed.
      #: (Integer) -> Integer
      def close(id)
        leaf = node(id)
        parent_id = leaf.parent
        return -1 if parent_id < 0
        parent = node(parent_id)
        siblings = parent.children
        pos = position_of(siblings, id)
        target = pos + 1 < siblings.length ? pos + 1 : pos - 1
        other = pos + 1 < siblings.length ? pos - 1 : pos + 1
        if parent.kind == :row && other >= 0 && other < siblings.length
          target = other if fixed_width?(siblings[target]) && !fixed_width?(siblings[other])
        end
        gain = leaf.size + (parent.kind == :row ? 1 : 0)
        taker = siblings[target]
        node(taker).size = node(taker).size + gain
        siblings.delete_at(pos)
        free(id)
        collapse(parent_id) if siblings.length == 1
        taker
      end

      # The first leaf under a node, in layout order.
      #: (Integer) -> Integer
      def first_leaf(id)
        current = id
        current = node(current).children[0] until node(current).leaf?
        current
      end

      # The leaf next to leaf id in a direction (:left, :right, :up, :down)
      # that overlaps the row or column of the window's cursor, or -1.
      #: (Integer, Symbol) -> Integer
      def neighbour(id, direction)
        window = window_at(id)
        crow = window.row + window.cursor.row - window.top
        crow = window.row if crow < window.row
        crow = window.row + window.height - 1 if crow > window.row + window.height - 1
        ccol = window.col + window.cursor.col - window.left
        ccol = window.col if ccol < window.col
        ccol = window.col + window.width - 1 if ccol > window.col + window.width - 1
        all = leaves
        i = 0
        while i < all.length
          other = all[i]
          if other != id
            candidate = window_at(other)
            found = false
            case direction
            when :right
              found = candidate.col == window.col + window.width + 1 && crow >= candidate.row && crow <= candidate.row + candidate.height
            when :left
              found = candidate.col + candidate.width + 1 == window.col && crow >= candidate.row && crow <= candidate.row + candidate.height
            when :down
              found = candidate.row == window.row + window.height + 1 && ccol >= candidate.col && ccol <= candidate.col + candidate.width
            when :up
              found = candidate.row + candidate.height + 1 == window.row && ccol >= candidate.col && ccol <= candidate.col + candidate.width
            end
            return other if found
          end
          i += 1
        end
        -1
      end

      # Makes the windows of every split the same size, the first children
      # taking the remainder; fixed-width windows keep their width and the
      # others of their row share the rest.
      #: () -> void
      def equalize
        equalize_node(root)
      end

      # Assigns every node its rectangle inside the given area, fitting the
      # children of each split to their parent's extent: the last child
      # absorbs a difference down to its minimum, then the one before it,
      # fixed-width windows last.
      #: (Integer, Integer, Integer, Integer) -> void
      def arrange(row, col, height, width)
        arrange_node(root, row, col, height, width)
      end

      # Whether the node is fixed-width: a leaf whose window is, a row all
      # of whose children are, or a column one of whose children is.
      #: (Integer) -> bool
      def fixed_width?(id)
        current = node(id)
        return window_at(id).fixed_width if current.leaf?
        children = current.children
        i = 0
        if current.kind == :row
          while i < children.length
            return false unless fixed_width?(children[i])
            i += 1
          end
          true
        else
          while i < children.length
            return true if fixed_width?(children[i])
            i += 1
          end
          false
        end
      end

      private

      # Builds the list on the way back up rather than filling one passed
      # down: an empty array literal handed to another method is copied by
      # the compiler and the callee's pushes are lost.
      #: (Integer) -> Array[Integer]
      def collect_leaves(id)
        current = node(id)
        result = []
        if current.leaf?
          result << id
          return result
        end
        children = current.children
        i = 0
        while i < children.length
          result.concat(collect_leaves(children[i]))
          i += 1
        end
        result
      end

      #: (Array[Integer], Integer) -> Integer
      def position_of(ids, id)
        i = 0
        while i < ids.length
          return i if ids[i] == id
          i += 1
        end
        -1
      end

      # A node in a free slot, or a new slot.
      #: (Symbol, Integer, Window?) -> Integer
      def allocate(kind, parent, window)
        i = 0
        while i < nodes.length
          if node(i).kind == :free
            nodes[i] = LayoutNode.new(kind, parent, window)
            return i
          end
          i += 1
        end
        nodes << LayoutNode.new(kind, parent, window)
        nodes.length - 1
      end

      #: (Integer) -> void
      def free(id)
        current = node(id)
        current.kind = :free
        current.parent = -1
        current.children = []
        current.window = nil
      end

      # Moves the only child of an inner node into the node's place.
      #: (Integer) -> void
      def collapse(id)
        inner = node(id)
        only = inner.children[0]
        child = node(only)
        grand = inner.parent
        child.parent = grand
        child.size = inner.size
        if grand < 0
          self.root = only
        else
          siblings = node(grand).children
          siblings[position_of(siblings, id)] = only
        end
        free(id)
      end

      #: (Integer) -> void
      def equalize_node(id)
        current = node(id)
        return if current.leaf?
        children = current.children
        count = children.length
        i = 0
        if current.kind == :column
          base = current.height / count
          extra = current.height % count
          while i < count
            child = node(children[i])
            child.size = base + (i < extra ? 1 : 0)
            child.height = child.size
            child.width = current.width
            i += 1
          end
        else
          avail = current.width - (count - 1)
          flex = 0
          fixed_total = 0
          while i < count
            if fixed_width?(children[i])
              fixed_total += node(children[i]).size
            else
              flex += 1
            end
            i += 1
          end
          base = flex > 0 ? (avail - fixed_total) / flex : 0
          extra = flex > 0 ? (avail - fixed_total) % flex : 0
          k = 0
          i = 0
          while i < count
            child = node(children[i])
            unless fixed_width?(children[i])
              child.size = base + (k < extra ? 1 : 0)
              k += 1
            end
            child.width = child.size
            child.height = current.height
            i += 1
          end
        end
        i = 0
        while i < count
          equalize_node(children[i])
          i += 1
        end
      end

      #: (Integer, Integer, Integer, Integer, Integer) -> void
      def arrange_node(id, row, col, height, width)
        current = node(id)
        current.row = row
        current.col = col
        current.height = height
        current.width = width
        if current.leaf?
          window = window_at(id)
          window.row = row
          window.col = col
          window.height = height > 1 ? height - 1 : 1
          window.width = width > 0 ? width : 1
          return
        end
        children = current.children
        count = children.length
        i = 0
        if current.kind == :column
          fit(children, height, false)
          r = row
          while i < count
            size = node(children[i]).size
            arrange_node(children[i], r, col, size, width)
            r += size
            i += 1
          end
        else
          fit(children, width - (count - 1), true)
          c = col
          while i < count
            size = node(children[i]).size
            arrange_node(children[i], row, c, height, size)
            c += size + 1
            i += 1
          end
        end
      end

      # Makes the children's sizes sum to total: growth goes to the last
      # child that may change, shrinking takes from the last child down to
      # its minimum and then from the one before it. Under a row a
      # fixed-width child changes only when no other child can.
      #: (Array[Integer], Integer, bool) -> void
      def fit(children, total, along_row)
        sum = 0
        flexible = false
        i = 0
        while i < children.length
          sum += node(children[i]).size
          flexible = true if !along_row || !fixed_width?(children[i])
          i += 1
        end
        diff = total - sum
        return if diff == 0
        i = children.length - 1
        while i >= 0 && diff != 0
          id = children[i]
          skip = along_row && flexible && fixed_width?(id)
          unless skip
            current = node(id)
            if diff > 0
              current.size = current.size + diff
              diff = 0
            else
              room = current.size - min_size(id, along_row)
              take = room < -diff ? room : -diff
              take = 0 if take < 0
              current.size = current.size - take
              diff += take
            end
          end
          i -= 1
        end
        return if diff == 0
        last = node(children[children.length - 1])
        last.size = last.size + diff
        last.size = 1 if last.size < 1
      end

      # The smallest extent a node can take along an axis: a leaf needs two
      # rows or one column; a split along that axis sums its children and
      # their separators, a split across it takes the largest child.
      #: (Integer, bool) -> Integer
      def min_size(id, along_row)
        current = node(id)
        return (along_row ? LEAF_MIN_WIDTH : LEAF_MIN_HEIGHT) if current.leaf?
        children = current.children
        i = 0
        result = 0
        if (current.kind == :row) == along_row
          while i < children.length
            result += min_size(children[i], along_row)
            i += 1
          end
          result += children.length - 1 if along_row
        else
          while i < children.length
            m = min_size(children[i], along_row)
            result = m if m > result
            i += 1
          end
        end
        result
      end
    end
  end
end
