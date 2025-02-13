module Edifact::Nodes
  class Element
    attr_reader :pos, :components
    def initialize(pos, components=[])
      @pos = pos
      @components = components
    end

    def length
      to_edifact.length
    end

    def <<(component)
      @components << component
    end

    def to_edifact
      "+" + @components.map(&:to_edifact).join(":") # TODO support different element/component separators
    end

    def ==(other)
      self.class == other.class && @pos == other.pos && @components == other.components
    end
  end
end
