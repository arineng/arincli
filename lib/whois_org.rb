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
