# Copyright (C) 2011 American Registry for Internet Numbers

require 'rexml/document'
require 'whois_xml_object'
require 'time'
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
        logger.datum( "Company Name", companyName.to_s() ) if companyName != nil

        # Street Address
        streetAddress.line.to_ary.each { |address_line|
          s = format( "%2d  %s", address_line.number, address_line.to_s.sub( /&#xD;/, '') )
          logger.extra( "Street Address", s )
        } if streetAddress != nil

        # City
        logger.extra( "City", city.to_s ) if city != nil

        # State/Province/Region
        iso3166_2_label = "Region"
        if( iso3166_1 != nil && iso3166_1.code2.to_s == "US" )
          iso3166_2_label = "State"
        elsif( iso3166_1 != nil && iso3166_1.code2.to_s == "CA" )
          iso3166_2_label = "Province"
        end
        logger.extra( iso3166_2_label, iso3166_2.to_s ) if iso3166_2 != nil

        # Country
        logger.extra( "Country", iso3166_1.name.to_s ) if iso3166_1 != nil

        # Postal Code/ Zip Code
        postal_code_label = "Postal Code"
        if( iso3166_1 != nil && iso3166_1.code2.to_s == "US" )
          postal_code_label = "Zip Code"
        end
        logger.extra( postal_code_label, postalCode.to_s ) if postalCode != nil

        # Email
        emails.email.to_ary.each { |email_addr|
          logger.datum( "Email", email_addr.to_s )
        } if emails != nil

        # Phones
        phones.phone.to_ary.each { |ph|
          phone_label = ph.e_type.description.to_s << " Phone"
          logger.extra( phone_label, ph.number.to_s )
        } if phones != nil

        # Registration Date
        logger.datum( "Registration Date", Time.parse( registrationDate.to_s ).rfc2822 ) if registrationDate != nil

        # Updated Date
        logger.datum( "Last Update Date", Time.parse( updateDate.to_s ).rfc2822 ) if updateDate != nil

        # Comments
        comment.line.to_ary.each { |comment_line|
          s = format( "%2d  %s", comment_line.number, comment_line.to_s.sub( /&#xD;/, '') )
          logger.datum( "Comment", s )
        } if comment != nil

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
