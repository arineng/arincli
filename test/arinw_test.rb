# Copyright (C) 2011 American Registry for Internet Numbers

require 'tmpdir'
require 'fileutils'
require 'config'
require 'test/unit'
require 'arinw'
require 'arinr_logger'

class ArinwTest < Test::Unit::TestCase

  @work_dir = nil

  def setup

    @work_dir = Dir.mktmpdir

  end

  def teardown

    FileUtils.rm_r( @work_dir )

  end

  def test_guess_query

    dir = File.join( @work_dir, "test_guess_query" )

    logger = ARINr::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = ARINr::MessageLevel::NO_MESSAGES
    config = ARINr::Config.new( dir )
    config.logger=logger

    arinw = ARINr::Whois::Main.new( [], config )

    assert_equal( arinw.guess_query_value_type( [ "NET-192-136-136-1" ] ), "NETHANDLE" )
    assert_equal( arinw.guess_query_value_type( [ "NET6-2001-500-13-1" ] ), "NETHANDLE" )
    assert_equal( arinw.guess_query_value_type( [ "ALN-ARIN" ] ), "POCHANDLE" )
    assert_equal( arinw.guess_query_value_type( [ "1.0.0.0" ] ), "IP4ADDR" )
    assert_equal( arinw.guess_query_value_type( [ "199.0.0.0" ] ), "IP4ADDR" )
    assert_equal( arinw.guess_query_value_type( [ "255.255.255.255" ] ), "IP4ADDR" )
    assert_nil( arinw.guess_query_value_type( [ "255.255.255.256" ] ) )
    assert_nil( arinw.guess_query_value_type( [ "256.255.255.255" ] ) )
    assert_equal( arinw.guess_query_value_type( [ "2001:500:13::" ] ), "IP6ADDR" )
    assert_equal( arinw.guess_query_value_type( [ "2001:500:13:FFFF:FFFF:FFFF:FFFF:FFFF" ] ), "IP6ADDR" )
    assert_equal( arinw.guess_query_value_type( [ "10745" ] ), "ASNUMBER" )
    assert_equal( arinw.guess_query_value_type( [ "11110745" ] ), "ASNUMBER" )
    assert_equal( arinw.guess_query_value_type( [ "AS10745" ] ), "ASNUMBER" )
    assert_equal( arinw.guess_query_value_type( [ "AS11110745" ] ), "ASNUMBER" )
    assert_equal( arinw.guess_query_value_type( [ "199.in-addr.arpa" ] ), "DELEGATION" )
    assert_equal( arinw.guess_query_value_type( [ "199.in-addr.arpa." ] ), "DELEGATION" )
    assert_equal( arinw.guess_query_value_type( [ "136.199.in-addr.arpa" ] ), "DELEGATION" )
    assert_equal( arinw.guess_query_value_type( [ "136.199.in-addr.arpa." ] ), "DELEGATION" )
    assert_equal( arinw.guess_query_value_type( [ "8.f.4.0.1.0.0.2.ip6.arpa" ] ), "DELEGATION" )
    assert_equal( arinw.guess_query_value_type( [ "8.f.4.0.1.0.0.2.ip6.arpa." ] ), "DELEGATION" )

  end

  def test_create_query

    dir = File.join( @work_dir, "test_create_query" )

    logger = ARINr::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = ARINr::MessageLevel::NO_MESSAGES
    config = ARINr::Config.new( dir )
    config.logger=logger

    arinw = ARINr::Whois::Main.new( [], config )

    assert_equal( "rest/net/NET-192-136-136-1",
                  arinw.create_resource_url(
                      [ "NET-192-136-136-1" ], ARINr::Whois::QueryType::BY_NET_HANDLE ) )
    assert_equal( "rest/net/NET6-2001-500-13-1",
                  arinw.create_resource_url(
                      [ "NET6-2001-500-13-1" ], ARINr::Whois::QueryType::BY_NET_HANDLE ) )
    assert_equal( "rest/poc/ALN-ARIN",
                  arinw.create_resource_url(
                      [ "ALN-ARIN" ], ARINr::Whois::QueryType::BY_POC_HANDLE ) )
    assert_equal( "rest/ip/1.0.0.0",
                  arinw.create_resource_url(
                      [ "1.0.0.0" ], ARINr::Whois::QueryType::BY_IP4_ADDR ) )
    assert_equal( "rest/ip/2001:500:13::",
                  arinw.create_resource_url(
                      [ "2001:500:13::" ], ARINr::Whois::QueryType::BY_IP6_ADDR ) )
    assert_equal( "rest/rdns/8.f.4.0.1.0.0.2.ip6.arpa",
                  arinw.create_resource_url(
                      [ "8.f.4.0.1.0.0.2.ip6.arpa" ], ARINr::Whois::QueryType::BY_DELEGATION ) )
    assert_equal( "rest/rdns/199.in-addr.arpa",
                  arinw.create_resource_url(
                      [ "199.in-addr.arpa" ], ARINr::Whois::QueryType::BY_DELEGATION ) )
  end

  def test_mod_url

    dir = File.join( @work_dir, "test_mod_url" )

    logger = ARINr::Logger.new
    logger.message_out = StringIO.new
    logger.message_level = ARINr::MessageLevel::NO_MESSAGES
    config = ARINr::Config.new( dir )
    config.logger=logger

    arinw = ARINr::Whois::Main.new( [], config )

    assert_raise( ArgumentError ) do
      arinw.mod_url( "/rest/ip/199.136.136.1", ARINr::Whois::RelatedType::DELS, false, false)
    end
    p = arinw.mod_url( "/rest/ip/199.136.136.1", nil, true, false)
    assert_equal( "/rest/ip/199.136.136.1/pft", p )
    p = arinw.mod_url( "/rest/ip/199.136.136.1", nil, false, true)
    assert_equal( "/rest/ip/199.136.136.1?showDetails=true", p )
    p = arinw.mod_url( "/rest/ip/199.136.136.1", nil, true, true)
    assert_equal( "/rest/ip/199.136.136.1/pft?showDetails=true", p )

    p = arinw.mod_url( "/rest/net/NET-192-136-136-1", ARINr::Whois::RelatedType::DELS, false, false)
    assert_equal( "/rest/net/NET-192-136-136-1/rdns", p )
    assert_raise( ArgumentError ) do
      arinw.mod_url( "/rest/net/NET-192-136-136-1", ARINr::Whois::RelatedType::NETS, false, false)
    end
    p = arinw.mod_url( "/rest/net/NET-192-136-136-1", nil, true, false)
    assert_equal( "/rest/net/NET-192-136-136-1/pft", p )
    p = arinw.mod_url( "/rest/net/NET-192-136-136-1", nil, false, true)
    assert_equal( "/rest/net/NET-192-136-136-1?showDetails=true", p )
    p = arinw.mod_url( "/rest/net/NET-192-136-136-1", nil, true, true)
    assert_equal( "/rest/net/NET-192-136-136-1/pft?showDetails=true", p )

    p = arinw.mod_url( "/rest/rdns/192.in-addr.arpa", ARINr::Whois::RelatedType::NETS, false, false )
    assert_equal( "/rest/rdns/192.in-addr.arpa/nets", p )
    assert_raise( ArgumentError ) do
      arinw.mod_url( "/rest/rdns/192.in-addr.arpa", ARINr::Whois::RelatedType::ORGS, false, false )
    end
    p = arinw.mod_url( "/rest/rdns/192.in-addr.arpa", nil, true, false )
    assert_equal( "/rest/rdns/192.in-addr.arpa", p )
    p = arinw.mod_url( "/rest/rdns/192.in-addr.arpa", nil, false, true )
    assert_equal( "/rest/rdns/192.in-addr.arpa", p )
    p = arinw.mod_url( "/rest/rdns/192.in-addr.arpa", nil, true, true )
    assert_equal( "/rest/rdns/192.in-addr.arpa", p )

    assert_raise( ArgumentError ) do
      arinw.mod_url( "/rest/asn/192.in-addr.arpa", ARINr::Whois::RelatedType::ORGS, false, false )
    end
    p = arinw.mod_url( "/rest/asn/703", nil, false, false )
    assert_equal( "/rest/asn/703", p )
    p = arinw.mod_url( "/rest/asn/703", nil, true, false )
    assert_equal( "/rest/asn/703", p )
    p = arinw.mod_url( "/rest/asn/703", nil, true, true )
    assert_equal( "/rest/asn/703?showDetails=true", p )
    p = arinw.mod_url( "/rest/asn/703", nil, false, true )
    assert_equal( "/rest/asn/703?showDetails=true", p )

    p = arinw.mod_url( "/rest/org/ARIN", ARINr::Whois::RelatedType::POCS, false, false )
    assert_equal( "/rest/org/ARIN/pocs", p )
    p = arinw.mod_url( "/rest/org/ARIN", ARINr::Whois::RelatedType::NETS, false, false )
    assert_equal( "/rest/org/ARIN/nets", p )
    p = arinw.mod_url( "/rest/org/ARIN", ARINr::Whois::RelatedType::ASNS, false, false )
    assert_equal( "/rest/org/ARIN/asns", p )
    assert_raise( ArgumentError ) do
      arinw.mod_url( "/rest/org/ARIN", ARINr::Whois::RelatedType::DELS, false, false )
    end
    p = arinw.mod_url( "/rest/org/ARIN", ARINr::Whois::RelatedType::ASNS, true, false )
    assert_equal( "/rest/org/ARIN/asns", p )
    p = arinw.mod_url( "/rest/org/ARIN", ARINr::Whois::RelatedType::ASNS, false, true )
    assert_equal( "/rest/org/ARIN/asns?showDetails=true", p )
    p = arinw.mod_url( "/rest/org/ARIN", ARINr::Whois::RelatedType::ASNS, true, true )
    assert_equal( "/rest/org/ARIN/asns?showDetails=true", p )
    p = arinw.mod_url( "/rest/org/ARIN", ARINr::Whois::RelatedType::NETS, true, false )
    assert_equal( "/rest/org/ARIN/nets", p )
    p = arinw.mod_url( "/rest/org/ARIN", ARINr::Whois::RelatedType::NETS, false, true )
    assert_equal( "/rest/org/ARIN/nets?showDetails=true", p )
    p = arinw.mod_url( "/rest/org/ARIN", ARINr::Whois::RelatedType::NETS, true, true )
    assert_equal( "/rest/org/ARIN/nets?showDetails=true", p )
    p = arinw.mod_url( "/rest/org/ARIN", ARINr::Whois::RelatedType::POCS, true, false )
    assert_equal( "/rest/org/ARIN/pocs", p )
    p = arinw.mod_url( "/rest/org/ARIN", ARINr::Whois::RelatedType::POCS, false, true )
    assert_equal( "/rest/org/ARIN/pocs?showDetails=true", p )
    p = arinw.mod_url( "/rest/org/ARIN", ARINr::Whois::RelatedType::POCS, true, true )
    assert_equal( "/rest/org/ARIN/pocs?showDetails=true", p )
    p = arinw.mod_url( "/rest/org/ARIN", nil, true, false )
    assert_equal( "/rest/org/ARIN/pft", p )
    p = arinw.mod_url( "/rest/org/ARIN", nil, false, true )
    assert_equal( "/rest/org/ARIN?showDetails=true", p )
    p = arinw.mod_url( "/rest/org/ARIN", nil, true, true )
    assert_equal( "/rest/org/ARIN/pft?showDetails=true", p )

    p = arinw.mod_url( "/rest/poc/ARIN", ARINr::Whois::RelatedType::ORGS, false, false )
    assert_equal( "/rest/poc/ARIN/orgs", p )
    p = arinw.mod_url( "/rest/poc/ARIN", ARINr::Whois::RelatedType::NETS, false, false )
    assert_equal( "/rest/poc/ARIN/nets", p )
    p = arinw.mod_url( "/rest/poc/ARIN", ARINr::Whois::RelatedType::ASNS, false, false )
    assert_equal( "/rest/poc/ARIN/asns", p )
    assert_raise( ArgumentError ) do
      arinw.mod_url( "/rest/poc/ARIN", ARINr::Whois::RelatedType::DELS, false, false )
    end
    p = arinw.mod_url( "/rest/poc/ARIN", ARINr::Whois::RelatedType::ASNS, true, false )
    assert_equal( "/rest/poc/ARIN/asns", p )
    p = arinw.mod_url( "/rest/poc/ARIN", ARINr::Whois::RelatedType::ASNS, false, true )
    assert_equal( "/rest/poc/ARIN/asns?showDetails=true", p )
    p = arinw.mod_url( "/rest/poc/ARIN", ARINr::Whois::RelatedType::ASNS, true, true )
    assert_equal( "/rest/poc/ARIN/asns?showDetails=true", p )
    p = arinw.mod_url( "/rest/poc/ARIN", ARINr::Whois::RelatedType::NETS, true, false )
    assert_equal( "/rest/poc/ARIN/nets", p )
    p = arinw.mod_url( "/rest/poc/ARIN", ARINr::Whois::RelatedType::NETS, false, true )
    assert_equal( "/rest/poc/ARIN/nets?showDetails=true", p )
    p = arinw.mod_url( "/rest/poc/ARIN", ARINr::Whois::RelatedType::NETS, true, true )
    assert_equal( "/rest/poc/ARIN/nets?showDetails=true", p )
    p = arinw.mod_url( "/rest/poc/ARIN", ARINr::Whois::RelatedType::ORGS, true, false )
    assert_equal( "/rest/poc/ARIN/orgs", p )
    p = arinw.mod_url( "/rest/poc/ARIN", ARINr::Whois::RelatedType::ORGS, false, true )
    assert_equal( "/rest/poc/ARIN/orgs?showDetails=true", p )
    p = arinw.mod_url( "/rest/poc/ARIN", ARINr::Whois::RelatedType::ORGS, true, true )
    assert_equal( "/rest/poc/ARIN/orgs?showDetails=true", p )
    p = arinw.mod_url( "/rest/poc/ARIN", nil, true, false )
    assert_equal( "/rest/poc/ARIN/pft", p )
    p = arinw.mod_url( "/rest/poc/ARIN", nil, false, true )
    assert_equal( "/rest/poc/ARIN?showDetails=true", p )
    p = arinw.mod_url( "/rest/poc/ARIN", nil, true, true )
    assert_equal( "/rest/poc/ARIN/pft?showDetails=true", p )
  end

end
