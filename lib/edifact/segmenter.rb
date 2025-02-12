require_relative 'tokenizer'
require_relative 'segment'
require_relative 'element'
require_relative 'component'

module Edifact
  class Segmenter
    def initialize
      @callbacks = {
        segment: [],
        # element: [],
        # component: [],
        eof: [],
      }
    end

    def on(tag, &block)
      if !@callbacks.key?(tag)
        raise "Unknown callback: #{tag}. Use one of: #{@callbacks.keys.join(", ")}"
      end

      @callbacks[tag] << block
    end

    def parse(input)
      mode = :start
      segments = []

      segment = nil
      element = nil

      prev_token = nil
      tokenizer = Edifact::Tokenizer.new(input)
      tokenizer.read_remaining.each do |token|
        case token.type
          when :segment_separator
            case mode
              when :element, :component
                if prev_token.type != :text
                  element << Component.new(token.pos, "")
                end
                mode = :segment
              else
                raise "Unexpected \"#{tokenizer.segment_separator}\" at position #{token.pos}"
            end
            mode = :segment
          when :element_separator
            case mode
              when :element, :component
                if prev_token.type == :element_separator
                  element << Component.new(token.pos, "")
                end
                element = Element.new(token.pos + 1) # +1 to skip the element separator
                segment << element
                mode = :element
              else
                raise "Unexpected \"#{tokenizer.element_separator}\" at position #{token.pos}"
            end
          when :component_separator
            case mode
              when :element
                if element.nil?
                  raise "Unexpected \"#{tokenizer.component_separator}\" at position #{token.pos}"
                end
                element << Component.new(token.pos, "")
                mode = :component
              when :component
                if prev_token.type == :component_separator
                  element << Component.new(token.pos, "")
                end
              else
                raise "Unexpected \"#{tokenizer.component_separator}\" at position #{token.pos}"
            end
          when :text
            case mode
              when :start, :segment
                segment_name = token.value
                if segment
                  callback(:segment, segment)
                end
                segment = Segment.new(token.pos, segment_name)
                segments << segment
                mode = :element
              when :element
                component_value = token.value
                element << Component.new(token.pos, component_value)
                mode = :component
              when :component
                component_value = token.value
                element << Component.new(token.pos, component_value)
              else
                raise "Unexpected text at position #{token.pos}"
            end
          when :eof
            case mode
              when :segment
                if segment
                  callback(:segment, segment)
                end
                callback(:eof, token.pos)
              else
                raise "Unexpected end of file at position #{token.pos}"
            end
        end
        prev_token = token
      end
      segments
    end

    private

    def callback(tag, *args)
      @callbacks[tag].each {|cb| cb.call(*args)}
    end
  end
end
