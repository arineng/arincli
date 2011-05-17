# Copyright (C) 2011 American Registry for Internet Numbers

require 'optparse'
require 'net/http'
require 'uri'
require 'rexml/document'
require 'base_opts'
require 'config'
require 'constants'
require 'cache'

module ARINr

  module Whois

    # The main class for the arinw command.
    class Main < ARINr::BaseOpts

      def initialize args

        @config = ARINr::Config.new( ARINr::Config::formulate_app_data_dir() )

        @opts = OptionParser.new do |opts|

          opts.banner = "Usage: arinw [options] QUERY_VALUE"

          opts.separator ""
          opts.separator "Query Options:"

          opts.on( "-U", "--url",
            "The base URL of the RESTful Web Service." ) do |url|
            @config.config[ "whois" ][ "url" ] = url
          end

          opts.separator ""
          opts.separator "Cache Options:"

          opts.on( "--cache-expiry SECONDS",
            "Age in seconds of items in the cache to be considered expired.") do |s|
            @config.config[ "whois" ][ "cache_expiry" ] = s
          end

          opts.on( "--[no]-cache",
            "Controls if the cache is used or not." ) do |cc|
            @config.config[ "whois" ][ "use_cache" ] = cc
          end

        end

        add_base_opts( @opts, @config )

        @opts.parse!( args )
        @config.options.argv = args

      end

      def run

        if( @config.options.help )
          help()
        elsif( @config.options.argv == nil || @config.options.argv == [] )
          help()
        end

        @config.logger.mesg( ARINr::VERSION )
        @config.setup_workspace
        @cache = ARINr::Whois::Cache.new( @config )

      end

      def help

        puts ARINr::VERSION
        puts ARINr::COPYRIGHT
        puts <<HELP_SUMMARY

This program uses ARIN's Whois-RWS RESTful API to query ARIN's Whois database.

HELP_SUMMARY
        puts @opts.help
        exit

      end

      # Do an HTTP GET with the path.
      # The base URL is taken from the config
      def get path

        url = @config.config[ "whois" ][ "url" ]
        if( ! url.end_with?( "/" ) )
          url << "/"
        end
        url << path

        data = @cache.get( url )
        if( data == nil )

          @config.logger.trace( "Issuing GET for " + url )
          req = Net::HTTP::Get.new( url )
          req[ "User-Agent" ] = ARINr::VERSION
          uri = URI.parse( url )
          res = Net::HTTP.start( url.host, url.port ) do |http|
            http.request( req )
          end

          case res
            when Net::HTTPSuccess
              data = res.body
              @cache.put( url, data )
            else
              res.error!
          end

        end

        return data

      end

    end

  end

end
