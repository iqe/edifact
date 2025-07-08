# EDIFACT

A validating parser and builder for EDIFACT messages in Ruby.

## Features

- **Parse EDIFACT messages** into structured Ruby objects.
- **Validate** segments, elements, and components against flexible specifications.
- **Build** EDIFACT messages programmatically with correct UNA headers and control characters.
- **Customizable** separators and escape characters.
- **Detailed error reporting** with position information.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'edifact'
```

Or build and install the gem locally:

```sh
rake build
gem install ./edifact-0.5.0.gem
```

## Usage

There are multiple layers of functionality in this library, from low-level tokenization to high-level interchange validation. We start with the most basic usage and build up to more complex scenarios.

### Parsing an EDIFACT message into segments

Use a `SegmentStream` to get a raw list of segments. This only requires that the message is made out of well-formed EDIFACT segments.

```ruby
require 'edifact'

input = "UNA:+.? 'ABC+Hello'DEF+World+42:1'"
token_stream = Edifact::TokenStream.new(StringIO.new(input))
segment_stream = Edifact::SegmentStream.new(token_stream)

puts segment_stream.read_remaining.inspect # A list of segments
```

### Validating and parsing an EDIFACT message into a tree

To validate the content of segments, elements and components, you can use a SegmentTree. This allows you to define segment specifications and validate the segments against them.

```ruby
require 'edifact'

# See further below for the segment specification format
spec = {
  name: "MSG",
  segments: [
    {
      name: "ABC",
      elements: [
        ["an..10", "n4"],
        { components: ["n2"], optional: true }
      ]
    },
    {
      name: "DEF",
      elements: [
        ["an..5"]
      ]
    }
  ]
}

token_stream = Edifact::TokenStream.new(StringIO.new("UNA:+.? 'ABC+Hello:2000+42'DEF+World'"))
segment_stream = Edifact::SegmentStream.new(token_stream)
segment_tree = Edifact::SegmentTree.new(segment_stream, spec)

puts segment_tree.root.inspect # Returns a tree structure of segments
```

### Validating a real-life EDIFACT interchange

In EDIFACT, messages are actually called 'interchanges'. They then contain one or more 'messages'. These interchanges and messages always require certain header and footer segments. You can use the `Interchange` class to parse and validate an entire interchange without having to manually handle the headers and footers.

You can then optionally use another specification to validate the message contents.

```ruby
require 'edifact'

input = "UNA:+.? 'UNB+UNOC:3+Sender:14+Receiver:14+240101:1200+42'UNH+7+INVOIC:D:97B:UN:1.0'ABC+Hello'DEF+World'UNT+4+7'UNH+8+INVOIC:D:97B:UN:1.0'ABC+Another'DEF+Message'UNT+4+8'UNZ+2+42'"
token_stream = Edifact::TokenStream.new(StringIO.new(input))
segment_stream = Edifact::SegmentStream.new(token_stream)
interchange = Edifact::Interchange.new(segment_stream)

# Get the raw list of segments of each message in the interchange
interchange.messages.each do |message|
  puts message.segments.inspect
end

# Or use a SegmentTree to validate each message
message_spec = {
  # .. specification for evertything between UNH and UNT
}

interchange.messages.each do |message|
  tree = Edifact::SegmentTree.new(message.segments, tree_spec)
  puts tree.root.inspect
end
```

### Validating segments, elements and components

You can define specifications to validate segments, elements and components. A specification is a hash that describes the expected structure of segments, including their elements and components.

What is a segment, element and component?

`ABC+Hello:World+42'` is a __segment__ with the name `ABC`. It contains two __elements__: `Hello:World` and `42`. The first element has two __components__, `Hello` and `World`. The second element has a single component, `42`.

Here is a simple example of how to define a specification and validate segments against it:

```ruby
# See below for the detailed specification format
spec = {
  name: "MSG", # arbitrary name for the message (does not show up in the EDIFACT message)
  segments: [
    {
      name: "ABC",
      elements: [
        ["an..10", "n4"],
        { components: ["n2"], optional: true }
      ]
    }
  ]
}

token_stream = Edifact::TokenStream.new(StringIO.new("UNA:+.? 'ABC+Hello:2000+42'"))
segment_stream = Edifact::SegmentStream.new(token_stream)
segment_tree = Edifact::SegmentTree.new(segment_stream, spec)

puts segment_tree.root.inspect
```

**Segments** are specified as hashes that contain element and component specifications:

```ruby
{
  name: "ABC",
  min: 0, # Segment can appear 0 or more times. Default is 1.
  max: 2, # Segment can appear up to 2 times. Default is 1.
  elements: [
    ["an..10"], # first element: alphanumeric, up to 10 chars
    { components: ["n2"], optional: true } # optional second element: numeric, 2 digits
  ]
}
```

**Segments can also be grouped** to allow repetition of a set of segments. Groups can also be nested inside other groups to form a tree. For example:

```ruby
spec = {
  name: "MSG",
  segments: [
    {
      name: "SG1", # Arbitrary name for the group (does not show up in the EDIFACT message)
      segments: [
        {
          name: "ABC",
          elements: [["an..10", "n2"], ["an..20", "somevalue"]]
        },
        {
          name: "SG2", # Nested group
          min: 0, # Nested group can appear 0 or more times. Omit to use the default '1'.
          max: 10, # Nested group can appear up to 10 times. Omit to use the default '1'.
          segments: [
            {
              name: "DEF",
              elements: [["an..5"]]
            },
            {
              name: "GHI",
              elements: [["n3"]]
            }
          ]
        },
        {
          name: "JKL",
          elements: [["an..10"]]
        }
      ]
    }
  ]
}
```

**Elements** can be specified with various formats:

* `["an..10", "n2"]` - An array of component specifications. All components must match. Any extra components will be ignored.
* `{components: ["an..10", "n2"], optional: true}` - An optional element. If the element is not present, it will not raise an error.

**Components** can be specified with one of the following:

* `"an..20"` - Alphanumeric, up to 20 characters
* `"n..2"` - Numeric, up to 2 digits
* `"n3"` - Numeric, exactly 3 digits
* `"a5"` - Characters [A-Za-z], exactly 5 characters
* `"somevalue"` - The literal value "somevalue"
* `/a+/` - Regular expression
* `["somevalue", "differentvalue", "n3"]` - An array of nested component specifications. Allows to match any of the given specifications.
* `{value: "n4", optional: true}` - an optional component. If the component is not present (it is blank or missing from the end of the element), it will not raise an error.


### Building an EDIFACT Message

There is also a `SegmentBuilder` class that allows you to programmatically build EDIFACT messages. This is useful for generating messages with specific segments and elements without having to manually format the string. It also handles escaping and the UNA header automatically.

```ruby
require 'edifact'

builder = Edifact::SegmentBuilder.new

# Low level API
builder.segment("ABC")
builder.element("Hello", "World")

# High level DSL
builder.DEF("How", "are", ["you", "?"])

puts builder.to_edifact # "UNA:+.? 'ABC+Hello:World'DEF+How'are+you:??'"
```

You can also customize the UNA header and control characters used in the message:

```ruby
require 'edifact'

builder = Edifact::SegmentBuilder.new(
  Edifact::Nodes::ToEdifactConfig.new(segment_separator: "\n")
)

# ... add segments as before ...

puts builder.to_edifact # uses \n as segment separator instead of the default '
```

## Development

- Run tests: `rake test`
- Test files are in the [`test/`](test/) directory.

## Project Structure

- [`lib/edifact/token_stream.rb`](lib/edifact/token_stream.rb): Tokenizes EDIFACT input.
- [`lib/edifact/segment_stream.rb`](lib/edifact/segment_stream.rb): Parses tokens into segments.
- [`lib/edifact/segment_tree.rb`](lib/edifact/segment_tree.rb): Builds a tree of segments/groups.
- [`lib/edifact/segment_builder.rb`](lib/edifact/segment_builder.rb): Programmatic EDIFACT message builder.
- [`lib/edifact/interchange.rb`](lib/edifact/interchange.rb): High-level interchange/message validation.
- [`lib/edifact/validation/`](lib/edifact/validation/): Validation logic for segments, elements, and components.

## License

MIT License
