# Copyright (C) 2011,2012 American Registry for Internet Numbers

require 'whois_xml_object'
require 'arinr_logger'

module ARINr

  module Whois

    # Represents a Network in Whois-RWS
    class WhoisNet < ARINr::Whois::WhoisXmlObject

      # Returns a multiline string for long output
      def to_log( logger )
        logger.start_data_item
        logger.terse( "IP Address Range", startAddress.to_s() + " - " + endAddress.to_s() )
        logger.terse( "Network Handle", handle.to_s() )
        logger.datum( "Network Name", name.to_s() )
        logger.extra( "Network Version", version.to_s )
        logger.extra( "Network Reference", ref.to_s )
        netBlocks.netBlock.to_ary.each { |netblock|
          s = format( "%s/%s ( %s - %s )", netblock.startAddress.to_s, netblock.cidrLength.to_s,
            netblock.startAddress.to_s, netblock.endAddress.to_s )
          logger.extra( "CIDR", s )
        } if netBlocks != nil
        logger.datum( "Network Type", netBlocks.netBlock.to_ary[0].description.to_s )
        originASes.originAS.to_ary.each { |oas|
          logger.datum( "Origin AS", oas.to_s )
        } if originASes != nil
        logger.datum( "Parent Network Handle", parentNetRef.handle ) if parentNetRef != nil
        logger.extra( "Parent Network Name", parentNetRef.name ) if parentNetRef != nil
        logger.extra( "Parent Network Reference", parentNetRef.to_s ) if parentNetRef != nil
        logger.datum( "Organization Handle", orgRef.handle ) if orgRef
        logger.terse( "Organization Name", orgRef.name ) if orgRef
        logger.extra( "Organization Reference", orgRef.to_s ) if orgRef
        logger.datum( "Customer Handle", customerRef.handle ) if customerRef
        logger.terse( "Customer Name", customerRef.name ) if customerRef
        logger.extra( "Customer Reference", customerRef.to_s ) if customerRef
        log_dates( logger )
        log_comments( logger )
        logger.end_data_item
      end

      def to_s
        handle.to_s + " ( " + startAddress.to_s + " - " + endAddress.to_s + " )"
      end

    end

  end

end
