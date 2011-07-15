# Copyright (C) 2011 American Registry for Internet Numbers

require 'test/unit'
require 'rexml/document'
require 'whois_trees'

class WhoisTreeTest < Test::Unit::TestCase

  def test_make_pocs_tree_pocLinkRef

    xml = <<POCLINKREF_XML
<ns3:pft xmlns="http://www.arin.net/whoisrws/core/v1" xmlns:ns2="http://www.arin.net/whoisrws/rdns/v1" xmlns:ns3="http://www.arin.net/whoisrws/pft/v1">
  <org termsOfUse="https://www.arin.net/whois_tou.html">
    <ref>http://whois.arin.net/rest/org/ARIN</ref>
    <pocs termsOfUse="https://www.arin.net/whois_tou.html">
      <pocLinkRef handle="ARIN-HOSTMASTER" function="AD" description="Admin">http://whois.arin.net/rest/poc/ARIN-HOSTMASTER</pocLinkRef>
      <pocLinkRef handle="ARINN-ARIN" function="N" description="NOC">http://whois.arin.net/rest/poc/ARINN-ARIN</pocLinkRef>
      <pocLinkRef handle="ARIN-HOSTMASTER" function="T" description="Tech">http://whois.arin.net/rest/poc/ARIN-HOSTMASTER</pocLinkRef>
    </pocs>
  </org>
</ns3:pft>
POCLINKREF_XML

    doc = REXML::Document.new( xml )
    org = doc.root.get_elements( "/*/org" )[ 0 ]
    assert_not_nil( org )
    assert_equal( "org", org.name )

    node = ARINr::Whois::make_pocs_tree( org )
    assert_not_nil( node )
    assert_equal( 3, node.children.length )

    node = ARINr::Whois::make_pocs_tree( org.elements[ "pocs" ] )
    assert_not_nil( node )
    assert_equal( 3, node.children.length )
  end

  def test_make_pocs_tree_pocRef

    xml = <<POCREF_XML
<pocs xmlns="http://www.arin.net/whoisrws/core/v1" xmlns:ns2="http://www.arin.net/whoisrws/rdns/v1" termsOfUse="https://www.arin.net/whois_tou.html">
  <limitExceeded limit="256">false</limitExceeded>
  <pocRef name="Newton, Andrew" handle="ALN-ARIN">http://whois.arin.net/rest/poc/ALN-ARIN</pocRef>
  <pocRef name="Newton, Audry" handle="ANE22-ARIN">http://whois.arin.net/rest/poc/ANE22-ARIN</pocRef>
  <pocRef name="Newton, Benjamin" handle="BNE40-ARIN">http://whois.arin.net/rest/poc/BNE40-ARIN</pocRef>
  <pocRef name="Newton, Bernard" handle="BNE83-ARIN">http://whois.arin.net/rest/poc/BNE83-ARIN</pocRef>
  <pocRef name="Newton, Brad" handle="BN1021-ARIN">http://whois.arin.net/rest/poc/BN1021-ARIN</pocRef>
  <pocRef name="NEWTON, BRIAN" handle="BNE8-ARIN">http://whois.arin.net/rest/poc/BNE8-ARIN</pocRef>
  <pocRef name="Newton, Bruce" handle="BN228-ARIN">http://whois.arin.net/rest/poc/BN228-ARIN</pocRef>
  <pocRef name="NEWTON, CATHY" handle="CNE11-ARIN">http://whois.arin.net/rest/poc/CNE11-ARIN</pocRef>
  <pocRef name="Newton, Charlie" handle="CN23-ARIN">http://whois.arin.net/rest/poc/CN23-ARIN</pocRef>
  <pocRef name="Newton, Chris" handle="CNE35-ARIN">http://whois.arin.net/rest/poc/CNE35-ARIN</pocRef>
  <pocRef name="Newton, Chris" handle="CNE45-ARIN">http://whois.arin.net/rest/poc/CNE45-ARIN</pocRef>
  <pocRef name="Newton, Christopher" handle="CN67-ARIN">http://whois.arin.net/rest/poc/CN67-ARIN</pocRef>
  <pocRef name="Newton, David" handle="DN337-ARIN">http://whois.arin.net/rest/poc/DN337-ARIN</pocRef>
  <pocRef name="Newton, David" handle="DNE64-ARIN">http://whois.arin.net/rest/poc/DNE64-ARIN</pocRef>
  <pocRef name="Newton, Derek" handle="DNE48-ARIN">http://whois.arin.net/rest/poc/DNE48-ARIN</pocRef>
  <pocRef name="NEWTON, DEVIN" handle="DNE109-ARIN">http://whois.arin.net/rest/poc/DNE109-ARIN</pocRef>
  <pocRef name="Newton, Dick" handle="DNE82-ARIN">http://whois.arin.net/rest/poc/DNE82-ARIN</pocRef>
  <pocRef name="NEWTON, SETH" handle="SNE121-ARIN">http://whois.arin.net/rest/poc/SNE121-ARIN</pocRef>
  <pocRef name="NEWTON, STEVE" handle="SNE108-ARIN">http://whois.arin.net/rest/poc/SNE108-ARIN</pocRef>
  <pocRef name="Newton, Terry" handle="TN115-ARIN">http://whois.arin.net/rest/poc/TN115-ARIN</pocRef>
  <pocRef name="Newton, Terry" handle="TNE29-ARIN">http://whois.arin.net/rest/poc/TNE29-ARIN</pocRef>
  <pocRef name="NEWTON, TODD" handle="TNE16-ARIN">http://whois.arin.net/rest/poc/TNE16-ARIN</pocRef>
  <pocRef name="NEWTON, TONY" handle="TNE63-ARIN">http://whois.arin.net/rest/poc/TNE63-ARIN</pocRef>
  <pocRef name="Newton, Valerie" handle="VJN-ARIN">http://whois.arin.net/rest/poc/VJN-ARIN</pocRef>
  <pocRef name="Newton, William" handle="WNE7-ARIN">http://whois.arin.net/rest/poc/WNE7-ARIN</pocRef>
</pocs>
POCREF_XML

    doc = REXML::Document.new( xml )

    node = ARINr::Whois::make_pocs_tree( doc.root )
    assert_not_nil( node )
    assert_equal( 25, node.children.length )

  end

  def test_sort_asns
    arry = [ "AS0", "AS1", "AS12", "AS200", "AS21", "AS10745", "AS393220", "AS393225", "AS53535" ]
    assert_equal( [ "AS0", "AS1","AS10745", "AS12", "AS200", "AS21", "AS393220", "AS393225", "AS53535" ], arry.sort )
    assert_equal( [ "AS0", "AS1", "AS12", "AS200", "AS21", "AS10745", "AS393220", "AS393225", "AS53535" ], arry )

    new_arry = ARINr::Whois::sort_asns arry
    assert_equal( [ "AS0", "AS1", "AS12", "AS21", "AS200", "AS10745","AS53535", "AS393220", "AS393225" ], new_arry )
  end

  def test_sort_nets
    arry = [ "NET6-2001-1800-0","NET6-2001-400-0","NET6-2001-4800-0", "NET-208-0-0-0-0","NET-209-0-0-0-0","NET-216-0-0-0-0","NET-23-0-0-0-0","NET-24-0-0-0-0" ]
    new_arry = ARINr::Whois::sort_nets arry
    assert_equal( [ "NET-23-0-0-0-0","NET-24-0-0-0-0","NET-208-0-0-0-0","NET-209-0-0-0-0","NET-216-0-0-0-0","NET6-2001-400-0","NET6-2001-1800-0","NET6-2001-4800-0"], new_arry )
  end

  def test_sort_nets2
    arry = [ "NET6-2001-1800-0","NET-208-0-0-0-0", "NET6-2001-400-0","NET6-2001-4800-0", "NET-209-0-0-0-0","NET-216-0-0-0-0","NET-23-0-0-0-0","NET-24-0-0-0-0" ]
    new_arry = ARINr::Whois::sort_nets arry
    assert_equal( [ "NET-23-0-0-0-0","NET-24-0-0-0-0","NET-208-0-0-0-0","NET-209-0-0-0-0","NET-216-0-0-0-0","NET6-2001-400-0","NET6-2001-1800-0","NET6-2001-4800-0"], new_arry )
  end

  def test_sort_dels
    arry = ["189.184.in-addr.arpa.","176.184.in-addr.arpa.","181.184.in-addr.arpa.","183.184.in-addr.arpa.","185.184.in-addr.arpa.","187.184.in-addr.arpa."]
    new_arry = ARINr::Whois::sort_dels arry
    assert_equal( ["176.184.in-addr.arpa.","181.184.in-addr.arpa.","183.184.in-addr.arpa.","185.184.in-addr.arpa.","187.184.in-addr.arpa.","189.184.in-addr.arpa."], new_arry)
  end

end
