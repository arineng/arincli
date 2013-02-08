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


require 'net/http'
require 'net/https'
require 'uri'
require 'constants'

module ARINcli

  class RestService

    def initialize
      @headers = { "User-Agent" => ARINcli::VERSION, "Content-Type" => "application/xml" }
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
