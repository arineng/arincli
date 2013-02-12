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


require 'optparse'
require 'rexml/document'
require 'base_opts'
require 'config'
require 'constants'
require 'reg_rws'
require 'rdns_reg'
require 'editor'
require 'data_tree'

module ARINcli

  module Registration

    class RdnsMain < ARINcli::BaseOpts

      def initialize args, config = nil

        if config
          @config = config
        else
          @config = ARINcli::Config.new( ARINcli::Config::formulate_app_data_dir() )
        end

        @opts = OptionParser.new do |opts|

          opts.banner = "Usage: rdns [options] arguments"

          opts.separator ""
          opts.separator "Actions:"

          opts.on( "--edit",
                   "Fetch and Modify a reverse DNS delegation." ) do |edit|
            if @config.options.modify_zonefile
              raise OptionParser::InvalidArgument, "--zonefile and --edit are mutually exclusive commands."
            end
            @config.options.edit_rdns = true
          end

          opts.on( "--zonefile",
                   "Modify reverse DNS delegations from a zone file." ) do |zonefile|
            if @config.options.edit_rdns
              raise OptionParser::InvalidArgument, "--zonefile and --edit are mutually exclusive commands."
            end
            @config.options.modify_zonefile = true
          end

          opts.separator ""
          opts.separator "Zone File Options:"

          opts.on( "--no-verify",
                   "Do not verify the zone file output in the editor." ) do |no_verify|
            @config.options.no_verify = true
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
        end

        add_base_opts( @opts, @config )

        begin
          @opts.parse!( args )
          if ! @config.options.modify_zonefile && ! @config.options.edit_rdns
            raise OptionParser::InvalidArgument, "You must specify either --zonefile or --edit."
          end
          if ! args[ 0 ] && @config.options.edit_rdns
            raise OptionParser::InvalidArgument, "You must specify a reverse DNS delegation name."
          end
          if ! args[ 0 ] && @config.options.modify_zonefile
            raise OptionParser::InvalidArgument, "You must specify one or more zone files to parse."
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
          @config.options.data_file = @config.make_file_name( ARINcli::MODIFY_POC_FILE )
          data_to_send = make_yaml_template(@config.options.data_file, @config.options.argv[0])
        else
          data_to_send = true
        end
        if ! @config.options.data_file_specified && data_to_send
          editor = ARINcli::Editor.new(@config)
          edited = editor.edit(@config.options.data_file)
          if ! edited
            @config.logger.mesg( "No changes were made to POC data file. Aborting." )
            return
          end
        end
        if data_to_send
          reg = ARINcli::Registration::RegistrationService.new(@config, ARINcli::POC_TX_PREFIX)
          file = File.new(@config.options.data_file, "r")
          data = file.read
          file.close
          poc = ARINcli::Registration.yaml_to_poc(data)
          poc_element = ARINcli::Registration.poc_to_element(poc)
          return_data = ARINcli::pretty_print_xml_to_s(poc_element)
          if reg.modify_poc(poc.handle, return_data)
            @config.logger.mesg(poc.handle + " has been modified.")
          else
            if !@config.options.data_file_specified
              @config.logger.mesg( 'Use "poc" to re-edit and resubmit.' )
            else
              @config.logger.mesg( 'Edit file then use "poc -f ' + @config.options.data_file + ' --modify" to resubmit.')
            end
          end
        else
          @config.logger.mesg( "No modification source specified." )
        end
      end

      def run

        if( @config.options.help )
          help()
          return
        end

        @config.logger.mesg( ARINcli::VERSION )
        @config.setup_workspace

        # If no action is given, then the default action is to modify a POC
        if ( ! @config.options.delete_poc ) && ( ! @config.options.create_poc ) && ( ! @config.options.make_template )
          @config.options.modify_poc = true
          @config.logger.mesg( "No action specified. Default action is to modify a POC." )
        end

        # because we use this constantly in this code section
        args = @config.options.argv

        # a POC handle is given, see if it is a tree reference and dereference it,
        # then make sure it looks like a POC handle.
        if !@config.options.help && args != nil && args != []
          if args[ 0 ] =~ ARINcli::DATA_TREE_ADDR_REGEX
            tree = @config.load_as_yaml( ARINcli::ARININFO_LASTTREE_YAML )
            handle = tree.find_handle( args[ 0 ] )
            raise ArgumentError.new( "Unable to find handle for " + args[ 0 ] ) unless handle
            args[ 0 ] = handle
          end
          if ! args[ 0 ] =~ ARINcli::POC_HANDLE_REGEX
            raise ArgumentError.new(args[ 0 ] + " does not look like a POC Handle.")
          end
        end

        exit_code = 0
        begin
          if @config.options.make_template
            make_yaml_template( @config.options.template_file, args[ 0 ] )
          elsif @config.options.modify_poc
            last_modified = @config.make_file_name( ARINcli::MODIFY_POC_FILE )
            if File.exists?( last_modified ) && (!args[ 0 ])
              @config.options.data_file = last_modified
              @config.logger.mesg( "Re-using data from last modify POC action." )
            elsif !args[ 0 ]
              raise ArgumentError.new("You must specify a Point of Contact to modify." )
            end
            modify_poc()
          elsif @config.options.delete_poc
            reg = ARINcli::Registration::RegistrationService.new( @config )
            element = reg.delete_poc( args[ 0 ] )
            @config.logger.mesg( args[ 0 ] + " deleted." ) if element
          elsif @config.options.create_poc
            last_created = @config.make_file_name( ARINcli::CREATE_POC_FILE )
            if File.exists?( last_created ) && !args[ 0 ]
              @config.options.data_file = last_created
              @config.logger.mesg( "Re-using data from last create POC action." )
            end
            create_poc()
          else
            @config.logger.mesg( "Action or feature is not implemented." )
            exit_code = 1
          end
        rescue ArgumentError => e
          @config.logger.mesg( e.message )
          exit_code = 1
        end

        @config.logger.end_run
        exit( exit_code )

      end

      def help

        puts ARINcli::VERSION
        puts ARINcli::COPYRIGHT
        puts <<HELP_SUMMARY

This program uses ARIN's Reg-RWS RESTful API to modify reverse DNS delegations.
There are two actions specified with either the --edit or --zonefile options.

The --edit option requires the name of a reverse DNS delegation name (or zone) as an
argument. It will fetch that delegation from ARIN and allow the user to edit it
in a YAML file and then modify the delegation in ARIN's database if the YAML
file has been modified.

The --zonefile option takes one or more zone file names as arguments. It will parse
the zone files and modify the corresponding reverse DNS delegations based on the
zone files. If the --no-verify is not specified, the delegation information will be
put into a YAML file and the user will be allowed to edit it before the delegations
are modified.

HELP_SUMMARY
        puts @opts.help
        exit

      end

      def make_yaml_template file_name, poc_handle
        success = false
        reg = ARINcli::Registration::RegistrationService.new @config, ARINcli::POC_TX_PREFIX
        element = reg.get_poc( poc_handle )
        if element
          poc = ARINcli::Registration.element_to_poc( element )
          file = File.new( file_name, "w" )
          file.puts( ARINcli::Registration.poc_to_template( poc ) )
          file.close
          success = true
          @config.logger.trace( poc_handle + " saved to " + file_name )
        end
        return success
      end

      def create_poc
        if ! @config.options.data_file
          poc = ARINcli::Registration::Poc.new
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
          @config.options.data_file = @config.make_file_name( ARINcli::CREATE_POC_FILE )
          file = File.new( @config.options.data_file, "w" )
          file.puts( ARINcli::Registration.poc_to_template( poc ) )
          file.close
        end
        if ! @config.options.data_file_specified
          editor = ARINcli::Editor.new( @config )
          edited = editor.edit( @config.options.data_file )
          if ! edited
            @config.logger.mesg( "No modifications made to POC data file. Aborting." )
            return
          end
        end
        reg = ARINcli::Registration::RegistrationService.new(@config,ARINcli::POC_TX_PREFIX)
        file = File.new(@config.options.data_file, "r")
        data = file.read
        file.close
        poc = ARINcli::Registration.yaml_to_poc( data )
        poc_element = ARINcli::Registration.poc_to_element(poc)
        send_data = ARINcli::pretty_print_xml_to_s(poc_element)
        element = reg.create_poc( send_data )
        if element
          new_poc = ARINcli::Registration.element_to_poc( element )
          @config.logger.mesg( "New point of contact created with handle " + new_poc.handle )
          @config.logger.mesg( 'Use "poc ' + new_poc.handle + '" to modify this point of contact.')
          last_created = @config.make_file_name( ARINcli::CREATE_POC_FILE )
          if File.exists?( last_created )
            File.delete( last_created )
          end
        else
          @config.logger.mesg( "Point of contact was not created." )
          if !@config.options.data_file_specified
            @config.logger.mesg( 'Use "poc --create" to re-edit and resubmit.' )
          else
            @config.logger.mesg( 'Edit file then use "poc -f ' + @config.options.data_file + ' --create" to resubmit.')
          end
        end
      end

    end

  end

end
