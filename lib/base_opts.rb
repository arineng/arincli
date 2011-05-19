# Copyright (C) 2011 American Registry for Internet Numbers

require 'optparse'

module ARINr

  # A class to be inherited from for added the standard optons
  class BaseOpts

    # Adds base options for OptParser
    # opts is the OptionParser
    # config is the Config.rb object
    def add_base_opts( opts, config )

      opts.separator ""
      opts.separator "Output Options:"

      opts.on( "--messages MESSAGE_LEVEL",
        "Specify the message level",
        "  none - no messages are to be output",
        "  some - some messages but not all",
        "  all  - all messages to be outupt" ) do |m|
        config.logger.message_level = m.to_s.upcase
        begin
          config.logger.validate_message_level
        rescue
          raise OptionParser::InvalidArgument, m.to_s
        end
      end

      opts.on( "--messages-out FILE",
        "FILE where messages will be written." ) do |f|
        config.logger.messages_out = f
      end

      opts.on( "--data DATA_AMOUNT",
               "Specify the amount of data",
               "  terse  - enough data to identify the object",
               "  normal - normal view of data on objects",
               "  extra  - all data about the object" ) do |d|
        config.logger.data_amount = d.to_s.upcase
        begin
          config.logger.validate_data_amount
        rescue
          raise OptionParser::InvalidArgument, d.to_s
        end
      end

      opts.on( "--data-out FILE",
               "FILE where data will be written." ) do |f|
        config.logger.data_out = f
      end

      opts.separator ""
      opts.separator "General Options:"

      opts.on( "-h", "--help",
        "Show this message" ) do
        config.options.help = true
      end

      return opts
    end

  end


end

