require_relative 'errors'
require_relative 'message_specification_node'
require_relative 'validation/segment_spec'

module Edifact
  # SegmentTree creates a tree structure from a stream of segments.
  #
  # The tree is built according to a message specification.
  # The tree structure and all segments' elements are validated against the specification.
  class SegmentTree
    class GroupNode
      attr_reader :name, :segments
      def initialize(name)
        @name = name
        @segments = []
      end

      def pos
        @segments.first ? @segments.first.pos : -1
      end
    end

    class SegmentNode
      def initialize(segment)
        @segment = segment
      end

      def pos
        @segment.pos
      end

      def name
        @segment.name
      end

      def elements
        @segment.elements
      end
    end

    def initialize(segment_stream, message_specification)
      @segment_stream = segment_stream

      # intialization for on_segment
      @spec_root_node = MessageSpecificationNode.new(nil, 0, message_specification)
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

            new_group_node = GroupNode.new(spec_node.parent.name)

            if @group_node_stack.empty?
              @tree = new_group_node
            else
              @group_node_stack.last.segments << new_group_node
            end
            @group_node_stack << new_group_node

            spec_node.parent.visits += 1
            spec_node.parent.segments.each {|s| s.visits = 0} # this only works because the first node in a group is required to have min=1 max=1
          end

          @group_node_stack.last.segments << SegmentNode.new(segment)
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
