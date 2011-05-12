# This file is public domain, and originates from Sean Russell
# in a posting at http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/99306
# for a Ruby object call XMlObject
# $Id$

require "rexml/document"

module ARINr

  module Whois

    # A quasi-serialization class.  Accepts a limited subset of XML and turns it
    # into Ruby objects.
    class WhoisXmlObject

      def initialize element
        @element = element
        @methods = {}
      end

      def method_missing method
        m_name = method.to_s
        return @methods[m_name] if @methods[m_name]
        el = REXML::XPath.match(@element, m_name)
        case el.size
          when 0
            return @element.attributes[m_name]
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

      # Simply returns this object as an array containing itself.
      # This method was added by Andy
      def to_ary
        return [ self ]
      end

    end

  end

end