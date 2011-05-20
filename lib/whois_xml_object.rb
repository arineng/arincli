# Copyright (C) 2011 American Registry for Internet Numbers
# This file is public domain, and originates from Sean Russell
# in a posting at http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/99306
# for a Ruby object call XMlObject. It has been modified from its original form though.


require "rexml/document"
require 'time'

module ARINr

  module Whois

    # A quasi-serialization class.  Accepts a limited subset of XML and turns it
    # into Ruby objects.
    class WhoisXmlObject

      attr_reader :element

      def initialize element
        @element = element
        @methods = {}
      end

      def method_missing method
        m_name = method.to_s
        return @methods[m_name] if @methods[m_name]
        el = REXML::XPath.match(@element, m_name)
        el2 = REXML::XPath.match(@element, m_name.tr( "_", "-" ) )
        el3 = REXML::XPath.match(@element, m_name.sub( /^e_/, "" ) )
        if( el.size == 0 && el2.size != 0 )
          el = el2
        elsif( el.size == 0 && el3.size != 0 )
          el = el3
        end
        case el.size
          when 0
            attr = @element.attributes[ m_name ]
            if( attr == nil )
              attr = @element.attributes[ m_name.tr( "_", "-" ) ]
            end
            return attr
          when 1
            @methods[m_name] = WhoisXmlObject.new(el[0])
          else
            el.collect! { |e| WhoisXmlObject.new(e) }
            @methods[m_name] = el
        end
        return @methods[m_name]
      end

      def to_s
        return REXML::XPath.match(@element, "text()").join.squeeze("\n\t").strip
      end

      def to_str
        s = to_s();
        s.sub!( "&amp;", "&" )
        s.sub!( "&quot;", '"' )
        s.sub!( "&lt;", ">" )
        s.sub!( "&gt;", "<" )
        s.sub!( "&#xD;", "" )
        s.sub!( "&#xA;", "" )
        return s
      end

      # Simply returns this object as an array containing itself.
      # This method was added by Andy
      def to_ary
        return [ self ]
      end

      def log_mailing_address( logger )
        log_street_address( logger )

        # City
        logger.extra( "City", city.to_str ) if city != nil

        log_region( logger )

        # Country
        logger.extra( "Country", iso3166_1.name.to_str ) if iso3166_1 != nil

        log_postal_code( logger )
      end

      def log_region( logger )
        # State/Province/Region
        iso3166_2_label = "Region"
        if( iso3166_1 != nil && iso3166_1.code2.to_s == "US" )
          iso3166_2_label = "State"
        elsif( iso3166_1 != nil && iso3166_1.code2.to_s == "CA" )
          iso3166_2_label = "Province"
        end
        logger.extra( iso3166_2_label, iso3166_2.to_str ) if iso3166_2 != nil
      end

      def log_postal_code( logger )
        # Postal Code/ Zip Code
        postal_code_label = "Postal Code"
        if( iso3166_1 != nil && iso3166_1.code2.to_s == "US" )
          postal_code_label = "Zip Code"
        end
        logger.extra( postal_code_label, postalCode.to_str ) if postalCode != nil
      end

      def log_comments( logger )
        # Comments
        comment.line.to_ary.each { |comment_line|
          s = format( "Comment (line %2d)", comment_line.number )
          logger.datum( s, comment_line.to_str )
        } if comment != nil
      end

      def log_street_address( logger )
        # Street Address
        streetAddress.line.to_ary.each { |address_line|
          s = format( "Street Address (line %2d)", address_line.number )
          logger.extra( s, address_line.to_str )
        } if streetAddress != nil
      end

      def log_dates( logger )
        # Registration Date
        logger.datum( "Registration Date", Time.parse( registrationDate.to_s ).rfc2822 ) if registrationDate != nil

        # Updated Date
        logger.datum( "Last Update Date", Time.parse( updateDate.to_s ).rfc2822 ) if updateDate != nil
      end

    end

  end

end