module Edifact::Nodes
  class ToEdifactConfig
    attr_reader :segment_separator, :element_separator, :component_separator, :decimal_point, :release_character

    def initialize(segment_separator: "'", element_separator: "+", component_separator: ":", release_character: "?")
      @segment_separator = segment_separator
      @element_separator = element_separator
      @component_separator = component_separator
      @decimal_point = "." # We only support Strings as Component.text, so the caller has to format Floats
      @release_character = release_character
    end

    def una_header
      "UNA#{@component_separator}#{@element_separator}#{@decimal_point}#{@release_character} #{@segment_separator}"
    end

    def escape(text)
      text.gsub(/([#{@segment_separator}#{@element_separator}#{@component_separator}#{@release_character}])/, "#{@release_character}\\1")
    end

    DEFAULT = new
  end
end
