# Copyright (C) 2011 American Registry for Internet Numbers

require 'test/unit'
require 'cache'


class CacheTests < Test::Unit::TestCase

  def test_make_safe

    assert_equal( ARINr::Whois::Cache.make_safe( "http://" ), "http%3A%2F%2F" )
    assert_equal( ARINr::Whois::Cache.make_safe(
                          "http://whois.arin.net/rest/nets;q=192.136.136.1?showDetails=true&showARIN=false" ),
                  "http%3A%2F%2Fwhois.arin.net%2Frest%2Fnets%3Bq%3D192.136.136.1%3FshowDetails%3Dtrue%26showARIN%3Dfalse")

  end

end

