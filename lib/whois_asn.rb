# Copyright (C) 2011,2012 American Registry for Internet Numbers

require 'whois_xml_object'
require 'arinr_logger'

module ARINr

  module Whois

    # Represents a AS block registration in Whois-RWS
    class WhoisAsn < ARINr::Whois::WhoisXmlObject

      # Returns a multiline string for long output
      def to_log( logger )
        logger.start_data_item
        logger.terse( "Autonomous System Handle", handle.to_s() )
        logger.datum( "Autonomous System Name", name.to_s() )
        logger.extra( "AS Reference", ref.to_s )
        logger.datum( "Start AS Number", startAsNumber.to_s )
        logger.datum( "End AS Number", endAsNumber.to_s )
        logger.datum( "Organization Handle", orgRef.handle )
        logger.terse( "Organization Name", orgRef.name )
        logger.extra( "Organization Reference", orgRef.to_s )
        log_dates( logger )
        log_comments( logger )
        logger.end_data_item
      end

      def to_s
        handle.to_s + " ( " + startAsNumber.to_s + " - " + endAsNumber.to_s + " )"
      end

    end

  end

end
