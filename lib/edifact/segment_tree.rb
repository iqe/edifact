require_relative 'errors'
require_relative 'nodes/segment_group'
require_relative 'validation/segment_spec'

module Edifact
  # SegmentTree creates a tree structure from a stream of segments.
  #
  # The tree is built according to a message specification.
  # The tree structure and all segments' elements are validated against the specification.
  class SegmentTree

    # A segment or a segment group
  class SpecificationNode
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
          SpecificationNode.new(self, i, child_spec)
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

    def initialize(segment_stream, message_specification)
      @segment_stream = segment_stream

      # intialization for on_segment
      @spec_root_node = SpecificationNode.new(nil, 0, message_specification)
      @tree = nil
      @group_node = nil
      @spec_nodes = @spec_root_node.next

      @group_node_stack = []
    end

    def root
      if @tree.nil?
        segment = nil
        while segment = @segment_stream.read
          on_segment(segment)
        end

        on_eof
      end
      @tree
    end

    private

    def on_segment(segment)
      @spec_nodes.each do |spec_node|
        if segment.name == spec_node.name

          until @group_node_stack.size <= spec_node.level
            @group_node_stack.pop
          end

          if spec_node.index == 0

            until @group_node_stack.size < spec_node.level
              @group_node_stack.pop
            end

            new_group_node = Nodes::SegmentGroup.new(spec_node.parent.name)

            if @group_node_stack.empty?
              @tree = new_group_node
            else
              @group_node_stack.last.segments << new_group_node
            end
            @group_node_stack << new_group_node

            spec_node.parent.visits += 1
            spec_node.parent.segments.each {|s| s.visits = 0} # this only works because the first node in a group is required to have min=1 max=1
          end

          @group_node_stack.last.segments << segment
          spec_node.visits += 1

          Validation::SegmentSpec.new(spec_node).validate(segment)

          @spec_nodes = spec_node.next

          return
        end
      end

      raise ParseError.new(segment.pos, "Invalid segment #{segment.name.inspect} at position #{segment.pos}. Expected one of #{@spec_nodes.map(&:name).inspect}")
    end

    def on_eof
      # Check if the spec requires more segments
      if @spec_nodes.any? {|node| node.min > node.visits}
        raise ParseError.new(-1, "Unexpected end of input. Expected one of #{@spec_nodes.map(&:name).inspect}") # FIXME: Position
      end

      # # Sanity check
      # if @group_node_stack.size != 1
      #   raise "Position #{position}: Unexpected end of input. Expected more segments. Group Node Stack: #{@group_node_stack.map(&:name).inspect}"
      # end
    end
  end
end
