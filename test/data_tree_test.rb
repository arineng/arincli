# Copyright (C) 2011 American Registry for Internet Numbers

require 'test/unit'
require 'arinr_logger'
require 'stringio'
require 'data_tree'

class DataTreeTest < Test::Unit::TestCase

  def test_to_log

    #setup the logger
    logger = ARINr::Logger.new
    logger.data_out = StringIO.new
    logger.data_amount = ARINr::DataAmount::EXTRA_DATA

    #do a tree
    tree = ARINr::DataTree.new

    #create the first root
    root1 = ARINr::DataNode.new( "first root" )
    root1.add_child( ARINr::DataNode.new( "first child of first root" ) )
    root1.add_child( ARINr::DataNode.new( "second child of first root" ) )

    #create the second root
    root2 = ARINr::DataNode.new( "second root" )
    r2c1 = ARINr::DataNode.new( "first child of second root" )
    r2c1.add_child( ARINr::DataNode.new(" first child of first child of second root" ) )
    r2c1.add_child( ARINr::DataNode.new(" second child of first child of second root" ) )
    root2.add_child( r2c1 )
    root2.add_child( ARINr::DataNode.new( "second child of second root" ) )
    r2c3 = ARINr::DataNode.new( "third child of second root" )
    r2c3c1 = ARINr::DataNode.new( "first child of third child of second root" )
    r2c3c1.add_child( ARINr::DataNode.new(" first child of first child of third child of second root" ) )
    r2c3c1.add_child( ARINr::DataNode.new(" second child of first child of third child of second root" ) )
    r2c3c1.add_child( ARINr::DataNode.new(" third child of first child of third child of second root" ) )
    r2c3.add_child( r2c3c1 )
    r2c3.add_child( ARINr::DataNode.new(" second child of third child of second root" ) )
    r2c3.add_child( ARINr::DataNode.new(" third child of third child of second root" ) )
    root2.add_child( r2c3 )
    r2c4 = ARINr::DataNode.new( "fourth child of second root" )
    r2c4.add_child( ARINr::DataNode.new(" first child of fourth child of second root" ) )
    r2c4.add_child( ARINr::DataNode.new(" second child of fourth child of second root" ) )
    r2c4.add_child( ARINr::DataNode.new(" third child of fourth child of second root" ) )
    root2.add_child( r2c4 )

    #create the third root
    root3 = ARINr::DataNode.new( "third root" )
    root3.add_child( ARINr::DataNode.new( "first child of third root" ) )
    root3.add_child( ARINr::DataNode.new( "second child of third root" ) )

    tree.add_root( root1 )
    tree.add_root( root2 )
    tree.add_root( root3 )

    tree.to_extra_log( logger )

    expected = <<EXPECTED_LOG
first root
  |- first child of first root
  `- second child of first root
second root
  |- first child of second root
  |  |-  first child of first child of second root
  |  `-  second child of first child of second root
  |- second child of second root
  |- third child of second root
  |  |- first child of third child of second root
  |  |  |-  first child of first child of third child of second root
  |  |  |-  second child of first child of third child of second root
  |  |  `-  third child of first child of third child of second root
  |  |-  second child of third child of second root
  |  `-  third child of third child of second root
  `- fourth child of second root
     |-  first child of fourth child of second root
     |-  second child of fourth child of second root
     `-  third child of fourth child of second root
third root
  |- first child of third root
  `- second child of third root
EXPECTED_LOG

    assert_equal( expected, logger.data_out.string )

  end

end