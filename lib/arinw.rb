# Copyright (C) 2011 American Registry for Internet Numbers

require 'optparse'
require 'net/http'
require 'uri'
require 'rexml/document'
require 'base_opts'
require 'config'
require 'constants'
require 'cache'
require 'enum'
require 'whois_net'
require 'whois_poc'
require 'whois_org'

module ARINr

  module Whois

    class QueryType < ARINr::Enum

      QueryType.add_item :BY_NET_HANDLE, "NET-HANDLE"
      QueryType.add_item :BY_POC_HANDLE, "POC-HANDLE"
      QueryType.add_item :BY_ORG_HANDLE, "ORG-HANDLE"

    end

    # The main class for the arinw command.
    class Main < ARINr::BaseOpts

      def initialize args

        @config = ARINr::Config.new( ARINr::Config::formulate_app_data_dir() )

        @opts = OptionParser.new do |opts|

          opts.banner = "Usage: arinw [options] QUERY_VALUE"

          opts.separator ""
          opts.separator "Query Options:"

          opts.on( "-U", "--url URL",
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

        begin
          @opts.parse!( args )
        rescue OptionParser::InvalidArgument => e
          puts e.message
          puts "use -h for help"
          exit
        end
        @config.options.argv = args

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
          res = Net::HTTP.start( uri.host, uri.port ) do |http|
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

      def run

        if( @config.options.help )
          help()
        elsif( @config.options.argv == nil || @config.options.argv == [] )
          help()
        end

        @config.logger.mesg( ARINr::VERSION )
        @config.setup_workspace
        @cache = ARINr::Whois::Cache.new( @config )

        if( @config.options.query_type == nil )
          @config.options.query_type = Main.guess_query( @config.options.argv, @config.logger  )
          if( @config.options.query_type == nil )
            @config.logger.mesg( "Unable to guess type of query. You must specify it." )
            exit
          else
            @config.logger.trace( "Assuming query is " + @config.options.query_type )
          end
        end

        begin
          data = get( Main.create_query( @config.options.argv, @config.options.query_type ) )
          root = REXML::Document.new( data ).root
          evaluate_response( root )
          @config.logger.end_run
        rescue Net::HTTPServerException => e
          case e.response.code
            when "404"
              @config.logger.mesg( "Query yielded no results." )
            when "503"
              @config.logger.mesg( "ARIN Whois-RWS is unavailable." )
          end
          @config.logger.trace( "Server response code was " + e.response.code )
        end

      end

      def evaluate_response element
        if( element.namespace == "http://www.arin.net/whoisrws/core/v1" )
          case element.name
            when "net"
              net = ARINr::Whois::WhoisNet.new( element )
              net.to_log( @config.logger )
            when "poc"
              poc = ARINr::Whois::WhoisPoc.new( element )
              poc.to_log( @config.logger )
            when "org"
              org = ARINr::Whois::WhoisOrg.new( element )
              org.to_log( @config.logger )
            else
              @config.logger.mesg "Response contained an answer this program does not implement."
          end
        elsif
          @config.logger.mesg "Response contained an answer this program does not understand."
        end
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

      # Evaluates the args and guesses at the type of query.
      # Args is an array of strings, most likely what is left
      # over after parsing ARGV
      def self.guess_query( args, logger )
        retval = nil

        if( args.length() == 1 )

          case args[ 0 ]
            when ARINr::NET_HANDLE_REGEX
              args[ 0 ] = args[ 0 ].upcase
              retval = QueryType::BY_NET_HANDLE
            when ARINr::NET6_HANDLE_REGEX
              args[ 0 ] = args[ 0 ].upcase
              retval = QueryType::BY_NET_HANDLE
            when ARINr::POC_HANDLE_REGEX
              args[ 0 ] = args[ 0 ].upcase
              retval = QueryType::BY_POC_HANDLE
            when ARINr::ORGL_HANDLE_REGEX
              args[ 0 ] = args[ 0 ].upcase
              retval = QueryType::BY_ORG_HANDLE
            when ARINr::ORGS_HANDLE_REGEX
              old = args[ 0 ]
              args[ 0 ] = args[ 0 ].sub( /-O$/i, "" )
              args[ 0 ].upcase!
              logger.trace( "Interpretting " + old + " as organization handle for " + args[ 0 ] )
              retval = QueryType::BY_ORG_HANDLE
          end

        end

        return retval
      end

      # Creates a query type
      def self.create_query( args, queryType )

        path = ""
        case queryType
          when QueryType::BY_NET_HANDLE
            path << "rest/net/" << args[ 0 ]
          when QueryType::BY_POC_HANDLE
            path << "rest/poc/" << args[ 0 ]
          when QueryType::BY_ORG_HANDLE
            path << "rest/org/" << args[ 0 ]
        end

        return path
      end


    end

  end

end

