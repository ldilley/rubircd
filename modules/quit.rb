# RubIRCd - An IRC server written in Ruby
# Copyright (C) 2013 Lloyd Dilley (see authors.txt for details)
# http://www.rubircd.rocks/
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

module Standard
  # Exits from the server with optional reason
  class Quit
    def initialize
      @command_name = 'quit'
      @command_proc = proc { |user, args| on_quit(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = optional quit message
    def on_quit(user, args)
      if args.length > 0
        # Remove leading ':'
        args = args[0][1..-1] if args[0][0] == ':'
        args = args[0][0..Limits::MAXQUIT - 1] if args.length > Limits::MAXQUIT
      else
        args = 'Client quit'
      end
      if user.nick == '*'
        Network.send(user, "ERROR :Closing link: #{user.hostname} (Quit: Client exited)")
      else
        Network.send(user, "ERROR :Closing link: #{user.hostname} (Quit: #{args})")
      end
      Network.close(user, args, false)
    end
  end
end
Standard::Quit.new
