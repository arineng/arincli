# Copyright (C) 2011 American Registry for Internet Numbers
# $Id$

require 'test/unit'
require 'rexml/document'
require 'whois_net'

# Test the XML parsing of the WhoisNet class
class WhoisNetText < Test::Unit::TestCase

  def setup
    net_xml = <<NET_XML
<net xmlns="http://www.arin.net/whoisrws/core/v1" xmlns:ns2="http://www.arin.net/whoisrws/rdns/v1" termsOfUse="https://www.arin.net/whois_tou.html">
  <registrationDate>2002-04-17T00:00:00-04:00</registrationDate>
  <ref>http://whois.arin.net/rest/net/NET-192-136-136-0-1</ref>
  <endAddress>192.136.136.255</endAddress>
  <handle>NET-192-136-136-0-1</handle>
  <name>ARIN-BLK-2</name>
  <netBlocks>
    <netBlock>
      <cidrLength>24</cidrLength>
      <endAddress>192.136.136.255</endAddress>
      <description>Direct Assignment</description>
      <type>DS</type>
      <startAddress>192.136.136.0</startAddress>
    </netBlock>
  </netBlocks>
  <originASes>
    <originAS>AS10745</originAS>
  </originASes>
  <orgRef name="American Registry for Internet Numbers" handle="ARIN">http://whois.arin.net/rest/org/ARIN</orgRef>
  <parentNetRef name="NET192" handle="NET-192-0-0-0-0">http://whois.arin.net/rest/net/NET-192-0-0-0-0</parentNetRef>
  <startAddress>192.136.136.0</startAddress>
  <updateDate>2011-03-19T00:00:00-04:00</updateDate>
  <version>4</version>
</net>
NET_XML
    @net_element = REXML::Document.new( net_xml ).root
  end

  def test_instantion
    net = ARINr::Whois::Net.new( @net_element )
  end

  def test_get_handle
    net = ARINr::Whois::Net.new( @net_element )
    assert_equal( "NET-192-136-136-0-1", net.handle.to_s )
  end

end