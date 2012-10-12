# Copyright (C) 2011,2012 American Registry for Internet Numbers
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


require 'rexml/document'
require 'rexml/streamlistener'
require "utils"
require "config"
require 'tempfile'
require 'base64'
require 'fileutils'

module ARINr

  module Registration

    class Ticket
      attr_accessor :ticket_no, :created_date, :resolved_date, :closed_date, :updated_date
      attr_accessor :ticket_type, :ticket_status, :ticket_resolution
      attr_accessor :messages
    end

    class TicketMessageRef
      attr_accessor :id
      attr_accessor :attachments
    end

    class TicketMessage
      attr_accessor :subject, :text, :category
      attr_accessor :attachments
      attr_accessor :id, :created_date
    end

    class TicketAttachment
      attr_accessor :file_name, :temp_file_name
      attr_accessor :id
    end

    def Registration::element_to_ticket element
      ticket = ARINr::Registration::Ticket.new
      ticket.ticket_no=element.elements[ "ticketNo" ].text
      ticket.created_date=element.elements[ "createdDate" ].text
      ticket.resolved_date=element.elements[ "resolvedDate" ].text if element.elements[ "resolvedDate" ]
      ticket.closed_date=element.elements[ "closedDate" ].text if element.elements[ "closedDate" ]
      ticket.updated_date=element.elements[ "updatedDate" ].text if element.elements[ "updatedDate" ]
      ticket.ticket_type=element.elements[ "webTicketType" ].text
      ticket.ticket_status=element.elements[ "webTicketStatus" ].text
      ticket.ticket_resolution=element.elements[ "webTicketResolution" ].text if element.elements[ "webTicketResolution" ]
      ticket.messages=[]
      element.elements.each( "messageReferences/messageReference" ) do |msgRef|
        ticket.messages << element_to_ticket_message_ref( msgRef )
      end
      return ticket
    end

    def Registration::ticket_to_element ticket_summary
      element = REXML::Element.new( "ticket" )
      element.add_namespace( "http://www.arin.net/regrws/core/v1" )
      element.add_namespace( "http://www.arin.net/regrws/messages/v1" )
      element.add_element( ARINr::new_element_with_text( "ticketNo", ticket_summary.ticket_no ) )
      element.add_element( ARINr::new_element_with_text( "createdDate", ticket_summary.created_date ) )
      element.add_element( ARINr::new_element_with_text( "resolvedDate", ticket_summary.resolved_date ) ) if ticket_summary.resolved_date
      element.add_element( ARINr::new_element_with_text( "closedDate", ticket_summary.closed_date ) ) if ticket_summary.closed_date
      element.add_element( ARINr::new_element_with_text( "updatedDate", ticket_summary.updated_date ) ) if ticket_summary.updated_date
      element.add_element( ARINr::new_element_with_text( "webTicketType", ticket_summary.ticket_type ) )
      element.add_element( ARINr::new_element_with_text( "webTicketStatus", ticket_summary.ticket_status ) )
      element.add_element( ARINr::new_element_with_text( "webTicketResolution", ticket_summary.ticket_resolution ) ) if ticket_summary.ticket_resolution
      if ticket_summary.messages && !ticket_summary.messages.empty?
        msg_ref_wrapper = REXML::Element.new( "messageReferences" )
        ticket_summary.messages.each do |msg_ref|
          msg_ref_wrapper.add_element( ticket_message_ref_to_element( msg_ref ) )
        end
        element.add_element( msg_ref_wrapper )
      end
      return element
    end

    def Registration::element_to_ticket_message_ref element
      ref = ARINr::Registration::TicketMessageRef.new
      ref.id=element.elements[ "messageId" ].text
      ref.attachments=[]
      element.elements.each( "attachmentReferences/attachmentReference" ) do |attachment|
        ref.attachments << element_to_ticket_attachment_ref( attachment )
      end
      return ref
    end

    def Registration::ticket_message_ref_to_element msg_ref
      element = REXML::Element.new( "messageReference" )
      element.add_element( ARINr::new_element_with_text( "messageId", msg_ref.id ) )
      if msg_ref.attachments && !msg_ref.attachments.empyt?
        attachment_wrapper = REXML::Element.new( "attachmentReferences" )
        msg_ref.attachments.each do |attachment_ref|
          attachment_wrapper.add_element( ticket_attachment_ref_to_element( attachment_ref ) )
        end
        element.add_element( attachment_wrapper )
      end
      return element
    end

    def Registration::element_to_ticket_attachment_ref element
      ref = ARINr::Registration::TicketAttachment.new
      ref.file_name=element.elements[ "attachmentFilename" ].text
      ref.id=element.elements[ "attachmentId" ].text
      return ref
    end

    def Registration::ticket_attachment_ref_to_element attachment_ref
      element = REXML::Element.new( "attachmentReference" )
      element.add_element( ARINr.new_element_with_text( "attachmentFilename", attachment_ref.file_name ) )
      element.add_element( ARINr.new_element_with_text( "attachmentId", attachment_ref.id ) )
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

    # Handles storage of the tickets.
    # The directory structure is thusly:
    # config_dir
    #  |-- tickets
    #       |-- ticketno_summary.xml
    #       |-- ticketno_msgrefs.xml
    #       |-- ticketno
    #            |-- message1.xml
    #            |-- message2.xml
    #            |-- message2
    #                 |-- attachment1
    #                 |-- attachment2
    class TicketStorageManager

      SUMMARY_FILE_SUFFIX = "_summary.xml"
      MSGREFS_FILE_SUFFIX = "_msgrefs.xml"

      def initialize config
        @config = config
      end

      def get_ticket ticket_no, suffix
        if( ticket_no.is_a?( ARINr::Registration::Ticket ) )
          ticket_no = ticket_no.ticket_no
        end
        base_name = ticket_no + suffix
        file_name = File.join( @config.tickets_dir, base_name )
        if File.exist?( file_name )
          @config.logger.trace( "Reading stored ticket summary from " + file_name );
          f = File.open( file_name, "r" )
          data = ''
          f.each_line do |line|
            data += line
          end
          f.close
          doc = REXML::Document.new( data )
          return ARINr::Registration::element_to_ticket doc.root
        end
        return nil
      end

      def put_ticket ticket, suffix
        file_name = File.join( @config.tickets_dir, ticket_summary.ticket_no + suffix )
        @config.logger.trace( "Storing ticket summary to " + file_name )
        element = ARINr::Registration::ticket_to_element( ticket_summary )
        xml_as_s = ARINr::pretty_print_xml_to_s( element )
        f = File.open( file_name, "w" )
        f.puts xml_as_s
        f.close
      end

      def get_ticket_entries suffix
        retval = []
        dir = Dir.new( @config.tickets_dir )
        dir.each do |file_name|
          retval << File.join( @config.tickets_dir, file_name ) if file_name.end_with?( suffix )
        end
        return retval
      end

      def get_tickets suffix
        entries = get_ticket_summary_entries suffix
        retval = []
        entries.each do |entry|
          ticket_no = File.basename( entry ).sub( suffix, "" )
          ticket = get_ticket_summary ticket_no
          retval << ticket if ticket
        end
        return retval
      end

      def put_ticket_message ticket_no, ticket_message
        if( ticket_no.is_a?( ARINr::Registration::Ticket ) )
          ticket_no = ticket_no.ticket_no
        end
        prepare_ticket_area(ticket_no)
        file_name =
          File.join( @config.tickets_dir, ticket_no, ticket_message.id + ".xml" )
        @config.logger.trace( "Storing ticket message to " + file_name )
        element = ARINr::Registration::ticket_message_to_element( ticket_message )
        xml_as_s = ARINr::pretty_print_xml_to_s( element )
        f = File.open( file_name, "w" )
        f.puts xml_as_s
        f.close
      end

      # returns an array of paths which can be used to get ticket messages
      # or to dive further down and get the attachments
      def get_ticket_message_entries ticket_no
        if( ticket_no.is_a?( ARINr::Registration::Ticket ) )
          ticket_no = ticket_no.ticket_no
        end
        ticket_area = prepare_ticket_area(ticket_no)
        retval = []
        dir = Dir.new( ticket_area )
        dir.each do |file_name|
          retval << File.join( ticket_area, file_name ) if file_name.end_with?( ".xml" )
        end
        return retval
      end

      def get_ticket_message message_entry
        f = File.open( message_entry, "r" )
        data = ''
        f.each_line do |line|
          data += line
        end
        f.close
        doc = REXML::Document.new( data )
        return ARINr::Registration::element_to_ticket_message( doc.root )
      end

      def prepare_file_attachment ticket_no, ticket_message, attachment_name
        if( ticket_no.is_a?( ARINr::Registration::Ticket ) )
          ticket_no = ticket_no.ticket_no
        end
        prepare_ticket_area(ticket_no)
        file_name =
            File.join( @config.tickets_dir, ticket_no, ticket_message.get_id_safe_s )
        Dir.mkdir( file_name ) if ! File.exist?( file_name )
        return File.join( file_name, ARINr::make_safe( attachment_name ) )
      end

      def get_attachment_entries ticket_message_entry
        message_dir = ticket_message_entry.sub( /\.xml$/, "" )
        if File.exist?( message_dir )
          retval = []
          dir = Dir.new( message_dir )
          dir.each do |file_name|
            path = File.join( message_dir, file_name )
            retval << path if File.file?( path )
          end
          return retval
        end
        return nil
      end

      private

      def prepare_ticket_area(ticket_no)
        ticket_area = File.join(@config.tickets_dir, ticket_no)
        if !File.exist?(ticket_area)
          Dir.mkdir(ticket_area)
        end
        return ticket_area
      end
    end

  end

end
