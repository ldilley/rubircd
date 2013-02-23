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
  class Userhost
    def initialize()
      @command_name = "userhost"
      @command_proc = Proc.new() { |user, args| on_userhost(user, args) }
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

    # args[0..-1] = space-separated nicks
    def on_userhost(user, args)
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "USERHOST"))
        return
      end
      args = args.join.split
      userhost_list = []
      args.each do |a|
        if userhost_list.length >= Limits::MAXTARGETS
          break
        end
        Server.users.each do |u|
          if u.nick.casecmp(a) == 0
            if u.is_admin || u.is_operator
              userhost_list << "#{u.nick}*=+#{u.ident}@#{u.hostname}"
            else
              userhost_list << "#{u.nick}=+#{u.ident}@#{u.hostname}"
            end
          end
        end
      end
      Network.send(user, Numeric.RPL_USERHOST(user.nick, userhost_list))
    end
  end
end
Standard::Userhost.new
