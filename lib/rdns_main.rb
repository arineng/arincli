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

      def run

        if( @config.options.help )
          help()
          return
        end

        @config.logger.mesg( ARINcli::VERSION )
        @config.setup_workspace

        # because we use this constantly in this code section
        args = @config.options.argv

        if @config.options.edit_rdns
          do_edit_rdns
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

      def do_edit_rdns
        if @config.options.argv[ 0 ] =~ ARINcli::DATA_TREE_ADDR_REGEX
          tree = @config.load_as_yaml( ARINcli::ARININFO_LASTTREE_YAML )
          handle = tree.find_handle( @config.options.argv[ 0 ] )
          raise ArgumentError.new( "Unable to find reverse delegation name for " + @config.options.argv[ 0 ] ) unless handle
          @config.options.argv[ 0 ] = handle
        end
        if ! ( @config.options.argv[ 0 ] =~ ARINcli::IP4_ARPA && args[ 0 ] =~ ARINcli::IP6_ARPA )
          raise ArgumentError.new( "#{@config.options.argv[ 0 ]} does not appear to be a valid reverse delegation name." )
        end
        reg = ARINcli::Registration::RegistrationService.new @config, ARINcli::RDNS_TX_PREFIX
        element = reg.get_poc( @config.options.argv[ 0 ] )
        if element
          file_name = @config.make_file_name( ARINcli::EDIT_RDNS_FILE )
          rdns = ARINcli::Registration.element_to_rdns( element )
          file = File.new( file_name, "w" )
          file.puts( ARINcli::Registration.zones_to_template( rdns ) )
          file.close
          @config.logger.trace( "#{@config.options.argv[ 0 ]} saved to #{file_name}" )
          editor = ARINcli::Editor.new(@config)
          edited = editor.edit( file_name )
          if ! edited
            @config.logger.mesg( "No changes were made to the RDNS template. Aborting." )
            return
          else
            file = File.new( file_name, "r")
            data = file.read
            file.close
            zones = ARINcli::Registration::yaml_to_zones( data )
            zones.each do |rdns|
              @config.logger.mesg( "Modifying reverse DNS delegation #{rdns.name}")
              rdns_element = ARINcli::Registration::rdns_to_element( rdns )
              send_data = ARINcli::pretty_print_xml_to_s( rdns_element )
              reg.modify_rdns( rdns.name, send_data )
            end
          end
        else
          raise ArgumentError.new( "Unable to parse answer from server for #{@config.options.argv[ 0 ]}" )
        end
      end

      def do_modify_zonefile
        zones = ARINcli::Registration::Zones.new
        @config.options.argv.each do |arg|
          @config.logger.mesg( "Parsing #{arg}.")
          file = File.new( arg, "r" )
          zf = Zonefile.new( file.read )
          zf.ns.each do |ns|
            zones.add_ns ns
          end
          zf.ds.each do |ds|
            zones.add_ds ds
          end
          file.close
          ds_filename = File.join( File.dirname( arg ) , "dsset-" + File.basename( arg ) )
          if File.exists?( ds_filename )
            @config.logger.mesg( "Parsing #{arg}.")
            file = File.new( ds_filename, "r" )
            zf = Zonefile.new( file.read )
            zf.ns.each do |ns|
              zones.add_ns ns
            end
            zf.ds.each do |ds|
                zones.add_ds ds
            end
            file.close
          end
          file_name = @config.make_file_name( ARINcli::MODIFY_RDNS_FILE )
          file = File.new( file_name, "w" )
          file.puts( ARINcli::Registration.zones_to_template( rdns ) )
          file.close
          @config.logger.trace( "Zone information saved to #{file_name}" )
          if ! @config.options.no_verify
            editor = ARINcli::Editor.new(@config)
            editor.edit( file_name )
          end
          file = File.new( file_name, "r")
          data = file.read
          file.close
          zones = ARINcli::Registration::yaml_to_zones( data )
          reg = ARINcli::Registration::RegistrationService.new @config, ARINcli::RDNS_TX_PREFIX
          zones.each do |rdns|
            @config.logger.mesg( "Modifying reverse DNS delegation #{rdns.name}")
            rdns_element = ARINcli::Registration::rdns_to_element( rdns )
            send_data = ARINcli::pretty_print_xml_to_s( rdns_element )
            reg.modify_rdns( rdns.name, send_data )
          end
        end
      end

    end

  end

end
