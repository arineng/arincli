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
require 'ticket_reg'
require 'data_tree'

module ARINcli

  module Registration

    class ReportsMain < ARINcli::BaseOpts

      class ReportType < ARINcli::Enum

        ReportType.add_item :WHOWAS_NET, "WHOWAS_NET"
        ReportType.add_item :WHOWAS_ASN, "WHOWAS_ASN"
        ReportType.add_item :ASSOCIATIONS, "ASSOCIATIONS"
        ReportType.add_item :REASSIGNMENT, "REASSIGNMENT"

      end

      def initialize args, config = nil

        if config
          @config = config
        else
          @config = ARINcli::Config.new( ARINcli::Config::formulate_app_data_dir() )
        end

        @opts = OptionParser.new do |opts|

          opts.banner = "Usage: arinreports [options] --type REPORT_TYPE [REPORT_KEY]"

          opts.separator ""
          opts.separator "Report Options:"

          opts.on( "--type",
                   "Specifies the type of report to request.",
                   "  whowas_net - Who Was report on an IP network by IP address",
                   "  whowas_asn - Who Was report on an Autonomous System number",
                   "  associations - ARIN user associations report",
                   "  reassignment - Network reassignments by NET handle") do |report_type|
            uptype = type.upcase
            raise OptionParser::InvalidArgument, type.to_s unless ReportType.has_value?( uptype )
            @config.options.report_type = uptype
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
          if !@config.options.report_type && !@config.options.help
            raise OptionParser::InvalidArgument, "You must specify --type."
          end
          if ! args[ 0 ] && ! @config.options.report_type == ReportType::ASSOCIATIONS
            raise OptionParser::InvalidArgument, "You must specify a report key."
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

        exit_code = 0
        begin
          if @config.options.argv[ 0 ] =~ ARINcli::DATA_TREE_ADDR_REGEX
            tree = @config.load_as_yaml( ARINcli::ARININFO_LASTTREE_YAML )
            handle = tree.find_handle( @config.options.argv[ 0 ] )
            raise ArgumentError.new( "Unable to find report key for " + @config.options.argv[ 0 ] ) unless handle
            @config.options.argv[ 0 ] = handle
          end
          reg = ARINcli::Registration::RegistrationService.new @config, ARINcli::REPORTS_TX_PREFIX
          request_report_type = nil
          case @config.options.report_type
            when ReportType::WHOWAS_NET
              request_report_type = ARINcli::Registration::ReportType::WHOWAS_NET
            when ReportType::WHOWAS_ASN
              request_report_type = ARINcli::Registration::ReportType::WHOWAS_ASN
            when ReportType::ASSOCIATIONS
              request_report_type = ARINcli::Registration::ReportType::ASSOCIATIONS
            when ReportType::REASSIGNMENT
              request_report_type = ARINcli::Registration::ReportType::REASSIGNMENT
          end
          element = reg.get_report( request_report_type, @config.options.argv[ 0 ] )
          if element
            ticket = ARINcli::Registration::element_to_ticket element
            raise ArgumentError.new( "Unable to get ticket for report." ) if ! ticket
            @config.logger.mesg( "Report has been assigned ticket number #{ticket.ticket_no}" )
            @config.logger.mesg( "Use the 'ticket' command to retrieve the report when it has been completed." )
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

This program uses ARIN's Reg-RWS RESTful API to request reports from ARIN.

The --type options specifies the types of report to request. Some reports
require a report key argument.

Ex. --type whowas_net 192.168.0.0 will request an ARIN Who Was report for
the networks encompassing IP address 192.168.0.0.

Ex. --type whowas_asn 10745 will request an ARIN Who Was report for the
autonomous system number 10745

Ex. --type associations will request an ARIN associations report for the
related POCs, Organizations, and network resources of the ARIN user associated
with the requesting API Key. No report key is required for this report type.

Ex. --type reassignments NET-192-136-136-0-1 will request a reassignments
report for the network denoted by handle NET-192-136-136-0-1.

ARIN reports are assigned tickets numbers, and the ticket command can be
used to retrieve the reports once they have been prepared.

HELP_SUMMARY
        puts @opts.help
        exit

      end

    end

  end

end
