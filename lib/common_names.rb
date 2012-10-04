# Copyright (C) 2011,2012 American Registry for Internet Numbers

module ARINr

  def ARINr::is_last_name name
    is_name "last-names.txt", name
  end

  def ARINr::is_male_name name
    is_name "male-first-names.txt", name
  end

  def ARINr::is_female_name name
    is_name "female-first-names.txt", name
  end

  def ARINr::is_name file_name, name
    retval = false

    file = File.new( File.join( File.dirname( __FILE__ ) , file_name ), "r" )
    file.lines.each do |line|
      if line.start_with?( name )
        retval = true
        break
      end
    end
    file.close

    return retval
  end

end
