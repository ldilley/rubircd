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

module Optional
  # Sends a broadcast message to all users connected to the network
  # This is useful to advise users of upcoming server maintenance and other events
  # This command is limited to administrators and services
  class Broadcast
    def initialize
      @command_name = 'broadcast'
      @command_proc = proc { |user, args| on_broadcast(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = message
    def on_broadcast(user, args)
      unless user.admin || user.service
        Network.send(user, Numeric.err_noprivileges(user.nick))
        return
      end
      if args.length < 1
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'BROADCAST'))
        return
      end
      Server.users.each do |u|
        Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick}: #{args[0]}")
      end
      Log.write(2, "BROADCAST issued by #{user.nick}!#{user.ident}@#{user.hostname}: #{args[0]}")
    end
  end
end
Optional::Broadcast.new
