# Copyright (C) 2011 American Registry for Internet Numbers

require 'uri'

module ARINr

  module Whois

    class Cache

      def initialize config
        @config = config
      end

      def put url, data
        safe = Cache.make_safe( url )
        @config.logger.trace( "Persisting " + url + " as " + safe )
        f = File.open( File.join( @config.whois_cache_dir, safe ), "w" )
        f.puts data
        f.close
      end

      def get url
        safe = Cache.make_safe( url )
        file_name = File.join( @config.whois_cache_dir, safe )
        if( File.exist( file_name ) )
          @config.logger.mesg( "Getting " + url + " from cache." )
          f = File.open( file_name, "r" )
          data = ''
          f.each_line do |line|
            data += line
          end
          f.close
          return data
        end
        #else
        return nil
      end

      def self.make_safe( url )
        safe = URI.escape( url )
        safe = URI.escape( safe, "!*'();:@&=+$,/?#[]" )
        return safe
      end

    end

  end

end