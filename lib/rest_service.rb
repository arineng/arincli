# Copyright (C) 2011 American Registry for Internet Numbers

require 'net/http'
require 'net/https'
require 'config'
require 'uri'

module ARINr

  class RestService

    def initialize config
      @config = config
    end

    def get url
      uri = URI.parse( url.to_s )
      http = make_http( uri )
      resp,data = http.get( uri.path + uri.query )
      return resp, data
    end

    def post url, send_data
      uri = URI.parse( url.to_s )
      http = make_http( uri )
      headers = {'Content-Type'=> 'text/xml'}
      resp,data = http.post( uri.path + uri.query, send_data, headers )
      return resp, data
    end

    def put url, send_data
      uri = URI.parse( url.to_s )
      http = make_http( uri )
      headers = {'Content-Type'=> 'text/xml'}
      resp,data = http.put( uri.path + uri.query, send_data, headers )
      return resp, data
    end

    def delete url
      uri = URI.parse( url.to_s )
      http = make_http( uri )
      resp = http.delete( uri.path + uri.query, headers )
      return resp
    end

    private

    def make_http uri
      http = Net::HTTP.new( uri.host, uri.port )
      http.use_ssl = uri.instance_of? URI::HTTPS
      return http
    end

  end

end
