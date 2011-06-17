# Copyright (C) 2011 American Registry for Internet Numbers

require 'rexml/document'
require 'data_tree'


module ARINr

  module Whois

    def Whois::make_asns_tree element
      retval = nil
      if element.name == "asns"
        asns = element
      else
        asns = REXML::XPath.first(element, "asns")
      end
      if (asns != nil && asns.elements[ "asnRef" ])
        retval = ARINr::DataNode.new("Autonomous Systems Blocks")
        asns.elements.each( "asnRef" ) do |asn|
          retval.add_child(ARINr::DataNode.new( asn.attribute("handle" ).to_s ) )
        end
      end
      return retval
    end

    def Whois::make_pocs_tree element
      retval = nil
      if element.name == "pocs"
        pocs = element
      else
        pocs = REXML::XPath.first(element, "pocs")
      end
      if (pocs != nil && pocs.elements[ "pocLinkRef" ])
        retval = ARINr::DataNode.new("Points of Contact")
        pocs.elements.each( "pocLinkRef" ) do |poc|
          s = format( "%s (%s)", poc.attribute( "handle" ), poc.attribute( "description" ) )
          retval.add_child(ARINr::DataNode.new(s))
        end
      end
      return retval
    end

    def Whois::make_nets_tree element
      retval = nil
      if element.name == "nets"
        nets = element
      else
        nets = REXML::XPath.first(element, "nets")
      end
      if (nets != nil && nets.elements[ "netRef" ] )
        retval = ARINr::DataNode.new("Networks")
        nets.elements.each( "netRef" ) do |net|
          s = format("%-24s ( %15s - %-15s )", net.attribute( "handle" ), net.attribute( "startAddress" ), net.attribute( "endAddress" ) )
          retval.add_child(ARINr::DataNode.new(s))
        end
      end
      return retval
    end

    def Whois::make_delegations_tree element
      retval = nil
      if element.name == "delegations"
        dels = element
      else
        dels = REXML::XPath.first(element, "ns2:delegations", "ns2"=>"http://www.arin.net/whoisrws/rdns/v1" )
      end
      if (dels != nil && dels.elements[ dels.prefix + ":delegationRef" ])
        retval = ARINr::DataNode.new("Reverse DNS Delegations")
        dels.elements.each( dels.prefix + ":delegationRef" ) do |del|
          retval.add_child(ARINr::DataNode.new( del.attribute( "name" ).to_s ) )
        end
      end
      return retval
    end

  end

end
