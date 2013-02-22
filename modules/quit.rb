# $Id$
# RubIRCd - An IRC server written in Ruby
# Copyright (C) 2013 Lloyd Dilley (see authors.txt for details) 
# http://www.rubircd.org/
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
  class Quit
    def initialize()
      @command_name = "quit"
      @command_proc = Proc.new() { |user, args| on_quit(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    def command_name
      @command_name
    end

    # args[0..-1] = optional quit message
    def on_quit(user, args)
      quit_message = "Client quit"
      if args.length > 0
        quit_message = args[0..-1].join(" ") # 0 may contain ':' and we already supply it
        if quit_message[0] == ':'
          quit_message = quit_message[1..-1]
        end
        if quit_message.length > Limits::MAXQUIT
          quit_message = quit_message[0..Limits::MAXQUIT]
        end
      end
      if user.nick == '*'
        Network.send(user, "ERROR :Closing link: #{user.hostname} (Quit: Client exited)")
      elsif args.length < 1
        Network.send(user, "ERROR :Closing link: #{user.hostname} (Quit: #{user.nick})")
      else
        Network.send(user, "ERROR :Closing link: #{user.hostname} (Quit: #{quit_message})")
      end
      Network.close(user, quit_message)
    end
  end
end
Standard::Quit.new
