# Copyright (C) 2011 American Registry for Internet Numbers

require 'rexml/document'
require "utils"
require "config"

module ARINr

  module Registration

    class TicketSummary
      attr_accessor :ticket_no, :created_date, :resolved_date, :closed_date, :updated_date
      attr_accessor :ticket_type, :ticket_status, :ticket_resolution
    end

    class TicketMessage
      attr_accessor :subject, :text, :category
    end

    def Registration::element_to_ticket_summary element
      ticket = ARINr::Registration::TicketSummary.new
      ticket.ticket_no=element.elements[ "ticketNo" ].text
      ticket.created_date=element.elements[ "createdDate" ].text
      ticket.resolved_date=element.elements[ "resolvedDate" ].text if element.elements[ "resolvedDate" ]
      ticket.closed_date=element.elements[ "closedDate" ].text if element.elements[ "closedDate" ]
      ticket.updated_date=element.elements[ "updatedDate" ].text if element.elements[ "updatedDate" ]
      ticket.ticket_type=element.elements[ "webTicketType" ].text
      ticket.ticket_status=element.elements[ "webTicketStatus" ].text
      ticket.ticket_resolution=element.elements[ "webTicketResolution" ].text if element.elements[ "webTicketResolution" ]
      return ticket
    end

    def Registration::ticket_summary_to_element ticket_summary
      element = REXML::Element.new( "ticket" )
      element.add_namespace( "http://www.arin.net/regrws/core/v1" )
      element.add_element( ARINr::new_element_with_text( "ticketNo", ticket_summary.ticket_no ) )
      element.add_element( ARINr::new_element_with_text( "createdDate", ticket_summary.created_date ) )
      element.add_element( ARINr::new_element_with_text( "resolvedDate", ticket_summary.resolved_date ) ) if ticket_summary.resolved_date
      element.add_element( ARINr::new_element_with_text( "closedDate", ticket_summary.closed_date ) ) if ticket_summary.closed_date
      element.add_element( ARINr::new_element_with_text( "updatedDate", ticket_summary.updated_date ) ) if ticket_summary.updated_date
      element.add_element( ARINr::new_element_with_text( "webTicketType", ticket_summary.ticket_type ) )
      element.add_element( ARINr::new_element_with_text( "webTicketStatus", ticket_summary.ticket_status ) )
      element.add_element( ARINr::new_element_with_text( "webTicketResolution", ticket_summary.ticket_resolution ) ) if ticket_summary.ticket_resolution
      return element
    end

    def Registration::element_to_ticket_message element
      message = ARINr::Registration::TicketMessage.new
      message.subject=element.elements[ "subject" ].text
      message.text=[]
      element.elements.each( "text/line" ) do |line|
        message.text << line.text
      end
      message.category=element.elements[ "category" ].text if element.elements[ "category" ]
      return message
    end

    def Registration::ticket_message_to_element ticket_message
      element = REXML::Element.new( "message" )
      element.add_namespace( "http://www.arin.net/regrws/core/v1" )
      element.add_element( ARINr::new_element_with_text( "subject", ticket_message.subject ) )
      element.add_element( ARINr::new_number_wrapped_element( "text", ticket_message.text ) )
      element.add_element( ARINr::new_element_with_text( "category", ticket_message.category ) ) if ticket_message.category
      return element
    end

    # Handles storage of the tickets
    class TicketStorageManager

      SUMMARY_FILE_SUFFIX = "_summary.xml"

      def initialize config
        @config = config
      end

      def get_ticket_summary ticket_no
        file_name = File.join( @config.tickets_dir, ticket_no + SUMMARY_FILE_SUFFIX )
        if File.exist?( file_name )
          @config.logger.trace( "Reading stored ticket summary from " + file_name );
          f = File.open( file_name, "r" )
          data = ''
          f.each_line do |line|
            data += line
          end
          f.close
          doc = REXML::Document.new( data )
          return ARINr::Registration::element_to_ticket_summary doc.root
        end
        return nil
      end

      def put_ticket_summary ticket_summary
        file_name = File.join( @config.tickets_dir, ticket_summary.ticket_no + SUMMARY_FILE_SUFFIX )
        @config.logger.trace( "Storing ticket summary to " + file_name )
        element = ARINr::Registration::ticket_summary_to_element( ticket_summary )
        xml_as_s = ARINr::pretty_print_xml_to_s( element )
        f = File.open( file_name, "w" )
        f.puts xml_as_s
        f.close
      end

      def put_ticket_message ticket_no, ticket_message
        if( ticket_no.is_a?( ARINr::Registration::TicketSummary ) )
          ticket_no = ticket_no.ticket_no
        end
        ticket_area = File.join( @config.tickets_dir, ticket_no )
        if ! File.exist?( ticket_area )
          Dir.mkdir( ticket_area )
        end
        file_name =
          File.join( @config.tickets_dir,
                     ticket_no, ARINr::make_safe( ticket_message.subject + ".xml" ) )
        @config.logger.trace( "Storing ticket message to " + file_name )
        element = ARINr::Registration::ticket_message_to_element( ticket_message )
        xml_as_s = ARINr::pretty_print_xml_to_s( element )
        f = File.open( file_name, "w" )
        f.puts xml_as_s
        f.close
      end

    end

  end

end
