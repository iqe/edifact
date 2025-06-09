require_relative 'to_edifact_config'

module Edifact::Nodes
  class SegmentGroup
    attr_reader :name, :segments
    def initialize(name, segments=[])
      @name = name
      @segments = segments
    end

    def pos
      @segments.first ? @segments.first.pos : -1
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
  end
end
