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

    # Represents a POC in Whois-RWS
    class WhoisPoc < ARINr::Whois::WhoisXmlObject

      # Returns a multiline string for long output
      def to_log( logger )
        logger.start_data_item

        # Full name
        logger.terse( "Full Name", full_name )

        # POC Handle
        logger.terse( "POC Handle", handle.to_s() )

        # POC Reference
        logger.extra( "POC Reference", ref.to_s )

        # Company Name
        logger.datum( "Company Name", companyName.to_str() ) if companyName != nil

        log_mailing_address( logger )

        # Email
        emails.email.to_ary.each { |email_addr|
          logger.datum( "Email", email_addr.to_s )
        } if emails != nil

        # Phones
        phones.phone.to_ary.each { |ph|
          phone_label = ph.e_type.description.to_s << " Phone"
          logger.extra( phone_label, ph.number.to_s )
        } if phones != nil

        log_dates( logger )

        log_comments( logger )

        logger.end_data_item
      end

      def full_name
        s = ""
        if (firstName != nil)
          s << firstName.to_s << " "
        end
        if (middleName != nil)
          s << middleName.to_s << " "
        end
        s << lastName.to_s if lastName != nil
        s.strip!
        return s
      end

      def to_s
        s = handle.to_s << " ( " << full_name << " )"
        return s
      end

    end

  end

end

