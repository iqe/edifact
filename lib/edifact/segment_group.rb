module Edifact
  class SegmentGroup
    attr_reader :name, :segments
    def initialize(name, segments=[])
      @name = name
      @segments = segments
    end

    def pos
      @segments.first ? @segments.first.pos : -1
    end
  end
end
