require_relative 'to_edifact_config'

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

    def to_edifact(config=Edifact::Nodes::ToEdifactConfig::DEFAULT)
      config.element_separator + @components.map {|c| c.to_edifact(config)}.join(config.component_separator)
    end

    def ==(other)
      self.class == other.class && @pos == other.pos && @components == other.components
    end
  end
end
