# Copyright (C) 2011 American Registry for Internet Numbers

require 'test/unit'
require 'arinw'

class ArinwTest < Test::Unit::TestCase

  def test_guess_query

    assert_equal( ARINr::Whois::Main.guess_query( [ "NET-192-136-136-1" ] ), "NET-HANDLE" )
    assert_equal( ARINr::Whois::Main.guess_query( [ "NET6-2001-500-13-1" ] ), "NET-HANDLE" )
    assert_equal( ARINr::Whois::Main.guess_query( [ "ALN-ARIN" ] ), "POC-HANDLE" )

  end

  def test_create_query

    assert_equal( "rest/net/NET-192-136-136-1",
                  ARINr::Whois::Main.create_query(
                      [ "NET-192-136-136-1" ], ARINr::Whois::QueryType::BY_NET_HANDLE ) )
    assert_equal( "rest/net/NET6-2001-500-13-1",
                  ARINr::Whois::Main.create_query(
                      [ "NET6-2001-500-13-1" ], ARINr::Whois::QueryType::BY_NET_HANDLE ) )
    assert_equal( "rest/poc/ALN-ARIN",
                  ARINr::Whois::Main.create_query(
                      [ "ALN-ARIN" ], ARINr::Whois::QueryType::BY_POC_HANDLE ) )

  end

end
