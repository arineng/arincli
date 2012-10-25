# Copyright (C) 2011,2012 American Registry for Internet Numbers
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
require 'rexml/document'
require 'whois_net'
require 'arinr_logger'
require 'stringio'

# Test the XML parsing of the WhoisNet class
class WhoisNetTest < Test::Unit::TestCase

  def setup
    net_xml = <<NET_XML
<net xmlns="http://www.arin.net/whoisrws/core/v1" xmlns:ns2="http://www.arin.net/whoisrws/rdns/v1" termsOfUse="https://www.arin.net/whois_tou.html">
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
        Comment (line  0):  This IP address range is not registered in the ARIN database.
        Comment (line  1):  For details, refer to the APNIC Whois Database via
        Comment (line  2):  WHOIS.APNIC.NET or http://wq.apnic.net/apnic-bin/whois.pl
        Comment (line  3):  ** IMPORTANT NOTE: APNIC is the Regional Internet Registry
        Comment (line  4):  for the Asia Pacific region. APNIC does not operate networks
        Comment (line  5):  using this IP address range and is not able to investigate
        Comment (line  6):  spam or abuse reports relating to these addresses. For more
        Comment (line  7):  help, refer to http://www.apnic.net/apnic-info/whois_search2/abuse-and-spamming
EXPECTED_LOG

    assert_equal( expected, logger.data_out.string )

  end

  def test_to_s
    net = ARINr::Whois::WhoisNet.new( @net_element )
    assert_equal( "NET-192-136-136-0-1 ( 192.136.136.0 - 192.136.136.255 )", net.to_s )
  end

end
