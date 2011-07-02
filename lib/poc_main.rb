# Copyright (C) 2011 American Registry for Internet Numbers

require 'optparse'
require 'rexml/document'
require 'base_opts'
require 'config'
require 'constants'
require 'reg_rws'

module ARINr

  module Registration

    class PocMain < ARINr::BaseOpts

      def initialize args, config = nil

        if config
          @config = config
        else
          @config = ARINr::Config.new( ARINr::Config::formulate_app_data_dir() )
        end

        @opts = OptionParser.new do |opts|

          opts.banner = "Usage: arinp [options] [POC_HANDLE]"

          opts.separator ""
          opts.separator "Actions:"

          opts.on( "--create",
                   "Creates a Point of Contact." ) do |create|
            if @config.options.modify_poc || @config.options.delete_poc || @config.options.make_template
              raise OptionParser::InvalidArgument, "Can't create and modify, delete, or template at the same time."
            end
            @config.options.create_poc = true
          end

          opts.on( "--modify",
                   "Modifies a Point of Contact." ) do |modify|
            if @config.options.create_poc || @config.options.delete_poc || @config.options.make_template
              raise OptionParser::InvalidArgument, "Can't create and modify, delete, or template at the same time."
            end
            @config.options.modify_poc = true
          end

          opts.on( "--delete",
                   "Deletes a Point of Contact." ) do |delete|
            if @config.options.create_poc || @config.options.modify_poc || @config.options.make_template
              raise OptionParser::InvalidArgument, "Can't create and modify, delete, or template at the same time."
            end
            @config.options.delete_poc = true
          end

          opts.on( "--yaml FILE",
                   "Create a YAML template for a Point of Contact." ) do |yaml|
            if @config.options.create_poc || @config.options.modify_poc || @config.options.delete_poc
              raise OptionParser::InvalidArgument, "Can't create and modify, delete or template at the same time."
            end
            @config.options.make_template = true
            @config.options.template_type = "YAML"
            @config.options.template_file = yaml
          end

          opts.separator ""
          opts.separator "Communications Options:"

          opts.on( "-U", "--url URL",
                   "The base URL of the Registration RESTful Web Service." ) do |url|
            @config.config[ "registration" ][ "url" ] = url
          end

          opts.on( "-A", "--apikey APIKEY",
                   "The API KEY to use with the RESTful Web Service." ) do |apikey|
            @config.config[ "registration" ][ "apikey" ] = apikey.to_s.upcase
          end

          opts.separator ""
          opts.separator "File Options:"

          opts.on( "-f", "--file FILE",
                   "The template to be read for the action taken." ) do |file|
            @config.options.data_file = file
          end
        end

        add_base_opts( @opts, @config )

        begin
          @opts.parse!( args )
          if !@config.options.help && args != nil && args != []
            if ( ! @config.options.delete_poc ) && ( ! @config.options.create_poc ) && ( ! @config.options.make_template )
              @config.options.modify_poc = true
            end
            if ! args[ 0 ] && @config.options.delete_poc
              raise OptionParser::InvalidArgument, "You must specify a POC Handle to delete a POC."
            end
            if ! args[ 0 ] && @config.options.modify_poc
              raise OptionParser::InvalidArgument, "You must specify a POC Handle to modify a POC."
            end
            if ! args[ 0 ] && @config.options.make_template
              raise OptionParser::InvalidArgument, "You must specify a POC Handle to template."
            end
            if ! args[ 0 ] =~ ARINr::POC_HANDLE_REGEX
              raise OptionParser::InvalidArgument, args[ 0 ] + " does not look like a POC Handle."
            end
          end
        rescue OptionParser::InvalidArgument => e
          puts e.message
          puts "use -h for help"
          exit
        end
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

      end

      def help

        puts ARINr::VERSION
        puts ARINr::COPYRIGHT
        puts <<HELP_SUMMARY

This program uses ARIN's Reg-RWS RESTful API to query ARIN's Registration database.
The general usage is "arinp POC_HANDLE" where POC_HANDLE is the identifier of the point
of contact to modify. Other actions can be specified with options, but if not explicit
action is given then modification is assumed.

HELP_SUMMARY
        puts @opts.help
        exit

      end

      def make_template file_name, poc_handle

        reg = ARINr::Registration::RegistrationService.new @config


      end
    end

  end

end
