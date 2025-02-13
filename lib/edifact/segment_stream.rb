require_relative 'nodes/segment'
require_relative 'nodes/element'
require_relative 'nodes/component'
require_relative 'errors'

module Edifact
  # SegmentStream creates a stream of segments from a TokenStream.
  class SegmentStream
    def initialize(token_stream)
      @token_stream = token_stream
      @peek_buf = []
    end

    # Read the next complete segment from the stream.
    #
    # Returns nil if the end of the stream is reached.
    # Raises ParseError if the segment is incomplete or invalid.
    def read
      read_segment
    end

    # Read all remaining segments from the stream.
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
      if token.type == :eof
        return nil
      end

      token = read_token(:text)
      segment = Nodes::Segment.new(token.pos, token.value)

      loop do
        token = peek_token
        case token.type
        when :segment_separator
          read_token(:segment_separator)
          return segment
        when :element_separator
          segment << read_element
        when :eof
          raise UnexpectedEndOfInputError.new(token.pos)
        else
          raise UnexpectedTokenError.new(token, [@token_stream.element_separator, @token_stream.segment_separator])
        end
      end
    end

    def read_element
      element_separator = read_token(:element_separator)
      element = Nodes::Element.new(element_separator.pos)

      prev_token = element_separator
      loop do
        token = peek_token
        case token.type
        when :text
          text = read_token(:text)
          element << Nodes::Component.new(text.pos, text.value)
        when :component_separator
          if prev_token.type == :component_separator || prev_token.type == :element_separator
            element << Nodes::Component.new(token.pos, "")
          end
          read_token(:component_separator)
        else
          if prev_token.type == :component_separator || prev_token.type == :element_separator
            element << Nodes::Component.new(token.pos, "")
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
        expected = case expected_type
          when :text
            "<text>"
          when :component_separator
            @token_stream.component_separator
          when :element_separator
            @token_stream.element_separator
          when :segment_separator
            @token_stream.segment_separator
          end

        raise UnexpectedTokenError.new(token, [expected])
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
