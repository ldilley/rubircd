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
  class Wallops
    def initialize()
      @command_name = "wallops"
      @command_alias = "operwall"
      @command_proc = Proc.new() { |user, args| on_wallops(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
      caller.register_command(@command_alias, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
      caller.unregister_command(@command_alias)
    end

    def command_name
      @command_name
    end

    # args[0] = message
    def on_wallops(user, args)
      unless user.is_operator || user.is_admin || user.is_service
        Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
        return
      end
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "WALLOPS"))
        return
      end
      Server.users.each do |u|
        if u.umodes.include?('w')
          Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} WALLOPS :#{args[0]}")
        end
      end
    end
  end
end
Standard::Wallops.new
