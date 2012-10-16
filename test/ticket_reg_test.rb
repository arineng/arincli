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

  def test_ticket_summary

    file = File.new( File.join( File.dirname( __FILE__ ) , "ticket-summary.xml" ), "r" )
    doc = REXML::Document.new( file )
    element = doc.root

    ticket = ARINr::Registration::element_to_ticket element
    assert_equal( "20121012-X1", ticket.ticket_no )
    assert_equal( "2012-10-12T11:39:36.724-04:00", ticket.created_date )
    assert_equal( "2012-10-12T11:39:36.724-04:00", ticket.updated_date )
    assert_equal( "PENDING_REVIEW", ticket.ticket_status )
    assert_equal( "QUESTION", ticket.ticket_type )

    element = ARINr::Registration::ticket_to_element ticket
    ticket = ARINr::Registration::element_to_ticket element
    assert_equal( "20121012-X1", ticket.ticket_no )
    assert_equal( "2012-10-12T11:39:36.724-04:00", ticket.created_date )
    assert_equal( "2012-10-12T11:39:36.724-04:00", ticket.updated_date )
    assert_equal( "PENDING_REVIEW", ticket.ticket_status )
    assert_equal( "QUESTION", ticket.ticket_type )

  end

  def test_ticket_message
    file = File.new( File.join( File.dirname( __FILE__ ) , "ticket_message.xml" ), "r" )
    doc = REXML::Document.new( file )
    element = doc.root

    message = ARINr::Registration::element_to_ticket_message element
    assert_equal( "NONE", message.category )
    assert_equal( "4", message.id )
    assert_equal( "2012-10-12T11:48:50.281-04:00", message.created_date )
    assert_equal( 2, message.text.size )
    assert_equal( "pleasee get back to me", message.text[0] )
    assert_equal( "you bone heads", message.text[1] )
    assert_equal( 1, message.attachments.size )
    assert_equal( "oracle-driver-license.txt", message.attachments[0].file_name )
    assert_equal( "8a8180b13a5597b1013a55a9d42f0007", message.attachments[0].id )

    element = ARINr::Registration::ticket_message_to_element message
    message = ARINr::Registration::element_to_ticket_message element
    assert_equal( "NONE", message.category )
    assert_equal( "4", message.id )
    assert_equal( "2012-10-12T11:48:50.281-04:00", message.created_date )
    assert_equal( 2, message.text.size )
    assert_equal( "pleasee get back to me", message.text[0] )
    assert_equal( "you bone heads", message.text[1] )
    assert_equal( 1, message.attachments.size )
    assert_equal( "oracle-driver-license.txt", message.attachments[0].file_name )
    assert_equal( "8a8180b13a5597b1013a55a9d42f0007", message.attachments[0].id )
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

    mgr.put_ticket ticket, ARINr::Registration::TicketStorageManager::SUMMARY_FILE_SUFFIX

    ticket2 = mgr.get_ticket "XB85", ARINr::Registration::TicketStorageManager::SUMMARY_FILE_SUFFIX

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
    message.id="4"

    mgr.put_ticket_message "XB85", message
  end

  def test_out_of_date_ticket
    # initialize ticket_tree_manager
    dir = File.join( @work_dir, "test_out_of_date" )
    c = ARINr::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace
    tree_mgr = ARINr::Registration::TicketTreeManager.new c

    # create a ticket and save it
    file = File.new( File.join( File.dirname( __FILE__ ) , "ticket-summary.xml" ), "r" )
    doc = REXML::Document.new( file )
    element = doc.root
    ticket = ARINr::Registration::element_to_ticket element
    tree_mgr.put_ticket ticket
    tree_mgr.save

    # initialize new ticket_tree_manager
    tree_mgr = ARINr::Registration::TicketTreeManager.new c

    # load ticket_tree_manager
    tree_mgr.load

    # compare ticket_node.updated_date to ticket_summary.updated_date
    out_of_date = tree_mgr.out_of_date?( ticket.ticket_no, ticket.updated_date )
    assert( out_of_date )

    # change ticket date to 2013 and check again
    ticket.updated_date="2013-10-12T11:48:50.303-04:00"
    out_of_date = tree_mgr.out_of_date?( ticket.ticket_no, ticket.updated_date )
    assert( !out_of_date )

    # now put the updated ticket in the tree manager and compare once more
    tree_mgr.put_ticket ticket
    out_of_date = tree_mgr.out_of_date?( ticket.ticket_no, ticket.updated_date )
    assert( out_of_date )

    # now change the ticket no so it won't be found and compare
    ticket.ticket_no="20121012-X1"
    out_of_date = tree_mgr.out_of_date?( ticket.ticket_no, ticket.updated_date )
    assert( out_of_date )
  end

  def test_update_ticket
    # setup workspace
    dir = File.join( @work_dir, "test_update_ticket" )
    c = ARINr::Config.new( dir )
    c.logger.message_level = "NONE"
    c.setup_workspace

    # initialize the managers
    store_mgr = ARINr::Registration::TicketStorageManager.new c
    tree_mgr = ARINr::Registration::TicketTreeManager.new c
    tree_mgr.load

    # get a ticket_msgrefs
    summary_file = File.new( File.join( File.dirname( __FILE__ ) , "ticket-msgrefs.xml" ), "r" )
    doc = REXML::Document.new( summary_file )
    element = doc.root
    ticket = ARINr::Registration::element_to_ticket element

    # put the ticket-msgrefs
    ticket_file = store_mgr.put_ticket ticket, ARINr::Registration::TicketStorageManager::MSGREFS_FILE_SUFFIX
    ticket_node = tree_mgr.put_ticket ticket, ticket_file, "http://ticket/" + ticket.ticket_no

    # get a ticket messasge
    message_file = File.new( File.join( File.dirname( __FILE__ ) , "ticket_message.xml" ), "r" )
    doc = REXML::Document.new( message_file )
    element = doc.root
    message = ARINr::Registration::element_to_ticket_message element

    # put the ticket message
    message_file = store_mgr.put_ticket_message ticket, message
    rest_ref = "http://ticket/" + ticket.ticket_no + "/" + message.id
    message_node = tree_mgr.put_ticket_message ticket_node, message, message_file, rest_ref

    # put the ticket attachment
    attachment = message.attachments[ 0 ]
    attachment_file = store_mgr.prepare_file_attachment ticket, message, attachment.id
    rest_ref = "http://ticket/" + ticket.ticket_no + "/" + message.id + "/" + attachment.id
    attachment_node =
        tree_mgr.put_ticket_attachment ticket_node, message_node, attachment, attachment_file, rest_ref

    tree_mgr.save
  end

end
