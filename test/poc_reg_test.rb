# Copyright (C) 2011 American Registry for Internet Numbers

require 'test/unit'
require 'poc_reg'

class PocRegTest < Test::Unit::TestCase

  def test_poc_template

    poc = ARINr::Registration::Poc.new
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

    template = ARINr::Registration::poc_to_template( poc )

    poc2 = ARINr::Registration::yaml_to_poc( template )

    template2 = ARINr::Registration::poc_to_template( poc2 )

    assert_equal( template, template2 )

  end

end
