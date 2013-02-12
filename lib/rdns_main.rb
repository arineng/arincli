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
          if args[ 0 ] =~ ARINcli::DATA_TREE_ADDR_REGEX
            tree = @config.load_as_yaml( ARINcli::ARININFO_LASTTREE_YAML )
            handle = tree.find_handle( args[ 0 ] )
            raise ArgumentError.new( "Unable to find reverse delegation name for " + args[ 0 ] ) unless handle
            args[ 0 ] = handle
          end
          if ! ( args[ 0 ] =~ ARINcli::IP4_ARPA && args[ 0 ] =~ ARINcli::IP6_ARPA )
            raise ArgumentError.new( "#{args[0]} does not appear to be a valid reverse delegation name." )
          end
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

    end

  end

end
