# Copyright (C) 2011 American Registry for Internet Numbers

# Code based on "Enumerations and Ruby"
#    http://www.rubyfleebie.com/enumerations-and-ruby/

module ARINr

  # A base class for enumerations
  class Enum

    def Enum.add_item( key, value )
      @hash ||= {}
      @hash[ key ] = value
    end

    def Enum.const_missing( key )
      @hash[ key ]
    end

    def Enum.each
      @hash.each { |key,value| yield( key, value ) }
    end

    def Enum.has_value? value
      @hash.value?( value )
    end

    def Enum.values
      @hash.values
    end

  end

end
