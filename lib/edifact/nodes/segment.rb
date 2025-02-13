module Edifact::Nodes
  class Segment
    attr_reader :pos, :name, :elements
    def initialize(pos, name, elements=[])
      @pos = pos
      @name = name
      @elements = elements
    end

    def <<(element)
      @elements << element
    end

    def to_edifact
      @name + @elements.map(&:to_edifact).join + "'" # TODO support different segment separator
    end
  end
end
