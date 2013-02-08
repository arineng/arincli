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


require 'optparse'
require 'rexml/document'
require 'base_opts'
require 'config'
require 'erb'
require 'constants'
require 'reg_rws'
require 'ticket_reg'
require 'editor'
require 'data_tree'
require 'time'
require 'tempfile'
require 'uri'

module ARINcli

  module Registration

    class TicketMain < ARINcli::BaseOpts

      def initialize args, config = nil

        if config
          @config = config
        else
          @config = ARINcli::Config.new( ARINcli::Config::formulate_app_data_dir() )
        end

        @opts = OptionParser.new do |opts|

          opts.banner = "Usage: ticket [options] [TICKET_NO]"

          opts.separator ""
          opts.separator "Actions:"

          opts.on( "-c", "--check",
                   "Checks to see if a given ticket or all tickets have been updated." ) do |check|
            @config.options.check_ticket = true
          end

          opts.on( "-u", "--update",
                   "Downloads a given ticket if updated or all updated tickets." ) do |check|
            @config.options.update_ticket = true
          end

          opts.on( "--force-update",
                   "Forces a download of a given ticket or all tickets." ) do |check|
            @config.options.update_ticket = true
            @config.options.force_update = true
          end

          opts.on( "-s", "--show",
                   "Shows information on a given ticket or summary of all tickets." ) do |check|
            @config.options.show_ticket = true
          end

          opts.on( "--remove",
                   "Removes a ticket from local storage." ) do |check|
            @config.options.remove_ticket = true
          end

          opts.on( "-m", "--message",
                   "Sends a message to be attached to a ticket.") do |msg|
            @config.options.message_ticket = true
          end

          opts.on( "-f FILE", "--file FILE",
                   "Sends a message to be attached to a ticket.") do |file|
            @config.options.data_file_specified = true
            @config.options.data_file = file
          end

          opts.separator ""
          opts.separator "Communications Options:"

          opts.on( "-U", "--url URL",
                   "The base URL of the Registration RESTful Web Service." ) do |url|
            @config.config[ "registration" ][ "url" ] = url
          end

          opts.on( "-A", "--apikey APIKEY",
                   "The API KEY to use with the RESTful Web Service." ) do |apikey|
            @config.config[ "registration" ][ "apikey" ] = apikey.to_s.upcase
          end

        end

        add_base_opts( @opts, @config )

        begin
          @opts.parse!( args )
        rescue OptionParser::InvalidArgument => e
          puts e.message
          puts "use -h for help"
          exit
        end
        @config.options.argv = args

      end

      def run

        if( @config.options.help )
          help()
          return
        end

        @config.logger.mesg( ARINcli::VERSION )
        @config.setup_workspace
        @store_mgr = ARINcli::Registration::TicketStorageManager.new @config

        if @config.options.argv[ 0 ] && @config.options.argv[ 0 ] =~ ARINcli::DATA_TREE_ADDR_REGEX
          tree = @config.load_as_yaml( ARINcli::TICKET_LASTTREE_YAML )
          v = nil
          # this is a short cut that basically says go consult the ticket tree db
          # it is an optimization to stop from saving the ticket tree db as the last ticket/ticket lis
          if tree != nil && tree.roots != nil && tree.roots[ 0 ].rest_ref == ARINcli::TICKET_TREE_YAML
            tree = get_tree_mgr.get_ticket_tree
          end
          v = tree.find_node @config.options.argv[ 0 ]
          @config.options.argv[ 0 ] = v if v
        end

        if @config.options.check_ticket
          @config.logger.run_pager
          check_tickets()
        elsif @config.options.update_ticket
          update_tickets()
        elsif @config.options.show_ticket
          @config.logger.run_pager
          show_tickets()
        elsif @config.options.remove_ticket
          remove_tickets
        elsif @config.options.message_ticket
          message_ticket
        else
          @config.logger.run_pager
          show_tickets()
        end

        @config.logger.end_run
        @tree_mgr.save if @tree_mgr

      end

      def get_tree_mgr
        if @tree_mgr == nil
          @tree_mgr = ARINcli::Registration::TicketTreeManager.new @config
          @tree_mgr.load
        end
        @tree_mgr
      end

      def help

        puts ARINcli::VERSION
        puts ARINcli::COPYRIGHT
        puts <<HELP_SUMMARY

This program uses ARIN's Reg-RWS RESTful API to query ARIN's Registration database.
The general usage is "ticket TICKET_NO" where TICKET_NO is the identifier of the ticket
to be acted upon.

HELP_SUMMARY
        puts @opts.help
        exit

      end

      def check_tickets

        if @config.options.argv[ 0 ] != nil && @config.options.argv[ 0 ].is_a?( ARINcli::DataNode )
          @config.options.argv[ 0 ] = @config.options.argv[ 0 ].handle
        end
        last_tree = ARINcli::DataTree.new

        reg = ARINcli::Registration::RegistrationService.new @config, ARINcli::TICKET_TX_PREFIX
        element = reg.get_ticket_summary( @config.options.argv[ 0 ] )
        if ! element
          @config.logger.mesg( "Unable to get ticket summary information." )
        elsif element.name == "collection"
          element.elements.each( "ticket" ) do |ticket|
            check_ticket( ticket, last_tree )
          end
        elsif element.name == "ticket"
          check_ticket( element, last_tree )
        else
          @config.logger.mesg( "Unimplemented ticket check!" )
        end

        if !last_tree.empty?
          last_tree.to_terse_log( @config.logger, true )
          @config.save_as_yaml( ARINcli::TICKET_LASTTREE_YAML, last_tree )
        else
          @config.logger.mesg( "No tickets have been updated." )
        end
        return last_tree
      end

      def check_ticket( element, last_tree )
        ticket = ARINcli::Registration.element_to_ticket element
        if get_tree_mgr.out_of_date?( ticket.ticket_no, ticket.updated_date ) || @config.options.force_update
          s = format( "%-20s %-15s %-15s", ticket.ticket_no, ticket.ticket_type, ticket.ticket_status )
          ticket_node = ARINcli::DataNode.new( s, ticket.ticket_no )
          last_tree.add_root( ticket_node )
        end
      end

      def remove_tickets
        if @config.options.argv[ 0 ] != nil
          ticket_no = @config.options.argv[ 0 ]
          if @config.options.argv[ 0 ].is_a?( ARINcli::DataNode )
            ticket_no = @config.options.argv[ 0 ].handle
          end
          @config.logger.mesg( "Removing #{ticket_no}" )
          @store_mgr.remove_ticket ticket_no
          get_tree_mgr.remove_ticket ticket_no
        else
          @config.logger.mesg( "Removing all tickets" )
          @store_mgr.remove_all_tickets
          get_tree_mgr.remove_all_tickets
        end
      end

      def message_ticket
        if @config.options.argv[ 0 ] == nil
          @config.logger.mesg( "A ticket must be specified." )
        else
          ticket_no = @config.options.argv[ 0 ]
          if @config.options.argv[ 0 ].is_a?( ARINcli::DataNode )
            ticket_no = @config.options.argv[ 0 ].handle
          end
          ticket_node = get_tree_mgr.get_ticket_node ticket_no
          if ticket_node == nil
            @config.logger.mesg( "Cannot find ticket #{ticket_no}" )
          else
            if !@config.options.data_file_specified
              create_data_file()
              editor = ARINcli::Editor.new( @config )
              edited = editor.edit( @config.options.data_file )
              if ! edited
                @config.logger.mesg( "No modifications made to message file. Aborting." )
                return
              end
            end
            @config.logger.mesg( "Sending message for #{ticket_no}")
            message = parse_data_file
            message_xml = ARINcli::Registration::ticket_message_to_element message, false
            send_data = ARINcli::pretty_print_xml_to_s( message_xml )
            reg = ARINcli::Registration::RegistrationService.new @config, ARINcli::TICKET_TX_PREFIX
            new_message_xml = reg.put_ticket_message ticket_no, send_data
            new_message = ARINcli::Registration::element_to_ticket_message new_message_xml
            message.created_date=new_message.created_date
            message.id=new_message.id
            @config.logger.mesg( "Message assigned ID #{message.id}" )
            storage_file = @store_mgr.put_ticket_message( ticket_no, message )
            message_uri = reg.ticket_message_uri ticket_no, message.id, false
            get_tree_mgr.put_ticket_message( ticket_node, message, storage_file, message_uri )
          end
        end
      end

      def parse_data_file
        message = ARINcli::Registration::TicketMessage.new
        file = File.new( @config.options.data_file, "r" )
        file.each_line do |line|
          if line.start_with?( ARINcli::SUBJECT_HEADER ) && message.subject == nil
            s = line.sub( ARINcli::SUBJECT_HEADER, "" ).strip
            message.subject=s if s != ARINcli::SUBJECT_DEFAULT
          else
            message.text = [] if message.text == nil
            message.text << line
          end
        end
        file.close
        return message
      end

      def create_data_file
        template = ""
        file = File.new(File.join(File.dirname(__FILE__), "ticket_message.erb"), "r")
        file.each_line do |line|
          template << line
        end
        file.close
        erb_template = ERB.new(template, 0, "<>")
        s = erb_template.result( binding )
        @config.options.data_file = @config.make_file_name(ARINcli::TICKET_MESSAGE_FILE)
        file = File.new(@config.options.data_file, "w")
        file.puts( s )
        file.close
      end

      def update_tickets
        updated = check_tickets
        reg = ARINcli::Registration::RegistrationService.new @config, ARINcli::TICKET_TX_PREFIX
        updated.roots.each do |ticket|
          ticket_no = ticket.handle
          @config.logger.mesg( "Getting ticket #{ticket_no}" )
          ticket_uri = reg.ticket_uri ticket_no
          element = reg.get_data ticket_uri
          new_ticket = ARINcli::Registration.element_to_ticket element
          new_ticket_file = @store_mgr.put_ticket new_ticket
          new_ticket_node = get_tree_mgr.put_ticket( new_ticket, new_ticket_file, ticket_uri )
          sort_needed = false
          new_ticket.messages.each do |message|
            if get_tree_mgr.get_ticket_message( new_ticket_node, message ) == nil || @config.options.force_update
              sort_needed = true
              @config.logger.mesg( "Getting message #{ticket_no} : #{message.id}" )
              message_uri = reg.ticket_message_uri( ticket_no, message.id )
              message_element = reg.get_data message_uri
              message_xml = ARINcli::Registration::element_to_ticket_message message_element
              message_file = @store_mgr.put_ticket_message( new_ticket, message_xml )
              message_node =
                      get_tree_mgr.put_ticket_message(
                              new_ticket_node, message_xml, message_file, message_uri )
              message.attachments.each do |attachment|
                if get_tree_mgr.get_ticket_attachment( new_ticket_node, message_node, attachment ) == nil ||
                        @config.options.force_update
                  @config.logger.mesg( "Getting attachment #{ticket_no} : #{message.id} : #{attachment.id}" )
                  attachment_uri = reg.ticket_attachment_uri( ticket_no, message.id, attachment.id )
                  attachment_file = @store_mgr.prepare_file_attachment( new_ticket, message, attachment.id )
                  f = File.open( attachment_file, "w" )
                  reg.get_data_as_stream( attachment_uri, f )
                  f.close
                  get_tree_mgr.put_ticket_attachment(
                          new_ticket_node, message_node, attachment, attachment_file, attachment_uri)
                else
                  @config.logger.mesg( "Skipping attachment #{ticket_no} : #{message.id} : #{attachment.id}" )
                end
              end if message.attachments
            else
              @config.logger.mesg( "Skipping message #{ticket_no} : #{message.id}" )
            end
          end
          if sort_needed
            @config.logger.mesg( "Sorting messages for #{ticket_no}" )
            get_tree_mgr.sort_messages( new_ticket_node )
          end
        end
      end

      def show_tickets
        if @config.options.argv[ 0 ]
          if @config.options.argv[ 0 ].is_a?( ARINcli::DataNode )
            node = @config.options.argv[ 0 ]
            if node.data == nil || node.data[ "node_type" ] == nil
              show_ticket_by_no( node.handle )
            else
              case node.data["node_type"]
                when "ticket"
                  return show_ticket(node)
                when "message"
                  return show_message(-1, node)
                when "attachment"
                  return detach_attachment(node)
              end
            end
          else
            return show_ticket_by_no( @config.options.argv[ 0 ])
          end
        else
          tree = get_tree_mgr.get_ticket_tree
          if tree.empty?
            @config.logger.mesg( "No tickets found." )
          else
            tree.to_terse_log( @config.logger, true )
            # instruct the load of the last tree to look at the ticket tree on next invokation
            fake_tree = ARINcli::DataTree.new
            redirect_node = ARINcli::DataNode.new( "redirect to ticket db", nil, ARINcli::TICKET_TREE_YAML, nil )
            fake_tree.add_root( redirect_node )
            @config.save_as_yaml( ARINcli::TICKET_LASTTREE_YAML, fake_tree )
          end
        end
      end

      def show_ticket_by_no( ticket_no )
        ticket_node = get_tree_mgr.get_ticket_node ticket_no
        if ticket_node == nil
          @config.logger.mesg("Ticket #{ticket_no} cannot be found.")
          return nil
        end
        return show_ticket(ticket_node)
      end

      def show_ticket( ticket_node )
        last_tree = ARINcli::DataTree.new
        last_tree.add_root(ticket_node)
        if last_tree.to_normal_log(@config.logger, true)
          @config.save_as_yaml(ARINcli::TICKET_LASTTREE_YAML, last_tree)
        end
        ticket = @store_mgr.get_ticket(ticket_node.handle)
        @config.logger.start_data_item
        @config.logger.terse("Ticket Number", ticket.ticket_no)
        @config.logger.terse("Status", ticket.ticket_status)
        @config.logger.terse("Resolution", ticket.ticket_resolution) if ticket.ticket_resolution
        @config.logger.datum("Type", ticket.ticket_type)
        @config.logger.terse("Created", Time.parse(ticket.created_date).rfc2822) if ticket.created_date
        @config.logger.datum("Resolved", Time.parse(ticket.resolved_date).rfc2822) if ticket.resolved_date
        @config.logger.datum("Closed", Time.parse(ticket.closed_date).rfc2822) if ticket.closed_date
        @config.logger.datum("Updated", Time.parse(ticket.updated_date).rfc2822) if ticket.updated_date
        @config.logger.extra("Message Count", ticket_node.children.size) if ticket_node.children
        @config.logger.end_data_item
        ticket_node.children.each_with_index do |message_node, message_index|
          show_message(message_index, message_node)
        end if ticket_node.children
      end

      def show_message(message_index, message_node)
        message_banner_index = (message_index + 1).to_s
        if message_index < 0
          message_banner_index = ""
        end
        message = @store_mgr.get_ticket_message(message_node.data["storage_file"])
        @config.logger.start_data_item
        log_banner "BEGIN MESSAGE #{message_banner_index}"
        subject = "Subject:    " + message.subject if message.subject
        subject = "Subject:    ( NO SUBJECT GIVEN )" if !message.subject
        @config.logger.raw ARINcli::DataAmount::TERSE_DATA, subject
        @config.logger.raw ARINcli::DataAmount::TERSE_DATA, "Category:   " + message.category if message.category
        @config.logger.raw ARINcli::DataAmount::TERSE_DATA, "Date:       " + Time.parse(message.created_date).rfc2822 if message.created_date
        @config.logger.raw ARINcli::DataAmount::TERSE_DATA, "Message Id: " + message.id if message.id
        @config.logger.raw ARINcli::DataAmount::TERSE_DATA, ""
        message.text.each do |line|
          line = "" if !line
          auto_wrap = @config.config["output"]["auto_wrap"]
          if auto_wrap && line.length > auto_wrap
            while line.length > auto_wrap
              cutoff = line.rindex(" ", auto_wrap)
              cutoff = auto_wrap if cutoff == 0
              @config.logger.raw ARINcli::DataAmount::TERSE_DATA, line[0..cutoff]
              line = line[(cutoff+1)..-1]
            end
            @config.logger.raw ARINcli::DataAmount::TERSE_DATA, line
          else
            @config.logger.raw ARINcli::DataAmount::TERSE_DATA, line
          end
        end if message.text
        @config.logger.raw ARINcli::DataAmount::TERSE_DATA, ""
        if message_node.children && message_node.children.size > 0
          log_banner "ATTACHMENTS"
          message_node.children.each_with_index do |attachment_node, attachment_index|
            s = format("%2d. %s", attachment_index + 1, attachment_node)
            @config.logger.raw ARINcli::DataAmount::TERSE_DATA, s
          end
        end
        log_banner "END MESSAGE #{message_banner_index}"
        @config.logger.end_data_item
      end

      def detach_attachment( attachment_node )
        name = attachment_node.to_s
        if @config.options.argv[ 1 ]
          name = @config.options.argv[ 1 ]
        end
        @config.logger.mesg( "Putting attachment in #{name}" )
        FileUtils.copy( attachment_node.data[ "storage_file" ], name )
      end

      def log_banner banner, fill_char = "-"
        s = fill_char*30 + " " + banner + " "
        (s.length..80).each {|x| s << fill_char}
        @config.logger.raw ARINcli::DataAmount::TERSE_DATA, s
      end

    end

  end

end
