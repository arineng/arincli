# Copyright (C) 2011 American Registry for Internet Numbers

require 'fileutils'
require 'logger'
require 'yaml'

module ARINr

  # Handles configuration of the application
  class Config

    attr_accessor :logger, :config

    def initialize

      @app_data = Config.formulate_app_data_dir()
      @logger = ARINr::Logger.new

      config_file_name = Config.formulate_config_file_name( @app_data )
      if File.exists?( config_file_name )
        @config = YAML.load( config_file_name )
        configure_logger
      end

      @logger.mesg "ARINr v.0.1 -- Copyright (C) 2011 American Registry for Internet Numbers"


      if ! File.exist?( @app_data )

        @logger.mesg "Creating configuration in " + @app_data
        Dir.mkdir( @app_data )
        f = File.open( Config.formulate_config_file_name( @app_data ), "w" )
        f.puts @@yaml_config
        f.close

      else

        @logger.mesg "Using configuration found in " + @app_data

      end

    end

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
YAML_CONFIG

  end

  Config.new

end
