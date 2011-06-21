# Copyright (C) 2011 American Registry for Internet Numbers

require 'yaml'
require 'arinr_logger'

module ARINr

  class DataNode

    attr_accessor :alert, :data, :children

    def initialize name, data = nil
      @name = name
      @children = []
      @data = data
    end

    def add_child node
      @children << node if node
    end

    def to_s
      @name
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

    def find_data data_address
      node = ARINr::DataNode.new( "fakeroot" )
      node.children=roots
      data_address.split( /\D/ ).each do |index_str|
        index = index_str.to_i - 1
        node = node.children[ index ]
      end
      if node != nil
        return node.data
      end
      #else
      return nil
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
      num_count = 1
      @roots.each do |root|
        @logger.start_data_item
        if annotate
          if root.alert
            s = format( "   # %s", root.to_s )
          elsif root.data
            s = format( "%3d= %s", num_count, root.to_s )
          else
            s = format( "%3d. %s", num_count, root.to_s )
          end
        else
          s = root.to_s
        end
        @logger.log_tree_item( @data_amount, s )
        if annotate
          prefix = " "
          child_num = 1
        else
          prefix = ""
          child_num = 0
        end
        root.children.each do |child|
          rprint( child_num, root, child, prefix )
          child_num += 1 if child_num > 0
        end if root.children() != nil
        num_count += 1
        @logger.end_data_item
      end
    end

    def rprint( num, parent, node, prefix )
      if( num > 0 )
        spacer = "    "
        if node.alert
          num_str = format( " # ", num )
        elsif node.data
          num_str = format( " %d= ", num )
        else
          num_str = format( " %d. ", num )
        end
        num_str = num_str.rjust( 7, "-" )
        child_num = 1
      else
        spacer = "  "
        num_str = "- "
        child_num = 0
      end
      prefix = prefix.tr( "`", " ") + spacer + ( node == parent.children.last ? "`" : "|" )
      @logger.log_tree_item( @data_amount, prefix + num_str + node.to_s )
      node.children.each do |child|
        rprint( child_num, node, child, prefix )
        child_num += 1 if child_num > 0
      end if node.children() != nil
    end

  end

end
