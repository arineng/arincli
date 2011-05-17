# Copyright (C) 2011 American Registry for Internet Numbers

require 'tmpdir'
require 'fileutils'
require 'test/unit'
require 'config'
require 'arinr_logger'

class ConfigTest < Test::Unit::TestCase

  @work_dir = nil

  def setup

    @work_dir = Dir.mktmpdir

  end

  def teardown

    FileUtils.rm_r( @work_dir )

  end

  def test_init_no_config_file

    dir = File.join( @work_dir, "test_init_no_config_file" )

    c = ARINr::Config.new( dir )
    assert_equal( "SOME", c.config[ "output" ][ "messages" ] )
    assert_equal( "NORMAL", c.config[ "output" ][ "data" ] )
    assert_nil( c.config[ "output" ][ "messages_file" ] )
    assert_nil( c.config[ "output" ][ "data_file" ] )
    assert_equal( "http://whois.arin.net", c.config[ "whois" ][ "url" ] )

    assert_equal( "NORMAL", c.logger.data_amount )
    assert_equal( "SOME", c.logger.message_level )

  end

  def test_init_config_file

    dir = File.join( @work_dir, "test_init_config_file" )
    Dir.mkdir( dir )
    not_default_config = <<NOT_DEFAULT_CONFIG
output:
  messages: NONE
  #messages_file: /tmp/ARINr.messages
  data: TERSE
  #data_file: /tmp/ARINr.data
whois:
  url: http://whois.test.arin.net
NOT_DEFAULT_CONFIG
    f = File.open( File.join( dir, "config.yaml" ), "w" )
    f.puts( not_default_config )
    f.close

    c = ARINr::Config.new( dir )
    assert_equal( "NONE", c.config[ "output" ][ "messages" ] )
    assert_equal( "TERSE", c.config[ "output" ][ "data" ] )
    assert_nil( c.config[ "output" ][ "messages_file" ] )
    assert_nil( c.config[ "output" ][ "data_file" ] )
    assert_equal( "http://whois.test.arin.net", c.config[ "whois" ][ "url" ] )

    assert_equal( "TERSE", c.logger.data_amount )
    assert_equal( "NONE", c.logger.message_level )

  end

  def test_setup_workspace

    dir = File.join( @work_dir, "test_setup_workspace" )

    c = ARINr::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    assert( File.exist?( File.join( dir, "config.yaml" ) ) )
    assert( File.exist?( File.join( dir, "whois_cache" ) ) )
    assert_equal( File.join( dir, "whois_cache" ), c.whois_cache_dir )

  end

end
