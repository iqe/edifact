require 'test_helper'

class InterchangeTest < Minitest::Test
  include TestHelper

  def test_reads_basic_interchange
    input = <<~EDIFACT
      UNB+UNOC:3+Sender:14+Receiver:14+240101:1200+42
      UNH+7+INVOIC:D:97B:UN:1.0
      ABC+Hello
      DEF+World
      UNT+4+7
      UNZ+1+42
    EDIFACT

    @interchange = interchange(input)
  end

  def test_reads_multiple_messages
    input = <<~EDIFACT
      UNB+UNOC:3+Sender:14+Receiver:14+240101:1200+42
      UNH+7+INVOIC:D:97B:UN:1.0
      ABC+First
      DEF+Message
      UNT+4+7
      UNH+8+INVOIC:D:97B:UN:1.0
      ABC+Second
      DEF+Message
      UNT+4+8
      UNZ+1+42
    EDIFACT

    ix = interchange(input)

    assert_equal 2, ix.messages.size
    assert_equal "7", ix.messages[0].unh.elements[0].components[0].text
    assert_equal "8", ix.messages[1].unh.elements[0].components[0].text

    assert_equal "UNH+7+INVOIC:D:97B:UN:1.0'ABC+First'DEF+Message'UNT+4+7'", ix.messages[0].to_edifact
    assert_equal "UNH+8+INVOIC:D:97B:UN:1.0'ABC+Second'DEF+Message'UNT+4+8'", ix.messages[1].to_edifact
  end

  def test_validates_unb_and_unz
    invalid_unb = <<~EDIFACT
      UNB
      UNH+7+Z:Y:X:W
      UNT+2+7
      UNZ+1+42
    EDIFACT

    invalid_unz = <<~EDIFACT
      UNB+UNOC:3+S+R+240101:1200+42
      UNH+7+Z:Y:X:W
      UNT+2+7
      UNZ
    EDIFACT

    assert_raises_msg(Edifact::ParseError, 'Missing element at position 2:4, expected ["a4", "n1"]') { interchange(invalid_unb) }
    assert_raises_msg(Edifact::ParseError, 'Missing element at position 5:4, expected ["n..6"]') { interchange(invalid_unz) }
  end

  def test_validates_unh_and_unt
    invalid_unh = <<~EDIFACT
      UNB+UNOC:3+S+R+240101:1200+42
      UNH
      UNT+2+7
      UNZ+1+42
    EDIFACT

    invalid_unt = <<~EDIFACT
      UNB+UNOC:3+S+R+240101:1200+42
      UNH+7+Z:Y:X:W
      UNT
      UNZ+1+42
    EDIFACT

    assert_raises_msg(Edifact::ParseError, 'Missing element at position 3:4, expected ["an..14"]') { interchange(invalid_unh) }
    assert_raises_msg(Edifact::ParseError, 'Missing element at position 4:4, expected ["n..6"]') { interchange(invalid_unt) }
  end

  def test_detects_missing_unz
    missing_unz = <<~EDIFACT
      UNB+UNOC:3+S+R+240101:1200+42
      UNH+7+Z:Y:X:W
      UNT+2+7
    EDIFACT

    assert_raises_msg(Edifact::ParseError, "Unexpected end of input at position 5:1.") { interchange(missing_unz) }
  end

  def test_detects_missing_unt
    missing_unt = <<~EDIFACT
      UNB+UNOC:3+S+R+240101:1200+42
      UNH+7+Z:Y:X:W
    EDIFACT

    assert_raises_msg(Edifact::ParseError, "Unexpected end of input at position 4:1.") { interchange(missing_unt) }
  end

  def test_detects_malformed_message
    malformed = <<~EDIFACT
      UNB+UNOC:3+S+R+240101:1200+42
      UNT+2+7   # UNT + UNH are in wrong order
      UNH+7+Z:Y:X:W
      UNZ+1+42
    EDIFACT

    assert_raises_msg(Edifact::ParseError, "Expected UNH segment, got UNT") { interchange(malformed) }
  end

  def test_detects_segments_after_interchange_end
    missing_unz = <<~EDIFACT
      UNB+UNOC:3+S+R+240101:1200+42
      UNH+7+Z:Y:X:W
      UNT+2+7
      UNZ+1+42
      ABC+Hello
    EDIFACT

    assert_raises_msg(Edifact::ParseError, "Expected end of interchange, but got ABC") { interchange(missing_unz) }
  end

  def test_validates_interchange_control_references
    input = <<~EDIFACT
      UNB+UNOC:3+Sender:14+Receiver:14+240101:1200+42
      UNH+7+INVOIC:D:97B:UN:1.0
      ABC+Hello
      DEF+World
      UNT+4+7
      UNZ+1+43
    EDIFACT

    assert_raises_msg(Edifact::ParseError, "Interchange control references do not match: UNB:42 != UNZ:43") { interchange(input) }
  end

  def test_validates_message_control_numbers
    input = <<~EDIFACT
      UNB+UNOC:3+Sender:14+Receiver:14+240101:1200+42
      UNH+7+INVOIC:D:97B:UN:1.0
      ABC+Hello
      DEF+World
      UNT+4+8
      UNZ+1+42
    EDIFACT

    assert_raises_msg(Edifact::ParseError, "Message control numbers do not match: UNH:7 != UNT:8") { interchange(input) }
  end

  def test_validates_message_segment_counts
    input = <<~EDIFACT
      UNB+UNOC:3+Sender:14+Receiver:14+240101:1200+42
      UNH+7+INVOIC:D:97B:UN:1.0
      ABC+Hello
      DEF+World
      UNT+5+7
      UNZ+1+42
    EDIFACT

    assert_raises_msg(Edifact::ParseError, "Segment count does not match: UNT:5 != Actual:4") { interchange(input) }
  end

  private

  def interchange(input)
    input = input.gsub(/\s*\#.*$/, '') # remove comments
    input = "UNA:+.? \n" + input
    segments = Edifact::SegmentStream.new(Edifact::TokenStream.new(StringIO.new(input)))
    Edifact::Interchange.new(segments)
  end
end
