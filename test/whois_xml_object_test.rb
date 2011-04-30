# Copyright (C) 2011 American Registry for Internet Numbers
# $Id$

require "test/unit"
require "rexml/document"
require "whois_xml_object"

class WhoisXmlObjectTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    test_xml = <<TEXT_XML
<a>
 <b x="1">
   <c y="2">C1</c>
   <c>C2</c>
   Text
 </b>
</a>
TEXT_XML
    @document = REXML::Document.new( test_xml )
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_xmlobject

    a = ARINr::Whois::WhoisXmlObject.new( @document.root )

    assert_equal( "1", a.b.x )
    assert_equal( "Text", a.b.to_s )
    assert_equal( "2", a.b.c[0].y )
    assert_equal( "C2", a.b.c[1].to_s )

  end

end