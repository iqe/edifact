module Edifact::Nodes
  class Segment
    attr_reader :pos, :name, :elements
    def initialize(pos, name, elements=[])
      @pos = pos
      @name = name
      @elements = elements
    end

    def length
      to_edifact.length
    end

    def <<(element)
      @elements << element
    end

    def to_edifact
      @name + @elements.map(&:to_edifact).join + "'" # TODO support different segment separator
    end

    def to_h
      {
        name: @name,
        elements: @elements.map {|e| e.components.map(&:text)}
      }
    end

    def ==(other)
      self.class == other.class && @pos == other.pos && @name == other.name && @elements == other.elements
    end
  end
end
