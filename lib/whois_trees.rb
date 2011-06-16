# Copyright (C) 2011 American Registry for Internet Numbers

require 'rexml/document'
require 'data_tree'


module ARINr

  module Whois

    def Whois::make_asns_tree element
      retval = nil
      asns = REXML::XPath.first(element, "asns")
      if (asns != nil && asns.has_elements?)
        retval = ARINr::DataNode.new("Autonomous Systems Blocks")
        asn_num = 1
        asns.elements.each( "asnRef" ) do |asn|
          s = format("%3d. %s", asn_num, asn.attribute("handle"))
          retval.add_child(ARINr::DataNode.new(s))
          asn_num += 1
        end
      end
      return retval
    end

    def Whois::make_pocs_tree element
      retval = nil
      pocs = REXML::XPath.first(element, "pocs")
      if (pocs != nil && pocs.has_elements?)
        retval = ARINr::DataNode.new("Points of Contact")
        poc_num = 1
        pocs.elements.each( "pocLinkRef" ) do |poc|
          s = format("%2d. %s (%s)", poc_num, poc.attribute( "handle" ), poc.attribute( "description" ) )
          retval.add_child(ARINr::DataNode.new(s))
          poc_num += 1
        end
      end
      return retval
    end

    def Whois::make_nets_tree element
      retval = nil
      nets = REXML::XPath.first(element, "nets")
      if (nets != nil && nets.has_elements?)
        retval = ARINr::DataNode.new("Networks")
        net_num = 1
        nets.elements.each( "netRef" ) do |net|
          s = format("%3d. %-24s ( %15s - %-15s )", net_num, net.attribute( "handle" ), net.attribute( "startAddress" ), net.attribute( "endAddress" ) )
          retval.add_child(ARINr::DataNode.new(s))
          net_num += 1
        end
      end
      return retval
    end

    def Whois::make_delegations_tree element
      retval = nil
      dels = REXML::XPath.first(element, "ns2:delegations", "ns2"=>"http://www.arin.net/whoisrws/rdns/v1" )
      if (dels != nil && dels.has_elements?)
        retval = ARINr::DataNode.new("Reverse DNS Delegations")
        del_num = 1
        dels.elements.each( dels.prefix + ":delegationRef" ) do |del|
          s = format("%3d. %s", del_num, del.attribute( "name" ) )
          retval.add_child(ARINr::DataNode.new(s))
          del_num += 1
        end
      end
      return retval
    end

  end

end
