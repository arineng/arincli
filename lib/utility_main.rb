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


require 'cache'
require 'config'
require 'constants'
require 'yaml'

module ARINcli

  class Utility

    def run args

      puts ARINcli::VERSION
      puts "ARINcli Utility Program"
      puts ARINcli::COPYRIGHT

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
          puts "Unknown command input for arinutil."
          puts
          help
      end

    end

    def help

      help_summary = <<HELP_SUMMARY

This program is for maintenance of the ARINcli program files.

Usage is "arinutil COMMAND" where COMMAND is one of the following:

  help        - shows this help
  clean_cache - forces a cleaning of the arininfo cache
  cache_count - reports the number of files in the arininfo cache
  cached_last - shows details on the last file cached
  config      - show the interpretted configuration

HELP_SUMMARY

      puts help_summary

    end

    def clean_cache
      config = ARINcli::Config.new( ARINcli::Config::formulate_app_data_dir() )
      config.setup_workspace
      cache = ARINcli::Whois::Cache.new( config )
      evicts = cache.clean
      puts "Cache reports " + evicts.to_s + " files evicted (removed)."
    end

    def cache_count
      config = ARINcli::Config.new( ARINcli::Config::formulate_app_data_dir() )
      config.setup_workspace
      cache = ARINcli::Whois::Cache.new( config )
      count = cache.count
      puts "Cache reports " + count.to_s + " files in cache."
    end

    def cached_last
      config = ARINcli::Config.new( ARINcli::Config::formulate_app_data_dir() )
      config.setup_workspace
      cache = ARINcli::Whois::Cache.new( config )
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
      config = ARINcli::Config.new( ARINcli::Config::formulate_app_data_dir() )
      puts "Data directory: " + ARINcli::Config::formulate_app_data_dir
      puts YAML::dump( config.config )
    end

  end

end
