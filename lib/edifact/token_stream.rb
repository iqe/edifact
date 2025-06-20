require_relative 'errors'

module Edifact
  class Position
    attr_reader :line, :column
    def initialize(line, column)
      @line, @column = line, column
    end

    def ==(other)
      other.is_a?(Position) && @line == other.line && @column == other.column
    end

    def to_s
      "#{@line}:#{@column}"
    end

    EOF = Position.new(-1, -1)
  end

  class Token
    attr_reader :pos, :type, :value
    def initialize(pos, type, value=nil)
      @pos, @type, @value = pos, type, value
    end
  end

  # TokenStream creates a stream of tokens from an EDIFACT input stream.
  #
  # It is also responsible for handling escape characters. The resulting text tokens will have escape characters removed.
  class TokenStream
    attr_reader :element_separator, :component_separator, :escape_character, :segment_separator

    def initialize(input)
      @input = input
      @peek_buf = []
      @text_buf = ""

      # Position of the current token
      @token_line = 1
      @token_column = 1

      # Position of the read cursor
      @next_line = 1
      @next_column = 1

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

    # The position of the next token to be read.
    def next_pos
      Position.new(@next_line, @next_column)
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
          read_byte # consume escape character

          c = peek_byte
          if c.nil?
            raise UnexpectedEndOfInputError.new(Position.new(@next_line, @next_column))
          end
          @text_buf << read_byte
        else
          @text_buf << read_byte
        end
      end
    end

    def parse_una_header
      # UNA:+.? '
      una = 9.times.map {read_byte}.join
      if una && una.length == 9 && una[0..2] == "UNA"
        @component_separator = una[3]
        @element_separator = una[4]
        @escape_character = una[6]
        @segment_separator = una[8]
      else
        raise InvalidUnaHeaderError.new(Position.new(@token_line, @token_column), una)
      end

      # Detect duplicate control characters
      if una[3, 6].bytes.uniq.length != 6
        raise InvalidUnaHeaderError.new(Position.new(@token_line, @token_column), una)
      end

      @token_line = @next_line
      @token_column = @next_column
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
      c = @peek_buf.shift

      if c == "\n"
        @next_line += 1
        @next_column = 1
      else
        @next_column += 1
      end

      c
    end

    def separator_token(delimiter_name, delimiter_value)
      if @text_buf.empty?
        read_byte # consume delimiter
        separator_line = @token_line
        separator_columm = @token_column

        @token_line = @next_line
        @token_column = @next_column

        Token.new(Position.new(separator_line, separator_columm), delimiter_name, delimiter_value)
      else
        text_token
      end
    end

    def text_token
      text = @text_buf
      text_line = @token_line
      text_column = @token_column

      @text_buf = ""
      @token_line = @next_line
      @token_column = @next_column

      Token.new(Position.new(text_line, text_column), :text, text)
    end

    def eof_token
      Token.new(Position.new(@next_line, @next_column), :eof)
    end
  end
end
