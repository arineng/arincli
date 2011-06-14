# Copyright (C) 2011 American Registry for Internet Numbers

require 'arinr_logger'

module ARINr

  class DataNode

    def initialize name
      @name = name
      @children = []
    end

    def add_child node
      @children << node if node
    end

    def to_s
      @name
    end

    def children
      @children
    end

  end

  class DataTree

    def initialize
      @roots = []
    end

    def add_root node
      @roots << node if node
    end

    def to_terse_log logger
      @logger = logger
      @data_amount = DataAmount::TERSE_DATA
      to_log()
    end

    def to_normal_log logger
      @logger = logger
      @data_amount = DataAmount::NORMAL_DATA
      to_log()
    end

    def to_extra_log logger
      @logger = logger
      @data_amount = DataAmount::EXTRA_DATA
      to_log()
    end

    private

    def to_log
      @logger.start_data_item
      @roots.each do |root|
        @logger.log_tree_item( @data_amount, root.to_s )
        prefix = ""
        root.children.each do |child|
          rprint( root, child, prefix )
        end if root.children() != nil
      end
      @logger.end_data_item
    end

    def rprint( parent, node, prefix )
      prefix = prefix.tr( "`", " ") + "  " + ( node == parent.children.last ? "`" : "|" )
      @logger.log_tree_item( @data_amount, prefix + "- " + node.to_s )
      node.children.each do |child|
        rprint( node, child, prefix )
      end if node.children() != nil
    end

  end

end
