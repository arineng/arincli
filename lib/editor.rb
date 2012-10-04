# Copyright (C) 2011,2012 American Registry for Internet Numbers

require 'config'

module ARINr

  # Used for launching the external editor
  class Editor

    def initialize config
      @config = config
    end

    def edit full_file_name

      mtime = File::mtime( full_file_name )

      editor = @config.config[ "registration" ][ "editor"] || ENV[ "EDITOR" ] || "vi"
      @config.logger.trace( "Invoking editor " + editor + " on " + full_file_name )

      unless Process.fork #Child Process
        exec editor, full_file_name rescue exec "/bin/sh", "-c", editor, full_file_name
      end

      #Parent process
      Process.wait

      if mtime == File::mtime( full_file_name )
        return false
      end
      #else
      return true

    end

  end

end
