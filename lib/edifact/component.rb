module Edifact
  class Component
    attr_reader :pos, :text
    def initialize(pos, text)
      @pos = pos
      @text = text
    end

    def to_edifact
      @text.gsub(/([+:'?])/, '?\1') # TODO support different escape character and separators
    end
  end
end
