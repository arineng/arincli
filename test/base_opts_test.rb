# Copyright (C) 2011 American Registry for Internet Numbers

require 'test/unit'
require 'ostruct'
require 'base_opts'
require 'config'
require 'arinr_logger'

class BaseOptsTest < Test::Unit::TestCase

  @work_dir = nil

  def setup

    @work_dir = Dir.mktmpdir

  end

  def teardown

    FileUtils.rm_r( @work_dir )

  end

  class ExtendBaseOpts < ARINr::BaseOpts

    def eval_opts( config, args )

      opts = OptionParser.new do |opts|

        opts.banner = "Usage: fake_example [options]"

        opts.separator ""
        opts.separator "Specific Options:"

        opts.on( "-r", "--require LIBRARY",
          "A LIBRARY is needed here" ) do |lib|
          config.options.required = lib
        end

        add_base_opts( opts, config )

      end

      opts.parse!( args )
      config.options.argv = args

    end

  end

  def test_base_opts

    dir = File.join( @work_dir, "test_base_opts" )
    c = ARINr::Config.new( dir )

    e = ExtendBaseOpts.new
    args = [ "--messages", "ALL", "-r", "FOO", "BAR" ]
    e.eval_opts( c, args )

    assert_equal( "ALL", c.logger.message_level.to_s )
    assert_equal( "FOO", c.options.required )
    assert_equal( [ "BAR" ], c.options.argv )

  end

  def test_help_option

    dir = File.join( @work_dir, "test_help_option" )
    c = ARINr::Config.new( dir )

    e = ExtendBaseOpts.new
    args = [ "-h" ]
    e.eval_opts( c, args )

    assert_equal( [], c.options.argv )
    assert( c.options.help )

  end

end

