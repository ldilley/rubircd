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
  class Ison
    def initialize()
      @command_name = "ison"
      @command_proc = Proc.new() { |user, args| on_ison(user, args) }
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

    # args[0..-1] = nick or space-separated nicks
    def on_ison(user, args)
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "ISON"))
        return
      end
      args = args.join.split
      if args[0][0] == ':'
        args[0] = args[0][1..-1] # remove leading ':'
      end
      good_nicks = []
      Server.users.each do |u|
        args.each do |n|
          if u.nick.casecmp(n) == 0
            good_nicks << u.nick
          end
        end
      end
      Network.send(user, Numeric.RPL_ISON(user.nick, good_nicks))
    end
  end
end
Standard::Ison.new
