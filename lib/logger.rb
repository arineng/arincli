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

    end

    # Outputs at the :SOME_MESSAGES level
    def mesg message

      raise ArgumentError, "Unknown message log level" if @message_level == nil

      if( @message_level != MessageLevel::NO_MESSAGES )
        @message_out.puts( "# " + message.to_s )
      end

    end

    # Outputs at the :ALL_MESSAGES level
    def trace message

      raise ArgumentError, "Unknown message log level" if @message_level == nil

      if( @message_level != MessageLevel::NO_MESSAGES && @message_level != MessageLevel::SOME_MESSAGES )
        @message_out.puts( "## " + message.to_s )
      end

    end

    # Outputs a datum at :TERSE_DATA level
    def terse item_name, item_value

      raise ArgumentError, "Unknown data log level" if @data_amount == nil

      log_data( item_name, item_value )

    end

    # Outputs a data at :NORMAL_DATA level
    def datum item_name, item_value

      raise ArgumentError, "Unknown data log level" if @data_amount == nil

      if( @data_amount != DataAmount::TERSE_DATA )
        log_data( item_name, item_value )
      end

    end

    def extra item_name, item_value

      raise ArgumentError, "Unknown data log level" if @data_amount == nil

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
      end
    end

  end

end
