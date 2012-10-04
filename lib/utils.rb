# Copyright (C) 2011,2012 American Registry for Internet Numbers

require 'rexml/document'
require 'stringio'
require 'rexml/formatters/transitive'
require 'uri'

module ARINr

  def ARINr::new_element_with_text( element_name, text )
    e = REXML::Element.new( element_name )
    e.text=text
    return e
  end

  def ARINr::new_wrapped_element( wrapper_name, element_name, data )
    e = REXML::Element.new( wrapper_name )
    data.each do |datum|
      e.add_element( ARINr::new_element_with_text( element_name, datum ) )
    end
    return e
  end

  def ARINr::new_number_wrapped_element( wrapper_name, data )
    e = REXML::Element.new( wrapper_name )
    line_no = 1
    data.each do |datum|
      child = ARINr::new_element_with_text( "line", datum )
      child.add_attribute( "number", line_no.to_s )
      e.add_element( child )
      line_no += 1
    end
    return e
  end

  def ARINr::pretty_print_xml_to_s( node )
    sio = StringIO.new
    output = REXML::Output.new sio
    formatter = REXML::Formatters::Transitive.new
    formatter.write( node, output )
    return sio.string
  end

  def ARINr.make_safe( url )
    safe = URI.escape( url )
    safe = URI.escape( safe, "!*'();:@&=+$,/?#[]" )
    return safe
  end
end
