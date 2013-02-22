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
  class Stats
    def initialize()
      @command_name = "stats"
      @command_proc = Proc.new() { |user, args| on_stats(user, args) }
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

    # args[0] = symbol
    # args[1] = optional server
    def on_stats(user, args)
      unless user.is_operator || user.is_admin || user.is_service
        Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
        return
      end
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "STATS"))
        return
      end
      # ToDo: Handle optional server argument after linking is in a working state
      symbol = args[0].to_s
      if symbol.length > 1 && symbol[0] == ':'
        symbol = symbol[1]
      else
        symbol = symbol[0]
      end
      case symbol
        when 'c' # command statistics
          Command.command_counter_map.each { |key, value| Network.send(user, Numeric.RPL_STATSCOMMANDS(user.nick, key, value.command_count, value.command_recv_bytes)) }
        when 'd' # data transferred
          #Network.send(user, Numeric.RPL_
        when 'g' # glines
        when 'i' # online admins and operators with idle times
        when 'k' # klines
        when 'l' # current client links
        when 'm' # memory usage for certain data structures
        when 'o' # configured opers and admins
        when 'p' # configured server ports
        when 'q' # reserved nicks (qlines)
        when 's' # configured server links
        when 'u' # uptime
        when 'z' # zlines
      end
      Network.send(user, Numeric.RPL_ENDOFSTATS(user.nick, symbol))
    end
  end
end
Standard::Stats.new
