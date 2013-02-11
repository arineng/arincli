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
require 'rdns_reg'
require 'rexml/document'

class RdnsRegTest < Test::Unit::TestCase

  def setup
    @rdns_xml = <<RDNS_XML
<delegation xmlns="http://www.arin.net/regrws/core/v1" >
     <name>0.76.in-addr.arpa.</name>
     <delegationKeys>
          <delegationKey>
                    <algorithm name = "RSA/SHA-1">5</algorithm>
                    <digest>0DC99D4B6549F83385214189CA48DC6B209ABB71</digest>
                    <digestType name = "SHA-1">1</digestType>
                    <keyTag>264</keyTag>
          </delegationKey>
     </delegationKeys>
     <nameservers>
          <nameserver>NS1.DOMAIN.COM</nameserver>
          <nameserver>NS2.DOMAIN.COM</nameserver>
     </nameservers>
</delegation>
RDNS_XML
  end

  def test_rdns_xml
    element = REXML::Document.new( @rdns_xml ).root
    rdns = ARINcli::Registration::element_to_rdns( element )
    element2 = ARINcli::Registration::rdns_to_element( rdns )
    rdns2 = ARINcli::Registration::element_to_rdns( element2 )
    assert_equal( rdns, rdns2 )
  end

  def test_zones_template
    element = REXML::Document.new( @rdns_xml ).root
    rdns = ARINcli::Registration::element_to_rdns( element )
    rdns2 = ARINcli::Registration::element_to_rdns( element )
    assert_equal( rdns, rdns2 )
    zones = ARINcli::Registration::Zones.new
    zones << rdns << rdns2
    template = ARINcli::Registration::zones_to_template( zones )
    zones2 = ARINcli::Registration::yaml_to_zones( template )
    assert_equal( zones.size, zones2.size )
    assert_equal( zones[ 0 ].name, zones2[ 0 ].name)
    assert_equal( zones[ 0 ].name_servers, zones2[ 0 ].name_servers)
    assert_equal( zones[ 0 ].signers, zones2[ 0 ].signers)
    assert_equal( zones[ 1 ], zones2[ 1 ])
  end

  def test_zones_template_single
    element = REXML::Document.new( @rdns_xml ).root
    rdns = ARINcli::Registration::element_to_rdns( element )
    rdns2 = ARINcli::Registration::element_to_rdns( element )
    assert_equal( rdns, rdns2 )
    template = ARINcli::Registration::zones_to_template( rdns )
    zones = ARINcli::Registration::yaml_to_zones( template )
    assert_equal( zones.size, 1 )
    assert_equal( zones[ 0 ], rdns2 )
  end

  def test_find_rdns
    element = REXML::Document.new( @rdns_xml ).root
    rdns1 = ARINcli::Registration::element_to_rdns( element )
    rdns2 = ARINcli::Registration::element_to_rdns( element )
    rdns2.name="1.0.76.in-addr.arpa"
    zones = ARINcli::Registration::Zones.new
    zones << rdns1
    zones << rdns2
    assert_equal( rdns1, zones.find_rdns( "0.76.in-addr.arpa." ) )
    assert_equal( rdns1, zones.find_rdns( "0.76.in-addr.arpa" ) )
    assert_equal( rdns2, zones.find_rdns( "1.0.76.in-addr.arpa" ) )
    assert_equal( rdns2, zones.find_rdns( "1.0.76.in-addr.arpa." ) )
  end

  def test_example_com
    zones = ARINcli::Registration::Zones.new
    file = File.new( File.join( File.dirname( __FILE__ ) , "example.com.signed" ), "r" )
    zf = Zonefile.new( file.read )
    zf.ns.each do |ns|
      zones.add_ns ns
    end
    file = File.new( File.join( File.dirname( __FILE__ ) , "dsset-example.com." ), "r" )
    zf = Zonefile.new( file.read )
    zf.ds.each do |ds|
      zones.add_ds ds
    end
    assert_equal( 1, zones.size )
    assert_equal( "example.com.", zones[0].name )
    assert_equal( 1, zones[0].name_servers.size )
    assert_equal( "ns1.example.com.", zones[0].name_servers[ 0 ] )
    assert_equal( 2, zones[0].signers.size )
    assert_equal( 31528, zones[0].signers[0].key_tag )
    assert_equal( 5, zones[0].signers[0].algorithm )
    assert_equal( 1, zones[0].signers[0].digest_type )
    assert_equal( "2274EACD70C5CD6862E1C0262E99D48D9FDEC271", zones[0].signers[0].digest )
    assert_equal( 31528, zones[0].signers[1].key_tag )
    assert_equal( 5, zones[0].signers[1].algorithm )
    assert_equal( 2, zones[0].signers[1].digest_type )
    assert_equal( "BF4CE575DA72A81263B09AD81826D013B91A4BC1925722FD22FF174500C6B351", zones[0].signers[1].digest )
  end

  def test_154_in_addr
    zones = ARINcli::Registration::Zones.new
    file = File.new( File.join( File.dirname( __FILE__ ) , "154.in-addr.arpa" ), "r" )
    zf = Zonefile.new( file.read )
    zf.ns.each do |ns|
      zones.add_ns ns
    end
    assert_equal( 65, zones.size )
  end

end
