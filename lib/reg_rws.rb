# Copyright (C) 2011 American Registry for Internet Numbers

require 'rest_service'
require 'config'
require 'uri'
require 'rexml/document'

module ARINr

  module Registration

    class RegistrationService < ARINr::RestService

      def initialize config
        super
        @config = config
      end

      def get_poc poc_handle
        uri = poc_service_uri
        uri.path << poc_handle
        uri = add_api_key( uri )
        handle_resp( get( uri ), uri )
      end

      def create_poc data
        uri = poc_service_uri
        uri = add_api_key( uri )
        resp = post( uri, data )
        handle_resp( resp, uri )
      end

      def modify_poc poc_handle, data
        uri = poc_service_uri
        uri.path << poc_handle
        uri = add_api_key( uri )
        resp = put( uri, data )
        handle_resp( resp, uri )
      end

      def delete_poc poc_handle
        uri = poc_service_uri
        uri.path << poc_handle
        uri = add_api_key( uri )
        resp = delete( uri )
        handle_resp( resp, uri )
      end

      def add_api_key uri
        uri.query << "&" unless uri.query
        uri.query << "apikey=" + @config.config[ "registration" ][ "apikey" ]
        return uri
      end

      def poc_service_uri
        uri = URI.parse @config.config[ "registration" ][ "url" ]
        uri.path <<= "/rest/poc/"
        return uri
      end

      def handle_resp resp, uri
        if resp.code == "200"
          element = get_root_element( resp )
          if ! element
            @config.logger.mesg( "ERROR: Received empty response entity for " + uri.to_s + "." )
          elsif is_in_error( element )
            @config.logger.mesg( "Error returned for " + uri.to_s + "." )
          else
            return element
          end
        elsif resp.code = "404"
          @config.logger.mesg( "NOT FOUND: Service returned " + resp.code + " error for " + uri.to_s + "." )
          element = get_root_element( resp )
          is_in_error( element ) if element
        elsif resp.code = "503"
          @config.logger.mesg( "SERVICE UNAVAILABLE: Service returned " + resp.code + " error for " + uri.to_s + "." )
          element = get_root_element( resp )
          is_in_error( element ) if element
        else
          @config.logger.mesg( "ERROR: Service returned " + resp.code + " error for " + uri.to_s + "." )
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
