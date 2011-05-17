# Copyright (C) 2011 American Registry for Internet Numbers

require 'rexml/document'
require 'whois_xml_object'
require 'time'
require 'arinr_logger'

module ARINr

  module Whois

    # Represents a Network in Whois-RWS
    class Net < ARINr::Whois::WhoisXmlObject

      # Returns a multiline string for long output
      def to_log( logger )
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
        logger.datum( "Parent Network Handle", parentNetRef.handle )
        logger.extra( "Parent Network Name", parentNetRef.name )
        logger.extra( "Parent Network Reference", parentNetRef.to_s )
        logger.datum( "Organization Handle", orgRef.handle )
        logger.terse( "Organization Name", orgRef.name )
        logger.extra( "Organization Reference", orgRef.to_s )
        logger.datum( "Registration Date", Time.parse( registrationDate.to_s ).rfc2822 )
        logger.datum( "Last Update Date", Time.parse( updateDate.to_s ).rfc2822 )
        comment.line.to_ary.each { |comment_line|
          s = format( "%2d  %s", comment_line.number, comment_line.to_s )
          logger.datum( "Comment", s )
        } if comment != nil
      end

      def to_s
        handle.to_s + " ( " + startAddress.to_s + " - " + endAddress.to_s + " )"
      end

    end

  end

end
