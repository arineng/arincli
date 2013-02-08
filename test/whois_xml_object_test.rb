# Copyright (C) 2011,2012,2013 American Registry for Internet Numbers
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


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
 <d1-1>blah</d1-1>
 <e z2-2="thing"/>
 <f>
  <type>bazz</type>
 </f>
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

    a = ARINcli::Whois::WhoisXmlObject.new( @document.root )

    assert_equal( "1", a.b.x )
    assert_equal( "Text", a.b.to_s )
    assert_equal( "2", a.b.c[0].y )
    assert_equal( "C2", a.b.c[1].to_s )
    assert_equal( 1, [ a.b ].length )
    assert_equal( 1, a.b.to_ary().length )
    assert_equal( 2, a.b.c.length )
    assert_equal( 2, a.b.c.to_ary.length )
    assert_equal( "blah", a.d1_1.to_s )
    assert_equal( "thing", a.e.z2_2 )
    assert_equal( "bazz", a.f.e_type.to_s )

  end

end
