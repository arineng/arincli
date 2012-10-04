# Copyright (C) 2011,2012 American Registry for Internet Numbers

require 'whois_xml_object'
require 'arinr_logger'

module ARINr

  module Whois

    # Represents a Org in Whois-RWS
    class WhoisOrg < ARINr::Whois::WhoisXmlObject

      # Returns a multiline string for long output
      def to_log( logger )
        logger.start_data_item

        # Name
        logger.terse( "Organization Name", name.to_str )

        # POC Handle
        logger.terse( "Organization Handle", handle.to_str )

        # POC Reference
        logger.extra( "Organization Reference", ref.to_str )

        log_mailing_address( logger )

        log_dates( logger )

        log_comments( logger )

        logger.end_data_item
      end

      def to_s
        s = handle.to_s << " ( " << name.to_str << " )"
        return s
      end

    end

  end

end
