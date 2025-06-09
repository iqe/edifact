require_relative 'to_edifact_config'

module Edifact::Nodes
  class Component
    attr_reader :pos, :text
    def initialize(pos, text)
      @pos = pos
      @text = text
    end

    def length
      to_edifact.length
    end

    def to_edifact(config=Edifact::Nodes::ToEdifactConfig::DEFAULT)
      config.escape(@text)
    end

    def ==(other)
      self.class == other.class && @pos == other.pos && @text == other.text
    end
  end
end
