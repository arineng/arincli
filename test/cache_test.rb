# Copyright (C) 2011 American Registry for Internet Numbers

require 'tmpdir'
require 'fileutils'
require 'test/unit'
require 'config'
require 'cache'


class CacheTests < Test::Unit::TestCase

  @work_dir = nil

  def setup

    @work_dir = Dir.mktmpdir

    # the contents are important... just that it is an XML blob
    @net_xml = <<NET_XML
<net xmlns="http://www.arin.net/whoisrws/core/v1" xmlns:ns2="http://www.arin.net/whoisrws/rdns/v1" termsOfUse="https://www.arin.net/whois_tou.html">
  <registrationDate>2002-04-17T00:00:00-04:00</registrationDate>
  <ref>http://whois.arin.net/rest/net/NET-192-136-136-0-1</ref>
  <endAddress>192.136.136.255</endAddress>
  <handle>NET-192-136-136-0-1</handle>
  <name>ARIN-BLK-2</name>
  <originASes>
    <originAS>AS10745</originAS>
    <originAS>AS107450</originAS>
  </originASes>
  <orgRef name="American Registry for Internet Numbers" handle="ARIN">http://whois.arin.net/rest/org/ARIN</orgRef>
  <parentNetRef name="NET192" handle="NET-192-0-0-0-0">http://whois.arin.net/rest/net/NET-192-0-0-0-0</parentNetRef>
  <startAddress>192.136.136.0</startAddress>
  <updateDate>2011-03-19T00:00:00-04:00</updateDate>
  <version>4</version>
</net>
NET_XML

  end

  def teardown

    FileUtils.rm_r( @work_dir )

  end

  def test_make_safe

    assert_equal( ARINr::Whois::Cache.make_safe( "http://" ), "http%3A%2F%2F" )
    assert_equal( ARINr::Whois::Cache.make_safe(
                          "http://whois.arin.net/rest/nets;q=192.136.136.1?showDetails=true&showARIN=false" ),
                  "http%3A%2F%2Fwhois.arin.net%2Frest%2Fnets%3Bq%3D192.136.136.1%3FshowDetails%3Dtrue%26showARIN%3Dfalse")

  end

  def test_put

    dir = File.join( @work_dir, "test_put" )
    c = ARINr::Config.new( dir )
    c.logger.message_level = "ALL"
    c.setup_workspace

    cache = ARINr::Whois::Cache.new c
    url = "http://whois.arin.net/rest/net/NET-192-136-136-0-1"
    cache.put( url, @net_xml )

    safe = ARINr::Whois::Cache.make_safe( url )
    file_name = File.join( c.whois_cache_dir, safe )
    assert( File.exist?( file_name ) )
    f = File.open( file_name, "r" )
    data = ''
    f.each_line do |line|
      data += line
    end
    f.close
    assert_equal( @net_xml, data )

  end

end

