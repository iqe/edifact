require_relative 'errors'
require_relative 'nodes/segment_group'
require_relative 'validation/segment_spec'

module Edifact
  # SegmentTree creates a tree structure from a stream of segments.
  #
  # The tree is built according to a message specification.
  # The segments and all their elements are validated against the specification.
  class SegmentTree
    # Create a new SegmentTree from a stream of segments and a message specification.
    #
    # segments can be a SegmentStream or an array of Segment objects.
    def initialize(segments, message_specification)
      @segments = segments

      # intialization for on_segment
      @spec_root_node = SpecificationNode.new(nil, 0, message_specification)
      @tree = nil
      @group_node = nil
      @spec_nodes = @spec_root_node.next

      @segment_group_stack = []
    end

    def root
      if @tree.nil?
        if @segments.respond_to?(:read)
          segment = nil
          while segment = @segments.read
            on_segment(segment)
          end
        else
          @segments.each do |segment|
            on_segment(segment)
          end
        end

        on_eof
      end
      @tree
    end

    private

    def on_segment(segment)
      first_parse_error = nil

      @spec_nodes.each do |spec_node|
        if segment.name == spec_node.name

          begin
            spec_node.validate(segment) # raises ParseError if segment is invalid
          rescue ParseError => e
            first_parse_error ||= e
            next # There may be another possible node with the same name whose elements match those of the current segment
          end

          until @segment_group_stack.size <= spec_node.level
            @segment_group_stack.pop
          end

          if spec_node.index == 0

            until @segment_group_stack.size < spec_node.level
              @segment_group_stack.pop
            end

            segment_group = Nodes::SegmentGroup.new(spec_node.parent.name)

            if @segment_group_stack.empty?
              @tree = segment_group
            else
              @segment_group_stack.last << segment_group
            end
            @segment_group_stack << segment_group

            spec_node.parent.visits += 1
            spec_node.parent.segments.each {|s| s.visits = 0} # this only works because the first node in a group is required to have min=1 max=1
          end

          @segment_group_stack.last << segment
          spec_node.visits += 1

          @spec_nodes = spec_node.next

          return
        end
      end

      if first_parse_error
        raise first_parse_error
      else
        raise ParseError.new(segment.pos, "Invalid segment #{segment.name.inspect} at position #{segment.pos}. Expected one of #{@spec_nodes.map(&:name).inspect}")
      end
    end

    def on_eof
      # Check if the spec requires more segments
      if @spec_nodes.any? {|node| node.min > node.visits}
        raise ParseError.new(Position::EOF, "Unexpected end of input. Expected one of #{@spec_nodes.map(&:name).inspect}")
      end

      # # Sanity check
      # if @segment_group_stack.size != 1
      #   raise "Position #{position}: Unexpected end of input. Expected more segments. Group Node Stack: #{@segment_group_stack.map(&:name).inspect}"
      # end
    end

    # A segment or a segment group
    class SpecificationNode
      attr_reader :level, :index, :parent, :segments
      attr_reader :name, :min, :max

      attr_accessor :visits

      def initialize(parent, index, spec)
        @parent = parent
        @level = parent ? parent.level + 1 : 0
        @index = index
        @name = spec[:name]
        @min = spec[:min] || 1
        @max = spec[:max] || 1

        # SegmentTree requires the first element of a group to be min=1 max=1
        if index == 0 && (min != 1 || max != 1)
          raise ArgumentError.new("Invalid specification for #{@name}: First element of a group must be min=1 max=1 (got min=#{min} max=#{max})")
        end

        # SegmentTree does not support groups as first element of a group (except for the root node)
        if index == 0 && spec[:segments] && parent
          raise ArgumentError.new("Invalid specification for #{@name}: First element of a group cannot be another group")
        end

        if spec[:segments]
          @segments = spec[:segments].map.with_index do |child_spec, i|
            SpecificationNode.new(self, i, child_spec)
          end
        else
          @spec = Validation::SegmentSpec.new(spec)
        end

        @visits = 0
      end

      # Validate the segment against its specification
      def validate(segment)
        @spec.validate(segment)
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
end
