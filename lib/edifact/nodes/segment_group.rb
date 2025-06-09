require_relative 'to_edifact_config'

module Edifact::Nodes
  class SegmentGroup
    attr_reader :name, :segments
    def initialize(name, segments=[])
      @name = name
      @segments = segments
    end

    def pos
      @segments.first ? @segments.first.pos : Edifact::Nodes::Position.new(0, 0)
    end

    def length
      to_edifact.length
    end

    def <<(segment)
      @segments << segment
    end

    def to_edifact(config=Edifact::Nodes::ToEdifactConfig::DEFAULT)
      @segments.map {|s| s.to_edifact(config)}.join
    end

    def to_h
      {
        name: @name,
        segments: @segments.map(&:to_h)
      }
    end

    def ==(other)
      self.class == other.class && @name == other.name && @segments == other.segments
    end

    def [](query)
      segments = case query
        when /^[A-Z0-9]{3}\+.+/ # segment name + content
          @segments.select { |segment| segment.to_edifact.start_with?(query) }
        when /^[A-Z0-9]{3}/ # segment name
          @segments.select { |segment| segment.name == query }
        when Regexp
          @segments.select { |segment| segment.to_edifact =~ query }
        when Integer
          [@segments[query]]
        else
          raise ArgumentError.new("Invalid query: #{query.inspect}")
        end

      case segments.length
      when 0
        nil
      when 1
        segments.first
      else
        segments
      end
    end
  end
end
