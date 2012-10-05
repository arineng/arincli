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

    # Represents a reverse DNS delegation
    class WhoisRdns < ARINr::Whois::WhoisXmlObject

      # Returns a multiline string for long output
      def to_log( logger )
        logger.start_data_item
        logger.terse( "Delegation Name", name.to_s() )
        logger.extra( "Delegation Reference", ref.to_s )
        ns_num = 1
        nameservers.nameserver.to_ary.each { |nameserver|
          s = format( "Nameserver %2d", ns_num )
          logger.datum( s, nameserver.to_s )
          ns_num += 1
        } if nameservers != nil
        key_num = 1
        delegationKeys.delegationKey.to_ary.each { |key|
          s = format( "Key Tag %2d", key_num )
          logger.extra( s, key.keyTag.to_s )
          s = format( "Key Algorithm %2d", key_num )
          logger.extra( s, key.algorithm.to_s + " ( " + key.algorithm.name + " )" )
          s = format( "Key Digest Type %2d", key_num )
          logger.extra( s, key.digestType.to_s + " ( " + key.digestType.name + " )" )
          s = format( "Key Digest %2d", key_num )
          logger.extra( s, key.digest.to_s )
          key_num += 1
        } if delegationKeys != nil
        log_dates( logger )
        logger.end_data_item
      end

      def to_s
        name.to_s
      end

    end

  end

end
