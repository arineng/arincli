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
require 'tempfile'
require 'uri'

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

          opts.on( "-c", "--check",
                   "Checks to see if a given ticket or all tickets have been updated." ) do |check|
            @config.options.check_ticket = true
          end

          opts.on( "-u", "--update",
                   "Downloads a given ticket if updated or all updated tickets." ) do |check|
            @config.options.update_ticket = true
          end

          opts.on( "-s", "--show",
                   "Shows information on a given ticket or summary of all tickets." ) do |check|
            @config.options.show_ticket = true
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
          @config.logger.run_pager
          check_tickets()
        elsif @config.options.update_ticket
          update_tickets()
        elsif @config.options.show_ticket
          @config.logger.run_pager
          show_tickets()
        else
          @config.logger.run_pager
          show_tickets()
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
        return updated
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

      def update_tickets
        updated = check_tickets
        reg = ARINr::Registration::RegistrationService.new @config
        updated.roots.each do |ticket|
          ticket_no = ticket.handle
          @config.logger.mesg( "Getting " + ticket_no )
          ticket_file = Tempfile.new "ticket_" + ticket_no
          resp = reg.get_ticket ticket_no, ticket_file
          ticket_file.close
          if resp.code == "200"
            @config.logger.mesg( "Processing " + ticket_no )
            listener = ARINr::Registration::TicketStreamListener.new @config
            source = File.new( ticket_file.path, "r" )
            REXML::Document::parse_stream( source, listener )
            source.close
          else
            @config.logger.mesg( "Error getting " + ticket_no )
          end
        end
      end

      def show_tickets
        mgr = ARINr::Registration::TicketStorageManager.new @config
        if @config.options.argv[ 0 ]
          ticket = mgr.get_ticket_summary @config.options.argv[ 0 ]
          if ! ticket
            @config.logger.mesg( "Ticket " + @config.options.argv[ 0 ] + " cannot be found." )
            return nil
          end
          @config.logger.start_data_item
          @config.logger.terse( "Ticket Number", ticket.ticket_no )
          @config.logger.terse( "Status", ticket.ticket_status )
          @config.logger.terse( "Resolution", ticket.ticket_resolution ) if ticket.ticket_resolution
          @config.logger.datum( "Type", ticket.ticket_type )
          @config.logger.extra( "Created", Time.parse( ticket.created_date ).rfc2822 ) if ticket.created_date
          @config.logger.extra( "Resolved", Time.parse( ticket.resolved_date ).rfc2822 ) if ticket.resolved_date
          @config.logger.datum( "Closed", Time.parse( ticket.closed_date ).rfc2822 ) if ticket.closed_date
          @config.logger.datum( "Updated", Time.parse( ticket.updated_date ).rfc2822 ) if ticket.updated_date
          message_entries = mgr.get_ticket_message_entries ticket
          @config.logger.extra( "Message Count", message_entries.size ) if message_entries
          @config.logger.end_data_item
          message_entries.each do |entry|
            message = mgr.get_ticket_message entry
            @config.logger.start_data_item
            log_banner "SUBJECT"
            if message.subject
              @config.logger.raw ARINr::DataAmount::TERSE_DATA, message.subject
            else
              @config.logger.raw ARINr::DataAmount::TERSE_DATA, "( NO SUBJECT )"
            end
            @config.logger.raw ARINr::DataAmount::EXTRA_DATA, message.category if message.category
            log_banner "BEGIN MESSAGE"
            message.text.each do |line|
              @config.logger.raw ARINr::DataAmount::TERSE_DATA, line
            end if message.text
            attachments = mgr.get_attachment_entries entry
            if attachments
              log_banner "ATTACHMENTS"
              attachments.each do |attachment|
                fn = URI.decode( File.basename( attachment ) )
                @config.logger.raw ARINr::DataAmount::TERSE_DATA, fn
              end
            end
            log_banner "END MESSAGE"
            @config.logger.end_data_item
          end if message_entries
        else
        end
      end

      def log_banner banner
        s = "== " + banner + " "
        (s.length..80).each {|x| s << "="}
        @config.logger.raw ARINr::DataAmount::TERSE_DATA, s
      end

    end

  end

end
