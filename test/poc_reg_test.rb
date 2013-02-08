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


require 'test/unit'
require 'poc_reg'
require 'rexml/document'

class PocRegTest < Test::Unit::TestCase

  def test_poc_template

    poc = ARINcli::Registration::Poc.new
    poc.handle="MAK21"
    poc.type="person"
    poc.last_name="Kosters"
    poc.first_name="Mark"
    poc.middle_name="Abner"
    poc.company_name="ARIN or ISOC, whichever"
    poc.street_address=[ "123 Maple Lane", "Box Last" ]
    poc.city="Chantilly"
    poc.state="VA"
    poc.country="US"
    poc.postal_code="XYZ"
    poc.phones={ "Office" => [ "703-999-9911", "x123" ], "Mobile" => [ "571-888-8888" ] }
    poc.emails=[ "mark@arin.net", "pbh@arin.net" ]
    poc.comments=[ "this isn't", "an appropriate comment" ]

    template = ARINcli::Registration::poc_to_template( poc )

    poc2 = ARINcli::Registration::yaml_to_poc( template )

    template2 = ARINcli::Registration::poc_to_template( poc2 )

    assert_equal( template, template2 )

  end

  def test_poc_xml

    xml = <<POC_XML
<poc xmlns="http://www.arin.net/regrws/core/v1" >
  <iso3166-2>VA</iso3166-2>
  <iso3166-1>
    <name>UNITED STATES</name>
    <code2>US</code2>
    <code3>USA</code3>
    <e164>1</e164>
  </iso3166-1>
  <emails>
    <email>you@example.com</email>
  </emails>
  <streetAddress>
    <line number = "1">Line 1</line>
  </streetAddress>
  <city>Chantilly</city>
  <postalCode>20151</postalCode>
  <comment>
    <line number = "1">Line 1</line>
  </comment>
  <registrationDate>Tue Jan 25 16:17:18 EST 2011</registrationDate>
  <handle>ARIN-HOSTMASTER</handle>
  <contactType>PERSON</contactType>
  <companyName>COMPANYNAME</companyName>
  <firstName>FIRSTNAME</firstName>
  <middleName>MIDDLENAME</middleName>
  <lastName>LASTNAME</lastName>
  <phones>
    <phone>
      <type>
        <description>DESCRIPTION</description>
        <code>O</code>
      </type>
      <number>+1.703.227.9840</number>
      <extension>101</extension>
    </phone>
  </phones>
</poc>
POC_XML

    element = REXML::Document.new( xml ).root

    poc = ARINcli::Registration::element_to_poc( element )

    element2 = ARINcli::Registration::poc_to_element( poc )

    poc2 = ARINcli::Registration::element_to_poc( element2 )

    assert_equal( poc, poc2 )

  end
end
