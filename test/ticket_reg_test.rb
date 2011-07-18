# Copyright (C) 2011 American Registry for Internet Numbers

require 'test/unit'
require 'ticket_reg'
require 'rexml/document'
require 'tmpdir'
require 'fileutils'

class TicketRegTest < Test::Unit::TestCase

  @workd_dir = nil

  def setup

    @work_dir = Dir.mktmpdir

  end

  def teardown

    FileUtils.rm_r( @work_dir )

  end

  def test_element_to_ticket_summary

    ticket = ARINr::Registration::TicketSummary.new
    ticket.ticket_no="XB85"
    ticket.created_date="July 18, 2011"
    ticket.resolved_date="July 19, 2011"
    ticket.closed_date="July 20, 2011"
    ticket.updated_date="July 21, 2011"
    ticket.ticket_type="QUESTION"
    ticket.ticket_status="APPROVED"
    ticket.ticket_resolution="DENIED"

    element = ARINr::Registration::ticket_summary_to_element ticket

    ticket2 = ARINr::Registration::element_to_ticket_summary element

    assert_equal( "XB85", ticket2.ticket_no )
    assert_equal( "July 18, 2011", ticket2.created_date )
    assert_equal( "July 19, 2011", ticket2.resolved_date )
    assert_equal( "July 20, 2011", ticket2.closed_date )
    assert_equal( "July 21, 2011", ticket2.updated_date )
    assert_equal( "QUESTION", ticket2.ticket_type )
    assert_equal( "APPROVED", ticket2.ticket_status )
    assert_equal( "DENIED", ticket2.ticket_resolution )
  end

  def test_element_to_ticket_message

    message = ARINr::Registration::TicketMessage.new
    message.subject="Test"
    message.text=[ "This is line 1", "This is line 2" ]
    message.category="NONE"

    element = ARINr::Registration::ticket_message_to_element( message )

    message2 = ARINr::Registration::element_to_ticket_message( element )

    assert_equal( "Test", message2.subject )
    assert_equal( ["This is line 1", "This is line 2" ], message2.text )
    assert_equal( "NONE", message2.category )
  end

  def test_store_ticket_summary

    dir = File.join( @work_dir, "test_store_ticket_summary" )
    c = ARINr::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    mgr = ARINr::Registration::TicketStorageManager.new c

    ticket = ARINr::Registration::TicketSummary.new
    ticket.ticket_no="XB85"
    ticket.created_date="July 18, 2011"
    ticket.resolved_date="July 19, 2011"
    ticket.closed_date="July 20, 2011"
    ticket.updated_date="July 21, 2011"
    ticket.ticket_type="QUESTION"
    ticket.ticket_status="APPROVED"
    ticket.ticket_resolution="DENIED"

    mgr.put_ticket_summary ticket

    ticket2 = mgr.get_ticket_summary "XB85"

    assert_equal( "XB85", ticket2.ticket_no )
    assert_equal( "July 18, 2011", ticket2.created_date )
    assert_equal( "July 19, 2011", ticket2.resolved_date )
    assert_equal( "July 20, 2011", ticket2.closed_date )
    assert_equal( "July 21, 2011", ticket2.updated_date )
    assert_equal( "QUESTION", ticket2.ticket_type )
    assert_equal( "APPROVED", ticket2.ticket_status )
    assert_equal( "DENIED", ticket2.ticket_resolution )

  end

  def test_store_ticket_message

    dir = File.join( @work_dir, "test_store_ticket_summary" )
    c = ARINr::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    mgr = ARINr::Registration::TicketStorageManager.new c
    message = ARINr::Registration::TicketMessage.new
    message.subject="Test"
    message.text=[ "This is line 1", "This is line 2" ]
    message.category="NONE"

    mgr.put_ticket_message "XB85", message
  end

end
