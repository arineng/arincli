# Copyright (C) 2011 American Registry for Internet Numbers

require 'rexml/document'

module ARINr

  module Registration

    class TicketSummary
      attr_accessor :ticket_no, :created_date, :resolved_date, :closed_date, :updated_date
      attr_accessor :ticket_type, :ticket_status, :ticket_resolution
    end

    def Registration::element_to_ticket_summary element
      ticket = ARINr::Registration::TicketSummary.new
      ticket.ticket_no=element.elements[ "ticketNo" ].text
      ticket.created_date=element.elements[ "createdDate" ].text
      ticket.resolved_date=element.elements[ "resolvedDate" ].text if element.elements[ "resolvedDate" ]
      ticket.closed_date=element.elements[ "closedDate" ].text if element.elements[ "closedDate" ]
      ticket.updated_date=element.elements[ "updatedDate" ].text if element.elements[ "updatedDate" ]
      ticket.ticket_type=element.elements[ "webTicketType" ].text
      ticket.ticket_status=element.elements[ "webTicketStatus" ].text
      ticket.ticket_resolution=element.elements[ "webTicketResolution" ].text if element.elements[ "webTicketResolution" ]
      return ticket
    end

  end

end
