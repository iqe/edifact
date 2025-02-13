module Edifact
  # A segment or a segment group
  class MessageSpecificationNode
    attr_reader :level, :index, :parent, :segments, :elements
    attr_reader :name, :min, :max

    attr_accessor :visits

    def initialize(parent, index, spec)
      @parent = parent
      @level = parent ? parent.level + 1 : 0
      @index = index
      @name = spec[:name]
      @min = spec[:min] || 1
      @max = spec[:max] || 1
      @elements = spec[:elements] || []

      # SegmentTree requires the first element of a group to be min=1 max=1
      if index == 0 && (min != 1 || max != 1)
        raise "Invalid specification for #{@name}: First element of a group must be min=1 max=1 (got min=#{min} max=#{max})"
      end

      # SegmentTree does not support groups as first element of a group (except for the root node)
      if index == 0 && spec[:segments] && parent
        raise "Invalid specification for #{@name}: First element of a group cannot be another group"
      end

      if spec[:segments]
        @segments = spec[:segments].map.with_index do |child_spec, i|
          MessageSpecificationNode.new(self, i, child_spec)
        end
      end

      @visits = 0
    end

    # Returns a list of all nodes that can be visited next, based on the current visit count of this node
    def next
      res = []
      if visits < max
        if self.segments
          child = self.segments.first
          if child
            res += child.next # Ask the first child for the next node
          end
        else
          res << self # I can still be visited
        end
        if visits >= min
          res += next_sibling # I have been visited enough times, so also try next sibling
        end
      else
        res += next_sibling # no more visits left on this node, try next sibling
      end
      res
    end

    protected

    def next_sibling
      if parent.nil?
        [] # I'm the root node, I don't have siblings
      else
        sibling = parent.segments[index + 1]
        if sibling
          sibling.next
        else
          # I'm the last child
          if parent.visits < parent.max
            # parent can still be visited, so try its first child and its next sibling
            [parent.segments.first, *parent.next_sibling] # only works if the first child is mandatory
          else
            parent.next_sibling # parent can not be visited anymore, so try its next sibling
          end
        end
      end
    end
  end
end
