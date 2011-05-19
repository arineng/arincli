# Copyright (C) 2011 American Registry for Internet Numbers

require 'enum'

module ARINr

  # Controls the type of informational messages that are about the function of the application.
  class MessageLevel < ARINr::Enum

    # no messages
    MessageLevel.add_item( :NO_MESSAGES, "NONE" )

    # some messages
    MessageLevel.add_item( :SOME_MESSAGES, "SOME" )

    # all messages
    MessageLevel.add_item( :ALL_MESSAGES, "ALL" )

  end

  # Controls the amount of data
  class DataAmount < ARINr::Enum

    # a terse amount of data
    DataAmount.add_item( :TERSE_DATA, "TERSE" )

    # a normal amount of data
    DataAmount.add_item( :NORMAL_DATA, "NORMAL" )

    # an extra amount of data
    DataAmount.add_item( :EXTRA_DATA, "EXTRA" )

  end

  # A logger for this application.
  class Logger

    attr_accessor :message_level, :data_amount, :message_out, :data_out, :item_name_length, :item_name_rjust

    def initialize

      @message_level = MessageLevel::SOME_MESSAGES
      @data_amount = DataAmount::NORMAL_DATA
      @message_out = $stderr
      @data_out = $stdout
      @item_name_length = 25
      @item_name_rjust = true

      @message_last_written_to = false
      @data_last_written_to = false

    end

    def validate_message_level
      raise ArgumentError, "Message log level not defined" if @message_level == nil
      raise ArgumentError, "Unknown message log level '" + @message_level.to_s + "'" if ! MessageLevel.has_value?( @message_level.to_s )
    end

    def validate_data_amount
      raise ArgumentError, "Data log level not defined" if @data_amount == nil
      raise ArgumentError, "Unknown data log level '" + @data_amount.to_s + "'" if ! DataAmount.has_value?( @data_amount.to_s )
    end

    def start_data_item
      if( @data_last_written_to )
        @data_out.puts
      elsif( @data_out == $stdout && @message_out == $stderr && @message_last_written_to )
        @data_out.puts
      elsif( @data_out == @message_out && @message_last_written_to )
        @data_out.puts
      end
    end

    def end_data_item
      #do nothing for now
    end

    def end_run
      start_data_item
    end

    # Outputs at the :SOME_MESSAGES level
    def mesg message

      validate_message_level()

      if( @message_level != MessageLevel::NO_MESSAGES )
        @message_out.puts( "# " + message.to_s )
        @message_last_written_to = true
      end

    end

    # Outputs at the :ALL_MESSAGES level
    def trace message

      validate_message_level()

      if( @message_level != MessageLevel::NO_MESSAGES && @message_level != MessageLevel::SOME_MESSAGES )
        @message_out.puts( "## " + message.to_s )
        @message_last_written_to = true
      end

    end

    # Outputs a datum at :TERSE_DATA level
    def terse item_name, item_value

      validate_data_amount()

      log_data( item_name, item_value )

    end

    # Outputs a data at :NORMAL_DATA level
    def datum item_name, item_value

      validate_data_amount()

      if( @data_amount != DataAmount::TERSE_DATA )
        log_data( item_name, item_value )
      end

    end

    def extra item_name, item_value

      validate_data_amount()

      if( @data_amount != DataAmount::TERSE_DATA && @data_amount != DataAmount::NORMAL_DATA )
        log_data( item_name, item_value )
      end

    end

    private

    def log_data item_name, item_value
      if( item_value != nil && !item_value.to_s.empty? )
        format_string = "%" + @item_name_length.to_s + "s:  %s"
        if( ! @item_name_rjust )
          format_string = "%-" + @item_name_length.to_s + "s:  %s"
        end
        @data_out.puts( format( format_string, item_name, item_value ) )
        @data_last_written_to = true
      end
    end

  end

end
