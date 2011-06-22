# Copyright (C) 2011 American Registry for Internet Numbers

require 'test/unit'
require 'common_names'

class CommonNamesTest < Test::Unit::TestCase

  def test_last_names

    assert_equal( true, ARINr::is_last_name( "JOHNSON") )
    assert_equal( true, ARINr::is_last_name( "NEWTON") )
    assert_equal( true, ARINr::is_last_name( "KOSTERS") )
    assert_equal( true, ARINr::is_last_name( "AALDERINK") )
    assert_equal( false, ARINr::is_last_name( "..........") )

  end

  def test_male_names

    assert_equal( true, ARINr::is_male_name( "JOHN" ) )
    assert_equal( true, ARINr::is_male_name( "JAMES" ) )
    assert_equal( true, ARINr::is_male_name( "ANDREW" ) )
    assert_equal( true, ARINr::is_male_name( "MARK" ) )
    assert_equal( false, ARINr::is_male_name( ".........." ) )

  end

  def test_female_names

    assert_equal( true, ARINr::is_female_name( "LINDA" ) )
    assert_equal( true, ARINr::is_female_name( "MARY" ) )
    assert_equal( true, ARINr::is_female_name( "GAIL" ) )
    assert_equal( true, ARINr::is_female_name( "ALLYN" ) )
    assert_equal( false, ARINr::is_female_name( "........" ) )

  end

end
