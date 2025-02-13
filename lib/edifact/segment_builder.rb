require_relative 'nodes/segment_group'
require_relative 'nodes/segment'
require_relative 'nodes/element'
require_relative 'nodes/component'

module Edifact
  class SegmentBuilder
    def initialize
      @una_header = "UNA:+.? '"
      @pos = 1 + @una_header.length

      @segment_group = Nodes::SegmentGroup.new("")
    end

    def segment(name)
      unless @segment_group.segments.empty?
        @pos += 1 # segment terminator of previous segment
      end

      @pos += name.length
      @segment = Nodes::Segment.new(@pos - name.length, name)
      @segment_group << @segment
    end

    def element(*component_values)
      @pos += 1 # element separator
      e = Nodes::Element.new(@pos)

      component_values.each_with_index do |component_value, i|
        if i > 0
          @pos += 1 # component separator
        end

        c = Nodes::Component.new(@pos, component_value)
        @pos += c.to_edifact.length # 'to_edifact' to correctly count escape characters

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
