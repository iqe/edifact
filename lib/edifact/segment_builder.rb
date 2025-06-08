require_relative 'nodes/segment_group'
require_relative 'nodes/segment'
require_relative 'nodes/element'
require_relative 'nodes/component'

module Edifact
  class SegmentBuilder
    def initialize
      @una_header = "UNA:+.? '"
      @line = 1
      @column = 1 + @una_header.length

      @segment_group = Nodes::SegmentGroup.new("")
    end

    def segment(name)
      unless @segment_group.segments.empty?
        @column += 1 # segment terminator of previous segment
      end

      @column += name.length
      @segment = Nodes::Segment.new(Position.new(@line, @column - name.length), name)
      @segment_group << @segment
    end

    def element(*component_values)
      e = Nodes::Element.new(Position.new(@line, @column))

      component_values.each_with_index do |component_value, i|
        @column += 1 # element separator (for i == 0) or component separator (for i > 0)

        c = Nodes::Component.new(Position.new(@line, @column), component_value)
        @column += c.length

        e.components << c
      end

      if @segment.nil?
        raise "No segment defined"
      end

      @segment.elements << e
    end

    def to_edifact
      @una_header + @segment_group.to_edifact
    end

    module SegmentStreamInterface
      def read
        @segment_group.segments.shift
      end

      def read_remaining
        @segment_group.segments.take(@segment_group.segments.length)
      end
    end
    include SegmentStreamInterface
  end
end
