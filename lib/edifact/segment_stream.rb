require_relative 'segment'
require_relative 'element'
require_relative 'component'

module Edifact
  class ParseError < StandardError
    attr_reader :pos, :actual_token, :expected_tokens

    def initialize(actual_token, expected_tokens=[])
      @pos = actual_token.pos
      @actual_token = actual_token
      @expected_tokens = expected_tokens

      #super("Position #{@pos}: Expected one of #{@expected_tokens.inspect}, but got #{@actual_token}")
      super("Unexpected \"#{@actual_token.value}\" at position #{@pos}")
    end
  end

  class SegmentStream
    def initialize(token_stream)
      @token_stream = token_stream
      @peek_buf = []
    end

    def read
      read_segment
    end

    def read_remaining
      segments = []
      while segment = read
        segments << segment
      end
      segments
    end

    private

    def read_segment
      token = peek_token
      if token.nil? || token.type == :eof # TokenStream returns :eof instead of nil at end of input
        return nil
      end

      token = read_token(:text)
      segment = Segment.new(token.pos, token.value)

      loop do
        token = peek_token
        case token.type
        when :segment_separator
          read_token(:segment_separator)
          return segment
        when :element_separator
          segment << read_element
        when :eof
          raise "Unexpected end of file at position #{token.pos}"
        else
          raise ParseError.new(token, [@token_stream.segment_separator, @token_stream.element_separator])
        end
      end
    end

    def read_element
      element_separator = read_token(:element_separator)
      element = Element.new(element_separator.pos + 1) # +1 to skip the element separator

      prev_token = element_separator
      loop do
        token = peek_token
        case token.type
        when :text
          text = read_token(:text)
          element << Component.new(text.pos, text.value)
        when :component_separator
          if prev_token.type == :component_separator || prev_token.type == :element_separator
            element << Component.new(token.pos, "")
          end
          read_token(:component_separator)
        else
          if prev_token.type == :component_separator || prev_token.type == :element_separator
            element << Component.new(token.pos, "")
          end
          break
        end
        prev_token = token
      end

      element
    end

    def read_token(expected_type)
      if @peek_buf.empty?
        peek_token
      end
      token = @peek_buf.shift

      if token.type != expected_type
        raise ParseError.new(token, [expected_type]) # FIXME wrong usage of expected_type
      end

      token
    end

    def peek_token
      if @peek_buf.empty?
        @peek_buf << @token_stream.read
      end
      @peek_buf.last
    end
  end
end
