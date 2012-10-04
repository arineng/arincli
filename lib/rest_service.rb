# Copyright (C) 2011,2012 American Registry for Internet Numbers

require 'net/http'
require 'net/https'
require 'uri'
require 'constants'

module ARINr

  class RestService

    def initialize
      @headers = { "User-Agent" => ARINr::VERSION, "Content-Type" => "application/xml" }
    end

    def get url
      uri = URI.parse( url.to_s )
      http = make_http( uri )
      resp = http.get( uri.to_s, @headers )
      return resp
    end

    def get_stream url, io
      uri = URI.parse( url.to_s )
      http = make_http( uri )
      resp = http.get( uri.to_s, @headers ) do |str|
        io.write str
      end
      return resp
    end

    def post url, send_data
      uri = URI.parse( url.to_s )
      http = make_http( uri )
      resp = http.post( uri.to_s, send_data, @headers )
      return resp
    end

    def put url, send_data
      uri = URI.parse( url.to_s )
      http = make_http( uri )
      resp = http.put( uri.to_s, send_data, @headers )
      return resp
    end

    def delete url
      uri = URI.parse( url.to_s )
      http = make_http( uri )
      resp = http.delete( uri.to_s, @headers )
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
