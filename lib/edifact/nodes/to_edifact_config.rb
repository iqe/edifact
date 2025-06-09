module Edifact::Nodes
  class ToEdifactConfig
    attr_reader :segment_separator, :element_separator, :component_separator, :decimal_point, :release_character

    def initialize(segment_separator: "'", element_separator: "+", component_separator: ":", release_character: "?")
      @segment_separator = segment_separator
      @element_separator = element_separator
      @component_separator = component_separator
      @decimal_point = "." # We only support Strings as Component.text, so the caller has to format Floats
      @release_character = release_character

      # Using '\n' for anything but the segment separator does not make any sense.
      # But it would complicate the implementation of SegmentBuilder a lot. So we disallow it.
      if element_separator == "\n"
        raise ArgumentError.new("Element separator cannot be '\\n'")
      end
      if component_separator == "\n"
        raise ArgumentError.new("Component separator cannot be '\\n'")
      end
      if release_character == "\n"
        raise ArgumentError.new("Release character cannot be '\\n'")
      end
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
