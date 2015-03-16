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
  class Names
    def initialize()
      @command_name = "names"
      @command_proc = Proc.new() { |user, args| on_names(user, args) }
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

    # args[0] = channel
    def on_names(user, args)
      if args.is_a?(String)
        args = args
      else
        args = args[0]
      end
      if args.length < 1
        Network.send(user, Numeric.RPL_ENDOFNAMES(user.nick, "*"))
        return
      end
      userlist = []
      channel = Server.channel_map[args.to_s.upcase]
      unless channel == nil
        channel.users.each { |u| userlist << u.get_prefixes(channel.name) + u.nick }
      end
      userlist = userlist[0..-1].join(" ")
      Network.send(user, Numeric.RPL_NAMREPLY(user.nick, args, userlist))
      Network.send(user, Numeric.RPL_ENDOFNAMES(user.nick, args))
    end
  end
end
Standard::Names.new
