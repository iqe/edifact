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

    def to_edifact
      @segments.map(&:to_edifact).join
    end
  end
end
