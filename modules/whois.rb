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
  # Shows information about a specified nick
  # Private (+p) and secret (+s) channels are not returned unless the issuer
  # is an administrator, an IRC operator, or is in the same channel as the target
  class Whois
    def initialize
      @command_name = 'whois'
      @command_proc = proc { |user, args| on_whois(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = nick
    def on_whois(user, args)
      args = args.join.split
      if args.length < 1
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'WHOIS'))
        return
      end
      Server.users.each do |u|
        next unless u.nick.casecmp(args[0]) == 0
        Network.send(user, Numeric.rpl_whoisuser(user.nick, u))
        if u.channels_length > 0
          channel_list = []
          chan = nil
          u_channels = u.channels_array
          u_channels.each do |c|
            chan = Server.channel_map[c.upcase]
            next if chan.nil?
            next if !user.admin && chan.invisible_nick_in_channel?(u.nick) # hide admins who used IJOIN
            # Hide private/secret channel from output unless user is a member of the target's channel
            if chan.modes.include?('p') || chan.modes.include?('s')
              user_channels = user.channels_array
              user_channels.each { |uc| channel_list << c if uc.casecmp(c) == 0 }
            else
              channel_list << c
            end
          end
          Network.send(user, Numeric.rpl_whoischannels(user.nick, u, channel_list))
        end
        Network.send(user, Numeric.rpl_whoisserver(user.nick, u, true))
        if u.operator && !u.admin
          Network.send(user, Numeric.rpl_whoisoperator(user.nick, u))
        end
        if u.admin && !u.operator
          Network.send(user, Numeric.rpl_whoisadmin(user.nick, u))
        end
        # TODO: Add bot and service check later
        if u.nick_registered
          Network.send(user, Numeric.rpl_whoisregnick(user.nick, u))
        end
        if u.away_message.length > 0
          Network.send(user, Numeric.rpl_away(user.nick, u))
        end
        # Only show (real if using cloaking/virtual host) IP address to self, operator, admin, or service
        if u.nick == user.nick || user.operator || user.admin || user.service
          Network.send(user, Numeric.rpl_whoisactually(user.nick, u))
        end
        Network.send(user, Numeric.rpl_whoisidle(user.nick, u))
        Network.send(user, Numeric.rpl_endofwhois(user.nick, u))
        if u.admin && u.nick != user.nick
          Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** NOTICE: #{user.nick} has performed a WHOIS on you.")
        end
        return
      end
      Network.send(user, Numeric.err_nosuchnick(user.nick, args[0]))
    end
  end
end
Standard::Whois.new
