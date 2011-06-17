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

    def empty?
      @children.empty?
    end

  end

  class DataTree

    def initialize
      @roots = []
    end

    def add_root node
      @roots << node if node
    end

    def add_children_as_root node
      node.children.each do |child|
        add_root( child )
      end if node
    end

    def roots
      @roots
    end

    def empty?
      @roots.empty?
    end

    def to_terse_log logger, annotate = false
      @logger = logger
      @data_amount = DataAmount::TERSE_DATA
      to_log( annotate )
    end

    def to_normal_log logger, annotate = false
      @logger = logger
      @data_amount = DataAmount::NORMAL_DATA
      to_log( annotate )
    end

    def to_extra_log logger, annotate = false
      @logger = logger
      @data_amount = DataAmount::EXTRA_DATA
      to_log( annotate )
    end

    private

    def to_log annotate
      @logger.start_data_item
      num_count = 1
      @roots.each do |root|
        if annotate
          s = format( "%3d. %s", num_count, root.to_s )
        else
          s = root.to_s
        end
        @logger.log_tree_item( @data_amount, s )
        if annotate
          prefix = "    "
        else
          prefix = ""
        end
        root.children.each do |child|
          rprint( root, child, prefix )
        end if root.children() != nil
        num_count += 1
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
