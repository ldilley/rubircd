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
  # Sends a ping request to a server with the specified message
  # The server will respond with a pong containing the message
  class Ping
    def initialize
      @command_name = 'ping'
      @command_proc = proc { |user, args| on_ping(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = message
    def on_ping(user, args)
      if args.length < 1
        Network.send(user, Numeric.err_noorigin(user.nick))
        return
      end
      Network.send(user, ":#{Options.server_name} PONG #{Options.server_name} :#{args[0]}")
    end
  end
end
Standard::Ping.new
