# Copyright (C) 2011,2012,2013 American Registry for Internet Numbers
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


require 'config'

module ARINcli

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
