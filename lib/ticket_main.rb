# Copyright (C) 2011 American Registry for Internet Numbers

require 'optparse'
require 'rexml/document'
require 'base_opts'
require 'config'
require 'constants'
require 'reg_rws'
require 'ticket_reg'
require 'editor'
require 'data_tree'
require 'time'

module ARINr

  module Registration

    class TicketMain < ARINr::BaseOpts

      ARINT_LOG_SUFFIX = 'arint_summary'
      ARINT_UPDATED_TICKETS = 'arint_updated_tickets.yaml'

      def initialize args, config = nil

        if config
          @config = config
        else
          @config = ARINr::Config.new( ARINr::Config::formulate_app_data_dir() )
        end

        @opts = OptionParser.new do |opts|

          opts.banner = "Usage: arint [options] [TICKET_NO]"

          opts.separator ""
          opts.separator "Actions:"

          opts.on( "-C", "--check",
                   "Checks to see if a ticket has been updated." ) do |check|
            @config.options.check_ticket = true
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

        @config.logger.mesg( ARINr::VERSION )
        @config.setup_workspace

        if( @config.options.check_ticket )
          check_tickets()
        else
          check_tickets()
        end

        @config.logger.end_run

      end

      def help

        puts ARINr::VERSION
        puts ARINr::COPYRIGHT
        puts <<HELP_SUMMARY

This program uses ARIN's Reg-RWS RESTful API to query ARIN's Registration database.
The general usage is "arint TICKET_NO" where TICKET_NO is the identifier of the ticket
to be acted upon.

HELP_SUMMARY
        puts @opts.help
        exit

      end

      def check_tickets

        updated = ARINr::DataTree.new
        mgr = ARINr::Registration::TicketStorageManager.new @config

        reg = ARINr::Registration::RegistrationService.new @config, ARINT_LOG_SUFFIX
        element = reg.get_ticket_summary( @config.options.argv[ 0 ] )
        if ! element
          @config.logger.mesg( "Unable to get ticket summary information." )
        elsif element.name == "collection"
          element.elements.each( "ticket" ) do |ticket|
            check_ticket( ticket, updated, mgr )
          end
        elsif element.name == "ticket"
          check_ticket( element, updated, mgr )
        else
          @config.logger.mesg( "Unimplemented ticket check!" )
        end

        if !updated.empty?
          updated.to_terse_log( @config.logger, true )
          @config.save_as_yaml( ARINT_UPDATED_TICKETS, updated )
        else
          @config.logger.mesg( "No tickets have been updated." )
        end

      end

      def check_ticket( element, updated, mgr )
        ticket = ARINr::Registration.element_to_ticket_summary element
        s = format( "%-20s %-15s %-15s", ticket.ticket_no, ticket.ticket_type, ticket.ticket_status )
        ticket_node = ARINr::DataNode.new( s, ticket.ticket_no )
        stored_ticket = mgr.get_ticket_summary ticket
        if ! stored_ticket
          updated.add_root( ticket_node )
        else
          ticket_time = Time.parse( ticket.updated_date )
          stored_ticket_time = Time.parse( stored_ticket.updated_date )
          if stored_ticket_time < ticket_time
            updated.add_root( ticket_node )
          end
        end
      end

    end

  end

end
