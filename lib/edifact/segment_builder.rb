require_relative 'nodes/segment_group'
require_relative 'nodes/segment'
require_relative 'nodes/element'
require_relative 'nodes/component'

module Edifact
  class SegmentBuilder
    def initialize(config = Edifact::Nodes::ToEdifactConfig::DEFAULT)
      @config = config
      @line = 1
      @column = 1 + @config.una_header.length

      @segment_group = Nodes::SegmentGroup.new("")
    end

    def segment(name)
      if @segment_group.segments.empty?
        # first segment, handle \n from una header
        if @config.segment_separator == "\n"
          @line += 1
          @column = 1
        end
      else
        # segment separator of previous segment
        if @config.segment_separator == "\n"
          @line += 1
          @column = 1
        else
          @column += 1
        end
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

        i = component_value.rindex("\n")
        if i
          newline_count = component_value.count("\n")

          @line += newline_count
          @column = component_value.length - i
        else
          @column += component_value.length
        end

        e.components << c
      end

      if @segment.nil?
        raise RuntimeError.new("Cannot build element. No segment defined")
      end

      @segment.elements << e
    end

    def method_missing(name, *args, &block)
      if name =~ /^[A-Z0-9]{3}$/
        self.segment(name.to_s)

        elements = args
        elements.each do |components|
          case components
          when String
            self.element(components) # single component
          when Array
            self.element(*components) # multiple components
          else
            raise ArgumentError.new("Invalid argument type: #{components.class}")
          end
        end
      else
        super
      end
    end

    def to_edifact
      @config.una_header + @segment_group.to_edifact(@config)
    end

    module SegmentGroupInterface
      def [](query)
        @segment_group[query]
      end

      def length
        @segment_group.length
      end

      def pos
        @segment_group.pos
      end

      def segments
        @segment_group.segments
      end

      def to_h
        @segment_group.to_h
      end
    end
    include SegmentGroupInterface

    module SegmentStreamInterface
      def read
        @segment_group.segments.shift
      end

      def read_remaining
        @segment_group.segments.take(@segment_group.segments.length)
      end

      def next_pos
        if @segment_group.segments.empty?
          Position.new(@line, @column)
        else
          Position.new(@line, @column + 1) # +1 for the last segment separator
        end
      end
    end
    include SegmentStreamInterface
  end
end
