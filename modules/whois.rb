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
  class Whois
    def initialize()
      @command_name = "whois"
      @command_proc = Proc.new() { |user, args| on_whois(user, args) }
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

    # args[0] = nick
    def on_whois(user, args)
      # ToDo: Support wildcards per RFC 1459
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "WHOIS"))
        return
      end
      args[0] = args[0].strip
      Server.users.each do |u|
        if u.nick.casecmp(args[0]) == 0
          Network.send(user, Numeric.RPL_WHOISUSER(user.nick, u))
          if u.channels.length > 0
            channel_list = []
            chan = nil
            u.channels.each_key do |c|
              chan = Server.channel_map[c.upcase]
              unless chan == nil
                # Hide private/secret channel from output unless user is a member of the target's channel
                if chan.modes.include?('p') || chan.modes.include?('s')
                  user.channels.each_key do |uc|
                    if uc.casecmp(c) == 0
                      channel_list << c
                    end
                  end
                else
                  channel_list << c
                end
              end
            end
            Network.send(user, Numeric.RPL_WHOISCHANNELS(user.nick, u, channel_list))
          end
          Network.send(user, Numeric.RPL_WHOISSERVER(user.nick, u))
          if u.is_operator && !u.is_admin
            Network.send(user, Numeric.RPL_WHOISOPERATOR(user.nick, u))
          end
          if u.is_admin && !u.is_operator
            Network.send(user, Numeric.RPL_WHOISADMIN(user.nick, u))
          end
          # ToDo: Add is_bot and is_service check later
          if u.is_nick_registered
            Network.send(user, Numeric.RPL_WHOISREGNICK(user.nick, u))
          end
          if u.away_message.length > 0
            Network.send(user, Numeric.RPL_AWAY(user.nick, u))
          end
          # ToDo: If hostname cloaking is enabled for this user, do not send this numeric
          Network.send(user, Numeric.RPL_WHOISACTUALLY(user.nick, u))
          Network.send(user, Numeric.RPL_WHOISIDLE(user.nick, u))
          Network.send(user, Numeric.RPL_ENDOFWHOIS(user.nick, u))
          if u.is_admin && u.nick != user.nick
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** NOTICE: #{user.nick} has performed a WHOIS on you.")
          end
          return
        end
      end
      Network.send(user, Numeric.ERR_NOSUCHNICK(user.nick, args[0]))
    end
  end
end
Standard::Whois.new
