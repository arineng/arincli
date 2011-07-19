# Copyright (C) 2011 American Registry for Internet Numbers

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

    class TicketMessage
      attr_accessor :subject, :text, :category
      attr_accessor :attachments

      def get_id
        s = ""
        s << @text.join if ! @text.empty?
        s << @category if ! @category
        @attachments.each do |attachment|
          s << attachment.file_name
        end if @attachments
        return s.hash
      end

      def get_id_safe_s
        id = get_id
        ARINr::make_safe( format( "%0X", id ) )
      end
    end

    class TicketAttachment
      attr_accessor :file_name, :temp_file_name
    end

    def Registration::element_to_ticket_summary element
      ticket = ARINr::Registration::Ticket.new
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

    # Handles storage of the tickets.
    # The directory structure is thusly:
    # config_dir
    #  |-- tickets
    #       |-- message1_summary.xml
    #       |-- message2_summary.xml
    #       |-- message2
    #            |-- attachment1
    #            |-- attachment2
    class TicketStorageManager

      SUMMARY_FILE_SUFFIX = "_summary.xml"

      def initialize config
        @config = config
      end

      def get_ticket_summary ticket_no
        if( ticket_no.is_a?( ARINr::Registration::Ticket ) )
          ticket_no = ticket_no.ticket_no
        end
        base_name = ticket_no + SUMMARY_FILE_SUFFIX
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
        if( ticket_no.is_a?( ARINr::Registration::Ticket ) )
          ticket_no = ticket_no.ticket_no
        end
        prepare_ticket_area(ticket_no)
        file_name =
          File.join( @config.tickets_dir, ticket_no, ticket_message.get_id_safe_s + ".xml" )
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

      def prepare_file_attachment ticket_no, ticket_message, attachment_name
        if( ticket_no.is_a?( ARINr::Registration::Ticket ) )
          ticket_no = ticket_no.ticket_no
        end
        prepare_ticket_area(ticket_no)
        file_name =
            File.join( @config.tickets_dir, ticket_no, ticket_message.get_id_safe_s )
        Dir.mkdir( file_name )
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

    class TicketStreamListener

      def initialize config
        @config = config
        @mgr = TicketStorageManager.new config
        @text_accumulators = [ "ticketNo", "createdDate", "updatedDate", "resolvedDate",
                               "closedDate", "webTicketStatus", "webTicketResolution", "webTicketType", "subject",
                               "line", "category", "filename" ]
      end

      def tag_start name, attrs
        if name == "ticket"
          @ticket = ARINr::Registration::Ticket.new
          @ticket.messages=[]
        elsif name == "message"
          @message = ARINr::Registration::TicketMessage.new
          @message.text=[]
          @message.attachments=[]
          @ticket.messages << @message
        elsif name == "data"
          @data_file = Tempfile.new "ticket_stream"
          @data_file.binmode
          attachment = ARINr::Registration::TicketAttachment.new
          attachment.temp_file_name=@data_file.path
          @message.attachments << attachment
          @data_accumulator = ""
          @accumulate_data = true
        elsif @text_accumulators.index( name )
          @accumulate_text = true
          @text_accumulator = ""
        end
      end
      def tag_end name
        case name
          when "ticketNo"
            @ticket.ticket_no=@text_accumulator
            @accumulate_text=false
          when "createdDate"
            @ticket.created_date=@text_accumulator
            @accumulate_text=false
          when "updatedDate"
            @ticket.updated_date=@text_accumulator
            @accumulate_text=false
          when "resolvedDate"
            @ticket.resolved_date=@text_accumulator
            @accumulate_text=false
          when "closedDate"
            @ticket.closed_date=@text_accumulator
            @accumulate_text=false
          when "webTicketStatus"
            @ticket.ticket_status=@text_accumulator
            @accumulate_text=false
          when "webTicketResolution"
            @ticket.ticket_resolution=@text_accumulator
            @accumulate_text=false
          when "webTicketType"
            @ticket.ticket_type=@text_accumulator
            @accumulate_text=false
          when "subject"
            @message.subject=@text_accumulator
            @accumulate_text=false
          when "line"
            @message.text << @text_accumulator
            @accumulate_text=false
          when "category"
            @message.category=@text_accumulator
            @accumulate_text=false
          when "filename"
            @message.attachments.last.file_name = @text_accumulator
            @accumulate_text=false
          when "ticket"
            @mgr.put_ticket_summary @ticket
            @ticket.messages.each do |message|
              @mgr.put_ticket_message @ticket, message
              message.attachments.each do |attachment|
                dest = @mgr.prepare_file_attachment @ticket, message, attachment.file_name
                @config.logger.trace( "Extracting " + attachment.file_name + " file attachment" )
                FileUtils.move attachment.temp_file_name, dest
              end if message.attachments
            end if @ticket.messages
          when "data"
            if @data_accumulator.length > 0
              @data_file.write( Base64::decode64( @data_accumulator ) )
            end
            @accumulate_data = false
            @data_file.close
        end
      end
      def text text
        if @accumulate_text
          @text_accumulator << text
        elsif @accumulate_data
          @data_accumulator << text
          if @data_accumulator.length % 4 == 0
            @data_file.write( Base64::decode64( @data_accumulator ) )
            @data_accumulator = ""
          elsif @data_accumulator.length > 1024
            @data_file.write( Base64::decode64( @data_accumulator[0..1023] ) )
            @data_accumulator = @data_accumulator[ 1024..-1]
          end
        end
      end
      def instruction name, instruction
      end
      def comment comment
      end
      def doctype name, pub_sys, long_name, uri
      end
      def doctype_end
      end
      def attlistdecl element_name, attributes, raw_content
      end
      def elementdecl content
      end
      def entitydecl content
      end
      def notationdecl content
      end
      def entity content
      end
      def cdata content
      end
      def xmldecl version, encoding, standalone
      end

    end

  end

end
