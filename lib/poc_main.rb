# Copyright (C) 2011 American Registry for Internet Numbers

require 'optparse'
require 'rexml/document'
require 'base_opts'
require 'config'
require 'constants'
require 'reg_rws'
require 'poc_reg'
require 'editor'

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

      def modify_poc
        if !@config.options.data_file
          @config.options.data_file = @config.make_file_name("arinp_modify_poc")
          if make_yaml_template(@config.options.data_file, args[0])
            editor = ARINr::Editor.new(@config)
            edited = editor.edit(@config.options.data_file)
            if ! edited
              @config.logger.mesg( "No changes were made to POC data file. Aborting." )
              return
            end
          end
        end
        reg = ARINr::Registration::RegistrationService.new(@config)
        file = File.new(@config.options.data_file, "r")
        data = file.read
        file.close
        poc = ARINr::Registration.yaml_to_poc( data )
        reg.modify_poc(args[0], ARINr::Registration.poc_to_element( poc ).write )
      end

      def run

        if( @config.options.help )
          help()
        elsif( @config.options.argv == nil || @config.options.argv == [] )
          help()
        end

        @config.logger.mesg( ARINr::VERSION )
        @config.setup_workspace

        if @config.options.make_template
          make_yaml_template( @config.options.template_file, @config.options.argv[ 0 ] )
        elsif @config.options.modify_poc
          modify_poc()
        elsif @config.options.delete_poc
          reg = ARINr::Registration::RegistrationService.new( @config )
          element = reg.delete_poc( @config.options.argv[ 0 ] )
          @config.logger.mesg( @config.options.argv[ 0 ] + " deleted." ) if element
        elsif @config.options.create_poc
          create_poc()
        else
          @config.logger.mesg( "Action or feature is not implemented." )
        end

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

      def make_yaml_template file_name, poc_handle
        success = false
        reg = ARINr::Registration::RegistrationService.new @config
        element = reg.get_poc( poc_handle )
        if element
          poc = ARINr::Registration.element_to_poc( element )
          file = File.new( file_name, "w" )
          file.puts( ARINr::Registration.poc_to_template( poc ) )
          file.close
          success = true
          @config.logger.trace( poc_handle + " saved to " + file_name )
        end
        return success
      end

      def create_poc
        if ! @config.options.data_file
          poc = ARINr::Registration::Poc.new
          poc.first_name="PUT FIRST NAME HERE"
          poc.middle_name="PUT MIDDLE NAME HERE"
          poc.last_name="PUT LAST NAME HERE"
          poc.company_name="PUT COMPANY NAME HERE"
          poc.type="PERSON"
          poc.street_address=["FIRST STREET ADDRESS LINE HERE", "SECOND STREET ADDRESS LINE HERE"]
          poc.city="PUT CITY HERE"
          poc.state="PUT STATE, PROVINCE, OR REGION HERE"
          poc.country="PUT COUNTRY HERE"
          poc.postal_code="PUT POSTAL OR ZIP CODE HERE"
          poc.emails=["YOUR_EMAIL_ADDRESS_HERE@SOME_COMPANY.NET"]
          poc.phones={ "office" => ["1-XXX-XXX-XXXX", "x123"]}
          poc.comments=["PUT FIRST LINE OF COMMENTS HEERE", "PUT SECOND LINE OF COMMENTS HERE"]
          @config.options.data_file = @config.make_file_name("arinp_create_poc")
          file = File.new( @config.options.data_file, "w" )
          file.puts( ARINr::Registration.poc_to_template( poc ) )
          file.close
          editor = ARINr::Editor.new( @config )
          edited = editor.edit( @config.option.data_file )
          if ! edited
            @config.logger.mesg( "No modifications made to POC data file. Aborting." )
            return
          end
        end
        reg = ARINr::Registration::RegistrationService.new(@config)
        file = File.new(@config.options.data_file, "r")
        data = file.read
        file.close
        poc = ARINr::Registration.yaml_to_poc( data )
        element = reg.create_poc( ARINr::Registration.poc_to_element( poc ).write )
        if element
          new_poc = ARINr::Registration.element_to_poc( element )
          @config.logger( "New point of contact created with handle " + new_poc.handle )
        else
          @config.logger( "Point of contact was not created." )
        end
      end

    end

  end

end
