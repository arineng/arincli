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


require 'rest_service'
require 'config'
require 'uri'
require 'rexml/document'
require 'utils'

module ARINcli

  module Registration

    class RegistrationService < ARINcli::RestService

      def initialize config, log_suffix=nil
        super()
        @config = config
        @log_suffix = log_suffix
      end

      def get_poc poc_handle
        uri = poc_service_uri
        uri.path << poc_handle
        uri = add_api_key( uri )
        begin_log "GET", uri
        handle_resp( get( uri ), uri )
      end

      def create_poc data
        uri = URI.parse @config.config[ "registration" ][ "url" ]
        uri.path <<= "/rest/poc;makeLink=true"
        uri = add_api_key( uri )
        begin_log "POST", uri, data
        resp = post( uri, data )
        handle_resp( resp, uri )
      end

      def modify_poc poc_handle, data
        uri = poc_service_uri
        uri.path << poc_handle
        uri = add_api_key( uri )
        begin_log "PUT", uri, data
        resp = put( uri, data )
        handle_resp( resp, uri )
      end

      def delete_poc poc_handle
        uri = poc_service_uri
        uri.path << poc_handle
        uri = add_api_key( uri )
        begin_log "DELETE", uri
        resp = delete( uri )
        handle_resp( resp, uri )
      end

      def get_ticket_summary ticket_no = nil
        uri = ticket_summary_uri ticket_no
        uri = add_api_key( uri )
        begin_log "GET", uri
        handle_resp( get( uri), uri )
      end

      def put_ticket_message ticket_no, data
        uri = ticket_uri ticket_no, false
        uri.path << "/message"
        uri = add_api_key( uri )
        begin_log "PUT", uri, data
        resp = put( uri, data )
        handle_resp( resp, uri )
      end

      def get_data uri
        uri = add_api_key( uri )
        begin_log "GET", uri
        handle_resp( get( uri), uri )
      end

      def get_data_as_stream uri, io
        uri = add_api_key( uri )
        get_stream( uri, io )
      end

      def begin_log verb, uri, data=nil
        if @log_suffix
          file_name = @config.make_file_name( @log_suffix + "_tx.log" )
          @log_file = File.new( file_name, "w" )
          @log_file.puts verb + " : " + uri.to_s
          if( data )
            @log_file.puts
            @log_file.puts "===BEGIN SEND DATA===="
            @log_file.puts data
            @log_file.puts "===END SEND DATA===="
          else
            @log_file.puts
            @log_file.puts "===NO SEND DATA===="
          end
        end
      end

      def end_log data=nil
        if @log_suffix
          if data
            if data.kind_of?( REXML::Node)
              data = ARINcli::pretty_print_xml_to_s( data )
            end
            @log_file.puts
            @log_file.puts "===BEGIN RETURN DATA===="
            @log_file.puts data
            @log_file.puts "===END RETURN DATA===="
          else
            @log_file.puts
            @log_file.puts "===NO RETURN DATA===="
          end
          @log_file.close
        end
      end

      def add_api_key uri
        if uri.query
          uri.query << "&"
        else
          uri.query = ""
        end
        uri.query << "apikey=" + @config.config[ "registration" ][ "apikey" ]
        return uri
      end

      def add_msgrefs uri
        if uri.query
          uri.query << "&"
        else
          uri.query = ""
        end
        uri.query << "msgRefs=true"
        return uri
      end

      def poc_service_uri
        uri = URI.parse @config.config[ "registration" ][ "url" ]
        uri.path <<= "/rest/poc/"
        return uri
      end

      def ticket_summary_uri ticket_no = nil
        uri = URI.parse @config.config[ "registration" ][ "url" ]
        uri.path <<= "/rest/ticket/"
        uri.path << ticket_no + "/" if ticket_no
        uri.path << "summary"
        return uri
      end

      def ticket_uri ticket_no, msgRefs=true
        uri = URI.parse @config.config[ "registration" ][ "url" ]
        uri.path <<= "/rest/ticket/"
        uri.path << ticket_no
        uri = add_msgrefs( uri ) if msgRefs
        return uri
      end

      def ticket_message_uri ticket_no, message_id, msgRefs=true
        uri = URI.parse @config.config[ "registration" ][ "url" ]
        uri.path <<= "/rest/ticket/"
        uri.path << ticket_no
        uri.path << "/message/"
        uri.path << message_id
        uri = add_msgrefs( uri ) if msgRefs
        return uri
      end

      def ticket_attachment_uri ticket_no, message_id, attachment_id
        uri = URI.parse @config.config[ "registration" ][ "url" ]
        uri.path <<= "/rest/ticket/"
        uri.path << ticket_no
        uri.path << "/message/"
        uri.path << message_id
        uri.path << "/attachment/"
        uri.path << attachment_id
        return uri
      end

      def handle_resp resp, uri
        case resp.code
          when "200"
            retval = handle_expected( "200 OK", resp, uri )
          when "404"
            retval = handle_expected( "404 NOT FOUND", resp, uri )
          when "503"
            retval = handle_expected( "503 SERVICE UNAVAILABLE", resp, uri )
          when "400"
            retval = handle_expected( "400 BAD REQUEST", resp, uri )
          when "401"
            retval = handle_expected( "400 UNAUTHORIZED", resp, uri )
          else
            end_log resp.entity
            @config.logger.mesg( "ERROR: Service returned " + resp.code + " error for " + uri.to_s + "." )
            retval = nil
        end
        return retval
      end

      def handle_expected error, resp, uri
        element = get_root_element( resp )
        if element
          end_log element
        else
          end_log resp.entity
        end
        if ! element
          @config.logger.mesg( error + ": Received empty response entity for " + uri.to_s + "." )
        elsif is_in_error( element )
          @config.logger.trace( error + ": Service returned " + resp.code + " error for " + uri.to_s + "." )
        else
          return element
        end
        return nil
      end

      def get_root_element resp
        begin
          doc = REXML::Document.new( resp.entity )
          retval = doc.root
        rescue
        end
        return retval
      end

      def is_in_error element
        retval = false
        if element.name == "error"
          retval = true
          message = element.elements[ "message" ].text
          code = element.elements[ "code" ].text
          @config.logger.mesg( "ERROR: " + code + " : " + message )
          components = element.elements[ "components" ]
          components.elements.each( "component" ) do |component|
            name = component.elements[ "name" ].text
            message = component.elements[ "message" ].text
            @config.logger.mesg( "Component in error:" + name + " : " + message )
          end if components
          additional_info = element.elements[ "additionalInfo" ]
          additional_info.elements.each( "message" ) do |message|
            @config.logger.mesg( "Additional Error Information: " + message.text )
          end if additional_info
        end
        return retval
      end

    end

  end

end
