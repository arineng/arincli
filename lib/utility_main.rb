# Copyright (C) 2011 American Registry for Internet Numbers

require 'cache'
require 'config'
require 'yaml'

module ARINr

  class Utility

    def run args

      puts "ARINr Control Program"

      case args[ 0 ]
        when "-h"
          help
        when "help"
          help
        when "clean_cache"
          clean_cache
        when "cache_count"
          cache_count
        when "cached_last"
          cached_last
        when "config"
          config
        else
          puts "Unknown command input for arinu."
          puts
          help
      end

    end

    def help

      help_summary = <<HELP_SUMMARY

This program is for maintenance of the ARINr program files.

Usage is "arinu COMMAND" where COMMAND is one of the following:

  help        - shows this help
  clean_cache - forces a cleaning of the arinw cache
  cache_count - reports the number of files in the arinw cache
  cached_last - shows details on the last file cached
  config      - show the interpretted configuration

HELP_SUMMARY

      puts help_summary

    end

    def clean_cache
      config = ARINr::Config.new( ARINr::Config::formulate_app_data_dir() )
      config.setup_workspace
      cache = ARINr::Whois::Cache.new( config )
      evicts = cache.clean
      puts "Cache reports " + evicts.to_s + " files evicted (removed)."
    end

    def cache_count
      config = ARINr::Config.new( ARINr::Config::formulate_app_data_dir() )
      config.setup_workspace
      cache = ARINr::Whois::Cache.new( config )
      count = cache.count
      puts "Cache reports " + count.to_s + " files in cache."
    end

    def cached_last
      config = ARINr::Config.new( ARINr::Config::formulate_app_data_dir() )
      config.setup_workspace
      cache = ARINr::Whois::Cache.new( config )
      arry = cache.get_last
      if arry == nil
        puts "Either there is nothing in the cache or the last cache file can't be found."
      else
        puts
        puts "File Last Cached: " + arry[ 0 ]
        puts "Created or Last Updated: " + arry[ 1 ].to_s
        puts
        puts "begin========"
        puts arry[ 2 ]
        puts "==========end"
      end
    end

    def config
      config = ARINr::Config.new( ARINr::Config::formulate_app_data_dir() )
      puts "Data directory: " + ARINr::Config::formulate_app_data_dir
      puts YAML::dump( config.config )
    end

  end

end
