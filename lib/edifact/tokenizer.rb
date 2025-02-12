module Edifact
  class Token
    attr_reader :pos, :type, :value
    def initialize(pos, type, value=nil)
      @pos, @type, @value = pos, type, value
    end
  end

  # Tokenizer creates a stream of tokens from an EDIFACT input stream.
  #
  # It is also responsible for handling escape characters. The resulting text tokens will have escape characters removed.
  class Tokenizer
    attr_reader :element_separator, :component_separator, :escape_character, :segment_separator

    def initialize(input)
      @input = input
      @peek_buf = []
      @text_buf = ""

      @token_pos = 1
      @escape_char_count = 0

      @element_separator = "+"
      @component_separator = ":"
      @escape_character = "?"
      @segment_separator = "'"

      parse_una_header
    end

    # Read the next token from the input stream.
    def read
      next_token
    end

    # Read all remaining tokens from the input stream.
    def read_remaining
      tokens = []
      while token = self.read
        tokens << token
        break if token.type == :eof
      end
      tokens
    end

    private

    def next_token
      loop do
        c = peek_byte
        case c
        when nil
          if @text_buf.empty?
            return eof_token
          else
            return text_token
          end
        when @segment_separator
          return separator_token(:segment_separator, @segment_separator)
        when @element_separator
          return separator_token(:element_separator, @element_separator)
        when @component_separator
          return separator_token(:component_separator, @component_separator)
        when @escape_character
          @escape_char_count += 1
          read_byte # consume escape character

          c = peek_byte
          if c.nil?
            raise "Unexpected end of input after escape character"
          end
          @text_buf << read_byte
        else
          @text_buf << read_byte
        end
      end
    end

    def parse_una_header
      if @input.nil?
        raise "Tokenizer input must not be nil"
      end

      # UNA:+.? '
      una = @input.read(9)
      @token_pos += 9
      if una && una.length == 9 && una[0..2] == "UNA"
        @component_separator = una[3]
        @element_separator = una[4]
        @escape_character = una[6]
        @segment_separator = una[8]
      else
        raise "Invalid or missing UNA header (got '#{una}')"
      end
    end

    def peek_byte
      if @peek_buf.empty?
        @peek_buf << @input.read(1)
      end
      @peek_buf.last
    end

    def read_byte
      if @peek_buf.size != 1
        peek_byte
      end
      @peek_buf.shift
    end

    def separator_token(delimiter_name, delimiter_value)
      if @text_buf.empty?
        read_byte # consume delimiter
        @token_pos += 1
        Token.new(@token_pos - 1, delimiter_name, delimiter_value)
      else
        text_token
      end
    end

    def text_token
      text = @text_buf
      text_pos = @token_pos

      @text_buf = ""
      @token_pos += text.size + @escape_char_count
      @escape_char_count = 0

      Token.new(text_pos, :text, text)
    end

    def eof_token
      Token.new(@token_pos, :eof, nil)
    end
  end
end
