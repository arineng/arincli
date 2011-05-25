# Copyright (C) 2011 American Registry for Internet Numbers

require 'test/unit'
require 'arinw'
require 'arinr_logger'

class ArinwTest < Test::Unit::TestCase

  def test_guess_query
    logger = ARINr::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = ARINr::MessageLevel::NO_MESSAGES

    assert_equal( ARINr::Whois::Main.guess_query( [ "NET-192-136-136-1" ], logger ), "NET-HANDLE" )
    assert_equal( ARINr::Whois::Main.guess_query( [ "NET6-2001-500-13-1" ], logger ), "NET-HANDLE" )
    assert_equal( ARINr::Whois::Main.guess_query( [ "ALN-ARIN" ], logger ), "POC-HANDLE" )
    assert_equal( ARINr::Whois::Main.guess_query( [ "1.0.0.0" ], logger ), "IP4-ADDR" )
    assert_equal( ARINr::Whois::Main.guess_query( [ "199.0.0.0" ], logger ), "IP4-ADDR" )
    assert_equal( ARINr::Whois::Main.guess_query( [ "255.255.255.255" ], logger ), "IP4-ADDR" )
    assert_nil( ARINr::Whois::Main.guess_query( [ "255.255.255.256" ], logger ) )
    assert_nil( ARINr::Whois::Main.guess_query( [ "256.255.255.255" ], logger ) )
    assert_equal( ARINr::Whois::Main.guess_query( [ "2001:500:13::" ], logger ), "IP6-ADDR" )
    assert_equal( ARINr::Whois::Main.guess_query( [ "2001:500:13:FFFF:FFFF:FFFF:FFFF:FFFF" ], logger ), "IP6-ADDR" )

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
    assert_equal( "rest/ip/1.0.0.0",
                  ARINr::Whois::Main.create_query(
                      [ "1.0.0.0" ], ARINr::Whois::QueryType::BY_IP4_ADDR ) )
    assert_equal( "rest/ip/2001:500:13::",
                  ARINr::Whois::Main.create_query(
                      [ "2001:500:13::" ], ARINr::Whois::QueryType::BY_IP6_ADDR ) )
  end

end
