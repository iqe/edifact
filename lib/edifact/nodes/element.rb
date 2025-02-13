module Edifact::Nodes
  class Element
    attr_reader :pos, :components
    def initialize(pos)
      @pos = pos
      @components = []
    end

    def <<(component)
      @components << component
    end

    def to_edifact
      "+" + @components.map(&:to_edifact).join(":") # TODO support different element/component separators
    end
  end
end
