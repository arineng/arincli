# Copyright (C) 2011 American Registry for Internet Numbers

require 'rest_service'
require 'config'
require 'uri'

module ARINr

  module Registration

    class RegistrationService < ARINr::RestService

      def get_poc poc_handle
        uri = poc_service_uri
        uri.path << poc_handle
        uri = add_api_key( uri )
        get uri
      end

      def modify_poc poc_handle, data
        uri = poc_service_uri
        uri.path << poc_handle
        uri = add_api_key( uri )
        put( uri, data )
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

    end

  end

end
