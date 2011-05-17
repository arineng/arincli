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

      opts.on( "--messages MESSAGE_LEVEL", [ :NONE, :SOME, :ALL ],
        "Specify the message level",
        "  NONE - no messages are to be output",
        "  SOME - some messages but not all",
        "  ALL  - all messages to be outupt" ) do |m|
        config.logger.message_level = m
      end

      opts.on( "--messages-out FILE",
        "FILE where messages will be written." ) do |f|
        config.logger.messages_out = f
      end

      opts.on( "--data DATA_AMOUNT", [ :TERSE, :NORMAL, :EXTRA ],
               "Specify the amount of data",
               "  TERSE  - enough data to identify the object",
               "  NORMAL - normal view of data on objects",
               "  EXTRA  - all data about the object" ) do |d|
        config.logger.data_amount = d
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

