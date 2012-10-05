# Copyright (C) 2011,2012 American Registry for Internet Numbers
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

    ticket = ARINr::Registration::Ticket.new
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

    ticket = ARINr::Registration::Ticket.new
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

  def test_ticket_stream_listener

    dir = File.join( @work_dir, "test_ticket_stream_listener" )
    c = ARINr::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    file = File.new( File.join( File.dirname( __FILE__ ) , "test-ticket.xml" ), "r" )
    listener = ARINr::Registration::TicketStreamListener.new c
    REXML::Document.parse_stream( file, listener )

    mgr = ARINr::Registration::TicketStorageManager.new c
    ticket = mgr.get_ticket_summary "20110718-X21"
    assert_not_nil ticket
    assert_equal( "2011-07-18T15:42:27-04:00", ticket.created_date )
    assert_equal( "20110718-X21", ticket.ticket_no )
    assert_equal( "2011-07-18T17:30:07-04:00", ticket.updated_date )
    assert_equal( "ASSIGNED", ticket.ticket_status )
    assert_equal( "ORG_CREATE", ticket.ticket_type )
    message_entries = mgr.get_ticket_message_entries( ticket )
    assert_equal( 3, message_entries.size )
    the_one_attachment = nil
    message_entries.each do |entry|
      attachments = mgr.get_attachment_entries entry
      the_one_attachment = attachments[ 0 ] if attachments
    end
    assert_not_nil( the_one_attachment )
    assert( File.exist?( the_one_attachment ) )
    assert_equal( "urnbis-ietf80-minutes.pdf", File.basename( the_one_attachment ) )
    assert_equal( 20620, File.size?( the_one_attachment ) )
  end

end
