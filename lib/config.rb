# Copyright (C) 2011 American Registry for Internet Numbers

require 'fileutils'
require 'logger'
require 'yaml'

module ARINr

  # Handles configuration of the application
  class Config

    attr_accessor :logger, :config, :whois_cache_dir

    # Intializes the configuration with a place to look for the config file
    # If the file doesn't exist, a default is used.
    # Main routines will do something like ARINr::Config.new( ARINr::Config.formulate_app_data_dir() )
    def initialize app_data

      @app_data = app_data
      @logger = ARINr::Logger.new

      config_file_name = Config.formulate_config_file_name( @app_data )
      if File.exist?( config_file_name )
        @config = YAML.load( File.open( config_file_name ) )
      else
        @config = YAML.load( @@yaml_config )
      end

      configure_logger()
    end

    # Setups work space for the application and lays down default config
    # If directory is nil, then it uses its own value
    def setup_workspace

      if ! File.exist?( @app_data )

        @logger.mesg "Creating configuration in " + @app_data
        Dir.mkdir( @app_data )
        f = File.open( Config.formulate_config_file_name( @app_data ), "w" )
        f.puts @@yaml_config
        f.close

        @whois_cache_dir = File.join( @app_data, "whois_cache" )
        Dir.mkdir( @whois_cache_dir )

      else

        @logger.mesg "Using configuration found in " + @app_data

      end

    end

    # Configures the logger
    def configure_logger
      output = @config[ "output" ]
      return if output == nil

      messages = output[ "messages" ]
      if( messages != nil )
        @logger.message_level = nil
        ARINr::MessageLevel.each { |key,value|
          if( messages == value )
            @logger.message_level = key
          end
        }
        raise ArgumentError, "Invalid message level in configuration file" if @logger.message_level == nil
      end
      messages_file = output[ "messages_file" ]
      if( messages_file != nil )
        @logger.message_out = File.open( messages_file, "w+" )
      end

      data = output[ "data" ]
      if( data != nil )
        @logger.data_amount=nil
        ARINr::DataAmount.each { |key,value|
          if( data == value )
            @logger.data_amount=key
          end
        }
        raise ArgumentError, "Invalid data amount in configuration file" if @logger.data_amount == nil
      end
      data_file = output[ "data_file" ]
      if( data_file != nil )
        @logger.data_out= File.open( data_file, "w+" )
      end
    end

    def self.clean

      FileUtils::rm_r( formulate_app_data_dir() )

    end

    def self.formulate_app_data_dir
      if RUBY_PLATFORM =~ /win32/
        data_dir = File.join(ENV['APPDATA'], "ARINr")
      elsif RUBY_PLATFORM =~ /linux/
        data_dir = File.join(ENV['HOME'], ".ARINr")
      elsif RUBY_PLATFORM =~ /darwin/
        data_dir = File.join(ENV['HOME'], ".ARINr")
      elsif RUBY_PLATFORM =~ /freebsd/
        data_dir = File.join(ENV['HOME'], ".ARINr")
      else
        raise ScriptError, "system platform is not recognized."
      end
      return data_dir
    end

    def self.formulate_config_file_name data_dir
      File.join( data_dir, "config.yaml" )
    end

    @@yaml_config = <<YAML_CONFIG
output:

  # possible values are NONE, SOME, ALL
  messages: SOME

  # If specified, messages goes to this file
  # otherwise, leave it commented out to go to stderr
  #messages_file: /tmp/ARINr.messages

  # possible values are TERSE, NORMAL, EXTRA
  data: NORMAL

  # If specified, data goest to this file
  # otherwise, leave it commented out to go to stdout
  #data_file: /tmp/ARINr.data

whois:

  # the base URL for the Whois-RWS service
  url: http://whois.arin.net
YAML_CONFIG

  end

end
