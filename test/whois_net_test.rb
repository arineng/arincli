# Copyright (C) 2011 American Registry for Internet Numbers
# $Id$

require 'test/unit'
require 'rexml/document'
require 'whois_net'
require 'arinr_logger'
require 'stringio'

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
    <originAS>AS107450</originAS>
  </originASes>
  <orgRef name="American Registry for Internet Numbers" handle="ARIN">http://whois.arin.net/rest/org/ARIN</orgRef>
  <comment>
    <line number="0">This IP address range is not registered in the ARIN database.</line>
    <line number="1">For details, refer to the APNIC Whois Database via</line>
    <line number="2">WHOIS.APNIC.NET or http://wq.apnic.net/apnic-bin/whois.pl</line>
    <line number="3">** IMPORTANT NOTE: APNIC is the Regional Internet Registry</line>
    <line number="4">for the Asia Pacific region. APNIC does not operate networks</line>
    <line number="5">using this IP address range and is not able to investigate</line>
    <line number="6">spam or abuse reports relating to these addresses. For more</line>
    <line number="7">help, refer to http://www.apnic.net/apnic-info/whois_search2/abuse-and-spamming</line>
  </comment>
  <parentNetRef name="NET192" handle="NET-192-0-0-0-0">http://whois.arin.net/rest/net/NET-192-0-0-0-0</parentNetRef>
  <startAddress>192.136.136.0</startAddress>
  <updateDate>2011-03-19T00:00:00-04:00</updateDate>
  <version>4</version>
</net>
NET_XML
    @net_element = REXML::Document.new( net_xml ).root
  end

  def test_instantion
    net = ARINr::Whois::WhoisNet.new( @net_element )
  end

  def test_get_handle
    net = ARINr::Whois::WhoisNet.new( @net_element )
    assert_equal( "NET-192-136-136-0-1", net.handle.to_s )
  end

  def test_no_element
    net = ARINr::Whois::WhoisNet.new( @net_element )
    assert_nil( net.noElement )
  end

  def test_to_log
    net = ARINr::Whois::WhoisNet.new( @net_element )
    logger = ARINr::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = ARINr::DataAmount::EXTRA_DATA
    net.to_log( logger )

    expected = <<EXPECTED_LOG
         IP Address Range:  192.136.136.0 - 192.136.136.255
           Network Handle:  NET-192-136-136-0-1
             Network Name:  ARIN-BLK-2
          Network Version:  4
        Network Reference:  http://whois.arin.net/rest/net/NET-192-136-136-0-1
                     CIDR:  192.136.136.0/24 ( 192.136.136.0 - 192.136.136.255 )
             Network Type:  Direct Assignment
                Origin AS:  AS10745
                Origin AS:  AS107450
    Parent Network Handle:  NET-192-0-0-0-0
      Parent Network Name:  NET192
 Parent Network Reference:  http://whois.arin.net/rest/net/NET-192-0-0-0-0
      Organization Handle:  ARIN
        Organization Name:  American Registry for Internet Numbers
   Organization Reference:  http://whois.arin.net/rest/org/ARIN
        Registration Date:  Wed, 17 Apr 2002 00:00:00 -0400
         Last Update Date:  Sat, 19 Mar 2011 00:00:00 -0400
                  Comment:   0  This IP address range is not registered in the ARIN database.
                  Comment:   1  For details, refer to the APNIC Whois Database via
                  Comment:   2  WHOIS.APNIC.NET or http://wq.apnic.net/apnic-bin/whois.pl
                  Comment:   3  ** IMPORTANT NOTE: APNIC is the Regional Internet Registry
                  Comment:   4  for the Asia Pacific region. APNIC does not operate networks
                  Comment:   5  using this IP address range and is not able to investigate
                  Comment:   6  spam or abuse reports relating to these addresses. For more
                  Comment:   7  help, refer to http://www.apnic.net/apnic-info/whois_search2/abuse-and-spamming
EXPECTED_LOG

    assert_equal( expected, logger.data_out.string )

  end

  def test_to_s
    net = ARINr::Whois::WhoisNet.new( @net_element )
    assert_equal( "NET-192-136-136-0-1 ( 192.136.136.0 - 192.136.136.255 )", net.to_s )
  end

end