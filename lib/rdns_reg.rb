# Copyright (C) 2011,2012,2013 American Registry for Internet Numbers
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


require 'erb'
require 'yaml'
require 'rexml/document'
require 'utils'
require 'constants'
require 'zonefile'

module ARINcli

  module Registration

    class Zones < Array

      def get_binding
        return binding
      end

      def find_rdns zone_name
        self.each do |rdns|
          return rdns if rdns.name.eql? zone_name
          return rdns if rdns.name.eql?( zone_name + "." )
          return rdns if ( rdns.name + "." ).eql?  zone_name
        end
        #else
        return nil
      end

      def add_ns ns_hash
        rdns = find_rdns( ns_hash[:name] )
        if rdns == nil
          rdns = ARINcli::Registration::Rdns.new
          rdns.name= ns_hash[ :name ]
          self << rdns
        end
        rdns.name_servers << ns_hash[ :host ]
      end

      def add_ds ds_hash
        rdns = find_rdns( ds_hash[:name] )
        if rdns == nil
          rdns = ARINcli::Registration::Rdns.new
          rdns.name= ds_hash[ :name ]
          self << rdns
        end
        signer = ARINcli::Registration::Signer.new
        signer.algorithm=ds_hash[ :algorithm ]
        signer.digest=ds_hash[ :digest ]
        signer.digest_type=ds_hash[ :digest_type ]
        signer.key_tag=ds_hash[ :key_tag ]
        rdns.signers << signer
      end
    end

    # basic holder RDNS registration information
    class Rdns
      attr_accessor :name, :name_servers, :signers

      def initialize
        @signers = []
        @name_servers = []
      end

      def ==(another_rdns)
        return false unless another_rdns.instance_of?( ARINcli::Registration::Rdns )
        instance_variables.each do |var|
          a = instance_variable_get( var )
          b = another_rdns.instance_variable_get( var )
          return false unless a == b
        end
        return true
      end
    end

    class Signer
      attr_accessor :digest, :digest_type, :key_tag

      def algorithm
        @algorithm
      end
      def algorithm=(val)
        if val.instance_of? String
          @algorithm = val.to_i if val.match( /\d+/ )
          @algorithm = ARINcli::DNSSEC_ALGORITHMS.index( val ) + 1 if @algorithm == nil
        else
          @algorithm = val
        end
      end
      def algorithm_name
        ARINcli::DNSSEC_ALGORITHMS[ @algorithm - 1 ]
      end
      def ==(another_signer)
        return false unless another_signer.instance_of?( ARINcli::Registration::Signer )
        instance_variables.each do |var|
          a = instance_variable_get( var )
          b = another_signer.instance_variable_get( var )
          return false unless a == b
        end
        return true
      end
    end

    # Takes Zones and returns a string full of YAML goodness
    def Registration::zones_to_template zones
      if zones.instance_of? ARINcli::Registration::Rdns
        zones = ARINcli::Registration::Zones.new << zones
      end
      template = ""
      file = File.new( File.join( File.dirname( __FILE__ ), "rdns_template.yaml" ), "r" )
      file.each_line do |line|
        template << line
      end
      file.close

      yaml = ERB.new( template, 0, "<>" )
      return yaml.result( zones.get_binding )
    end

    # Takes a string containing YAML and converts it to Zones
    def Registration::yaml_to_zones yaml_str
      struct = YAML.load( yaml_str )
      zones = ARINcli::Registration::Zones.new
      if struct.instance_of? Hash
        struct = Array.new << struct
      end
      struct.each do |zone|
        rdns = ARINcli::Registration::Rdns.new
        rdns.name=zone[ "delegation name" ]
        rdns.name_servers=zone[ "name servers" ]
        zone[ "delegation signers" ].each do |signer|
          ds = ARINcli::Registration::Signer.new
          ds.algorithm=signer[ "algorithm" ]
          ds.digest=signer[ "digest" ]
          ds.digest_type=signer[ "digest type" ]
          ds.key_tag=signer[ "key tag" ]
          rdns.signers << ds
        end
        zones << rdns
      end
      return zones
    end

    # Example XML
    #  the attribute 'name' on algorithm and digestType are optional
    #
    # <delegation xmlns="http://www.arin.net/regrws/core/v1" >
    #   <name>0.76.in-addr.arpa.</name>
    #   <delegationKeys>
    #     <delegationKey>
    #       <algorithm name = "RSA/SHA-1">5</algorithm>
    #       <digest>0DC99D4B6549F83385214189CA48DC6B209ABB71</digest>
    #       <digestType name = "SHA-1">1</digestType>
    #       <keyTag>264</keyTag>
    #     </delegationKey>
    #   </delegationKeys>
    #   <nameservers>
    #     <nameserver>NS1.DOMAIN.COM</nameserver>
    #     <nameserver>NS2.DOMAIN.COM</nameserver>
    #   </nameservers>
    # </delegation>

    # Takes RDNS and creates XML
    def Registration::rdns_to_element rdns
      element = REXML::Element.new( "delegation" )
      element.add_namespace( "http://www.arin.net/regrws/core/v1" )
      element.add_element( ARINcli::new_element_with_text( "name", rdns.name ) )
      element.add_element( ARINcli::new_wrapped_element( "nameservers", "nameserver", rdns.name_servers ) ) if !rdns.name_servers.empty?
      if !rdns.signers.empty?
        dks = REXML::Element.new( "delegationKeys" )
        element.add_element( dks )
        rdns.signers.each do |signer|
          dk = REXML::Element.new( "delegationKey" )
          dk.add_element( ARINcli::new_element_with_text( "digest", signer.digest ) )
          dk.add_element( ARINcli::new_element_with_text( "keyTag", signer.key_tag ) )
          dk.add_element( ARINcli::new_element_with_text( "algorithm", signer.algorithm ) )
          dk.add_element( ARINcli::new_element_with_text( "digestType", signer.digest_type ) )
          dks.add_element( dk )
        end
      end
      return element
    end

    def Registration::element_to_rdns element
      rdns = ARINcli::Registration::Rdns.new
      rdns.name = element.elements[ "name" ].text
      element.elements.each( "nameservers/nameserver" ) do |ns_e |
        rdns.name_servers << ns_e.text
      end
      element.elements.each( "delegationKeys/delegationKey" ) do |dk_e|
        signer = ARINcli::Registration::Signer.new
        signer.algorithm = dk_e.elements[ "algorithm" ].text.to_i
        signer.digest = dk_e.elements[ "digest" ].text
        signer.digest_type = dk_e.elements[ "digestType" ].text.to_i
        signer.key_tag = dk_e.elements[ "keyTag" ].text.to_i
        rdns.signers << signer
      end
      return rdns
    end

  end

end

