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
      args = args.join.split(' ', 2)
      unless user.is_operator || user.is_admin || user.is_service
        Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
        return
      end
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "STATS"))
        return
      end
      # ToDo: Handle optional server argument after linking is in a working state
      if args[0].length > 1 && args[0][0] == ':'
        args[0] = args[0][1]
      else
        args[0] = args[0][0]
      end
      case args[0]
        when 'c' # command statistics
          Command.command_counter_map.each { |key, value| Network.send(user, Numeric.RPL_STATSCOMMANDS(user.nick, key, value.command_count, value.command_recv_bytes)) }
        when 'd' # data transferred
          #Network.send(user, Numeric.RPL_
        when 'g' # glines
          # ToDo: Coming in 0.3a
          # Uses numeric 223 (RPL_STATSGLINE)
        when 'i' # online admins and operators with idle times
          Server.users.each do |u|
            if u.is_admin || u.is_operator || u.is_service
              Network.send(user, Numeric.RPL_STATSDEBUG(u.nick, sprintf("%s (%s) Idle: %i seconds", u.nick, u.hostname, (::Time.now.to_i - u.last_activity))))
            end
          end
        when 'k' # klines
          unless Server.kline_mod == nil
            Server.kline_mod.list_klines().each do |entry|
              Network.send(user, Numeric.RPL_STATSKLINE(user.nick, entry.target, entry.create_time, entry.duration, entry.creator, entry.reason))
            end
          end
        when 'l' # current client links
        when 'm' # memory usage for certain data structures
        when 'o' # configured opers and admins
          Server.opers.each do |entry|
            Network.send(user, Numeric.RPL_STATSOLINE(user.nick, entry.host, entry.nick, "Operator"))
          end
          Server.admins.each do |entry|
            Network.send(user, Numeric.RPL_STATSOLINE(user.nick, entry.host, entry.nick, "Administrator"))
          end
        when 'p' # configured server ports
        when 'q' # reserved nicks (qlines)
          unless Server.qline_mod == nil
            Server.qline_mod.list_qlines().each do |entry|
              Network.send(user, Numeric.RPL_STATSQLINE(user.nick, entry.target, entry.create_time, entry.duration, entry.creator, entry.reason))
              end
          end
        when 's' # configured server links
          # ToDo: Coming in 0.3a
          # Uses numerics 213 (RPL_STATSCLINE) and 244 (RPL_STATSHLINE)
        when 'u' # uptime
          current_time = ::Time.now.to_i
          delta = current_time - Server.start_timestamp
          days = delta / (60 * 60 * 24) # 60 seconds in a minute, 60 minutes in an hour, 24 hours in a day
          delta = delta - days * 60 * 60 * 24
          hours = delta / (60 * 60)
          delta = delta - hours * 60 * 60
          minutes = delta / 60
          delta = delta - minutes * 60
          seconds = delta
          Network.send(user, Numeric.RPL_STATSUPTIME(user.nick, days, hours, minutes, seconds)) # check for negative values later if it's a problem...
        when 'z' # zlines
          unless Server.zline_mod == nil
            Server.zline_mod.list_zlines().each do |entry|
              Network.send(user, Numeric.RPL_STATSZLINE(user.nick, entry.target, entry.create_time, entry.duration, entry.creator, entry.reason))
            end
          end
        # when does not require "end"
      end
      Network.send(user, Numeric.RPL_ENDOFSTATS(user.nick, args[0]))
    end
  end
end
Standard::Stats.new
